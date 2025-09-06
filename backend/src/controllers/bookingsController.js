
const Booking = require('../models/Booking');
const Service = require('../models/Service');
const Availability = require('../models/Availability');
const { DateTime } = require('luxon');
const { ok, created, error } = require('../utils/response');
const { bookingPolicies } = require('../policies');

// Helpers for business thresholds
function getMinutes(name, fallback) {
  const raw = process.env[name];
  if (raw && !Number.isNaN(parseInt(raw))) return parseInt(raw);
  // In non-production, prefer a very small window unless explicitly set
  if (process.env.NODE_ENV !== 'production' && fallback === 2880) return 1;
  return fallback;
}
const BOOKING_MIN_LEAD_MINUTES = getMinutes('BOOKING_MIN_LEAD_MINUTES', 2880);
const CANCELLATION_MIN_LEAD_MINUTES = getMinutes('CANCELLATION_MIN_LEAD_MINUTES', 2880);
const ALLOW_ADMIN_LEAD_BYPASS = (() => {
  const raw = process.env.ALLOW_ADMIN_LEAD_BYPASS;
  if (typeof raw === 'string') return ['true', '1', 'yes'].includes(raw.toLowerCase());
  // Default: allow in non-production to facilitate QA
  return process.env.NODE_ENV !== 'production';
})();

function minutesUntilStart(bookingOrParams) {
  const { schedule, tz } = bookingOrParams;
  let startDateTime;
  if (schedule?.startUtc) {
    startDateTime = DateTime.fromJSDate(new Date(schedule.startUtc));
  } else if (schedule?.date && schedule?.startTime) {
    startDateTime = DateTime.fromISO(`${schedule.date}T${schedule.startTime}`, { zone: tz || schedule.timezone || 'Asia/Jerusalem' }).toUTC();
  } else {
    return null;
  }
  return startDateTime.diffNow('minutes').minutes;
}

async function createBooking(req, res) {
  try {
  const actor = req.user;
  const { serviceId, schedule, location, notes, clientId, clientType, emergency } = req.body;

    const service = await Service.findById(serviceId).populate('provider');
    if (!service || !service.isActive) return error(res, 404, 'Service not available');

  const priceType = service.price?.type || 'hourly';
  let baseAmount = service.price.amount;

  // Resolve client for the booking (User or Provider)
  // - Anyone can book. A provider/admin can pass clientId and clientType ('User'|'Provider').
  // - If not provided, default to actor and infer type from actor.role
  let resolvedClientId = clientId || actor._id;
  let resolvedClientRef = (clientType === 'Provider' || clientType === 'User') ? clientType : (actor.role === 'provider' ? 'Provider' : 'User');

    // Timezone-aware start/end
    const tz = schedule.timezone || 'Asia/Jerusalem';
    const startDateTime = DateTime.fromISO(`${schedule.date}T${schedule.startTime}`, { zone: tz });
    const endDateTime = DateTime.fromISO(`${schedule.date}T${schedule.endTime}`, { zone: tz });
    if (!startDateTime.isValid || !endDateTime.isValid || endDateTime <= startDateTime) {
      return error(res, 400, 'Invalid schedule times');
    }

    // Compute duration (supports multi-day bookings)
    const durationMinutes = Math.max(0, endDateTime.diff(startDateTime, 'minutes').minutes);

    // Enforce min lead time for booking creation (supports emergency override)
    let minLead = BOOKING_MIN_LEAD_MINUTES;
    const wantEmergency = !!emergency;
    if (wantEmergency && service.emergencyEnabled) {
      // Default emergency short-notice lead time
      minLead = 120; // 2 hours
      const svcLead = parseInt(service.emergencyLeadTimeMinutes);
      if (!Number.isNaN(svcLead)) {
        minLead = Math.max(0, svcLead);
      }
    }
    const minutesLead = minutesUntilStart({ schedule: { ...schedule, startUtc: startDateTime.toUTC().toJSDate() }, tz });
    if (minutesLead !== null && minutesLead < minLead) {
      const isAdmin = actor && actor.role === 'admin';
      if (!(isAdmin && ALLOW_ADMIN_LEAD_BYPASS)) {
        return error(res, 422, 'Booking must be at least the minimum lead time in advance', { code: 'booking_min_lead_time', minMinutes: minLead });
      }
    }

    // If emergency, validate emergency type and apply emergency rate multiplier
    const requestedEmergencyType = req.body.emergencyType || null; // e.g. 'medicine_pickup'
      if (wantEmergency) {
      if (!service.emergencyEnabled) return error(res, 422, 'Emergency booking not supported for this service');
      if (requestedEmergencyType && Array.isArray(service.emergencyTypes) && service.emergencyTypes.length) {
        if (!service.emergencyTypes.includes(requestedEmergencyType)) {
          return error(res, 422, 'Service not certified for requested emergency type');
        }
      }
      const multiplier = Number(service.emergencyRateMultiplier) || 1.0;
      if (priceType === 'hourly') {
        baseAmount = Math.round(baseAmount * multiplier);
      }
    }

    // Compute total amount after any emergency multiplier
    let totalAmount = baseAmount;
    if (priceType === 'hourly') {
      const hours = durationMinutes / 60;
      totalAmount = Math.round(baseAmount * hours);
    }

    // Check provider availability (emergency vs normal)
    const avail = await Availability.findOne({ provider: service.provider._id });
    let isAvailable = true;
    if (avail) {
      const provTz = avail.timezone || tz;
      const day = startDateTime.setZone(provTz).toFormat('cccc').toLowerCase();
      const dateKey = startDateTime.setZone(provTz).toFormat('yyyy-MM-dd');
      let windows = [];
      if (wantEmergency) {
        // Merge base weekly + emergencyWeekly + default emergency extras so
        // emergency includes normal slots plus extra late-night/early slots.
        const defaultEmergencyExtras = [ { start: '00:00', end: '06:00' }, { start: '22:00', end: '23:59' } ];
        // Merge exceptions for the date
        const baseEx = (avail.exceptions || []).find(e => e.date === dateKey);
        const emergEx = (Array.isArray(avail.emergencyExceptions) && avail.emergencyExceptions.length > 0)
          ? (avail.emergencyExceptions || []).find(e => e.date === dateKey)
          : null;
        const mergedExWins = [];
        if (baseEx && Array.isArray(baseEx.windows)) mergedExWins.push(...baseEx.windows.map(w => ({ start: w.start, end: w.end })));
        if (emergEx && Array.isArray(emergEx.windows)) mergedExWins.push(...emergEx.windows.map(w => ({ start: w.start, end: w.end })));
        if (mergedExWins.length) {
          // remove duplicates
          const seen = new Set();
          windows = mergedExWins.filter(w => {
            const k = `${w.start}-${w.end}`;
            if (seen.has(k)) return false; seen.add(k); return true;
          });
        }

        // If no exception windows, merge weekly slots
        if (windows.length === 0) {
          const baseWeekly = (avail.weekly || {})[day] || [];
          const emergWeekly = (avail.emergencyWeekly && Object.keys(avail.emergencyWeekly || {}).length > 0)
            ? (avail.emergencyWeekly || {})[day] || []
            : [];
          const combined = [...baseWeekly.map(w => ({ start: w.start, end: w.end })), ...emergWeekly.map(w => ({ start: w.start, end: w.end })), ...defaultEmergencyExtras];
          const seen = new Set();
          windows = combined.filter(w => { const k = `${w.start}-${w.end}`; if (seen.has(k)) return false; seen.add(k); return true; });
        }

        // Final fallback minimal emergency window
        if (windows.length === 0) windows = [{ start: '22:00', end: '23:59' }];
      } else {
        const ex = (avail.exceptions || []).find(e => e.date === dateKey);
        if (ex) windows = (ex.windows || []).map(w => ({ start: w.start, end: w.end }));
        if (windows.length === 0) {
          windows = (avail.weekly?.[day] || []).map(w => ({ start: w.start, end: w.end }));
        }
      }
  const within = (w) => w.start <= schedule.startTime && w.end >= schedule.endTime;
      isAvailable = windows.length ? windows.some(within) : true;
    }
    if (!isAvailable) return error(res, 400, 'Provider not available at requested time');

    // Anti double-booking for provider (overlap with non-cancelled)
    const overlap = await Booking.findOne({
      provider: service.provider._id,
      status: { $in: ['pending','confirmed'] },
      $or: [
        { 'schedule.startUtc': { $lt: endDateTime.toUTC().toJSDate() }, 'schedule.endUtc': { $gt: startDateTime.toUTC().toJSDate() } }
      ]
    }).select('_id');
    if (overlap) return error(res, 409, 'Time slot already booked');

  const booking = await Booking.create({
      client: resolvedClientId,
      clientRef: resolvedClientRef,
      provider: service.provider._id,
      service: service._id,
      serviceDetails: { title: service.title, description: service.description, category: service.category },
      schedule: {
        ...schedule,
        startUtc: startDateTime.toUTC().toJSDate(),
        endUtc: endDateTime.toUTC().toJSDate(),
        timezone: tz,
        duration: Math.round(durationMinutes)
      },
      location,
      pricing: (function(){
        let total = totalAmount;
        const charges = [];
        if (wantEmergency) {
          if (!service.emergencyEnabled) {
            throw new Error('Emergency booking not supported for this service');
          }
          const type = (service.emergencySurcharge && service.emergencySurcharge.type) || 'flat';
          const amountNum = Number((service.emergencySurcharge && service.emergencySurcharge.amount) || 0);
          const calc = type === 'percent' ? Math.round(total * (amountNum / 100)) : Math.round(amountNum);
          if (calc > 0) {
            charges.push({ description: 'Emergency surcharge', amount: calc });
            total += calc;
          }
        }
        return { baseAmount, additionalCharges: charges, totalAmount: total, currency: service.price.currency || 'ILS' };
      })(),
      emergency: wantEmergency,
      emergencyCharge: (function(){
        if (!wantEmergency) return undefined;
        const type = (service.emergencySurcharge && service.emergencySurcharge.type) || 'flat';
        const amountNum = Number((service.emergencySurcharge && service.emergencySurcharge.amount) || 0);
        const calc = type === 'percent' ? Math.round(totalAmount * (amountNum / 100)) : Math.round(amountNum);
        return calc > 0 ? { description: 'Emergency surcharge', amount: calc } : { description: 'Emergency surcharge', amount: 0 };
      })(),
      notes: { clientNotes: notes || '' }
    });

    // Fire-and-forget counters: provider and service
    try {
      if (service.provider?._id) {
        // Increment provider total bookings
        await require('../models/Provider').updateOne(
          { _id: service.provider._id },
          { $inc: { totalBookings: 1 } }
        );
      }
      // Increment service total bookings
      await Service.updateOne({ _id: service._id }, { $inc: { totalBookings: 1 } });
    } catch (incErr) {
      console.warn('Counter increment failed (non-fatal):', incErr?.message || incErr);
    }

    // Return populated booking for immediate UI use
    const populated = await Booking.findById(booking._id)
      .populate('client', 'firstName lastName email')
      .populate({ path: 'provider', select: 'firstName lastName email', model: 'Provider' })
      .populate({ path: 'service', select: 'title category provider', populate: { path: 'provider', select: 'firstName lastName email', model: 'Provider' } });
    return created(res, populated, 'Booking created');
  } catch (e) {
    console.error('createBooking error', e);
    return error(res, 400, e.message || 'Failed to create booking');
  }
}

async function listMyBookings(req, res) {
  try {
    const user = req.user;
    const { status, page, limit, as } = req.query || {};
    // Default for providers: show bookings where they are the provider. If as=client, show bookings they made as a client (clientRef='Provider').
    let filter;
    if (user.role === 'provider') {
      if (as === 'client') {
        filter = { client: user._id, clientRef: 'Provider' };
      } else {
        filter = { provider: user._id };
      }
    } else {
      filter = { client: user._id };
    }
    if (status) filter.status = status;
    const pg = Math.max(parseInt(page) || 1, 1);
    const sz = Math.min(Math.max(parseInt(limit) || 50, 1), 100);

    let q = Booking.find(filter)
      // Use refPath from schema; no explicit model override needed
      .populate({ path: 'client', select: 'firstName lastName email rating' })
      .populate({ path: 'provider', select: 'firstName lastName email rating', model: 'Provider' })
      .populate({ path: 'service', select: 'title category provider', populate: { path: 'provider', select: 'firstName lastName email', model: 'Provider' } })
      .sort({ createdAt: -1 })
      .skip((pg - 1) * sz)
      .limit(sz);

    let bookings = await q;

    // Backfill provider for legacy rows where booking.provider is null
    // Also clean up invalid rating data
    bookings = bookings.map(b => {
      if (!b.provider && b.service && b.service.provider) {
        // clone lean-ish object to avoid mutating Mongoose internals unexpectedly in response
        const obj = b.toObject ? b.toObject() : b;
        obj.provider = b.service.provider;
        return obj;
      }
      return b;
    });

    // Clean up invalid rating data in the background
    for (const booking of bookings) {
      let needsUpdate = false;
      
      // Clean up invalid providerRating - only if it exists and is invalid
      if (booking.providerRating && 
          (!booking.providerRating.rating || 
           booking.providerRating.rating <= 0 || 
           !booking.providerRating.ratedAt)) {
        console.log('🧹 Cleaning up invalid providerRating for booking:', booking._id);
        booking.providerRating = null; // Set to null instead of undefined
        needsUpdate = true;
      }
      
      // Clean up invalid clientRating - only if it exists and is invalid
      if (booking.clientRating && 
          (!booking.clientRating.rating || 
           booking.clientRating.rating <= 0 || 
           !booking.clientRating.ratedAt)) {
        console.log('🧹 Cleaning up invalid clientRating for booking:', booking._id);
        booking.clientRating = null; // Set to null instead of undefined
        needsUpdate = true;
      }
      
      if (needsUpdate) {
        // Save in background without waiting
        booking.save().catch(err => console.error('Error cleaning up rating data:', err));
      }
    }
    return ok(res, bookings);
  } catch (e) {
    console.error('listMyBookings error', e);
    return error(res, 500, 'Failed to fetch bookings');
  }
}

async function getBookingById(req, res) {
  try {
    let booking = await Booking.findById(req.params.id)
      .populate({ path: 'client', select: 'firstName lastName email' })
      .populate({ path: 'provider', select: 'firstName lastName email', model: 'Provider' })
      .populate({ path: 'service', select: 'title category provider', populate: { path: 'provider', select: 'firstName lastName email', model: 'Provider' } });
    if (!booking) return error(res, 404, 'Booking not found');
    if (!booking.provider && booking.service && booking.service.provider) {
      booking = booking.toObject();
      booking.provider = booking.service.provider;
    }
  if (!bookingPolicies.canView(req.user, booking)) return error(res, 403, 'Access denied');
    return ok(res, booking);
  } catch (e) {
    return error(res, 404, 'Booking not found');
  }
}


async function updateBookingStatus(req, res) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return error(res, 404, 'Booking not found');

  const allowed = bookingPolicies.allowedStatusFor(req.user, booking);
  if (!allowed.has(req.body.status)) return error(res, 403, 'Not allowed to set this status');

    const previousStatus = booking.status;
    booking.status = req.body.status;
    booking.updatedAt = Date.now();
    // Admin audit trail
    if (req.user.role === 'admin') {
      booking.adminActions = booking.adminActions || [];
      booking.adminActions.push({
        actor: req.user._id,
        role: 'admin',
        action: 'status_update',
        fromStatus: previousStatus,
        toStatus: booking.status,
        note: req.body?.note || ''
      });
      booking.notes = booking.notes || {};
      const info = `Admin set to ${booking.status}`;
      booking.notes.adminNotes = booking.notes.adminNotes ? `${booking.notes.adminNotes}\n${info}` : info;
    }
    await booking.save();

    // If first time moving to completed, increment provider.completedBookings
  if (previousStatus !== 'completed' && booking.status === 'completed') {
      try {
        await require('../models/Provider').updateOne(
          { _id: booking.provider },
          { $inc: { completedBookings: 1 } }
        );
      } catch (incErr) {
        console.warn('completedBookings increment failed (non-fatal):', incErr?.message || incErr);
      }
    }
    return ok(res, booking, 'Status updated');
  } catch (e) {
    return error(res, 400, 'Failed to update status');
  }
}

// Admin: list all bookings
async function listAllBookings(req, res) {
  try {
    const { status, page, limit } = req.query || {};
    const filter = {};
    if (status) filter.status = status;
    const pg = Math.max(parseInt(page) || 1, 1);
    const sz = Math.min(Math.max(parseInt(limit) || 50, 1), 100);

    const bookings = await Booking.find(filter)
      .populate({ path: 'client', select: 'firstName lastName email' })
      .populate({ path: 'provider', select: 'firstName lastName email', model: 'Provider' })
      .populate({ path: 'service', select: 'title category provider', populate: { path: 'provider', select: 'firstName lastName email', model: 'Provider' } })
      .sort({ createdAt: -1 })
      .skip((pg - 1) * sz)
      .limit(sz);

    return ok(res, bookings);
  } catch (e) {
    console.error('listAllBookings error', e);
    return error(res, 500, 'Failed to fetch bookings');
  }
}

module.exports = { createBooking, listMyBookings, getBookingById, updateBookingStatus, listAllBookings };

// New controller actions (appended for clarity)
async function cancelBooking(req, res) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return error(res, 404, 'Booking not found');
    if (!bookingPolicies.canView(req.user, booking)) return error(res, 403, 'Access denied');
    if (['completed','cancelled'].includes(booking.status)) return error(res, 409, 'Booking is in a final state');

    const mins = minutesUntilStart(booking);
    const now = DateTime.now();
  // Admins can cancel immediately; others require threshold window
  if (req.user.role === 'admin' || (mins !== null && mins >= CANCELLATION_MIN_LEAD_MINUTES)) {
  // Direct cancel
  const prevStatus = booking.status;
  booking.status = 'cancelled';
      booking.cancellation = booking.cancellation || {};
      booking.cancellation.cancelledBy = req.user._id;
      booking.cancellation.cancelledAt = now.toJSDate();
      if (req.user.role === 'admin') {
        booking.adminActions = booking.adminActions || [];
  booking.adminActions.push({ actor: req.user._id, role: 'admin', action: 'cancel', fromStatus: prevStatus, toStatus: 'cancelled' });
        booking.notes = booking.notes || {};
        const info = 'Admin cancelled the booking';
        booking.notes.adminNotes = booking.notes.adminNotes ? `${booking.notes.adminNotes}\n${info}` : info;
      }
      await booking.save();
      return ok(res, booking, 'Booking cancelled');
    }

    // Create a cancellation request
    const isClient = req.user.role === 'client';
    const requestedTo = isClient ? booking.provider : booking.client;
    const requestedByRole = isClient ? 'client' : 'provider';
    const request = {
      status: 'pending',
      requestedBy: req.user._id,
      requestedByRole,
      requestedTo,
      reason: req.body?.reason || '',
      requestedAt: now.toJSDate(),
      // Optional expiry: at start time
      expiresAt: booking.schedule?.startUtc ? new Date(booking.schedule.startUtc) : undefined,
    };
    booking.cancellationRequests = booking.cancellationRequests || [];
    booking.cancellationRequests.push(request);
    await booking.save();
    const last = booking.cancellationRequests[booking.cancellationRequests.length - 1];
    return res.status(202).json({ success: true, message: 'Cancellation request created', data: { bookingId: booking._id, request: last } });
  } catch (e) {
    return error(res, 400, 'Failed to cancel booking');
  }
}

async function respondCancellationRequest(req, res) {
  try {
    const { id, requestId } = req.params;
    const { action } = req.body; // 'accept' | 'decline'
    const booking = await Booking.findById(id);
    if (!booking) return error(res, 404, 'Booking not found');
    const reqIdx = (booking.cancellationRequests || []).findIndex(r => r._id?.toString() === requestId && r.status === 'pending');
    if (reqIdx === -1) return error(res, 404, 'Cancellation request not found');
    const cReq = booking.cancellationRequests[reqIdx];
    // Only the counterparty can respond
    const userId = req.user._id.toString();
    const targetId = cReq.requestedTo?.toString();
    if (userId !== targetId) return error(res, 403, 'Not allowed to respond to this request');

    if (action === 'accept') {
      cReq.status = 'accepted';
      cReq.respondedAt = new Date();
      booking.status = 'cancelled';
      booking.cancellation = booking.cancellation || {};
      booking.cancellation.cancelledBy = cReq.requestedBy;
      booking.cancellation.cancelledAt = new Date();
      await booking.save();
      return ok(res, booking, 'Cancellation request accepted');
    }
    if (action === 'decline') {
      cReq.status = 'declined';
      cReq.respondedAt = new Date();
      await booking.save();
      return ok(res, booking, 'Cancellation request declined');
    }
    return error(res, 400, 'Invalid action');
  } catch (e) {
    return error(res, 400, 'Failed to respond to cancellation request');
  }
}

async function confirmBooking(req, res) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return error(res, 404, 'Booking not found');
    // Provider only
    if (req.user.role !== 'provider' || req.user._id.toString() !== booking.provider.toString()) return error(res, 403, 'Only the assigned provider can confirm');
  if (booking.status !== 'pending') return error(res, 409, 'Only pending bookings can be confirmed');
    booking.status = 'confirmed';
    await booking.save();
    return ok(res, booking, 'Booking confirmed');
  } catch (e) {
    return error(res, 400, 'Failed to confirm booking');
  }
}

async function completeBooking(req, res) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return error(res, 404, 'Booking not found');
  if (req.user.role !== 'provider' || req.user._id.toString() !== booking.provider.toString()) return error(res, 403, 'Only the assigned provider can complete');
  if (booking.status !== 'confirmed') return error(res, 409, 'Only confirmed bookings can be completed');
    const prev = booking.status;
    booking.status = 'completed';
    booking.completion = booking.completion || {};
    booking.completion.providerConfirmation = true;
    booking.completion.completedAt = new Date();
    await booking.save();
    // increment counter if transitioned to completed
    if (prev !== 'completed') {
  try {
        await require('../models/Provider').updateOne({ _id: booking.provider }, { $inc: { completedBookings: 1 } });
      } catch {}
    }
    return ok(res, booking, 'Booking completed');
  } catch (e) {
    return error(res, 400, 'Failed to complete booking');
  }
}

async function rateClient(req, res) {
  try {
    console.log('🔍 Rate client request received:');
    console.log('  - Booking ID:', req.params.id);
    console.log('  - User ID:', req.user?._id);
    console.log('  - User Role:', req.user?.role);
    console.log('  - Request Body:', req.body);
    
    const { rating, comment } = req.body;
    const bookingId = req.params.id;
    
    const booking = await Booking.findById(bookingId).populate('client');
    if (!booking) {
      console.log('❌ Booking not found:', bookingId);
      return error(res, 404, 'Booking not found');
    }
    
    console.log('✅ Booking found:', booking._id);
    console.log('  - Status:', booking.status);
    console.log('  - Provider:', booking.provider);
    console.log('  - Client:', booking.client);
    console.log('  - Current clientRating:', JSON.stringify(booking.clientRating));
    
    // Check if the current user is the provider for this booking
    if (req.user.role !== 'provider' || req.user._id.toString() !== booking.provider.toString()) {
      return error(res, 403, 'Only the assigned provider can rate the client');
    }
    
    // Check if the booking is completed
    if (booking.status !== 'completed') {
      return error(res, 409, 'Can only rate clients for completed bookings');
    }
    
    // Check if already rated - be more specific about what constitutes a rating
    if (booking.clientRating && 
        booking.clientRating.rating && 
        booking.clientRating.rating > 0 && 
        booking.clientRating.ratedAt) {
      console.log('❌ Client already rated for this booking:', booking.clientRating);
      return error(res, 409, 'Client has already been rated for this booking');
    }
    
    // Clear any existing null/undefined clientRating and add the new rating
    booking.clientRating = {
      rating: rating,
      comment: comment || null,
      ratedAt: new Date(),
      ratedBy: req.user._id
    };
    
    console.log('📝 Setting new client rating:', booking.clientRating);
    
    await booking.save();
    console.log('✅ Booking saved with client rating:', JSON.stringify(booking.clientRating));
    
    // Update client's rating and add review to their profile
    const User = require('../models/User');
    const client = await User.findById(booking.client);
    
    if (client) {
      // Get provider name for the review
      const Provider = require('../models/Provider');
      const provider = await Provider.findById(req.user._id);
      const providerName = provider ? `${provider.firstName} ${provider.lastName}` : 'Unknown Provider';
      
      // Add review to client's profile
      const review = {
        title: 'Review',
        comment: comment || '',
        rating: rating,
        providerId: req.user._id,
        providerName: providerName,
        bookingId: bookingId,
        createdAt: new Date()
      };
      
      client.reviews.push(review);
      
      // Update client's average rating
      const totalRatings = client.rating.count + 1;
      const totalScore = (client.rating.average * client.rating.count) + rating;
      client.rating.average = totalScore / totalRatings;
      client.rating.count = totalRatings;
      
      await client.save();
      console.log('✅ Client rating updated:', {
        average: client.rating.average,
        count: client.rating.count,
        reviewsCount: client.reviews.length
      });
    }
    
    console.log('✅ Rating submitted successfully');
    return ok(res, booking, 'Client rated successfully and review added to client profile');
  } catch (e) {
    console.error('❌ Error rating client:', e);
    console.error('Error stack:', e.stack);
    return error(res, 500, 'Failed to rate client');
  }
}

async function rateProvider(req, res) {
  try {
    console.log('🔍 Rate provider request received:');
    console.log('  - Booking ID:', req.params.id);
    console.log('  - User ID:', req.user?._id);
    console.log('  - User Role:', req.user?.role);
    console.log('  - Request Body:', req.body);
    
    const { rating, comment } = req.body;
    const bookingId = req.params.id;
    
    const booking = await Booking.findById(bookingId).populate('provider');
    if (!booking) {
      console.log('❌ Booking not found:', bookingId);
      return error(res, 404, 'Booking not found');
    }
    
    console.log('✅ Booking found:', booking._id);
    console.log('  - Status:', booking.status);
    console.log('  - Provider:', booking.provider);
    console.log('  - Client:', booking.client);
    
    // Check if the current user is the client for this booking
    if ((req.user.role !== 'client' && req.user.role !== 'user') || req.user._id.toString() !== booking.client.toString()) {
      return error(res, 403, 'Only the client can rate the provider');
    }
    
    // Check if the booking is completed
    if (booking.status !== 'completed') {
      return error(res, 409, 'Can only rate providers for completed bookings');
    }
    
    // Check if already rated
    console.log('🔍 Checking existing provider rating:');
    console.log('  - providerRating exists:', !!booking.providerRating);
    console.log('  - providerRating value:', JSON.stringify(booking.providerRating));
    console.log('  - providerRating.rating:', booking.providerRating?.rating);
    console.log('  - providerRating.rating > 0:', (booking.providerRating?.rating || 0) > 0);
    
    // Clear any invalid providerRating data (null, undefined, or rating <= 0)
    if (booking.providerRating && (!booking.providerRating.rating || booking.providerRating.rating <= 0)) {
      console.log('🧹 Clearing invalid providerRating data:', booking.providerRating);
      booking.providerRating = null;
      await booking.save();
      console.log('✅ Invalid providerRating data cleared and booking saved');
    }
    
    // Also check for empty objects or objects with only null values
    if (booking.providerRating && typeof booking.providerRating === 'object') {
      const hasValidRating = booking.providerRating.rating && 
                           booking.providerRating.rating > 0 && 
                           booking.providerRating.ratedAt;
      if (!hasValidRating) {
        console.log('🧹 Clearing invalid providerRating object:', booking.providerRating);
        booking.providerRating = null;
        await booking.save();
        console.log('✅ Invalid providerRating object cleared and booking saved');
      }
    }
    
    // Final check - only block if there's a complete, valid rating
    if (booking.providerRating && 
        booking.providerRating.rating && 
        booking.providerRating.rating > 0 && 
        booking.providerRating.ratedAt) {
      console.log('❌ Provider already rated for this booking:', booking.providerRating);
      return error(res, 409, 'Provider has already been rated for this booking');
    }
    
    // Add the provider rating to the booking
    booking.providerRating = {
      rating: rating,
      comment: comment || null,
      ratedAt: new Date(),
      ratedBy: req.user._id
    };
    
    console.log('📝 Setting new provider rating:', booking.providerRating);
    
    await booking.save();
    console.log('✅ Booking saved with provider rating:', JSON.stringify(booking.providerRating));
    
    // Update provider's rating and add review to their profile
    const Provider = require('../models/Provider');
    console.log('🔍 Looking for provider with ID:', booking.provider);
    console.log('🔍 Provider ID type:', typeof booking.provider);
    console.log('🔍 Provider ID value:', booking.provider);
    
    const provider = await Provider.findById(booking.provider);
    console.log('🔍 Provider query result:', provider ? 'Found' : 'Not found');
    
    if (provider) {
      console.log('✅ Provider found:', provider.firstName, provider.lastName);
      console.log('🔍 Provider current reviews count:', provider.reviews?.length || 0);
      console.log('🔍 Provider ID:', provider.providerId);
      console.log('🔍 Provider ID type:', typeof provider.providerId);
      // Get client name for the review
      const User = require('../models/User');
      console.log('🔍 Looking for client with ID:', req.user._id);
      const client = await User.findById(req.user._id);
      console.log('🔍 Client query result:', client ? 'Found' : 'Not found');
      const clientName = client ? `${client.firstName} ${client.lastName}` : 'Unknown Client';
      console.log('🔍 Client name for review:', clientName);
      
      // Add review to provider's profile
      const review = {
        title: 'Review',
        comment: comment || '',
        rating: rating,
        clientId: req.user._id,
        clientName: clientName,
        bookingId: bookingId,
        createdAt: new Date()
      };
      
      console.log('📝 Adding review to provider:', JSON.stringify(review, null, 2));
      
      provider.reviews = provider.reviews || [];
      provider.reviews.push(review);
      
      console.log('📊 Provider reviews after adding:', provider.reviews.length);
      console.log('📊 Provider reviews data:', JSON.stringify(provider.reviews, null, 2));
      
      // Update provider's average rating
      const totalRatings = (provider.rating?.count || 0) + 1;
      const totalScore = ((provider.rating?.average || 0) * (provider.rating?.count || 0)) + rating;
      provider.rating = {
        average: totalScore / totalRatings,
        count: totalRatings
      };
      
      try {
        console.log('🔍 Attempting to save provider...');
        console.log('🔍 Provider data before save:', {
          providerId: provider.providerId,
          firstName: provider.firstName,
          lastName: provider.lastName,
          reviewsCount: provider.reviews.length,
          rating: provider.rating
        });
        
        // Ensure providerId is preserved
        if (!provider.providerId) {
          console.error('❌ Provider ID is missing! Cannot save provider.');
          return error(res, 500, 'Provider ID is missing');
        }
        
        await provider.save();
        console.log('✅ Provider saved successfully');
        console.log('✅ Provider rating updated:', {
          average: provider.rating.average,
          count: provider.rating.count,
          reviewsCount: provider.reviews.length
        });
      } catch (saveError) {
        console.error('❌ Error saving provider:', saveError);
        console.error('Save error details:', saveError.message);
        console.error('Save error stack:', saveError.stack);
        
        // Try to identify the specific validation error
        if (saveError.errors) {
          console.error('Validation errors:', Object.keys(saveError.errors));
          Object.keys(saveError.errors).forEach(field => {
            console.error(`  ${field}: ${saveError.errors[field].message}`);
          });
        }
      }
    } else {
      console.log('❌ Provider not found with ID:', booking.provider);
    }
    
    console.log('✅ Provider rating submitted successfully');
    return ok(res, booking, 'Provider rated successfully and review added to provider profile');
  } catch (e) {
    console.error('❌ Error rating provider:', e);
    console.error('Error stack:', e.stack);
    return error(res, 500, 'Failed to rate provider');
  }
}

module.exports.cancelBooking = cancelBooking;
module.exports.respondCancellationRequest = respondCancellationRequest;
module.exports.confirmBooking = confirmBooking;
module.exports.completeBooking = completeBooking;
module.exports.rateClient = rateClient;
module.exports.rateProvider = rateProvider;

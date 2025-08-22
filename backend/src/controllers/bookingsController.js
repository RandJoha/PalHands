const Booking = require('../models/Booking');
const Service = require('../models/Service');
const Availability = require('../models/Availability');
const { DateTime } = require('luxon');
const { ok, created, error } = require('../utils/response');
const { bookingPolicies } = require('../policies');
const { validateTransition } = require('../utils/bookingStateMachine');

async function createBooking(req, res) {
  try {
    const actor = req.user;
    const { serviceId, schedule, location, notes, clientId } = req.body;
    const idempotencyKey = req.headers['idempotency-key'] || req.body.idempotencyKey;

    // Check for duplicate request if idempotency key provided
    if (idempotencyKey) {
      const existingBooking = await Booking.findOne({
        client: clientId || actor._id,
        idempotencyKey: idempotencyKey
      });
      
      if (existingBooking) {
        // Return existing booking for duplicate request
        return res.status(200).json({
          success: true,
          message: 'Booking already exists (idempotent request)',
          data: existingBooking
        });
      }
    }

    const service = await Service.findById(serviceId).populate('provider');
    if (!service || !service.isActive) return error(res, 404, 'Service not available');

    const baseAmount = service.price.amount;
    const totalAmount = baseAmount; // simple for Phase 1

    // Resolve client for the booking
    // - client role: client is self
    // - provider/admin: may pass clientId; if not, default to actor (for quick ops)
    const resolvedClientId = clientId || actor._id;

    // Timezone-aware start/end
    const tz = schedule.timezone || 'Asia/Jerusalem';
    const startDateTime = DateTime.fromISO(`${schedule.date}T${schedule.startTime}`, { zone: tz });
    const endDateTime = DateTime.fromISO(`${schedule.date}T${schedule.endTime}`, { zone: tz });
    if (!startDateTime.isValid || !endDateTime.isValid || endDateTime <= startDateTime) {
      return error(res, 400, 'Invalid schedule times');
    }

    // Check provider availability
    const avail = await Availability.findOne({ provider: service.provider._id });
    let isAvailable = true;
    if (avail) {
      const day = startDateTime.setZone(avail.timezone || tz).toFormat('cccc').toLowerCase();
      const windows = (avail.weekly?.[day] || []).concat((avail.exceptions || []).filter(e => e.date === startDateTime.toFormat('yyyy-MM-dd')).flatMap(e => e.windows || []));
      const within = (w) => w.start <= schedule.startTime && w.end >= schedule.endTime;
      isAvailable = windows.length ? windows.some(within) : true; // if no windows, treat as available
    }
    if (!isAvailable) return error(res, 400, 'Provider not available at requested time');

    // Anti double-booking for provider (overlap with non-cancelled)
    const overlap = await Booking.findOne({
      provider: service.provider._id,
      status: { $in: ['pending','confirmed','in_progress'] },
      $or: [
        { 'schedule.startUtc': { $lt: endDateTime.toUTC().toJSDate() }, 'schedule.endUtc': { $gt: startDateTime.toUTC().toJSDate() } }
      ]
    }).select('_id');
    if (overlap) return error(res, 409, 'Time slot already booked');

    const bookingData = {
      client: resolvedClientId,
      provider: service.provider._id,
      service: service._id,
      serviceDetails: { title: service.title, description: service.description, category: service.category },
      schedule: {
        date: startDateTime.toJSDate(),
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        startUtc: startDateTime.toUTC().toJSDate(),
        endUtc: endDateTime.toUTC().toJSDate(),
        timezone: tz
      },
      location,
      pricing: { baseAmount, additionalCharges: [], totalAmount, currency: service.price.currency || 'ILS' },
      notes: { clientNotes: notes || '' }
    };

    // Add idempotency key if provided
    if (idempotencyKey) {
      bookingData.idempotencyKey = idempotencyKey;
    }

    const booking = await Booking.create(bookingData);

    return created(res, booking, 'Booking created');
  } catch (e) {
    console.error('createBooking error', e);
    return error(res, 400, e.message || 'Failed to create booking');
  }
}

async function listMyBookings(req, res) {
  try {
    const user = req.user;
    const filter = user.role === 'provider' ? { provider: user._id } : { client: user._id };
    const bookings = await Booking.find(filter)
      .populate('client', 'firstName lastName email')
      .populate('provider', 'firstName lastName email')
      .populate('service', 'title category')
      .sort({ createdAt: -1 });
    return ok(res, bookings);
  } catch (e) {
    console.error('listMyBookings error', e);
    return error(res, 500, 'Failed to fetch bookings');
  }
}

async function getBookingById(req, res) {
  try {
    const booking = await Booking.findById(req.params.id)
      .populate('client', 'firstName lastName email')
      .populate('provider', 'firstName lastName email')
      .populate('service', 'title category');
    if (!booking) return error(res, 404, 'Booking not found');
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

    // Check if user can view/modify this booking
    if (!bookingPolicies.canView(req.user, booking)) {
      return error(res, 403, 'Access denied');
    }

    const currentStatus = booking.status;
    const newStatus = req.body.status;
    const userRole = req.user.role;

    // Validate status transition using state machine
    const validation = validateTransition({
      fromStatus: currentStatus,
      toStatus: newStatus,
      userRole: userRole,
      booking: booking,
      user: req.user
    });

    if (!validation.success) {
      return error(res, 400, validation.error);
    }

    // Update booking status
    booking.status = newStatus;
    booking.updatedAt = Date.now();

    // Add status-specific metadata
    if (newStatus === 'cancelled') {
      booking.cancellation = {
        cancelledBy: req.user._id,
        reason: req.body.reason || 'Cancelled by user',
        cancelledAt: new Date()
      };
    } else if (newStatus === 'completed') {
      booking.completion = {
        completedAt: new Date(),
        ...(userRole === 'client' ? { clientConfirmation: true } : {}),
        ...(userRole === 'provider' ? { providerConfirmation: true } : {})
      };
    }

    await booking.save();
    return ok(res, booking, 'Status updated successfully');
  } catch (e) {
    console.error('updateBookingStatus error', e);
    return error(res, 400, e.message || 'Failed to update status');
  }
}

module.exports = { createBooking, listMyBookings, getBookingById, updateBookingStatus };

const Booking = require('../models/Booking');
const Service = require('../models/Service');
const { ok, created, error } = require('../utils/response');
const { bookingPolicies } = require('../policies');

async function createBooking(req, res) {
  try {
  const actor = req.user;
  const { serviceId, schedule, location, notes, clientId } = req.body;

    const service = await Service.findById(serviceId).populate('provider');
    if (!service || !service.isActive) return error(res, 404, 'Service not available');

    const baseAmount = service.price.amount;
    const totalAmount = baseAmount; // simple for Phase 1

    // Resolve client for the booking
    // - client role: client is self
    // - provider/admin: may pass clientId; if not, default to actor (for quick ops)
    const resolvedClientId = clientId || actor._id;

    const booking = await Booking.create({
      client: resolvedClientId,
      provider: service.provider._id,
      service: service._id,
      serviceDetails: { title: service.title, description: service.description, category: service.category },
      schedule,
      location,
      pricing: { baseAmount, additionalCharges: [], totalAmount, currency: service.price.currency || 'ILS' },
      notes: { clientNotes: notes || '' }
    });

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

async function getBookingByCode(req, res) {
  try {
    const booking = await Booking.findOne({ bookingId: req.params.bookingId })
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

  const allowed = bookingPolicies.allowedStatusFor(req.user, booking);
  if (!allowed.has(req.body.status)) return error(res, 403, 'Not allowed to set this status');

    booking.status = req.body.status;
    booking.updatedAt = Date.now();
    await booking.save();
    return ok(res, booking, 'Status updated');
  } catch (e) {
    return error(res, 400, 'Failed to update status');
  }
}

module.exports = { createBooking, listMyBookings, getBookingById, getBookingByCode, updateBookingStatus };

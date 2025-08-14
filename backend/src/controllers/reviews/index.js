const Review = require('../../models/Review');
const Booking = require('../../models/Booking');
const Service = require('../../models/Service');
const User = require('../../models/User');
const { ok, created, error } = require('../../utils/response');

async function recalcServiceRating(serviceId) {
  const agg = await Review.aggregate([
    { $match: { service: new (require('mongoose')).Types.ObjectId(serviceId) } },
    { $group: { _id: '$service', avg: { $avg: '$rating' }, count: { $sum: 1 } } }
  ]);
  const s = await Service.findById(serviceId);
  if (s) {
    s.rating = { average: agg[0]?.avg || 0, count: agg[0]?.count || 0 };
    await s.save();
  }
}

async function recalcProviderRating(providerId) {
  const agg = await Review.aggregate([
    { $match: { provider: new (require('mongoose')).Types.ObjectId(providerId) } },
    { $group: { _id: '$provider', avg: { $avg: '$rating' }, count: { $sum: 1 } } }
  ]);
  const u = await User.findById(providerId);
  if (u) {
    u.rating = { average: agg[0]?.avg || 0, count: agg[0]?.count || 0 };
    await u.save();
  }
}

// POST /api/reviews
async function createReview(req, res) {
  try {
    const { bookingId, rating, comment } = req.body;
    const actor = req.user;

    const booking = await Booking.findById(bookingId).populate('service provider client');
    if (!booking) return error(res, 404, 'Booking not found');
    if (actor.role !== 'admin' && booking.client.toString() !== actor._id.toString()) {
      return error(res, 403, 'Only the booking client can review');
    }
    if (booking.status !== 'completed') {
      return error(res, 400, 'You can review only completed bookings');
    }

    const existing = await Review.findOne({ booking: booking._id });
    if (existing) return error(res, 400, 'Review already exists for this booking');

    const review = await Review.create({
      booking: booking._id,
      service: booking.service._id || booking.service,
      provider: booking.provider._id || booking.provider,
      client: booking.client._id || booking.client,
      rating,
      comment: comment || ''
    });

    // Update booking rating snapshot
    booking.rating = booking.rating || {};
    booking.rating.clientRating = { stars: rating, comment: comment || '', ratedAt: new Date() };
    await booking.save();

    await recalcServiceRating(review.service);
    await recalcProviderRating(review.provider);

    return created(res, review, 'Review submitted');
  } catch (e) {
    console.error('createReview error', e);
    return error(res, 400, e.message || 'Failed to submit review');
  }
}

// GET /api/reviews/service/:serviceId
async function listServiceReviews(req, res) {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const { serviceId } = req.params;
    const [items, total] = await Promise.all([
      Review.find({ service: serviceId }).populate('client', 'firstName lastName').sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      Review.countDocuments({ service: serviceId })
    ]);
    return ok(res, { reviews: items, pagination: { current: parseInt(page), total: Math.ceil(total / limit), totalRecords: total } });
  } catch (e) {
    return error(res, 500, 'Failed to fetch reviews');
  }
}

// GET /api/reviews/provider/:providerId
async function listProviderReviews(req, res) {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const { providerId } = req.params;
    const [items, total] = await Promise.all([
      Review.find({ provider: providerId }).populate('client', 'firstName lastName').populate('service', 'title').sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      Review.countDocuments({ provider: providerId })
    ]);
    return ok(res, { reviews: items, pagination: { current: parseInt(page), total: Math.ceil(total / limit), totalRecords: total } });
  } catch (e) {
    return error(res, 500, 'Failed to fetch reviews');
  }
}

module.exports = { createReview, listServiceReviews, listProviderReviews };

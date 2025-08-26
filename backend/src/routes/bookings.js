const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const bookingsController = require('../controllers/bookingsController');
const { celebrate, Joi, Segments } = require('celebrate');

const createBookingValidator = celebrate({
  [Segments.BODY]: Joi.object({
  clientId: Joi.string().hex().length(24).optional(),
    serviceId: Joi.string().hex().length(24).required(),
    schedule: Joi.object({
  date: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).required(),
      startTime: Joi.string().pattern(/^\d{2}:\d{2}$/).required(),
      endTime: Joi.string().pattern(/^\d{2}:\d{2}$/).required(),
  duration: Joi.number().integer().min(0).optional(),
  timezone: Joi.string().required()
    }).required(),
    location: Joi.object({
      address: Joi.string().required(),
      coordinates: Joi.object({ latitude: Joi.number(), longitude: Joi.number() }).optional(),
      instructions: Joi.string().allow('').optional()
    }).required(),
    notes: Joi.string().allow('').optional()
  })
});

const updateStatusValidator = celebrate({
  [Segments.BODY]: Joi.object({ status: Joi.string().valid('confirmed','in_progress','completed','cancelled','disputed').required() })
});

router.post('/', auth, checkRole(['client','provider','admin']), createBookingValidator, bookingsController.createBooking);
router.get('/', auth, bookingsController.listMyBookings);
// Admin listing
router.get('/admin/all', auth, checkRole(['admin']), bookingsController.listAllBookings);
// Important: define the 'code' route before the generic ':id' route
router.get('/:id', auth, bookingsController.getBookingById);
router.put('/:id/status', auth, updateStatusValidator, bookingsController.updateBookingStatus);

// New business endpoints
const reasonValidator = celebrate({
  [Segments.BODY]: Joi.object({ reason: Joi.string().allow('').optional() })
});

router.post('/:id/cancel', auth, reasonValidator, bookingsController.cancelBooking);
router.post('/:id/confirm', auth, checkRole(['provider']), bookingsController.confirmBooking);
router.post('/:id/complete', auth, checkRole(['provider']), bookingsController.completeBooking);
router.post('/:id/cancellation-requests/:requestId/respond', auth, celebrate({
  [Segments.BODY]: Joi.object({ action: Joi.string().valid('accept','decline').required() })
}), bookingsController.respondCancellationRequest);

module.exports = router;

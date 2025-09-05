const express = require('express');
const router = express.Router();
const { auth: authenticate, checkRole } = require('../middleware/auth');
const bookingsController = require('../controllers/bookingsController');
const { celebrate, Joi, Segments } = require('celebrate');

const createBookingValidator = celebrate({
  [Segments.BODY]: Joi.object({
  clientId: Joi.string().hex().length(24).optional(),
  clientType: Joi.string().valid('User','Provider').optional(),
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
  notes: Joi.string().allow('').optional(),
  emergency: Joi.boolean().optional()
  })
});

const updateStatusValidator = celebrate({
  [Segments.BODY]: Joi.object({ status: Joi.string().valid('pending','confirmed','completed','cancelled').required() })
});

router.post('/', authenticate, createBookingValidator, bookingsController.createBooking);
router.get('/', authenticate, bookingsController.listMyBookings);
// Admin listing
router.get('/admin/all', authenticate, checkRole(['admin']), bookingsController.listAllBookings);
// Important: define the 'code' route before the generic ':id' route
router.get('/:id', authenticate, bookingsController.getBookingById);
router.put('/:id/status', authenticate, updateStatusValidator, bookingsController.updateBookingStatus);

// New business endpoints
const reasonValidator = celebrate({
  [Segments.BODY]: Joi.object({ reason: Joi.string().allow('').optional() })
});

router.post('/:id/cancel', authenticate, reasonValidator, bookingsController.cancelBooking);
router.post('/:id/confirm', authenticate, checkRole(['provider']), bookingsController.confirmBooking);
router.post('/:id/complete', authenticate, checkRole(['provider']), bookingsController.completeBooking);
router.post('/:id/cancellation-requests/:requestId/respond', authenticate, celebrate({
  [Segments.BODY]: Joi.object({ action: Joi.string().valid('accept','decline').required() })
}), bookingsController.respondCancellationRequest);

module.exports = router;

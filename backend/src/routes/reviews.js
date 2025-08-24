const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const controller = require('../controllers/reviews');
const { celebrate, Joi, Segments } = require('celebrate');

const createReviewValidator = celebrate({
  [Segments.BODY]: Joi.object({
    bookingId: Joi.string().hex().length(24).required(),
    rating: Joi.number().integer().min(1).max(5).required(),
    comment: Joi.string().max(1000).allow('').optional()
  })
});

router.post('/', auth, checkRole(['client','admin']), createReviewValidator, controller.createReview);
router.get('/service/:serviceId', controller.listServiceReviews);
router.get('/provider/:providerId', controller.listProviderReviews);

module.exports = router;

const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const controller = require('../controllers/payments');
const { celebrate, Joi, Segments } = require('celebrate');

const createPaymentValidator = celebrate({
  [Segments.BODY]: Joi.object({
    bookingId: Joi.string().hex().length(24).required(),
    method: Joi.string().valid('cash','credit_card','paypal','bank_transfer').optional()
  })
});

const updatePaymentValidator = celebrate({
  [Segments.BODY]: Joi.object({
    status: Joi.string().valid('pending','paid','failed','refunded').required(),
    transactionId: Joi.string().allow('').optional()
  })
});

router.post('/', auth, checkRole(['client','admin']), createPaymentValidator, controller.createPayment);
router.put('/:id/status', auth, checkRole(['admin']), updatePaymentValidator, controller.updatePaymentStatus);
router.post('/webhook', controller.webhook);

module.exports = router;

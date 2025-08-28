const { celebrate, Joi, Segments } = require('celebrate');

const objectId = Joi.string().regex(/^[0-9a-fA-F]{24}$/);

const createReportValidator = celebrate({
  [Segments.BODY]: Joi.object({
    reportCategory: Joi.string().valid('user_issue', 'technical_issue', 'feature_suggestion', 'service_category_request', 'other').default('user_issue'),

    // Common
    description: Joi.string().min(10).max(1000).required(),
    contactEmail: Joi.string().email()
      .when('reportCategory', { is: Joi.valid('feature_suggestion', 'service_category_request', 'technical_issue', 'other'), then: Joi.required(), otherwise: Joi.optional() }),
    contactName: Joi.string().min(2).max(80)
      .when('reportCategory', { is: Joi.valid('feature_suggestion', 'service_category_request', 'technical_issue', 'other'), then: Joi.required(), otherwise: Joi.optional() }),
    subject: Joi.string().min(3).max(200).optional(),
    evidence: Joi.array().items(Joi.string()).default([]),

    // Optional linkage keys
    relatedBookingId: objectId.optional(),
    reportedServiceId: objectId.optional(),

    // User issue specifics
    reportedType: Joi.string().valid('user', 'service', 'booking', 'review', 'payment').optional(),
    reportedId: objectId.optional(),
    reportedName: Joi.string().min(2).max(120)
      .when('reportCategory', { is: 'user_issue', then: Joi.required(), otherwise: Joi.forbidden() }),
    reportedUserRole: Joi.string().valid('client', 'provider')
      .when('reportedType', { is: 'user', then: Joi.required(), otherwise: Joi.forbidden() }),
    issueType: Joi.string().valid('unsafe', 'harassment', 'misleading', 'inappropriate_behavior', 'fraud', 'spam', 'payment_issue', 'safety_concern', 'poor_quality', 'no_show', 'other')
      .when('reportCategory', { is: 'user_issue', then: Joi.required(), otherwise: Joi.forbidden() }),
    partyInfo: Joi.object({
      reporterName: Joi.string().min(2).max(80).required(),
      reporterEmail: Joi.string().email().required(),
      reportedEmail: Joi.string().email().optional()
    }).when('reportCategory', { is: 'user_issue', then: Joi.optional(), otherwise: Joi.forbidden() }),

    // Feature suggestion specifics
    ideaTitle: Joi.string().min(3).max(150)
      .when('reportCategory', { is: 'feature_suggestion', then: Joi.required(), otherwise: Joi.forbidden() }),
    communityBenefit: Joi.string().min(5).max(1000)
      .when('reportCategory', { is: 'feature_suggestion', then: Joi.required(), otherwise: Joi.forbidden() }),

    // Service category request specifics
    serviceName: Joi.string().min(2).max(120)
      .when('reportCategory', { is: 'service_category_request', then: Joi.required(), otherwise: Joi.forbidden() }),
    categoryFit: Joi.string().min(2).max(120)
      .when('reportCategory', { is: 'service_category_request', then: Joi.required(), otherwise: Joi.forbidden() }),
    importanceReason: Joi.string().min(5).max(1000)
      .when('reportCategory', { is: 'service_category_request', then: Joi.required(), otherwise: Joi.forbidden() }),
    requestedCategory: Joi.string().min(2).max(120).optional(),

    // Technical issue metadata
    device: Joi.string().min(2).max(120).optional(),
    os: Joi.string().min(2).max(120).optional(),
    appVersion: Joi.string().min(1).max(60).optional(),

    // Idempotency key
    idempotencyKey: Joi.string().min(8).max(100).optional()
  })
});

const listMyReportsValidator = celebrate({
  [Segments.QUERY]: Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
    status: Joi.string().valid('pending', 'under_review', 'resolved', 'dismissed', 'active').optional(),
    reportCategory: Joi.string().valid('user_issue', 'technical_issue', 'feature_suggestion', 'service_category_request', 'other').optional(),
    issueType: Joi.string().valid('unsafe', 'harassment', 'misleading', 'inappropriate_behavior', 'fraud', 'spam', 'payment_issue', 'safety_concern', 'poor_quality', 'no_show', 'other').optional(),
    hasEvidence: Joi.boolean().optional(),
    createdFrom: Joi.date().iso().optional(),
    createdTo: Joi.date().iso().optional()
  })
});

const getByIdValidator = celebrate({
  [Segments.PARAMS]: Joi.object({ id: objectId.required() })
});

// Admin list filters
const adminListValidator = celebrate({
  [Segments.QUERY]: Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
    status: Joi.string().valid('pending', 'under_review', 'resolved', 'dismissed', 'active').optional(),
    reportCategory: Joi.string().valid('user_issue', 'technical_issue', 'feature_suggestion', 'service_category_request', 'other').optional(),
    issueType: Joi.string().valid('unsafe', 'harassment', 'misleading', 'inappropriate_behavior', 'fraud', 'spam', 'payment_issue', 'safety_concern', 'poor_quality', 'no_show', 'other').optional(),
    hasEvidence: Joi.boolean().optional(),
    assignedAdmin: objectId.optional(),
    awaiting_user: Joi.boolean().optional(),
    sort: Joi.string().valid('createdAt:asc', 'createdAt:desc').default('createdAt:desc')
  })
});

// Admin update validator includes FSM and resolution
const adminUpdateValidator = celebrate({
  [Segments.BODY]: Joi.object({
    status: Joi.string().valid('pending', 'under_review', 'resolved', 'dismissed').optional(),
    assignedAdmin: objectId.optional(),
    adminNote: Joi.string().max(1000).optional(),
    resolution: Joi.object({
      action: Joi.string().valid('warning_sent','warn_user','user_suspended','user_banned','service_disabled','booking_cancelled','refund_issued','no_action','other').optional(),
      reason: Joi.string().max(200).optional(),
      details: Joi.string().max(1000).optional()
    }).optional()
  })
});

// Admin request-info body
const adminRequestInfoValidator = celebrate({
  [Segments.BODY]: Joi.object({
    message: Joi.string().min(5).max(500).required()
  })
});

module.exports = {
  createReportValidator,
  listMyReportsValidator,
  getByIdValidator,
  adminListValidator,
  adminUpdateValidator,
  adminRequestInfoValidator
};

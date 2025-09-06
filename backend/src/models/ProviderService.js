const mongoose = require('mongoose');

// Service-level weekly override schema (optional)
const timeWindowSchema = new mongoose.Schema({ start: String, end: String }, { _id: false });
const weeklySchema = new mongoose.Schema({
	monday: [timeWindowSchema],
	tuesday: [timeWindowSchema],
	wednesday: [timeWindowSchema],
	thursday: [timeWindowSchema],
	friday: [timeWindowSchema],
	saturday: [timeWindowSchema],
	sunday: [timeWindowSchema]
}, { _id: false });

const exceptionSchema = new mongoose.Schema({
	date: { type: String, required: true }, // YYYY-MM-DD
	windows: [timeWindowSchema] // empty => unavailable all day
}, { _id: false });

const deactivationBatchSchema = new mongoose.Schema({
	batchId: { type: String, required: true },
	fromDate: { type: String, required: true }, // YYYY-MM-DD
	toDate: { type: String, required: true },   // YYYY-MM-DD inclusive
	reason: { type: String, default: 'manual_deactivation' },
	createdAt: { type: Date, default: Date.now }
}, { _id: false });

const providerServiceSchema = new mongoose.Schema({
	provider: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
	service: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },

	// Per-service configuration
	hourlyRate: { type: Number, required: false, min: 0 },
	experienceYears: { type: Number, required: false, min: 0 },
	emergencyEnabled: { type: Boolean, default: false },
	emergencyLeadTimeMinutes: { type: Number, default: 0 },

	// Optional per-service availability overrides (base comes from Availability model)
	weeklyOverrides: { type: weeklySchema, default: undefined },
	exceptionOverrides: { type: [exceptionSchema], default: undefined },

	// Optional per-service emergency-only additive overrides
	emergencyWeeklyOverrides: { type: weeklySchema, default: undefined },
	emergencyExceptionOverrides: { type: [exceptionSchema], default: undefined },

	// Admin/moderation & lifecycle
	status: { type: String, enum: ['draft','active','inactive','deleted'], default: 'draft' },
	publishable: { type: Boolean, default: false },
	publishedAt: { type: Date, default: null },
	completenessScore: { type: Number, default: 0 },

	// Deactivation bookkeeping (reactivation restores last batch only)
	deactivationBatches: { type: [deactivationBatchSchema], default: [] },
	lastDeactivationBatchId: { type: String, default: null },

	createdAt: { type: Date, default: Date.now },
	updatedAt: { type: Date, default: Date.now }
});

providerServiceSchema.index({ provider: 1, service: 1 }, { unique: true });
providerServiceSchema.index({ provider: 1, status: 1, publishable: 1 });
providerServiceSchema.index({ service: 1, status: 1, publishable: 1 });

providerServiceSchema.pre('save', function(next) {
	this.updatedAt = Date.now();
	// Compute publishable and score
	let score = 0;
	if (Number.isFinite(this.hourlyRate) && this.hourlyRate > 0) score += 35;
	if (Number.isFinite(this.experienceYears) && this.experienceYears >= 0) score += 25;
	// Availability considered if overrides provided, otherwise rely on global provider availability
	const hasAvailability = (this.weeklyOverrides && Object.values(this.weeklyOverrides.toObject() || {}).some(arr => (arr||[]).length > 0))
		|| (Array.isArray(this.exceptionOverrides) && this.exceptionOverrides.length > 0);
	if (hasAvailability) score += 25; // bonus when service override exists
	// Emergency is optional, not required to publish
	if (this.emergencyEnabled) score += 5;
	this.completenessScore = score;
	const requiredOk = Number.isFinite(this.hourlyRate) && this.hourlyRate > 0
		&& Number.isFinite(this.experienceYears) && this.experienceYears >= 0;
	this.publishable = !!requiredOk;
	if (this.publishable && this.status === 'active' && !this.publishedAt) this.publishedAt = new Date();
	next();
});

module.exports = mongoose.model('ProviderService', providerServiceSchema);

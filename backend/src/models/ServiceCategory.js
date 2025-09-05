const { mongoose } = require('../config/database');

// ServiceCategory model mapped to the 'servicecategories' collection
// This mirrors the schema used in utils/restoreFrontendData.js
const serviceCategorySchema = new mongoose.Schema({
  id: { type: String, unique: true },
  name: String,              // i18n key used on FE
  description: String,       // i18n key used on FE
  icon: String,
  color: String,
  isActive: { type: Boolean, default: true },
  sortOrder: { type: Number, default: 0 },
  services: [String],        // service keys (legacy FE taxonomy)
}, { collection: 'servicecategories' });

module.exports = mongoose.models.ServiceCategory || mongoose.model('ServiceCategory', serviceCategorySchema);

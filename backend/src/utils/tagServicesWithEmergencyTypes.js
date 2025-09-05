require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Provider = require('../models/Provider');
const Service = require('../models/Service');

// Simple heuristic mapping from subcategory keywords to emergency types
const mapping = [
  { keywords: ['elder','elderly','homeElderlyCare','home_nursing'], types: ['elder_care'] },
  { keywords: ['medicine','prescription','prescriptionPickup','medicalTransport','sickChildCare'], types: ['medicine_pickup','medical_transport'] },
  { keywords: ['documentDelivery','shoppingDelivery','specialErrands','acquire'], types: ['acquire_item','errand'] },
  { keywords: ['babysitting','sickChildCare'], types: ['childcare_emergency'] }
];

(async function main(){
  try {
    await connectDB();
  const providers = await Provider.find({}).limit(50);
    const updated = [];
    for (const p of providers) {
      const services = await Service.find({ provider: p._id, emergencyEnabled: true });
      for (const s of services) {
        const types = new Set(s.emergencyTypes || []);
        const name = (s.subcategory || s.title || '').toLowerCase();
        for (const m of mapping) {
          for (const kw of m.keywords) {
            if (name.includes(kw.toLowerCase())) {
              for (const t of m.types) types.add(t);
            }
          }
        }
        s.emergencyTypes = Array.from(types);
        await s.save();
        updated.push({ provider: p.email, service: s.title, emergencyTypes: s.emergencyTypes });
      }
    }
    console.log('Tagged services with emergency types:', JSON.stringify(updated, null, 2));
  } catch (e) {
    console.error('tagServicesWithEmergencyTypes error', e);
    process.exit(1);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
  }
})();

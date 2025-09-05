require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Provider = require('../models/Provider');
const Service = require('../models/Service');

(async function main(){
  try {
    await connectDB();
  const providers = await Provider.find({}).select('_id firstName lastName email');
    const rows = [];
    for (const p of providers) {
      const services = await Service.find({ provider: p._id, emergencyEnabled: true }).select('title emergencyTypes emergencyLeadTimeMinutes emergencyRateMultiplier emergencySurcharge');
      if (services && services.length) {
        rows.push({ id: String(p._id), email: p.email, name: `${p.firstName || ''} ${p.lastName || ''}`.trim(), services: services.map(s => ({ id: String(s._id), title: s.title, emergencyTypes: s.emergencyTypes || [], leadMinutes: s.emergencyLeadTimeMinutes, rateMultiplier: s.emergencyRateMultiplier, surcharge: s.emergencySurcharge })) });
      }
    }
    console.log(JSON.stringify(rows, null, 2));
  } catch (e) {
    console.error('listEmergencyProviders error', e);
    process.exit(1);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
  }
})();

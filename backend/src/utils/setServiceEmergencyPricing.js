const mongoose = require('mongoose');
const Service = require('../models/Service');

const MONGO_URL = process.env.MONGO_URL || process.env.MONGODB_URI || 'mongodb://localhost:27017/palhands';

async function main() {
  const sid = process.argv[2];
  const multiplier = parseFloat(process.argv[3] || '1.5');
  const surchargeType = process.argv[4] || 'percent';
  const surchargeAmt = parseFloat(process.argv[5] || '25');
  if (!sid) {
    console.error('Usage: node src/utils/setServiceEmergencyPricing.js <serviceId> [multiplier] [surchargeType] [surchargeAmount]');
    process.exit(2);
  }
  await mongoose.connect(MONGO_URL, { useNewUrlParser: true, useUnifiedTopology: true });
  const s = await Service.findById(sid);
  if (!s) {
    console.error('Service not found:', sid);
    await mongoose.disconnect();
    process.exit(1);
  }
  s.emergencyRateMultiplier = Number.isFinite(multiplier) ? multiplier : s.emergencyRateMultiplier;
  s.emergencySurcharge = { type: surchargeType === 'percent' ? 'percent' : 'flat', amount: Number.isFinite(surchargeAmt) ? surchargeAmt : (s.emergencySurcharge?.amount || 0) };
  s.updatedAt = Date.now();
  await s.save();
  console.log('Updated emergency pricing for', sid, s.title, 'multiplier=', s.emergencyRateMultiplier, 'surcharge=', s.emergencySurcharge);
  await mongoose.disconnect();
}

main().catch(e => { console.error(e); process.exit(1); });

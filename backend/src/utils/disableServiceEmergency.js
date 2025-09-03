const mongoose = require('mongoose');
const Service = require('../models/Service');

const MONGO_URL = process.env.MONGO_URL || process.env.MONGODB_URI || 'mongodb://localhost:27017/palhands';

async function main() {
  const sid = process.argv[2];
  if (!sid) {
    console.error('Usage: node src/utils/disableServiceEmergency.js <serviceId>');
    process.exit(2);
  }
  await mongoose.connect(MONGO_URL, { useNewUrlParser: true, useUnifiedTopology: true });
  const s = await Service.findById(sid);
  if (!s) {
    console.error('Service not found:', sid);
    await mongoose.disconnect();
    process.exit(1);
  }
  s.emergencyEnabled = false;
  s.updatedAt = Date.now();
  await s.save();
  console.log('Disabled emergency for service', sid, s.title);
  await mongoose.disconnect();
}

main().catch(e => { console.error(e); process.exit(1); });

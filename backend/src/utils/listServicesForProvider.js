const mongoose = require('mongoose');
const Service = require('../models/Service');
const Provider = require('../models/Provider');

const MONGO_URL = process.env.MONGO_URL || process.env.MONGODB_URI || 'mongodb://localhost:27017/palhands';

async function main() {
  const providerId = process.argv[2];
  if (!providerId) {
    console.error('Usage: node src/utils/listServicesForProvider.js <providerId>');
    process.exit(2);
  }
  await mongoose.connect(MONGO_URL, { useNewUrlParser: true, useUnifiedTopology: true });
  const prov = await Provider.findById(providerId).select('firstName lastName email');
  console.log('Provider:', prov ? `${prov.firstName} ${prov.lastName} <${prov.email}>` : providerId);
  const services = await Service.find({ provider: providerId }).select('title subcategory emergencyEnabled emergencyTypes emergencyRateMultiplier emergencySurcharge');
  console.log(JSON.stringify(services, null, 2));
  await mongoose.disconnect();
}

main().catch(e => { console.error(e); process.exit(1); });

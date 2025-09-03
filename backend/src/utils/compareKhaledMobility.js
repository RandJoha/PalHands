// Script to compare Khaled Mansour's service fields with Mobility Assistance services
require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Provider = require('../models/Provider');
const Service = require('../models/Service');

(async function main(){
  try {
    await connectDB();

    // Find Khaled Mansour provider by name/email patterns
    const khaled = await Provider.findOne({ $or: [{ email: /khaled/i }, { firstName: /khaled/i }, { lastName: /mansour/i }] });
    if (!khaled) console.log('Khaled Mansour provider not found');
    else {
      console.log('Khaled provider:', khaled.email, khaled._id.toString());
      const khaledServices = await Service.find({ provider: khaled._id });
      console.log('Khaled services count:', khaledServices.length);
      for (const s of khaledServices) {
        console.log('Khaled service:', { id: s._id.toString(), title: s.title, subcategory: s.subcategory, slug: s.slug || s.code || '', emergencyEnabled: s.emergencyEnabled, emergencyRateMultiplier: s.emergencyRateMultiplier, emergencySurcharge: s.emergencySurcharge, emergencyTypes: s.emergencyTypes });
      }
    }

    // Mobility assistance services
    const mobilityServices = await Service.find({ $or: [{ subcategory: 'mobilityAssistance' }, { title: /mobility/i }, { title: /bathing/i }] });
    console.log('Mobility services count:', mobilityServices.length);
    for (const s of mobilityServices) {
      const provider = await Provider.findById(s.provider);
      console.log('Mobility service:', { id: s._id.toString(), title: s.title, subcategory: s.subcategory, slug: s.slug || s.code || '', provider: provider ? (provider.email || `${provider.firstName} ${provider.lastName}`) : s.provider, emergencyEnabled: s.emergencyEnabled, emergencyRateMultiplier: s.emergencyRateMultiplier, emergencySurcharge: s.emergencySurcharge, emergencyTypes: s.emergencyTypes });
    }

  } catch (e) {
    console.error('compare error', e);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
    process.exit(0);
  }
})();

// Script: tagMobilityEmergency.js
// Usage: node src/utils/tagMobilityEmergency.js

require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Service = require('../models/Service');

(async function main() {
  try {
    await connectDB();
    // Find services by subcategory or title
    const query = {
      $or: [
        { subcategory: 'mobilityAssistance' },
        { title: /mobility/i },
        { title: /bathing/i },
      ]
    };

    const services = await Service.find(query);
    console.log(`Found ${services.length} candidate services`);

    const updated = [];
    for (const s of services) {
      const prev = {
        emergencyEnabled: s.emergencyEnabled,
        emergencyRateMultiplier: s.emergencyRateMultiplier,
      };
      s.emergencyEnabled = true;
      s.emergencyRateMultiplier = 1.6;
      s.emergencyLeadTimeMinutes = 60;
      s.emergencySurcharge = { type: 'flat', amount: 0 };
      s.emergencyTypes = (s.emergencyTypes && s.emergencyTypes.length) ? s.emergencyTypes : ['mobility_and_bathing'];
      await s.save();
      updated.push({ id: s._id.toString(), title: s.title, before: prev, after: { emergencyEnabled: s.emergencyEnabled, emergencyRateMultiplier: s.emergencyRateMultiplier } });
      console.log(`Updated service ${s._id} (${s.title})`);
    }

    console.log('Updated services:', JSON.stringify(updated, null, 2));
  } catch (err) {
    console.error('Error tagging mobility emergency:', err);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
    process.exit(0);
  }
})();

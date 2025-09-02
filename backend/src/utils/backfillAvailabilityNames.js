require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Availability = require('../models/Availability');
const Provider = require('../models/Provider');

(async () => {
  try {
    await connectDB();
    const avail = await Availability.find({});
    let updated = 0;
    for (const a of avail) {
      if (!a.provider) continue;
      const p = await Provider.findById(a.provider);
      if (!p) continue;
      const fullName = `${p.firstName || ''} ${p.lastName || ''}`.trim();
      const changes = {};
      if (a.providerName !== fullName) changes.providerName = fullName;
      if (a.providerEmail !== p.email) changes.providerEmail = p.email;
      if (Object.keys(changes).length) {
        await Availability.updateOne({ _id: a._id }, { $set: changes });
        updated++;
      }
    }
    console.log(`Backfill complete. Updated: ${updated}`);
  } catch (e) {
    console.error('backfillAvailabilityNames error:', e);
    process.exit(1);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
  }
})();

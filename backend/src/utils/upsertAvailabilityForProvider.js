require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Availability = require('../models/Availability');
const Provider = require('../models/Provider');

/**
 * Usage:
 *   node src/utils/upsertAvailabilityForProvider.js <providerEmailOrId>
 * Seeds a default Mon-Fri 09:00-17:00 availability in Asia/Jerusalem if missing.
 */
(async () => {
  const idOrEmail = process.argv[2];
  if (!idOrEmail) {
    console.log('Usage: node src/utils/upsertAvailabilityForProvider.js <providerEmailOrId>');
    process.exit(1);
  }
  try {
    await connectDB();
    let provider;
    if (/^[0-9a-fA-F]{24}$/.test(idOrEmail)) {
      provider = await Provider.findById(idOrEmail);
    } else {
      provider = await Provider.findOne({ email: idOrEmail });
    }
    if (!provider) {
      console.error('Provider not found for', idOrEmail);
      process.exit(1);
    }

    const fullName = `${provider.firstName || ''} ${provider.lastName || ''}`.trim();
    const base = {
      provider: provider._id,
      providerName: fullName,
      providerEmail: provider.email,
      timezone: 'Asia/Jerusalem',
      weekly: {
        monday: [{ start: '09:00', end: '17:00' }],
        tuesday: [{ start: '09:00', end: '17:00' }],
        wednesday: [{ start: '09:00', end: '17:00' }],
        thursday: [{ start: '09:00', end: '17:00' }],
        friday: [{ start: '09:00', end: '17:00' }],
        saturday: [],
        sunday: []
      },
      exceptions: []
    };

    const existing = await Availability.findOne({ provider: provider._id });
    let a;
    if (!existing) {
      a = await Availability.create(base);
    } else {
  existing.timezone = 'Asia/Jerusalem';
  existing.providerName = fullName;
  existing.providerEmail = provider.email;
      await existing.save();
      a = existing;
    }
    console.log('Availability upserted for', provider.email, '->', a._id.toString());
  } catch (e) {
    console.error('upsertAvailabilityForProvider error:', e);
    process.exit(1);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
  }
})();

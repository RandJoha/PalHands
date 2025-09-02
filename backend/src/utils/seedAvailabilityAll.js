// Ensure we load the backend/.env even when running from repo root
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '..', '.env') });
const { connectDB, mongoose } = require('../config/database');
const Provider = require('../models/Provider');
const Availability = require('../models/Availability');

/**
 * Seed default availability for ALL providers who lack a valid weekly schedule.
 *
 * Defaults:
 *  - Timezone: Asia/Jerusalem
 *  - Mon-Thu: 09:00-12:00, 13:00-17:00
 *  - Fri:     09:00-12:00
 *  - Sat:     []
 *  - Sun:     09:00-12:00, 13:00-17:00
 */
async function main() {
  const tz = process.env.DEFAULT_AVAILABILITY_TZ || 'Asia/Jerusalem';
  const weekly = {
    monday: [{ start: '09:00', end: '12:00' }, { start: '13:00', end: '17:00' }],
    tuesday: [{ start: '09:00', end: '12:00' }, { start: '13:00', end: '17:00' }],
    wednesday: [{ start: '09:00', end: '12:00' }, { start: '13:00', end: '17:00' }],
    thursday: [{ start: '09:00', end: '12:00' }, { start: '13:00', end: '17:00' }],
    friday: [{ start: '09:00', end: '12:00' }],
    saturday: [],
    sunday: [{ start: '09:00', end: '12:00' }, { start: '13:00', end: '17:00' }],
  };

  function isValidWindows(w) {
    if (!w) return false;
    const days = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
    return days.some(d => Array.isArray(w[d]) && w[d].length > 0);
  }

  await connectDB();
  try {
    const providers = await Provider.find({ role: 'provider' }).select('_id firstName lastName email');
    const ids = providers.map(p => p._id);

    // Find existing availability docs
    const existing = await Availability.find({ provider: { $in: ids } });
    const byProv = new Map(existing.map(a => [String(a.provider), a]));

    let created = 0, updated = 0, skipped = 0;
    for (const p of providers) {
      const key = String(p._id);
      const fullName = `${p.firstName || ''} ${p.lastName || ''}`.trim();
      const have = byProv.get(key);
      if (!have) {
        await Availability.create({
          provider: p._id,
          providerName: fullName,
          providerEmail: p.email,
          timezone: tz,
          weekly,
          exceptions: [],
        });
        created++;
        continue;
      }
      // If exists but has no valid weekly windows, set defaults
      if (!isValidWindows(have.weekly)) {
        have.weekly = weekly;
        have.timezone = have.timezone || tz;
        have.providerName = fullName;
        have.providerEmail = p.email;
        await have.save();
        updated++;
      } else {
        skipped++;
      }
    }

    console.log(JSON.stringify({ providers: providers.length, created, updated, skipped }, null, 2));
  } catch (e) {
    console.error('seedAvailabilityAll error:', e);
    process.exit(1);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
  }
}

main();

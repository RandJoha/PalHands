require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Provider = require('../models/Provider');
const Service = require('../models/Service');
const Availability = require('../models/Availability');

/**
 * Usage:
 *   node src/utils/enableEmergencyForProviders.js [comma,separated,emails]
 * If no emails provided, the script will pick the first 5 providers and enable emergency for them.
 */
(async function main() {
  try {
    await connectDB();
    const arg = process.argv[2];
    let providers;
    if (arg) {
      const keys = String(arg).split(',').map(s => s.trim()).filter(Boolean);
      const byId = keys.filter(k => /^[0-9a-fA-F]{24}$/.test(k));
      const byEmail = keys.filter(k => !/^[0-9a-fA-F]{24}$/.test(k));
      const q = { role: 'provider', $or: [] };
      if (byId.length) q.$or.push({ _id: { $in: byId } });
      if (byEmail.length) q.$or.push({ email: { $in: byEmail } });
      if (!q.$or.length) delete q.$or;
      providers = await Provider.find(q).limit(100);
    } else {
      providers = await Provider.find({ role: 'provider' }).limit(5);
    }

    if (!providers || providers.length === 0) {
      console.log('No providers found to enable emergency for.');
      return process.exit(0);
    }

    const results = [];
    for (const p of providers) {
      const pid = p._id;
      // Update all services for provider to enable emergency
      const svcUpdate = {
        emergencyEnabled: true,
        emergencyLeadTimeMinutes: 120,
        emergencySurcharge: { type: 'flat', amount: 50 }
      };
      await Service.updateMany({ provider: pid }, { $set: svcUpdate });

      // Ensure availability doc exists and add emergencyWeekly (late-night short-notice window)
      let avail = await Availability.findOne({ provider: pid });
      const fullName = `${p.firstName || ''} ${p.lastName || ''}`.trim();
      if (!avail) {
        avail = await Availability.create({
          provider: pid,
          providerName: fullName,
          providerEmail: p.email,
          timezone: 'Asia/Jerusalem',
          weekly: {},
          emergencyWeekly: {
            monday: [{ start: '22:00', end: '23:59' }],
            tuesday: [{ start: '22:00', end: '23:59' }],
            wednesday: [{ start: '22:00', end: '23:59' }],
            thursday: [{ start: '22:00', end: '23:59' }],
            friday: [{ start: '22:00', end: '23:59' }],
            saturday: [{ start: '22:00', end: '23:59' }],
            sunday: [{ start: '22:00', end: '23:59' }]
          },
          exceptions: [],
          emergencyExceptions: []
        });
      } else {
        avail.emergencyWeekly = {
          monday: [{ start: '22:00', end: '23:59' }],
          tuesday: [{ start: '22:00', end: '23:59' }],
          wednesday: [{ start: '22:00', end: '23:59' }],
          thursday: [{ start: '22:00', end: '23:59' }],
          friday: [{ start: '22:00', end: '23:59' }],
          saturday: [{ start: '22:00', end: '23:59' }],
          sunday: [{ start: '22:00', end: '23:59' }]
        };
        avail.emergencyExceptions = avail.emergencyExceptions || [];
        await avail.save();
      }

      results.push({ id: String(pid), email: p.email, name: fullName });
    }

    console.log('Enabled emergency for providers:', JSON.stringify(results, null, 2));
    process.exit(0);
  } catch (e) {
    console.error('enableEmergencyForProviders error:', e);
    try { await mongoose.connection.close(); } catch (_) {}
    process.exit(1);
  }
})();

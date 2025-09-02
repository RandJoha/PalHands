require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Provider = require('../models/Provider');
const Availability = require('../models/Availability');

(async () => {
  try {
    await connectDB();
    const providers = await Provider.find({ role: 'provider' }).select('_id firstName lastName email');
    const ids = providers.map(p => p._id);
    const avas = await Availability.find({ provider: { $in: ids } }).select('provider');
    const setAvail = new Set(avas.map(a => String(a.provider)));
    const rows = providers.map(p => ({
      id: String(p._id),
      name: `${p.firstName || ''} ${p.lastName || ''}`.trim(),
      email: p.email,
      hasAvailability: setAvail.has(String(p._id))
    }));
    console.log(JSON.stringify(rows, null, 2));
  } catch (e) {
    console.error('listProviders error:', e);
    process.exit(1);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
  }
})();

require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const User = require('../models/User');

(async function main(){
  try {
    await connectDB();
    const toRemove = await User.find({ role: 'provider' }).select('_id firstName lastName email');
    if (!toRemove.length) {
      console.log('No provider-role documents found in users collection. Nothing to do.');
      return process.exit(0);
    }
    console.log(`Found ${toRemove.length} provider documents lingering in users collection.`);
    toRemove.forEach(u => console.log(` - ${u._id} ${u.firstName} ${u.lastName} <${u.email}>`));

    const ids = toRemove.map(u => u._id);
    const res = await User.deleteMany({ _id: { $in: ids } });
    console.log(`Deleted ${res.deletedCount} users with role=provider.`);
    process.exit(0);
  } catch (e) {
    console.error('Migration failed:', e);
    process.exit(1);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
  }
})();

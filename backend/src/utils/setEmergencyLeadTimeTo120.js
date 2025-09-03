/**
 * Migration script: set emergencyLeadTimeMinutes = 120 for all Service documents
 * Usage: node backend/src/utils/setEmergencyLeadTimeTo120.js
 * This script is idempotent and will update any document where the value differs.
 */
const mongoose = require('mongoose');
const path = require('path');

require('dotenv').config({ path: path.resolve(process.cwd(), 'backend', '.env') });

const Service = require('../models/Service');

async function run() {
  const uri = process.env.MONGODB_URI || process.env.DB_URI || process.env.MONGO_URI;
  if (!uri) {
    console.error('MONGODB_URI not set in environment. Set it and re-run the script.');
    process.exit(1);
  }

  await mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true });
  console.log('Connected to MongoDB');

  try {
    const res = await Service.updateMany(
      { $or: [ { emergencyLeadTimeMinutes: { $exists: false } }, { emergencyLeadTimeMinutes: { $ne: 120 } } ] },
      { $set: { emergencyLeadTimeMinutes: 120 } }
    );
    console.log('Matched:', res.matchedCount, 'Modified:', res.modifiedCount);
  } catch (err) {
    console.error('Migration failed:', err);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected');
  }
}

if (require.main === module) {
  run().catch(err => {
    console.error(err);
    process.exit(1);
  });
}

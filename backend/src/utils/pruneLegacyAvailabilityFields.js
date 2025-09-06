// Remove legacy per-service availability fields and normalize to unified Availability collection
// Run with: node src/utils/pruneLegacyAvailabilityFields.js

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '..', '.env') });
const { connectDB, mongoose } = require('../config/database');
const Service = require('../models/Service');

async function main() {
  await connectDB();
  try {
    // Remove legacy embedded availability fields from Service docs when present
    const res = await Service.updateMany(
      { 'availability.timeSlots': { $exists: true } },
      { $unset: { availability: '' } }
    );
    console.log(JSON.stringify({ matched: res.matchedCount, modified: res.modifiedCount }, null, 2));
  } catch (e) {
    console.error('pruneLegacyAvailabilityFields error:', e);
    process.exit(1);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
  }
}

main();

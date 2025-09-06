require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const ProviderService = require('../models/ProviderService');

(async function main() {
  try {
    await connectDB();
    console.log('🔗 DB connected');

    const cursor = ProviderService.find({ status: { $ne: 'deleted' } }).cursor();
    let updated = 0, total = 0;
    for (let doc = await cursor.next(); doc != null; doc = await cursor.next()) {
      total++;
      const ps = doc;
      let score = 0;
      if (Number.isFinite(ps.hourlyRate) && ps.hourlyRate > 0) score += 35;
      if (Number.isFinite(ps.experienceYears) && ps.experienceYears >= 0) score += 25;
      const hasWeekly = ps.weeklyOverrides && Object.values(ps.weeklyOverrides.toObject?.() || {}).some(arr => (arr||[]).length > 0);
      const hasExceptions = Array.isArray(ps.exceptionOverrides) && ps.exceptionOverrides.length > 0;
      if (hasWeekly || hasExceptions) score += 25;
      if (ps.emergencyEnabled) score += 5;
      const publishable = (Number.isFinite(ps.hourlyRate) && ps.hourlyRate > 0) && (Number.isFinite(ps.experienceYears) && ps.experienceYears >= 0);

      // Only update when changes detected
      if (ps.publishable !== publishable || ps.completenessScore !== score) {
        ps.publishable = publishable;
        ps.completenessScore = score;
        if (publishable && ps.status === 'active' && !ps.publishedAt) ps.publishedAt = new Date();
        await ps.save();
        updated++;
      }
    }
    console.log(`✅ Done. Updated ${updated}/${total} ProviderService docs.`);
    await mongoose.connection.close();
    process.exit(0);
  } catch (e) {
    console.error('❌ Failed to recompute publishable:', e);
    process.exit(1);
  }
})();

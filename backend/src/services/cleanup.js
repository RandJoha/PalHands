const { validateEnv } = require('../utils/config');
const Service = require('../models/Service');
const { cleanupOrphansForService } = require('./storage');

function startMediaCleanupScheduler() {
  const env = validateEnv();
  if (!env.ENABLE_MEDIA_CLEANUP) return;
  const intervalMs = Math.max(5, env.MEDIA_CLEANUP_INTERVAL_MIN) * 60 * 1000;
  setInterval(async () => {
    try {
      const services = await Service.find({}).select('_id images').limit(200);
      for (const s of services) {
        await cleanupOrphansForService(s);
      }
      console.log('[media-cleanup] sweep complete');
    } catch (e) {
      console.error('[media-cleanup] error', e);
    }
  }, intervalMs);
}

module.exports = { startMediaCleanupScheduler };

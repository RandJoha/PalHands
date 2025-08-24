const dotenv = require('dotenv');
dotenv.config();
const { validateEnv } = require('./src/utils/config');
const env = validateEnv();
const { connectDB, mongoose } = require('./src/config/database');
const app = require('./src/app');
const { startMediaCleanupScheduler } = require('./src/services/cleanup');
const processorManager = require('./src/services/paymentProcessors/processorManager');

const PORT = env.PORT || 3000;





(async () => {
  await connectDB();
  
  // Initialize payment processors
  await processorManager.initialize();

  // Start outbox scheduler
  const outboxScheduler = require('./src/services/outboxScheduler');
  outboxScheduler.start({
    pendingIntervalMs: 5000,  // 5 seconds
    retryIntervalMs: 30000,   // 30 seconds
    cleanupIntervalMs: 3600000, // 1 hour
    batchSize: 50
  });

  // Start reconciliation scheduler
  const reconciliationScheduler = require('./src/services/reconciliationScheduler');
  reconciliationScheduler.start({
    dailyIntervalMs: 24 * 60 * 60 * 1000, // 24 hours
    weeklyIntervalMs: 7 * 24 * 60 * 60 * 1000, // 7 days
    monthlyIntervalMs: 24 * 60 * 60 * 1000, // 1 day for development (instead of 30 days)
    batchSize: 5
  });
  
  app.listen(PORT, () => {
    console.log(`🚀 PalHands server running on port ${PORT}`);
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🌐 Health check: http://localhost:${PORT}/api/health`);
  });
  startMediaCleanupScheduler();
})().catch((err) => {
  console.error('❌ Failed to start server:', err);
  process.exit(1);
});

// Graceful shutdown
const shutdown = async (signal) => {
  console.log(`${signal} received. Shutting down gracefully...`);
  try {
    await mongoose.connection.close();
    console.log('MongoDB connection closed.');
  } catch (err) {
    console.error('MongoDB close error:', err);
  }
  process.exit(0);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
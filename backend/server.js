const dotenv = require('dotenv');
dotenv.config();
const { validateEnv } = require('./src/utils/config');
const env = validateEnv();
const { connectDB, mongoose } = require('./src/config/database');
const app = require('./src/app-minimal');
const { startMediaCleanupScheduler } = require('./src/services/cleanup');

const PORT = env.PORT || 3000;
const HOST = '127.0.0.1'; // Force IPv4 binding

(async () => {
  await connectDB();
  app.listen(PORT, HOST, () => {
    console.log(`🚀 PalHands server running on http://${HOST}:${PORT}`);
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🌐 Health check: http://${HOST}:${PORT}/api/health`);
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
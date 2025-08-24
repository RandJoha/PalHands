const dotenv = require('dotenv');
dotenv.config();
const { validateEnv } = require('./src/utils/config');
const env = validateEnv();
const { connectDB, mongoose } = require('./src/config/database');
const app = require('./src/app');
const { startMediaCleanupScheduler } = require('./src/services/cleanup');

const PORT = env.PORT || 3000;


const express = require("express");
const cors = require("cors");
const morgan = require("morgan");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

// 👇 Add your test route here
app.post("/api/auth/register", (req, res) => {
  const { firstName, lastName, email, password, phone, role } = req.body;
  console.log("Register request:", req.body);

  // TODO: Save user to DB with Mongoose
  res.json({ message: "User registered successfully!" });
});





(async () => {
  await connectDB();
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
/* Auto-restored server.js - starts the PalHands API using src/app-minimal.js
   This file was accidentally emptied; recreate a safe startup that connects
   to MongoDB and listens on PORT.
*/
require('dotenv').config();
const mongoose = require('mongoose');
const app = require('./src/app-minimal');

const DEFAULT_PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/palhands-dev';

async function start() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URI, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
    });
    console.log('✅ Connected to MongoDB');

    const port = DEFAULT_PORT;
    app.listen(port, () => {
      console.log(`🚀 PalHands API listening on http://0.0.0.0:${port} (env=${process.env.NODE_ENV || 'development'})`);
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err && err.message ? err.message : err);
    // exit with non-zero code so nodemon will not treat as clean exit
    process.exit(1);
  }
}

start();

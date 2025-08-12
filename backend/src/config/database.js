const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const { MONGODB_URI } = process.env;
    if (!MONGODB_URI) {
      throw new Error('MONGODB_URI is not set. Please configure your .env with a valid MongoDB Atlas connection string.');
    }

    await mongoose.connect(MONGODB_URI);
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error.message || error);
    process.exit(1);
  }
};

module.exports = { connectDB, mongoose };
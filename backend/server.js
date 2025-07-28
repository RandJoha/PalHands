const mongoose = require('mongoose');
const app = require('./src/app');

const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/palhands';

// Connect to MongoDB
mongoose.connect(MONGODB_URI)
.then(() => {
  console.log('✅ Connected to MongoDB');
  
  // Start server
  app.listen(PORT, () => {
    console.log(`🚀 PalHands server running on port ${PORT}`);
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🌐 Health check: http://localhost:${PORT}/api/health`);
  });
})
.catch((error) => {
  console.error('❌ MongoDB connection error:', error);
  console.log('💡 To fix this:');
  console.log('   1. Start Docker Desktop and run: docker run -d -p 27017:27017 --name mongodb-palhands mongo:latest');
  console.log('   2. Or update your .env file with MongoDB Atlas connection string');
  console.log('   3. Or install MongoDB locally');
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received. Shutting down gracefully...');
  mongoose.connection.close(() => {
    console.log('MongoDB connection closed.');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received. Shutting down gracefully...');
  mongoose.connection.close(() => {
    console.log('MongoDB connection closed.');
    process.exit(0);
  });
}); 
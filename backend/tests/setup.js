require('dotenv').config();
process.env.MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/palhands_test';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';

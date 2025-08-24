// Test setup file
require('dotenv').config({ path: 'test.env' });

// Set test environment
process.env.NODE_ENV = 'test';

// Increase timeout for all tests
jest.setTimeout(30000);

// Global test utilities
global.testUtils = {
  // Helper to create test data
  createTestUser: (role = 'client') => ({
    firstName: 'Test',
    lastName: 'User',
    email: `test${Date.now()}@example.com`,
    phone: '+970590000000',
    password: 'TestPass123!',
    role,
    isVerified: true,
    isActive: true
  }),

  // Helper to create test booking
  createTestBooking: (clientId, providerId) => ({
    bookingId: `TEST_BOOKING_${Date.now()}`,
    client: clientId,
    provider: providerId,
    service: '507f1f77bcf86cd799439011',
    status: 'pending',
    scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
    pricing: {
      totalAmount: 150,
      currency: 'ILS',
      breakdown: {
        serviceFee: 100,
        platformFee: 50
      }
    }
  })
};

// Mock console methods to reduce noise in tests
global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn()
};

const mongoose = require('mongoose');
const Availability = require('../models/Availability');
const ProviderService = require('../models/ProviderService');

// Simple test script to ensure we have availability data for testing
async function seedTestAvailability() {
  try {
    console.log('🌱 Seeding test availability data...');

    // Create default availability for test providers
    const testProviders = [
      { 
        providerId: '507f1f77bcf86cd799439011', // Test provider ID
        name: 'Test Provider 1',
        email: 'test@provider.com'
      },
      { 
        providerId: '507f1f77bcf86cd799439012', // Another test provider
        name: 'Test Provider 2', 
        email: 'test2@provider.com'
      }
    ];

    for (const provider of testProviders) {
      // Create availability document
      const availability = {
        provider: provider.providerId,
        providerName: provider.name,
        providerEmail: provider.email,
        timezone: 'Asia/Jerusalem',
        weekly: {
          monday: [{ start: '09:00', end: '17:00' }],
          tuesday: [{ start: '09:00', end: '17:00' }],
          wednesday: [{ start: '09:00', end: '17:00' }],
          thursday: [{ start: '09:00', end: '17:00' }],
          friday: [{ start: '09:00', end: '17:00' }],
          saturday: [],
          sunday: []
        },
        emergencyWeekly: {
          monday: [{ start: '18:00', end: '20:00' }],
          tuesday: [{ start: '18:00', end: '20:00' }],
          wednesday: [{ start: '18:00', end: '20:00' }],
          thursday: [{ start: '18:00', end: '20:00' }],
          friday: [{ start: '18:00', end: '20:00' }],
          saturday: [{ start: '08:00', end: '12:00' }],
          sunday: [{ start: '08:00', end: '12:00' }]
        },
        exceptions: [],
        emergencyExceptions: []
      };

      await Availability.findOneAndUpdate(
        { provider: provider.providerId },
        availability,
        { upsert: true, new: true }
      );

      console.log(`✅ Created availability for ${provider.name}`);

      // Create test provider service
      const testServiceId = '507f1f77bcf86cd799439099';
      await ProviderService.findOneAndUpdate(
        { provider: provider.providerId, service: testServiceId },
        {
          provider: provider.providerId,
          service: testServiceId,
          hourlyRate: 50,
          experienceYears: 3,
          status: 'active',
          publishable: true,
          emergencyEnabled: true,
          emergencyLeadTimeMinutes: 120 // 2 hours
        },
        { upsert: true, new: true }
      );

      console.log(`✅ Created provider service for ${provider.name}`);
    }

    console.log('🌱 Test availability data seeded successfully!');
  } catch (error) {
    console.error('❌ Error seeding test availability:', error);
  }
}

module.exports = { seedTestAvailability };

// Run directly if called as script
if (require.main === module) {
  const { connectDB } = require('../config/database');
  connectDB()
    .then(() => seedTestAvailability())
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('Database connection failed:', error);
      process.exit(1);
    });
}

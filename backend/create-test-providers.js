require('dotenv').config();
const { connectDB, mongoose } = require('./src/config/database');
const Provider = require('./src/models/Provider');

async function createTestProviders() {
  await connectDB();

  try {
    // Clear existing providers
    await Provider.deleteMany({});
    console.log('✅ Cleared existing providers');

    // Create test providers
    const testProviders = [
      {
        providerId: 1001,
        firstName: 'Ahmed',
        lastName: 'Hassan',
        email: 'ahmed.hassan@test.com',
        password: 'Test123!',
        phone: '+970590000001',
        experienceYears: 5,
        languages: ['Arabic', 'English'],
        hourlyRate: 80,
        services: ['homeCleaning', 'bedroomCleaning'],
        rating: { average: 4.5, count: 25 },
        addresses: [
          {
            type: 'home',
            city: 'Ramallah',
            area: 'Al-Bireh',
            isDefault: true
          }
        ],
        isActive: true,
        isVerified: true
      },
      {
        providerId: 1002,
        firstName: 'Fatima',
        lastName: 'Ali',
        email: 'fatima.ali@test.com',
        password: 'Test123!',
        phone: '+970590000002',
        experienceYears: 3,
        languages: ['Arabic', 'Hebrew'],
        hourlyRate: 70,
        services: ['elderlyCare', 'childcare'],
        rating: { average: 4.8, count: 18 },
        addresses: [
          {
            type: 'home',
            city: 'Nablus',
            area: 'Old City',
            isDefault: true
          }
        ],
        isActive: true,
        isVerified: true
      },
      {
        providerId: 1003,
        firstName: 'Omar',
        lastName: 'Khalil',
        email: 'omar.khalil@test.com',
        password: 'Test123!',
        phone: '+970590000003',
        experienceYears: 7,
        languages: ['Arabic', 'English', 'Turkish'],
        hourlyRate: 90,
        services: ['homeMaintenance', 'carpentry'],
        rating: { average: 4.6, count: 32 },
        addresses: [
          {
            type: 'home',
            city: 'Jerusalem',
            area: 'East Jerusalem',
            isDefault: true
          }
        ],
        isActive: true,
        isVerified: true
      }
    ];

    const createdProviders = await Provider.insertMany(testProviders);
    console.log(`✅ Created ${createdProviders.length} test providers:`);
    
    createdProviders.forEach(provider => {
      console.log(`   - ${provider.firstName} ${provider.lastName} (ID: ${provider._id})`);
    });

    console.log('\n🎯 Test providers ready for chat testing!');
    console.log('📱 Provider IDs for testing:');
    createdProviders.forEach(provider => {
      console.log(`   - ${provider._id} (${provider.firstName} ${provider.lastName})`);
    });

  } catch (error) {
    console.error('❌ Error creating test providers:', error);
  } finally {
    await mongoose.connection.close();
  }
}

createTestProviders();

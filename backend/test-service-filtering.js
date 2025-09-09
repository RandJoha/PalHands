// Test script to verify service filtering works correctly
const mongoose = require('mongoose');
const Provider = require('./backend/src/models/Provider');
const ProviderService = require('./backend/src/models/ProviderService');
const Service = require('./backend/src/models/Service');

async function testServiceFiltering() {
  try {
    // Connect to MongoDB
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/palhands';
    console.log('🔌 Attempting to connect to MongoDB:', mongoUri);
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB');

    // Test 1: Check if "Door Cabinet Cleaning" service exists
    const doorCabinetService = await Service.findOne({ title: 'Door Cabinet Cleaning' });
    console.log('🔍 Door Cabinet Cleaning service:', doorCabinetService ? 'Found' : 'Not found');
    
    if (doorCabinetService) {
      console.log('   Service ID:', doorCabinetService._id);
      console.log('   Service Title:', doorCabinetService.title);
      console.log('   Service Category:', doorCabinetService.category);
    }

    // Test 2: Find providers who offer "Door Cabinet Cleaning"
    const providersWithDoorCabinet = await ProviderService.aggregate([
      { 
        $match: { 
          status: 'active', 
          publishable: true 
        } 
      },
      {
        $lookup: {
          from: 'services',
          localField: 'service',
          foreignField: '_id',
          as: 'serviceData'
        }
      },
      {
        $unwind: '$serviceData'
      },
      {
        $match: {
          'serviceData.title': 'Door Cabinet Cleaning'
        }
      },
      {
        $group: {
          _id: '$provider'
        }
      }
    ]);

    console.log('🏢 Providers offering Door Cabinet Cleaning:', providersWithDoorCabinet.length);
    
    if (providersWithDoorCabinet.length > 0) {
      const providerIds = providersWithDoorCabinet.map(x => String(x._id));
      console.log('   Provider IDs:', providerIds);
      
      // Get provider details
      const providers = await Provider.find({ _id: { $in: providerIds } })
        .select('name providerId services');
      
      console.log('   Provider Details:');
      providers.forEach(p => {
        console.log(`     - ${p.name} (ID: ${p.providerId}) - Services: ${p.services.join(', ')}`);
      });
    }

    // Test 3: Check what services "rand 2" actually offers
    const rand2Provider = await Provider.findOne({ name: 'rand 2' });
    if (rand2Provider) {
      console.log('🔍 rand 2 provider details:');
      console.log('   Provider ID:', rand2Provider._id);
      console.log('   Services in Provider.services:', rand2Provider.services);
      
      // Check what services rand 2 offers through ProviderService
      const rand2ProviderServices = await ProviderService.find({ 
        provider: rand2Provider._id,
        status: 'active',
        publishable: true
      }).populate('service', 'title category');
      
      console.log('   Services through ProviderService:');
      rand2ProviderServices.forEach(ps => {
        console.log(`     - ${ps.service.title} (${ps.service.category})`);
      });
    }

    console.log('✅ Test completed successfully');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run the test
testServiceFiltering();

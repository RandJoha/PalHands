const mongoose = require('mongoose');
require('dotenv').config();

async function findLinaServices() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    
    const Provider = require('./src/models/Provider');
    const Service = require('./src/models/Service');
    const ProviderService = require('./src/models/ProviderService');
    
    // Get Lina's provider record
    const provider = await Provider.findOne({ email: 'provider.lina.33@palhands.com' });
    console.log('Lina Provider ID:', provider._id);
    console.log('Lina Services Array:', provider.services);
    
    console.log('\n=== SERVICES BELONGING TO LINA ===');
    const linaServices = await Service.find({ provider: provider._id });
    console.log('Services directly assigned to Lina:', linaServices.length);
    
    linaServices.forEach(service => {
      console.log(`- ${service.title} (${service.subcategory}) - ₪${service.price.amount}/hour`);
    });
    
    console.log('\n=== CHECKING FOR LINA\'S EXPECTED SERVICES ===');
    const expectedCodes = ['emotionalSupport', 'preOccupancyRepairs', 'prescriptionPickup'];
    
    for (const code of expectedCodes) {
      // Check if service exists with this subcategory and belongs to Lina
      const service = await Service.findOne({ 
        subcategory: code, 
        provider: provider._id 
      });
      
      if (service) {
        console.log(`✅ ${code}: Found "${service.title}" (ID: ${service._id})`);
      } else {
        // Check if service exists but belongs to someone else
        const serviceElsewhere = await Service.findOne({ subcategory: code });
        if (serviceElsewhere) {
          console.log(`⚠️  ${code}: Found but belongs to different provider (${serviceElsewhere.provider})`);
        } else {
          console.log(`❌ ${code}: Not found anywhere`);
        }
      }
    }
    
    console.log('\n=== ALL SERVICES BY SUBCATEGORY ===');
    const servicesBySubcategory = await Service.aggregate([
      { $group: { _id: '$subcategory', count: { $sum: 1 }, providers: { $addToSet: '$provider' } } },
      { $sort: { _id: 1 } }
    ]);
    
    expectedCodes.forEach(code => {
      const found = servicesBySubcategory.find(s => s._id === code);
      if (found) {
        console.log(`${code}: ${found.count} services, providers: ${found.providers.join(', ')}`);
      } else {
        console.log(`${code}: No services found`);
      }
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

findLinaServices();

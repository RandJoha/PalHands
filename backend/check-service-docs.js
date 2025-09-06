const mongoose = require('mongoose');
require('dotenv').config();

async function checkServiceDocuments() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    
    const Service = require('./src/models/Service');
    
    console.log('=== ALL SERVICE DOCUMENTS ===');
    const allServices = await Service.find();
    console.log('Total Service documents:', allServices.length);
    
    allServices.forEach(service => {
      console.log(`- ${service.code}: ${service.name}`);
    });
    
    console.log('\n=== LINA\'S REQUIRED SERVICES ===');
    const linaCodes = ['emotionalSupport', 'preOccupancyRepairs', 'prescriptionPickup'];
    
    for (const code of linaCodes) {
      const service = await Service.findOne({ code });
      if (service) {
        console.log(`✅ ${code}: ${service.name} (ID: ${service._id})`);
      } else {
        console.log(`❌ ${code}: NOT FOUND`);
      }
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

checkServiceDocuments();

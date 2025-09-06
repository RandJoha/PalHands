const mongoose = require('mongoose');
require('dotenv').config();

async function inspectServiceDocuments() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    
    const Service = require('./src/models/Service');
    
    console.log('=== FIRST 5 SERVICE DOCUMENTS (Raw) ===');
    const services = await Service.find().limit(5);
    
    services.forEach((service, index) => {
      console.log(`\nService ${index + 1}:`);
      console.log(JSON.stringify(service.toObject(), null, 2));
    });
    
    console.log('\n=== CHECKING FOR SPECIFIC TITLES ===');
    const emotionalSupport = await Service.findOne({ 
      $or: [
        { title: { $regex: /emotional/i } },
        { description: { $regex: /emotional/i } }
      ]
    });
    
    if (emotionalSupport) {
      console.log('Found emotional support service:');
      console.log(JSON.stringify(emotionalSupport.toObject(), null, 2));
    } else {
      console.log('No emotional support service found');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

inspectServiceDocuments();

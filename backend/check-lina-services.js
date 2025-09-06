const mongoose = require('mongoose');
require('dotenv').config();

async function checkLinaServices() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    
    const Provider = require('./src/models/Provider');
    const Service = require('./src/models/Service');
    const ProviderService = require('./src/models/ProviderService');
    
    console.log('=== PROVIDER DATA ===');
    const provider = await Provider.findOne({ email: 'provider.lina.33@palhands.com' });
    if (!provider) {
      console.log('Provider not found!');
      return;
    }
    
    console.log('Provider ID:', provider._id);
    console.log('Provider Services Array:', provider.services);
    console.log('Provider Hourly Rate:', provider.hourlyRate);
    console.log('Provider Experience Years:', provider.experienceYears);
    
    console.log('\n=== SERVICE DOCUMENTS ===');
    const services = await Service.find({ code: { $in: provider.services } });
    services.forEach(service => {
      console.log(`Service: ${service.code} - ${service.name}`);
    });
    
    console.log('\n=== PROVIDER-SERVICE RECORDS ===');
    const providerServices = await ProviderService.find({ providerId: provider._id });
    console.log('Total ProviderService records:', providerServices.length);
    
    for (const ps of providerServices) {
      const service = await Service.findById(ps.serviceId);
      console.log(`ProviderService: ${service ? service.code : 'UNKNOWN'} - Rate: ₪${ps.hourlyRate}/hour, Experience: ${ps.experienceYears} years, Status: ${ps.status}`);
    }
    
    console.log('\n=== EXPECTED vs ACTUAL ===');
    console.log('Expected services from provider.services:', provider.services);
    console.log('Actual ProviderService count:', providerServices.length);
    
    if (provider.services.length !== providerServices.length) {
      console.log('❌ MISMATCH: Provider should have', provider.services.length, 'services but has', providerServices.length, 'ProviderService records');
    } else {
      console.log('✅ Count matches');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

checkLinaServices();

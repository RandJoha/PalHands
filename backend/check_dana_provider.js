const mongoose = require('mongoose');
const Provider = require('./src/models/Provider');

async function checkDanaProvider() {
  try {
    // Connect to MongoDB
    await mongoose.connect('mongodb://127.0.0.1:27017/palhands-dev');
    console.log('Connected to MongoDB');

    // Find Dana M by name
    const danaProviders = await Provider.find({
      $or: [
        { firstName: { $regex: /dana/i } },
        { lastName: { $regex: /m/i } }
      ]
    }).select('_id providerId firstName lastName email phone createdAt updatedAt');

    console.log(`Found ${danaProviders.length} providers matching "Dana M":`);
    
    danaProviders.forEach((provider, index) => {
      console.log(`\nProvider ${index + 1}:`);
      console.log(`  MongoDB _id: ${provider._id}`);
      console.log(`  Provider ID: ${provider.providerId}`);
      console.log(`  Name: ${provider.firstName} ${provider.lastName}`);
      console.log(`  Email: ${provider.email}`);
      console.log(`  Phone: ${provider.phone}`);
      console.log(`  Created: ${provider.createdAt}`);
      console.log(`  Updated: ${provider.updatedAt}`);
    });

    // Check if there are multiple providers with the same email
    if (danaProviders.length > 0) {
      const emails = danaProviders.map(p => p.email);
      const uniqueEmails = [...new Set(emails)];
      
      if (emails.length !== uniqueEmails.length) {
        console.log('\n⚠️  WARNING: Multiple providers found with the same email!');
        emails.forEach((email, index) => {
          const count = emails.filter(e => e === email).length;
          if (count > 1) {
            console.log(`  Email "${email}" appears ${count} times`);
          }
        });
      }
    }

    // Check for duplicate providerIds
    const providerIds = danaProviders.map(p => p.providerId).filter(id => id != null);
    const uniqueProviderIds = [...new Set(providerIds)];
    
    if (providerIds.length !== uniqueProviderIds.length) {
      console.log('\n⚠️  WARNING: Duplicate providerIds found!');
      providerIds.forEach((id, index) => {
        const count = providerIds.filter(i => i === id).length;
        if (count > 1) {
          console.log(`  ProviderId ${id} appears ${count} times`);
        }
      });
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

checkDanaProvider();

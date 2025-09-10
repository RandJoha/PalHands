const mongoose = require('mongoose');
const Provider = require('./src/models/Provider');
const User = require('./src/models/User');

async function testAdminSearch() {
  try {
    // Connect to MongoDB
    await mongoose.connect('mongodb://127.0.0.1:27017/palhands-dev');
    console.log('Connected to MongoDB');

    // Test search for "4621"
    const searchTerm = "4621";
    console.log(`\n🔍 Testing search for: "${searchTerm}"`);

    // Test the new search logic
    const isProviderId = /^\d{4}$/.test(searchTerm);
    console.log(`Is 4-digit ID: ${isProviderId}`);

    if (isProviderId) {
      // Search providers by providerId
      const providersByProviderId = await Provider.find({ 
        providerId: parseInt(searchTerm, 10) 
      }).select('_id providerId firstName lastName email');
      
      console.log(`\n📋 Providers found by providerId (${searchTerm}):`);
      providersByProviderId.forEach(p => {
        console.log(`  - ${p.firstName} ${p.lastName} (providerId: ${p.providerId}, _id: ${p._id})`);
      });

      // Search providers by last 4 digits of _id
      const providersByMongoId = await Provider.find({
        $expr: {
          $eq: [
            { $substr: [{ $toString: "$_id" }, -4, 4] },
            searchTerm
          ]
        }
      }).select('_id providerId firstName lastName email');
      
      console.log(`\n📋 Providers found by MongoDB _id suffix (${searchTerm}):`);
      providersByMongoId.forEach(p => {
        console.log(`  - ${p.firstName} ${p.lastName} (providerId: ${p.providerId}, _id: ${p._id})`);
      });

      // Search users by last 4 digits of _id
      const usersByMongoId = await User.find({
        $expr: {
          $eq: [
            { $substr: [{ $toString: "$_id" }, -4, 4] },
            searchTerm
          ]
        }
      }).select('_id firstName lastName email role');
      
      console.log(`\n📋 Users found by MongoDB _id suffix (${searchTerm}):`);
      usersByMongoId.forEach(u => {
        console.log(`  - ${u.firstName} ${u.lastName} (role: ${u.role}, _id: ${u._id})`);
      });

      // Combined search (as the admin controller would do)
      const allProviders = await Provider.find({
        $or: [
          { firstName: { $regex: searchTerm, $options: 'i' } },
          { lastName: { $regex: searchTerm, $options: 'i' } },
          { email: { $regex: searchTerm, $options: 'i' } },
          { phone: { $regex: searchTerm, $options: 'i' } },
          { providerId: parseInt(searchTerm, 10) },
          {
            $expr: {
              $eq: [
                { $substr: [{ $toString: "$_id" }, -4, 4] },
                searchTerm
              ]
            }
          }
        ]
      }).select('_id providerId firstName lastName email');
      
      console.log(`\n📋 All providers found with combined search:`);
      allProviders.forEach(p => {
        console.log(`  - ${p.firstName} ${p.lastName} (providerId: ${p.providerId}, _id: ${p._id})`);
      });

      const allUsers = await User.find({
        $or: [
          { firstName: { $regex: searchTerm, $options: 'i' } },
          { lastName: { $regex: searchTerm, $options: 'i' } },
          { email: { $regex: searchTerm, $options: 'i' } },
          { phone: { $regex: searchTerm, $options: 'i' } },
          {
            $expr: {
              $eq: [
                { $substr: [{ $toString: "$_id" }, -4, 4] },
                searchTerm
              ]
            }
          }
        ]
      }).select('_id firstName lastName email role');
      
      console.log(`\n📋 All users found with combined search:`);
      allUsers.forEach(u => {
        console.log(`  - ${u.firstName} ${u.lastName} (role: ${u.role}, _id: ${u._id})`);
      });
    }

    // Also test with Dana's data
    console.log(`\n🔍 Testing search for Dana:`);
    const danaProviders = await Provider.find({
      $or: [
        { firstName: { $regex: /dana/i } },
        { lastName: { $regex: /m/i } }
      ]
    }).select('_id providerId firstName lastName email');
    
    danaProviders.forEach(p => {
      const mongoIdSuffix = p._id.toString().slice(-4);
      console.log(`  - ${p.firstName} ${p.lastName} (providerId: ${p.providerId}, _id: ${p._id}, suffix: ${mongoIdSuffix})`);
    });

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

testAdminSearch();

require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const User = require('../models/User');
const Service = require('../models/Service');

async function run() {
  await connectDB();

  // Ensure admin user exists (dev-only)
  const adminEmail = 'admin@example.com';
  let admin = await User.findOne({ email: adminEmail });
  if (!admin) {
    admin = new User({
      firstName: 'Admin',
      lastName: 'User',
      email: adminEmail,
      phone: '+970590000000',
      password: 'Admin123!',
      role: 'admin',
      isVerified: true
    });
    await admin.save();
    console.log('Created admin:', admin.email);
  } else {
  // Ensure correct role/flags and reset password to known dev value
  admin.role = 'admin';
  admin.isVerified = true;
  admin.isActive = true;
  admin.password = 'Admin123!'; // will be hashed by pre-save hook
  await admin.save();
  console.log('Existing admin updated and password reset:', admin.email);
  }

  const providers = [
    { firstName: 'Lina', lastName: 'Provider', email: 'lina.provider@example.com', phone: '+970590000001', password: 'Passw0rd!', role: 'provider', isVerified: true },
    { firstName: 'Omar', lastName: 'Provider', email: 'omar.provider@example.com', phone: '+970590000002', password: 'Passw0rd!', role: 'provider', isVerified: true }
  ];

  const created = [];
  for (const p of providers) {
    let user = await User.findOne({ email: p.email });
    if (!user) {
      user = new User(p);
      await user.save();
      created.push(user);
      console.log('Created provider:', user.email);
    } else {
      console.log('Existing provider:', user.email);
    }
  }

  // Ensure at least one demo service per provider
  for (const prov of await User.find({ role: 'provider' })) {
    const count = await Service.countDocuments({ provider: prov._id });
    if (count === 0) {
      await Service.create({
        title: 'General Cleaning Service',
        description: 'Thorough home cleaning by experienced provider.',
        category: 'cleaning',
        subcategory: 'home',
        provider: prov._id,
        price: { amount: 100, type: 'hourly', currency: 'ILS' },
        duration: { estimated: 120, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday'], timeSlots: [{ start: '09:00', end: '17:00' }], flexible: true },
        location: { serviceArea: 'Ramallah', radius: 20, onSite: true, remote: false },
        images: [],
        requirements: [],
        equipment: []
      });
      console.log('Seeded service for', prov.email);
    }
  }

  console.log('\nTest provider credentials:');
  console.log('- Email: lina.provider@example.com | Password: Passw0rd!');
  console.log('- Email: omar.provider@example.com | Password: Passw0rd!');
  console.log('\nAdmin credentials:');
  console.log('- Email: admin@example.com | Password: Admin123!');

  await mongoose.connection.close();
}

run().catch(err => { console.error(err); process.exit(1); });

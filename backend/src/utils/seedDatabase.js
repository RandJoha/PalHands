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
    { firstName: 'Lina', lastName: 'Provider', email: 'lina.provider@example.com', phone: '+970590000011', password: 'Passw0rd!', role: 'provider', isVerified: true },
    { firstName: 'Omar', lastName: 'Provider', email: 'omar.provider@example.com', phone: '+970590000012', password: 'Passw0rd!', role: 'provider', isVerified: true },
    { firstName: 'Fatima', lastName: 'Al-Zahra', email: 'fatima.cleaning@example.com', phone: '+970590000013', password: 'Passw0rd!', role: 'provider', isVerified: true },
    { firstName: 'Mariam', lastName: 'Hassan', email: 'mariam.care@example.com', phone: '+970590000014', password: 'Passw0rd!', role: 'provider', isVerified: true },
    { firstName: 'Aisha', lastName: 'Mohammed', email: 'aisha.maintenance@example.com', phone: '+970590000015', password: 'Passw0rd!', role: 'provider', isVerified: true },
    { firstName: 'Khalil', lastName: 'Abu-Rahma', email: 'khalil.carpentry@example.com', phone: '+970590000016', password: 'Passw0rd!', role: 'provider', isVerified: true }
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
      // Update existing provider to ensure correct role and verification
      user.role = 'provider';
      user.isVerified = true;
      user.isActive = true;
      user.password = p.password; // will be hashed by pre-save hook
      await user.save();
      console.log('Existing provider updated:', user.email);
    }
  }

  // Create comprehensive services for each provider
  const providerServices = {
    'fatima.cleaning@example.com': [
      {
        title: 'Professional Home Cleaning',
        description: 'Complete home cleaning service including kitchen, bathroom, living areas, and bedrooms. Deep cleaning with eco-friendly products.',
        category: 'cleaning',
        subcategory: 'home_cleaning',
        price: { amount: 150, type: 'fixed', currency: 'ILS' },
        duration: { estimated: 180, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday','saturday'], timeSlots: [{ start: '08:00', end: '18:00' }], flexible: true },
        location: { serviceArea: 'Jerusalem', radius: 15, onSite: true, remote: false },
        rating: { average: 4.8, count: 45 },
        totalBookings: 67,
        isActive: true,
        featured: true
      },
      {
        title: 'Kitchen Deep Cleaning',
        description: 'Specialized kitchen cleaning including appliances, cabinets, countertops, and floors. Perfect for maintaining a hygienic cooking space.',
        category: 'cleaning',
        subcategory: 'kitchen_cleaning',
        price: { amount: 80, type: 'fixed', currency: 'ILS' },
        duration: { estimated: 90, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday'], timeSlots: [{ start: '09:00', end: '17:00' }], flexible: true },
        location: { serviceArea: 'Jerusalem', radius: 15, onSite: true, remote: false },
        rating: { average: 4.9, count: 23 },
        totalBookings: 34,
        isActive: true,
        featured: false
      }
    ],
    'mariam.care@example.com': [
      {
        title: 'Elderly Care & Companionship',
        description: 'Compassionate elderly care services including companionship, medication reminders, meal preparation, and light housekeeping.',
        category: 'elderly_support',
        subcategory: 'companionship',
        price: { amount: 120, type: 'hourly', currency: 'ILS' },
        duration: { estimated: 240, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'], timeSlots: [{ start: '07:00', end: '20:00' }], flexible: true },
        location: { serviceArea: 'Ramallah', radius: 20, onSite: true, remote: false },
        rating: { average: 4.7, count: 38 },
        totalBookings: 52,
        isActive: true,
        featured: true
      },
      {
        title: 'Childcare & Babysitting',
        description: 'Reliable childcare services for children of all ages. Activities, meal preparation, and safe supervision in your home.',
        category: 'caregiving',
        subcategory: 'childcare',
        price: { amount: 90, type: 'hourly', currency: 'ILS' },
        duration: { estimated: 180, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday','saturday'], timeSlots: [{ start: '08:00', end: '22:00' }], flexible: true },
        location: { serviceArea: 'Ramallah', radius: 20, onSite: true, remote: false },
        rating: { average: 4.6, count: 29 },
        totalBookings: 41,
        isActive: true,
        featured: false
      }
    ],
    'aisha.maintenance@example.com': [
      {
        title: 'Home Maintenance & Repairs',
        description: 'Comprehensive home maintenance including plumbing, electrical, painting, and general repairs. Licensed and insured.',
        category: 'maintenance',
        subcategory: 'general_repairs',
        price: { amount: 200, type: 'fixed', currency: 'ILS' },
        duration: { estimated: 240, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday'], timeSlots: [{ start: '08:00', end: '18:00' }], flexible: true },
        location: { serviceArea: 'Bethlehem', radius: 25, onSite: true, remote: false },
        rating: { average: 4.5, count: 31 },
        totalBookings: 43,
        isActive: true,
        featured: true
      },
      {
        title: 'Plumbing Services',
        description: 'Professional plumbing services including repairs, installations, and emergency fixes. Available 24/7 for urgent issues.',
        category: 'maintenance',
        subcategory: 'plumbing',
        price: { amount: 150, type: 'fixed', currency: 'ILS' },
        duration: { estimated: 120, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday','saturday'], timeSlots: [{ start: '07:00', end: '20:00' }], flexible: true },
        location: { serviceArea: 'Bethlehem', radius: 25, onSite: true, remote: false },
        rating: { average: 4.4, count: 27 },
        totalBookings: 38,
        isActive: true,
        featured: false
      }
    ],
    'khalil.carpentry@example.com': [
      {
        title: 'Custom Furniture & Carpentry',
        description: 'Custom furniture making, repairs, and carpentry work. Quality craftsmanship with attention to detail.',
        category: 'carpentry',
        subcategory: 'furniture',
        price: { amount: 300, type: 'fixed', currency: 'ILS' },
        duration: { estimated: 480, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday'], timeSlots: [{ start: '08:00', end: '17:00' }], flexible: true },
        location: { serviceArea: 'Nablus', radius: 30, onSite: true, remote: false },
        rating: { average: 4.9, count: 19 },
        totalBookings: 25,
        isActive: true,
        featured: true
      },
      {
        title: 'Door & Window Installation',
        description: 'Professional installation and repair of doors, windows, and frames. Quality materials and expert installation.',
        category: 'carpentry',
        subcategory: 'installation',
        price: { amount: 250, type: 'fixed', currency: 'ILS' },
        duration: { estimated: 360, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday'], timeSlots: [{ start: '08:00', end: '17:00' }], flexible: true },
        location: { serviceArea: 'Nablus', radius: 30, onSite: true, remote: false },
        rating: { average: 4.7, count: 15 },
        totalBookings: 22,
        isActive: true,
        featured: false
      }
    ],
    'lina.provider@example.com': [
      {
        title: 'Laundry & Ironing Service',
        description: 'Professional laundry service including washing, drying, ironing, and folding. Pickup and delivery available.',
        category: 'laundry',
        subcategory: 'full_service',
        price: { amount: 60, type: 'fixed', currency: 'ILS' },
        duration: { estimated: 1440, flexible: true }, // 24 hours
        availability: { days: ['monday','tuesday','wednesday','thursday','friday','saturday'], timeSlots: [{ start: '08:00', end: '18:00' }], flexible: true },
        location: { serviceArea: 'Hebron', radius: 15, onSite: false, remote: true },
        rating: { average: 4.6, count: 42 },
        totalBookings: 58,
        isActive: true,
        featured: false
      }
    ],
    'omar.provider@example.com': [
      {
        title: 'Furniture Moving & Assembly',
        description: 'Professional furniture moving, disassembly, and assembly services. Careful handling and timely delivery.',
        category: 'furniture_moving',
        subcategory: 'moving',
        price: { amount: 180, type: 'fixed', currency: 'ILS' },
        duration: { estimated: 180, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday','saturday'], timeSlots: [{ start: '08:00', end: '18:00' }], flexible: true },
        location: { serviceArea: 'Gaza', radius: 20, onSite: true, remote: false },
        rating: { average: 4.5, count: 33 },
        totalBookings: 47,
        isActive: true,
        featured: false
      }
    ]
  };

  // Create services for each provider
  for (const [email, services] of Object.entries(providerServices)) {
    const provider = await User.findOne({ email });
    if (provider) {
      for (const serviceData of services) {
        const existingService = await Service.findOne({ 
          provider: provider._id, 
          title: serviceData.title 
        });
        
        if (!existingService) {
          await Service.create({
            ...serviceData,
            provider: provider._id,
            images: [],
            requirements: [],
            equipment: []
          });
          console.log(`Created service "${serviceData.title}" for ${provider.firstName}`);
        } else {
          console.log(`Service "${serviceData.title}" already exists for ${provider.firstName}`);
        }
      }
    }
  }

  console.log('\n📋 Default Provider Credentials:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🧹 Fatima Al-Zahra (Cleaning Services)');
  console.log('   Email: fatima.cleaning@example.com | Password: Passw0rd!');
  console.log('   Services: Professional Home Cleaning, Kitchen Deep Cleaning');
  console.log('   Location: Jerusalem');
  console.log('');
  console.log('👵 Mariam Hassan (Care Services)');
  console.log('   Email: mariam.care@example.com | Password: Passw0rd!');
  console.log('   Services: Elderly Care & Companionship, Childcare & Babysitting');
  console.log('   Location: Ramallah');
  console.log('');
  console.log('🔧 Aisha Mohammed (Maintenance Services)');
  console.log('   Email: aisha.maintenance@example.com | Password: Passw0rd!');
  console.log('   Services: Home Maintenance & Repairs, Plumbing Services');
  console.log('   Location: Bethlehem');
  console.log('');
  console.log('🪑 Khalil Abu-Rahma (Carpentry Services)');
  console.log('   Email: khalil.carpentry@example.com | Password: Passw0rd!');
  console.log('   Services: Custom Furniture & Carpentry, Door & Window Installation');
  console.log('   Location: Nablus');
  console.log('');
  console.log('👕 Lina Provider (Laundry Services)');
  console.log('   Email: lina.provider@example.com | Password: Passw0rd!');
  console.log('   Services: Laundry & Ironing Service');
  console.log('   Location: Hebron');
  console.log('');
  console.log('📦 Omar Provider (Moving Services)');
  console.log('   Email: omar.provider@example.com | Password: Passw0rd!');
  console.log('   Services: Furniture Moving & Assembly');
  console.log('   Location: Gaza');
  console.log('');
  console.log('👨‍💼 Admin credentials:');
  console.log('   Email: admin@example.com | Password: Admin123!');
  console.log('');
  console.log('🔍 Search Test Queries:');
  console.log('   - "cleaning" → Fatima\'s cleaning services');
  console.log('   - "care" → Mariam\'s care services');
  console.log('   - "maintenance" → Aisha\'s maintenance services');
  console.log('   - "carpentry" → Khalil\'s carpentry services');
  console.log('   - "laundry" → Lina\'s laundry service');
  console.log('   - "moving" → Omar\'s moving service');

  await mongoose.connection.close();
}

run().catch(err => { console.error(err); process.exit(1); });

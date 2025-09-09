const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

jest.setTimeout(60000);

// Models (loaded after connection)
let User, Service, ProviderService;

/*
This test simulates the "card" data the frontend expects for a provider when filtering
by a service (e.g., Special Errands). It constructs:
  - Two provider users
  - One Service document (subcategory slug: specialErrands)
  - Two ProviderService links (one publishable/active, one draft)
Then hits the public providers-by-services endpoint and asserts only the active+publishable
provider is returned with the service slug in its services array.
*/

describe('Provider card data via providers-by-services endpoint', () => {
  let app; let mongoServer; let serviceId; let activeProviderId; let draftProviderId;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    process.env.MONGODB_URI = mongoServer.getUri();
    process.env.JWT_SECRET = 'test-secret';
    process.env.NODE_ENV = 'test';
    process.env.RATE_LIMIT = 'false';

    app = require('../../src/app');
    const { connectDB } = require('../../src/config/database');
    await connectDB();

    User = require('../../src/models/User');
    Service = require('../../src/models/Service');
    ProviderService = require('../../src/models/ProviderService');

    // Create two provider users
    const [p1, p2] = await User.insertMany([
      { firstName: 'Active', lastName: 'Provider', email: 'active@example.com', phone: '0590000001', password: 'Pass1234', role: 'provider', services: [], hourlyRate: 0 },
      { firstName: 'Draft', lastName: 'Provider', email: 'draft@example.com', phone: '0590000002', password: 'Pass1234', role: 'provider', services: [], hourlyRate: 0 }
    ]);
    activeProviderId = p1._id; draftProviderId = p2._id;

    // Create service (Special Errands)
    const svc = await Service.create({
      title: 'Special Errands',
      description: 'Errand running help',
      category: 'miscellaneous',
      subcategory: 'specialErrands',
      provider: p1._id, // arbitrary association
      price: { amount: 50, type: 'hourly', currency: 'ILS' },
      availability: { days: ['monday'], timeSlots: [{ start: '09:00', end: '17:00' }] },
      location: { serviceArea: 'ramallah', radius: 10, onSite: true, remote: false },
      requirements: [], equipment: []
    });
    serviceId = svc._id.toString();

    // Create ProviderService docs
    await ProviderService.create({ provider: activeProviderId, service: serviceId, hourlyRate: 60, experienceYears: 2, status: 'active' });
    await ProviderService.create({ provider: draftProviderId, service: serviceId, hourlyRate: 55, experienceYears: 1, status: 'draft' });
  });

  afterAll(async () => {
    await mongoose.connection.dropDatabase().catch(() => {});
    await mongoose.connection.close().catch(() => {});
    if (mongoServer) await mongoServer.stop();
  });

  test('returns only active + publishable provider with service slug in services array', async () => {
    const res = await request(app)
      .get(`/api/provider-services/public/providers-by-services?serviceIds=${serviceId}`)
      .expect(200);

    expect(res.body.success).toBe(true);
    const outer = res.body.data || {}; // unified helper wraps { data: {...} }
    const list = outer.data || []; // our controller put providers in data.data
    // Only one provider (active) should appear
    expect(Array.isArray(list)).toBe(true);
    expect(list.length).toBe(1);
    const card = list[0];
    // Card essentials
    expect(card._id).toBe(activeProviderId.toString());
    expect(card.firstName).toBe('Active');
    expect(Array.isArray(card.services)).toBe(true);
    expect(card.services).toContain('specialErrands');
    // Log mapping for documentation of card -> source fields
    // (Would appear in test output for human verification)
    console.log('CARD_FIELD_SOURCES', {
      providerId: 'Provider (User collection _id)',
      firstName: 'Provider.firstName',
      lastName: 'Provider.lastName',
      city: 'Provider.city (if present)',
      services: 'Derived matched slugs from ProviderService.service.subcategory',
      hourlyRate: 'Provider.hourlyRate (legacy, may differ from ProviderService.hourlyRate)',
    });
  });

  test('filter by slug instead of ObjectId returns same result', async () => {
    const res = await request(app)
      .get('/api/provider-services/public/providers-by-services?serviceIds=specialErrands')
      .expect(200);
    expect(res.body.success).toBe(true);
    const outer = res.body.data || {};
    const list = outer.data || [];
    expect(list.length).toBe(1);
    expect(list[0].services).toContain('specialErrands');
  });
});

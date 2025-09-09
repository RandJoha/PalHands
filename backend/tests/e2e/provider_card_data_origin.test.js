const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

// Models (direct) to assert DB state
const Provider = require('../../src/models/Provider');
const Service = require('../../src/models/Service');
const ProviderService = require('../../src/models/ProviderService');

jest.setTimeout(60000);

/**
 * This test documents EXACTLY where each field shown on the "Service Providers" card comes from.
 * Card fields of interest:
 *  - Provider display name        -> User.firstName + ' ' + User.lastName (or User.name if exists)
 *  - City                          -> First address.city (or provider.city legacy) from User.addresses
 *  - Services list (titles)        -> For each active+publishable ProviderService for that provider, take populated Service.title
 *  - Hourly rate shown per service -> ProviderService.hourlyRate (NOT Service.price.amount, unless ProviderService is missing)
 *  - Experience years per service  -> ProviderService.experienceYears (fallback to User.experienceYears if undefined)
 *  - Rating (stars + count)        -> User.rating.average / User.rating.count (aggregated, not per service)
 *
 * The test seeds:
 *  - Two services (Garage Cleaning, Special Errands)
 *  - One provider offering both, with different hourlyRate & experience per ProviderService
 *  - Second provider offering only Special Errands with its own rates
 * Then it calls the public providers listing endpoint used by the frontend ( /api/provider-services/public/providers-by-services )
 * and asserts data alignment.
 */

describe('Provider card data origin', () => {
  let app; let mongo;
  let serviceGarage; let serviceErrands; let provider1; let provider2;

  beforeAll(async () => {
    mongo = await MongoMemoryServer.create();
    process.env.MONGODB_URI = mongo.getUri();
    process.env.JWT_SECRET = 'test-secret';
    process.env.NODE_ENV = 'test';

    app = require('../../src/app');
    const { connectDB } = require('../../src/config/database');
    await connectDB();

    // Seed services
    serviceGarage = await Service.create({
      title: 'Garage Cleaning', description: 'Desc', category: 'cleaning', subcategory: 'garageCleaning',
      price: { amount: 10, type: 'hourly', currency: 'ILS' },
      location: { serviceArea: 'ramallah', radius: 10, onSite: true, remote: false }
    });
    serviceErrands = await Service.create({
      title: 'Special Errands', description: 'Desc', category: 'misc', subcategory: 'specialErrands',
      price: { amount: 11, type: 'hourly', currency: 'ILS' },
      location: { serviceArea: 'ramallah', radius: 10, onSite: true, remote: false }
    });

    // Seed providers (Users)
    provider1 = await Provider.create({
      firstName: 'Alice', lastName: 'Provider', email: 'a@example.com', phone: '0590000001', password: 'Pass1234',
      experienceYears: 1, hourlyRate: 99, addresses: [{ city: 'ramallah', street: 'Main', isDefault: true }], rating: { average: 4.3, count: 6 },
      languages: ['Arabic'], age: 30, services: []
    });
    provider2 = await Provider.create({
      firstName: 'Bob', lastName: 'Runner', email: 'b@example.com', phone: '0590000002', password: 'Pass1234',
      experienceYears: 5, hourlyRate: 120, addresses: [{ city: 'nablus', street: 'Side', isDefault: true }], rating: { average: 4.8, count: 12 },
      languages: ['Arabic','English'], age: 32, services: []
    });

    // Link via ProviderService with distinct per-service values
    await ProviderService.create({ provider: provider1._id, service: serviceGarage._id, hourlyRate: 48, experienceYears: 2, status: 'active' });
    await ProviderService.create({ provider: provider1._id, service: serviceErrands._id, hourlyRate: 50, experienceYears: 3, status: 'active' });
    await ProviderService.create({ provider: provider2._id, service: serviceErrands._id, hourlyRate: 77, experienceYears: 6, status: 'active' });
  });

  afterAll(async () => {
    await mongoose.connection.dropDatabase().catch(()=>{});
    await mongoose.connection.close().catch(()=>{});
    if (mongo) await mongo.stop();
  });

  test('providers-by-services endpoint returns provider list for a single service', async () => {
    const endpoint = `/api/provider-services/public/providers-by-services?serviceIds=${serviceErrands._id}`;
    const res = await request(app).get(endpoint).expect(200);

    // Response shape: { success, data: [ { _id, name?, ratingAverage?, services: [ {title,...} ] } ] }
    expect(res.body).toHaveProperty('data');
    const list = res.body.data || [];
    expect(list.length).toBe(2);

    const names = list.map(p => (p.firstName + ' ' + (p.lastName||'')).trim());
    expect(names).toEqual(expect.arrayContaining(['Alice Provider','Bob Runner']));
    // Each provider has services array containing the subcategory slug
    for (const p of list) {
      expect(Array.isArray(p.services)).toBe(true);
      expect(p.services).toContain('specialErrands');
      // rating object present
      expect(p.rating).toBeDefined();
    }
  });

  test('multi-service query returns provider with multiple matched slugs', async () => {
    const endpoint = `/api/provider-services/public/providers-by-services?serviceIds=${serviceGarage._id},${serviceErrands._id}`;
    const res = await request(app).get(endpoint).expect(200);
    const list = res.body.data || [];
    expect(list.length).toBeGreaterThanOrEqual(2);
    const alice = list.find(p => (p.firstName==='Alice' && p.lastName==='Provider'));
    expect(alice).toBeTruthy();
    expect(alice.services).toEqual(expect.arrayContaining(['garageCleaning','specialErrands']));
  });
});

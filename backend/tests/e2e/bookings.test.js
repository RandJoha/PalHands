const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../../src/app');
const User = require('../../src/models/User');
const Service = require('../../src/models/Service');
const Booking = require('../../src/models/Booking');
const Availability = require('../../src/models/Availability');

describe('Bookings E2E Tests', () => {
  let clientToken, providerToken, adminToken;
  let clientUser, providerUser, adminUser;
  let testService, testProvider;
  let mongoServer;

  beforeAll(async () => {
    // Use in-memory MongoDB for tests
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  }, 30000);

  beforeEach(async () => {
    // Clean up database
    await User.deleteMany({});
    await Service.deleteMany({});
    await Booking.deleteMany({});
    await Availability.deleteMany({});
    await require('../../src/models/Provider').deleteMany({});

    // Create test users directly in database
    clientUser = await User.create({
      firstName: 'Test',
      lastName: 'Client',
      email: 'client@test.com',
      phone: '+1234567890',
      password: 'password123',
      role: 'client'
    });

    providerUser = await User.create({
      firstName: 'Test',
      lastName: 'Provider',
      email: 'provider@test.com',
      phone: '+1234567891',
      password: 'password123',
      role: 'provider'
    });

    adminUser = await User.create({
      firstName: 'Test',
      lastName: 'Admin',
      email: 'admin@test.com',
      phone: '+1234567892',
      password: 'password123',
      role: 'admin'
    });

    // Generate tokens manually
    const jwt = require('jsonwebtoken');
    const generateToken = (userId) => {
      return jwt.sign(
        { userId },
        process.env.JWT_SECRET || 'fallback-secret',
        { expiresIn: '7d' }
      );
    };

    clientToken = generateToken(clientUser._id);
    providerToken = generateToken(providerUser._id);
    adminToken = generateToken(adminUser._id);

    // Create a test provider first
    const Provider = require('../../src/models/Provider');
    testProvider = await Provider.create({
      firstName: 'Test',
      lastName: 'Provider',
      email: 'testprovider@palhands.com',
      password: 'password123',
      role: 'provider',
      phone: '+1234567890',
      profileImage: null,
      age: 30,
      addresses: [{
        type: 'home',
        street: '123 Test Street',
        city: 'Test City',
        area: 'Test Area',
        coordinates: { latitude: 31.5, longitude: 35.0 },
        isDefault: true
      }],
      experienceYears: 5,
      languages: ['English'],
      hourlyRate: 100,
      services: ['cleaning'],
      rating: { average: 4.5, count: 10 },
      location: {
        address: '123 Test Street, Test City',
        coordinates: { latitude: 31.5, longitude: 35.0 }
      },
      isActive: true,
      isVerified: true,
      totalBookings: 0,
      completedBookings: 0,
      // Email verification fields
      emailVerificationToken: null,
      emailVerificationExpires: null,
      pendingEmail: null,
      emailChangeToken: null,
      emailChangeExpires: null,
      passwordResetToken: null,
      passwordResetTokenHash: null,
      passwordResetExpires: null
    });

    // Create a test service
    const serviceData = {
      title: 'Test Cleaning Service',
      description: 'A test cleaning service',
      category: 'cleaning',
      provider: testProvider._id,
      price: {
        amount: 100,
        type: 'hourly',
        currency: 'ILS'
      },
      location: {
        serviceArea: 'Test City',
        radius: 10,
        onSite: true
      }
    };

    testService = await Service.create(serviceData);

    // Create provider availability
    await Availability.create({
      provider: testProvider._id,
      timezone: 'Asia/Jerusalem',
      weekly: {
        monday: [{ start: '09:00', end: '17:00' }],
        tuesday: [{ start: '09:00', end: '17:00' }],
        wednesday: [{ start: '09:00', end: '17:00' }],
        thursday: [{ start: '09:00', end: '17:00' }],
        friday: [{ start: '09:00', end: '17:00' }]
      }
    });
  });

  afterAll(async () => {
    await mongoose.connection.close();
    if (mongoServer) {
      await mongoServer.stop();
    }
  });

  describe('POST /api/bookings', () => {
    it('should create a booking successfully', async () => {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const dateStr = tomorrow.toISOString().split('T')[0];

      const bookingData = {
        serviceId: testService._id.toString(),
        schedule: {
          date: dateStr,
          startTime: '10:00',
          endTime: '12:00',
          timezone: 'Asia/Jerusalem'
        },
        location: {
          address: '123 Test Street, Test City',
          instructions: 'Ring the doorbell twice'
        },
        notes: 'Please be careful with the fragile items'
      };

      const response = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${clientToken}`)
        .send(bookingData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Booking created');
      expect(response.body.data).toHaveProperty('bookingId');
      expect(response.body.data.client).toBe(clientUser._id.toString());
      expect(response.body.data.provider).toBe(testProvider._id.toString());
      expect(response.body.data.service).toBe(testService._id.toString());
      expect(response.body.data.status).toBe('pending');
      expect(response.body.data.pricing.totalAmount).toBe(100);
    });

    it('should prevent double booking', async () => {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const dateStr = tomorrow.toISOString().split('T')[0];

      const bookingData = {
        serviceId: testService._id.toString(),
        schedule: {
          date: dateStr,
          startTime: '10:00',
          endTime: '12:00',
          timezone: 'Asia/Jerusalem'
        },
        location: {
          address: '123 Test Street, Test City'
        }
      };

      // Create first booking
      await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${clientToken}`)
        .send(bookingData)
        .expect(201);

      // Try to create overlapping booking
      const overlappingData = {
        ...bookingData,
        schedule: {
          ...bookingData.schedule,
          startTime: '11:00',
          endTime: '13:00'
        }
      };

      const response = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${clientToken}`)
        .send(overlappingData)
        .expect(409);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Time slot already booked');
    });

    it('should handle idempotency correctly', async () => {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const dateStr = tomorrow.toISOString().split('T')[0];

      const bookingData = {
        serviceId: testService._id.toString(),
        schedule: {
          date: dateStr,
          startTime: '10:00',
          endTime: '12:00',
          timezone: 'Asia/Jerusalem'
        },
        location: {
          address: '123 Test Street, Test City'
        },
        idempotencyKey: 'test-key-123'
      };

      // First request
      const response1 = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${clientToken}`)
        .send(bookingData)
        .expect(201);

      // Second request with same idempotency key
      const response2 = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${clientToken}`)
        .send(bookingData)
        .expect(200);

      expect(response2.body.message).toBe('Booking already exists (idempotent request)');
      expect(response2.body.data._id).toBe(response1.body.data._id);

      // Verify only one booking was created
      const bookings = await Booking.find({ client: clientUser._id });
      expect(bookings.length).toBe(1);
    });

    it('should validate required fields', async () => {
      const invalidData = {
        serviceId: testService._id.toString(),
        // Missing required schedule and location
      };

      const response = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${clientToken}`)
        .send(invalidData)
        .expect(400);

      expect(response.body.message).toContain('Validation');
    });

    it('should reject booking for inactive service', async () => {
      // Deactivate service
      testService.isActive = false;
      await testService.save();

      const bookingData = {
        serviceId: testService._id.toString(),
        schedule: {
          date: '2024-12-25',
          startTime: '10:00',
          endTime: '12:00',
          timezone: 'Asia/Jerusalem'
        },
        location: {
          address: '123 Test Street'
        }
      };

      const response = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${clientToken}`)
        .send(bookingData)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Service not available');
    });
  });

  describe('GET /api/bookings', () => {
    let testBooking;

    beforeEach(async () => {
      // Create a test booking
      testBooking = await Booking.create({
        client: clientUser._id,
        provider: providerUser._id,
        service: testService._id,
        serviceDetails: {
          title: testService.title,
          description: testService.description,
          category: testService.category
        },
        schedule: {
          date: new Date('2024-12-25'),
          startTime: '10:00',
          endTime: '12:00',
          startUtc: new Date('2024-12-25T08:00:00Z'),
          endUtc: new Date('2024-12-25T10:00:00Z'),
          timezone: 'Asia/Jerusalem'
        },
        location: {
          address: '123 Test Street'
        },
        pricing: {
          baseAmount: 100,
          totalAmount: 100,
          currency: 'ILS'
        }
      });
    });

    it('should return client bookings for client', async () => {
      const response = await request(app)
        .get('/api/bookings')
        .set('Authorization', `Bearer ${clientToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].client._id).toBe(clientUser._id.toString());
    });

    it('should return provider bookings for provider', async () => {
      const response = await request(app)
        .get('/api/bookings')
        .set('Authorization', `Bearer ${providerToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].provider._id).toBe(providerUser._id.toString());
    });

    it('should require authentication', async () => {
      await request(app)
        .get('/api/bookings')
        .expect(401);
    });
  });

  describe('GET /api/bookings/:id', () => {
    let testBooking;

    beforeEach(async () => {
      testBooking = await Booking.create({
        client: clientUser._id,
        provider: providerUser._id,
        service: testService._id,
        serviceDetails: {
          title: testService.title,
          description: testService.description,
          category: testService.category
        },
        schedule: {
          date: new Date('2024-12-25'),
          startTime: '10:00',
          endTime: '12:00',
          startUtc: new Date('2024-12-25T08:00:00Z'),
          endUtc: new Date('2024-12-25T10:00:00Z'),
          timezone: 'Asia/Jerusalem'
        },
        location: {
          address: '123 Test Street'
        },
        pricing: {
          baseAmount: 100,
          totalAmount: 100,
          currency: 'ILS'
        }
      });
    });

    it('should return booking details for client', async () => {
      const response = await request(app)
        .get(`/api/bookings/${testBooking._id}`)
        .set('Authorization', `Bearer ${clientToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data._id).toBe(testBooking._id.toString());
    });

    it('should return booking details for provider', async () => {
      const response = await request(app)
        .get(`/api/bookings/${testBooking._id}`)
        .set('Authorization', `Bearer ${providerToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data._id).toBe(testBooking._id.toString());
    });

    it('should deny access to unrelated users', async () => {
      // Create another user to test access denial
      const otherUser = await User.create({
        firstName: 'Other',
        lastName: 'Client',
        email: 'other@test.com',
        phone: '+1234567893',
        password: 'password123',
        role: 'client'
      });

      const jwt = require('jsonwebtoken');
      const generateToken = (userId) => {
        return jwt.sign(
          { userId },
          process.env.JWT_SECRET || 'fallback-secret',
          { expiresIn: '7d' }
        );
      };

      const otherToken = generateToken(otherUser._id);

      const response = await request(app)
        .get(`/api/bookings/${testBooking._id}`)
        .set('Authorization', `Bearer ${otherToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Access denied');
    });
  });

  describe('PUT /api/bookings/:id/status', () => {
    let testBooking;

    beforeEach(async () => {
      testBooking = await Booking.create({
        client: clientUser._id,
        provider: providerUser._id,
        service: testService._id,
        serviceDetails: {
          title: testService.title,
          description: testService.description,
          category: testService.category
        },
        schedule: {
          date: new Date('2024-12-25'),
          startTime: '10:00',
          endTime: '12:00',
          startUtc: new Date('2024-12-25T08:00:00Z'),
          endUtc: new Date('2024-12-25T10:00:00Z'),
          timezone: 'Asia/Jerusalem'
        },
        location: {
          address: '123 Test Street'
        },
        pricing: {
          baseAmount: 100,
          totalAmount: 100,
          currency: 'ILS'
        },
        status: 'pending'
      });
    });

    it('should allow provider to confirm booking', async () => {
      const response = await request(app)
        .put(`/api/bookings/${testBooking._id}/status`)
        .set('Authorization', `Bearer ${providerToken}`)
        .send({ status: 'confirmed' })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('confirmed');
    });

    it('should allow client to cancel booking', async () => {
      // Create a fresh booking for this test
      const cancelBooking = await Booking.create({
        bookingId: `TEST-CANCEL-${Date.now()}`,
        client: clientUser._id,
        provider: providerUser._id,
        service: testService._id,
        schedule: {
          date: new Date('2024-12-31'),
          startTime: '10:00',
          endTime: '12:00',
          timezone: 'Asia/Jerusalem'
        },
        location: {
          type: 'on_site',
          address: 'Test Address'
        },
        pricing: {
          baseAmount: 100,
          totalAmount: 100,
          currency: 'ILS'
        },
        status: 'pending',
        idempotencyKey: `cancel-test-${Date.now()}-${Math.random()}`
      });

      const response = await request(app)
        .put(`/api/bookings/${cancelBooking._id}/status`)
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ status: 'cancelled', reason: 'Change of plans' });

      if (response.status !== 200) {
        console.log('Error response:', response.body);
        console.log('Status code:', response.status);
      }
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('cancelled');
      expect(response.body.data.cancellation.reason).toBe('Change of plans');
    });

    it('should reject invalid status transitions', async () => {
      const response = await request(app)
        .put(`/api/bookings/${testBooking._id}/status`)
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ status: 'completed' })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid transition');
    });

    it('should reject unauthorized status changes', async () => {
      const response = await request(app)
        .put(`/api/bookings/${testBooking._id}/status`)
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ status: 'confirmed' })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('not allowed');
    });
  });

  describe('Status Transition Flow', () => {
    let testBooking;

    beforeEach(async () => {
      testBooking = await Booking.create({
        client: clientUser._id,
        provider: providerUser._id,
        service: testService._id,
        serviceDetails: {
          title: testService.title,
          description: testService.description,
          category: testService.category
        },
        schedule: {
          date: new Date('2024-12-25'),
          startTime: '10:00',
          endTime: '12:00',
          startUtc: new Date('2024-12-25T08:00:00Z'),
          endUtc: new Date('2024-12-25T10:00:00Z'),
          timezone: 'Asia/Jerusalem'
        },
        location: {
          address: '123 Test Street'
        },
        pricing: {
          baseAmount: 100,
          totalAmount: 100,
          currency: 'ILS'
        },
        status: 'pending'
      });
    });

    it('should follow complete booking lifecycle', async () => {
      // Create a fresh booking for this test
      const lifecycleBooking = await Booking.create({
        bookingId: `TEST-LIFECYCLE-${Date.now()}`,
        client: clientUser._id,
        provider: providerUser._id,
        service: testService._id,
        schedule: {
          date: new Date('2024-12-31'),
          startTime: '14:00',
          endTime: '16:00',
          timezone: 'Asia/Jerusalem'
        },
        location: {
          type: 'on_site',
          address: 'Test Address'
        },
        pricing: {
          baseAmount: 100,
          totalAmount: 100,
          currency: 'ILS'
        },
        status: 'pending',
        idempotencyKey: `lifecycle-test-${Date.now()}-${Math.random()}`
      });

      // 1. Provider confirms booking
      let response = await request(app)
        .put(`/api/bookings/${lifecycleBooking._id}/status`)
        .set('Authorization', `Bearer ${providerToken}`)
        .send({ status: 'confirmed' })
        .expect(200);

      expect(response.body.data.status).toBe('confirmed');

      // 2. Provider starts service
      response = await request(app)
        .put(`/api/bookings/${lifecycleBooking._id}/status`)
        .set('Authorization', `Bearer ${providerToken}`)
        .send({ status: 'in_progress' })
        .expect(200);

      expect(response.body.data.status).toBe('in_progress');

      // 3. Provider completes service
      response = await request(app)
        .put(`/api/bookings/${lifecycleBooking._id}/status`)
        .set('Authorization', `Bearer ${providerToken}`)
        .send({ status: 'completed' })
        .expect(200);

      expect(response.body.data.status).toBe('completed');
      expect(response.body.data.completion.completedAt).toBeDefined();
      expect(response.body.data.completion.providerConfirmation).toBe(true);
    });
  });
});

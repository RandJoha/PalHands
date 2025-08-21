const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

jest.setTimeout(60000);

// Mock the mailer to capture the last reset token sent
let lastEmailPayload = null;
jest.mock('../../src/services/mailer', () => ({
  sendEmail: async (payload) => {
    lastEmailPayload = payload;
    return { messageId: 'mock-' + Date.now() };
  }
}));

describe('Auth E2E happy paths', () => {
  let app;
  let mongoServer;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    const uri = mongoServer.getUri();
    process.env.MONGODB_URI = uri;
    process.env.JWT_SECRET = 'test-secret';
    process.env.NODE_ENV = 'test';
    // Relax rate limiters in tests
    process.env.RATE_LIMIT = 'false';
    // Ensure email verification flows are disabled for simplicity unless needed
    process.env.ENABLE_EMAIL_VERIFICATION = 'false';

    // Load app after env is prepared
    app = require('../../src/app');

    // Connect mongoose used by the app
    const { connectDB } = require('../../src/config/database');
    await connectDB();
  });

  afterAll(async () => {
    await mongoose.connection.dropDatabase().catch(() => {});
    await mongoose.connection.close().catch(() => {});
    if (mongoServer) await mongoServer.stop();
  });

  test('client: register → login → get profile → update profile → change password → forgot → reset', async () => {
    const unique = Date.now();
    const email = `test${unique}@example.com`;
    const phone = `059${Math.floor(Math.random() * 10000000)}`;

    // Register
    const registerRes = await request(app)
      .post('/api/auth/register')
      .send({
        firstName: 'Test',
        lastName: 'User',
        email,
        phone,
        password: 'Password1',
        role: 'client',
        age: 25,
        address: { city: 'hebron', street: 'Main' }
      })
      .expect(201);

    expect(registerRes.body.success).toBe(true);
    expect(registerRes.body.data && registerRes.body.data.token).toBeTruthy();
    const token = registerRes.body.data.token;

    // Login
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({ email, password: 'Password1' })
      .expect(200);
    expect(loginRes.body.success).toBe(true);
    expect(loginRes.body.data && loginRes.body.data.token).toBeTruthy();

    const authHeader = { Authorization: `Bearer ${loginRes.body.data.token}` };

    // Get profile
    const profileRes = await request(app)
      .get('/api/auth/profile')
      .set(authHeader)
      .expect(200);
    expect(profileRes.body.success).toBe(true);
    expect(profileRes.body.data && profileRes.body.data._id).toBeTruthy();

    // Update profile
    const updateRes = await request(app)
      .put('/api/users/profile')
      .set(authHeader)
      .send({ firstName: 'Updated', age: 26 })
      .expect(200);
    expect(updateRes.body.success).toBe(true);
    const updated = (updateRes.body && updateRes.body.data && updateRes.body.data.user) || null;
    expect((updated && updated.firstName) || updateRes.body.message).toBeTruthy();

    // Change password (authed)
    await request(app)
      .put('/api/users/change-password')
      .set(authHeader)
      .send({ currentPassword: 'Password1', newPassword: 'Password2' })
      .expect(200);

    // Login with new password
    await request(app)
      .post('/api/auth/login')
      .send({ email, password: 'Password2' })
      .expect(200);

    // Forgot password (triggers email with token)
    await request(app)
      .post('/api/auth/forgot-password')
      .send({ email })
      .expect(200);

    // Extract raw token from mocked email
    expect(lastEmailPayload).toBeTruthy();
    const text = lastEmailPayload.text || '';
    const html = lastEmailPayload.html || '';
    // Try to extract token from text part first; fallback to URL query or any long hex
    const tokenFromText = /token[^\w]*:?\s*([a-f0-9]{32,})/i.exec(text);
    const tokenFromUrl = /[?&]token=([a-f0-9]{32,})/i.exec(text) || /[?&]token=([a-f0-9]{32,})/i.exec(html);
    const anyHex = /\b([a-f0-9]{32,})\b/i.exec(text) || /\b([a-f0-9]{32,})\b/i.exec(html);
    const tokenMatch = tokenFromText || tokenFromUrl || anyHex;
    expect(tokenMatch).toBeTruthy();
    const rawToken = tokenMatch[1];

    // Reset password with token
    await request(app)
      .post('/api/auth/reset-password')
      .send({ token: rawToken, newPassword: 'Password3' })
      .expect(200);

    // Login with reset password
    await request(app)
      .post('/api/auth/login')
      .send({ email, password: 'Password3' })
      .expect(200);
  });

  test('admin: register → login → get profile', async () => {
    const unique = Date.now() + 1;
    const email = `admin${unique}@example.com`;
    const phone = `058${Math.floor(Math.random() * 10000000)}`;

    // Register as admin
    await request(app)
      .post('/api/auth/register')
      .send({
        firstName: 'Admin',
        lastName: 'User',
        email,
        phone,
        password: 'StrongPass1',
        role: 'admin',
        age: 30,
        address: { city: 'hebron', street: 'HQ' }
      })
      .expect(201);

    // Login
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({ email, password: 'StrongPass1' })
      .expect(200);
    expect(loginRes.body.success).toBe(true);
    const token = loginRes.body.data && loginRes.body.data.token;
    expect(token).toBeTruthy();

    // Get profile
    const profileRes = await request(app)
      .get('/api/auth/profile')
      .set({ Authorization: `Bearer ${token}` })
      .expect(200);
    expect(profileRes.body.success).toBe(true);
    expect(profileRes.body.data && profileRes.body.data._id).toBeTruthy();
  });
});



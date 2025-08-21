const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

jest.setTimeout(60000);

let lastEmailPayload = null;
jest.mock('../../src/services/mailer', () => ({
  sendEmail: async (payload) => {
    lastEmailPayload = payload;
    return { messageId: 'mock-' + Date.now() };
  }
}));

describe('Auth E2E negative cases', () => {
  let app;
  let mongoServer;
  let User;

  beforeAll(async () => {
    // For rate limit test, enforce production limits
    process.env.NODE_ENV = 'production';
    process.env.TRUST_PROXY = 'true';
    mongoServer = await MongoMemoryServer.create();
    process.env.MONGODB_URI = mongoServer.getUri();
    process.env.JWT_SECRET = 'test-secret';
    process.env.ENABLE_EMAIL_VERIFICATION = 'false';

    // Load app and DB
    app = require('../../src/app');
    const { connectDB } = require('../../src/config/database');
    await connectDB();
    User = require('../../src/models/User');
  });

  afterAll(async () => {
    await mongoose.connection.dropDatabase().catch(() => {});
    await mongoose.connection.close().catch(() => {});
    if (mongoServer) await mongoServer.stop();
  });

  test('login wrong email/password → 401', async () => {
    const email = `neg${Date.now()}@example.com`;
    const phone = `056${Math.floor(Math.random() * 10000000)}`;
    const ip = '203.0.113.10';
    // Register a valid user
    await request(app)
      .post('/api/auth/register')
      .send({ firstName: 'A', lastName: 'B', email, phone, password: 'GoodPass1', role: 'client', age: 20, address: { city: 'hebron', street: 'x' } })
      .expect(201);

    // Wrong password
    await request(app)
      .post('/api/auth/login')
      .set('X-Forwarded-For', ip)
      .send({ email, password: 'WrongPass1' })
      .expect(401);

    // Unknown email
    await request(app)
      .post('/api/auth/login')
      .set('X-Forwarded-For', ip)
      .send({ email: 'nope@example.com', password: 'GoodPass1' })
      .expect(401);
  });

  test('register duplicate email/phone → 400; weak password → 400', async () => {
    const unique = Date.now();
    const email = `dup${unique}@example.com`;
    const phone = `057${Math.floor(Math.random() * 10000000)}`;

    await request(app)
      .post('/api/auth/register')
      .send({ firstName: 'X', lastName: 'Z', email, phone, password: 'Strong11', role: 'client', age: 22, address: { city: 'hebron', street: 'y' } })
      .expect(201);

    // Duplicate email
    await request(app)
      .post('/api/auth/register')
      .send({ firstName: 'Y', lastName: 'Q', email, phone: `059${Math.floor(Math.random() * 10000000)}`, password: 'Strong11', role: 'client', age: 22, address: { city: 'hebron', street: 'y' } })
      .expect(400);

    // Duplicate phone
    await request(app)
      .post('/api/auth/register')
      .send({ firstName: 'Z', lastName: 'Q', email: `other${unique}@example.com`, phone, password: 'Strong11', role: 'client', age: 22, address: { city: 'hebron', street: 'y' } })
      .expect(400);

    // Weak password (min 6)
    await request(app)
      .post('/api/auth/register')
      .send({ firstName: 'W', lastName: '', email: `weak${unique}@example.com`, phone: `058${Math.floor(Math.random() * 10000000)}`, password: '123', role: 'client', age: 22, address: { city: 'hebron', street: 'y' } })
      .expect(400);
  });

  test('change password wrong current → 400', async () => {
    const email = `chg${Date.now()}@example.com`;
    const phone = `059${Math.floor(Math.random() * 10000000)}`;
    await request(app)
      .post('/api/auth/register')
      .send({ firstName: 'C', lastName: 'D', email, phone, password: 'Start11', role: 'client', age: 21, address: { city: 'hebron', street: 'z' } })
      .expect(201);
    const login = await request(app).post('/api/auth/login').send({ email, password: 'Start11' }).expect(200);
    const token = login.body.data && login.body.data.token;
    await request(app)
      .put('/api/users/change-password')
      .set({ Authorization: `Bearer ${token}` })
      .send({ currentPassword: 'Wrong', newPassword: 'Next11' })
      .expect(400);
  });

  test('forgot password unknown email → 200 neutral', async () => {
    await request(app)
      .post('/api/auth/forgot-password')
      .send({ email: `unknown${Date.now()}@example.com` })
      .expect(200);
  });

  test('reset password expired/tampered token → 400', async () => {
    const email = `rst${Date.now()}@example.com`;
    const phone = `055${Math.floor(Math.random() * 10000000)}`;
    await request(app)
      .post('/api/auth/register')
      .send({ firstName: 'R', lastName: 'S', email, phone, password: 'Abcdef1', role: 'client', age: 23, address: { city: 'hebron', street: 'a' } })
      .expect(201);

    // Trigger forgot to set token fields
    await request(app).post('/api/auth/forgot-password').send({ email }).expect(200);
    expect(lastEmailPayload).toBeTruthy();
    const text = lastEmailPayload.text || '';
    const html = lastEmailPayload.html || '';
    const tokenFromUrl = /[?&]token=([a-f0-9]{32,})/i.exec(text) || /[?&]token=([a-f0-9]{32,})/i.exec(html);
    const anyHex = /\b([a-f0-9]{32,})\b/i.exec(text) || /\b([a-f0-9]{32,})\b/i.exec(html);
    const token = (tokenFromUrl && tokenFromUrl[1]) || (anyHex && anyHex[1]);
    expect(token).toBeTruthy();

    // Expire it
    const user = await User.findOne({ email: email.toLowerCase() });
    user.passwordResetExpires = new Date(Date.now() - 60 * 1000);
    await user.save();
    await request(app).post('/api/auth/reset-password').send({ token, newPassword: 'Zyxwv11' }).expect(400);

    // Tampered token
    await request(app).post('/api/auth/reset-password').send({ token: 'deadbeefdeadbeefdeadbeefdeadbeef', newPassword: 'Qwerty11' }).expect(400);
  });

  test('rate limit: too many login attempts → 429', async () => {
    const email = `rl${Date.now()}@example.com`;
    const phone = `054${Math.floor(Math.random() * 10000000)}`;
    const ip = '198.51.100.77';
    await request(app)
      .post('/api/auth/register')
      .send({ firstName: 'L', lastName: 'R', email, phone, password: 'GoodPass1', role: 'client', age: 24, address: { city: 'hebron', street: 'b' } })
      .expect(201);
    // Make 11 failed logins (prod limiter max=10)
    for (let i = 0; i < 10; i++) {
      await request(app)
        .post('/api/auth/login')
        .set('X-Forwarded-For', ip)
        .send({ email, password: 'WrongPass1' })
        .expect(401);
    }
    await request(app)
      .post('/api/auth/login')
      .set('X-Forwarded-For', ip)
      .send({ email, password: 'WrongPass1' })
      .expect(429);
  });
});



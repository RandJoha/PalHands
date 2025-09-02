require('dotenv').config();
const request = require('supertest');
const { connectDB, mongoose } = require('../config/database');
const app = require('../app-minimal');

async function main() {
  const providerId = process.argv[2];
  const from = process.argv[3] || '2025-09-01';
  const to = process.argv[4] || '2025-09-30';
  const step = process.argv[5] || '30';
  if (!providerId) {
    console.log('Usage: node src/utils/probeAvailabilityHttp.js <providerId> [from] [to] [step]');
    process.exit(1);
  }
  await connectDB();
  const url = `/api/availability/${providerId}/resolve?from=${from}&to=${to}&step=${step}`;
  const res = await request(app).get(url).expect(200);
  const body = res.body?.data || res.body;
  console.log(JSON.stringify({
    status: res.status,
    timezone: body.timezone,
    step: body.step,
    daysWithSlots: (body.days || []).filter(d => (d.slots||[]).length > 0).length,
    sampleDay: (body.days || []).find(d => (d.slots||[]).length > 0) || null
  }, null, 2));
  await mongoose.connection.close();
}

main().catch(async (e) => { console.error(e); try { await mongoose.connection.close(); } catch(_){} process.exit(1); });

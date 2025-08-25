require('dotenv').config();
const { connectDB, mongoose } = require('../src/config/database');
const User = require('../src/models/User');

const ALLOWED = new Set([
  'jerusalem','ramallah','nablus','hebron','bethlehem','jericho','tulkarm','qalqilya','jenin','salfit','tubas',
  'gaza','rafah','khan yunis','deir al-balah','north gaza'
]);

async function run(){
  await connectDB();
  const cursor = User.find({ 'addresses.0': { $exists: true } }).cursor();
  let scanned = 0, updated = 0;
  for await (const u of cursor) {
    scanned++;
    let changed = false;
    const next = (u.addresses || []).map(a => {
      if (!a) return a;
      const city = (a.city || '').toString();
      const lc = city.toLowerCase().trim();
      if (city !== lc && (lc.length === 0 || ALLOWED.has(lc))) {
        changed = true;
        return { ...a.toObject?.() || a, city: lc };
      }
      return a;
    });
    if (changed) {
      u.addresses = next;
      try { await u.save(); updated++; } catch (_) {}
    }
  }
  console.log(`Normalized cities for ${updated}/${scanned} user(s)`);
  await mongoose.connection.close();
}

run().catch(e => { console.error(e); process.exit(1); });

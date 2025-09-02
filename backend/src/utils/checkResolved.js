require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Availability = require('../models/Availability');
const Booking = require('../models/Booking');
const { DateTime, Interval } = require('luxon');

function usage() {
  console.log('Usage: node src/utils/checkResolved.js <providerId> <from YYYY-MM-DD> <to YYYY-MM-DD> [stepMinutes]');
}

function getMinutes(name, fallback) {
  const raw = process.env[name];
  if (raw && !Number.isNaN(parseInt(raw))) return parseInt(raw);
  return fallback;
}

async function resolve(providerId, fromStr, toStr, step) {
  const MIN_LEAD = getMinutes('BOOKING_MIN_LEAD_MINUTES', 2880);
  const nowUtc = DateTime.utc();
  let from = DateTime.fromISO(fromStr, { zone: 'utc' });
  let to = DateTime.fromISO(toStr, { zone: 'utc' });
  if (!from.isValid || !to.isValid) throw new Error('Invalid date range');
  const a = await Availability.findOne({ provider: providerId });
  if (!a) return { timezone: 'Asia/Jerusalem', step, days: [] };
  const tz = a.timezone || 'Asia/Jerusalem';
  const weekly = a.weekly || {};
  const exceptions = a.exceptions || [];

  const bookings = await Booking.find({
    provider: providerId,
    status: { $in: ['pending', 'confirmed'] },
    $or: [
      { 'schedule.startUtc': { $lte: to.toJSDate() }, 'schedule.endUtc': { $gte: from.toJSDate() } }
    ]
  }).select('schedule.startUtc schedule.endUtc');

  const leadThresholdLocal = nowUtc.plus({ minutes: MIN_LEAD }).setZone(tz);
  const days = [];
  for (let cursor = from.setZone(tz).startOf('day'); cursor <= to.setZone(tz).endOf('day'); cursor = cursor.plus({ days: 1 })) {
    const dateKey = cursor.toFormat('yyyy-MM-dd');
    const ex = exceptions.find(e => e.date === dateKey);
    let windows = [];
    if (ex) windows = (ex.windows || []).map(w => ({ start: w.start, end: w.end }));
    else {
      const dayName = cursor.toFormat('cccc').toLowerCase();
      windows = (weekly[dayName] || []).map(w => ({ start: w.start, end: w.end }));
    }
    if (!windows.length) { days.push({ date: dateKey, slots: [] }); continue; }
    let free = windows.map(w => {
      const s = DateTime.fromISO(`${dateKey}T${w.start}`, { zone: tz });
      const e = DateTime.fromISO(`${dateKey}T${w.end}`, { zone: tz });
      return Interval.fromDateTimes(s, e);
    }).filter(iv => iv.isValid && iv.length('minutes') > 0);
    for (const b of bookings) {
      const bs = DateTime.fromJSDate(b.schedule.startUtc).setZone(tz);
      const be = DateTime.fromJSDate(b.schedule.endUtc).setZone(tz);
      const biv = Interval.fromDateTimes(bs, be);
      if (!biv || !biv.isValid) continue;
      const newFree = [];
      for (const iv of free) {
        const overlap = iv.intersection(biv);
        if (!overlap) { newFree.push(iv); continue; }
        if (iv.start < overlap.start) newFree.push(Interval.fromDateTimes(iv.start, overlap.start));
        if (overlap.end < iv.end) newFree.push(Interval.fromDateTimes(overlap.end, iv.end));
      }
      free = newFree.filter(iv => iv.length('minutes') > 0);
      if (!free.length) break;
    }
    free = free.map(iv => {
      if (iv.end <= leadThresholdLocal) return null;
      const start = iv.start < leadThresholdLocal ? leadThresholdLocal : iv.start;
      return Interval.fromDateTimes(start, iv.end);
    }).filter(Boolean).filter(iv => iv.length('minutes') > 0);
    const slots = [];
    for (const iv of free) {
      let s = iv.start;
      while (s.plus({ minutes: step }) <= iv.end) {
        slots.push({ start: s.toFormat('HH:mm'), end: s.plus({ minutes: step }).toFormat('HH:mm') });
        s = s.plus({ minutes: step });
      }
    }
    days.push({ date: dateKey, slots });
  }
  return { timezone: tz, step, days };
}

(async () => {
  const [providerId, from, to, stepRaw] = process.argv.slice(2);
  if (!providerId || !from || !to) { usage(); process.exit(1); }
  const step = Math.max(parseInt(stepRaw || '30') || 30, 10);
  try {
    await connectDB();
    const result = await resolve(providerId, from, to, step);
    console.log(JSON.stringify(result, null, 2));
  } catch (e) {
    console.error('checkResolved error:', e);
    process.exit(1);
  } finally {
    try { await mongoose.connection.close(); } catch (_) {}
  }
})();

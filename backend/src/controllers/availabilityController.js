const Availability = require('../models/Availability');
const Booking = require('../models/Booking');
const { DateTime, Interval } = require('luxon');
const { ok, created, error } = require('../utils/response');

async function getAvailability(req, res) {
  try {
    const providerId = req.params.providerId;
  const a = await Availability.findOne({ provider: providerId });
    return ok(res, a || {});
  } catch (e) {
    return error(res, 400, 'Failed to fetch availability');
  }
}

async function upsertAvailability(req, res) {
  try {
    const providerId = req.params.providerId;
    const data = { ...req.body, provider: providerId };
    const a = await Availability.findOneAndUpdate({ provider: providerId }, data, { upsert: true, new: true, setDefaultsOnInsert: true });
    return ok(res, a, 'Availability saved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to save availability');
  }
}

module.exports = { getAvailability, upsertAvailability };
 
// --- New: resolved availability with bookings and lead-time applied ---

function getMinutes(name, fallback) {
  const raw = process.env[name];
  if (raw && !Number.isNaN(parseInt(raw))) return parseInt(raw);
  if (process.env.NODE_ENV !== 'production' && fallback === 2880) return 1;
  return fallback;
}

/**
 * GET /api/availability/:providerId/resolve?from=YYYY-MM-DD&to=YYYY-MM-DD&step=30
 * Returns list of days with discrete time slots after subtracting bookings.
 */
async function getResolvedAvailability(req, res) {
  try {
    const providerId = req.params.providerId;
    const step = Math.max(parseInt(req.query.step) || 30, 10); // minutes
  const MIN_LEAD = getMinutes('BOOKING_MIN_LEAD_MINUTES', 2880);
  const isEmergency = String(req.query.emergency || 'false').toLowerCase() === 'true';
    const nowUtc = DateTime.utc();

    const fromStr = (req.query.from || nowUtc.toISODate());
    const toStr = req.query.to || nowUtc.plus({ days: 30 }).toISODate();
    let from = DateTime.fromISO(fromStr, { zone: 'utc' });
    let to = DateTime.fromISO(toStr, { zone: 'utc' });
    if (!from.isValid || !to.isValid) return error(res, 400, 'Invalid date range');
    if (to.diff(from, 'days').days > 62) {
      to = from.plus({ days: 62 });
    }

    // Ensure provider supports emergency if requested
    if (isEmergency) {
      try {
        const Service = require('../models/Service');
        const sid = (req.query.serviceId || '').toString();
        const q = { provider: providerId, emergencyEnabled: true };
        const has = sid && sid.length === 24
          ? await Service.exists({ _id: sid, ...q })
          : await Service.exists(q);
        if (!has) return ok(res, { timezone: 'Asia/Jerusalem', step, days: [] });
      } catch (_) {
        return ok(res, { timezone: 'Asia/Jerusalem', step, days: [] });
      }
    }

    // Load availability
    const a = await Availability.findOne({ provider: providerId });
  const tz = a?.timezone || 'Asia/Jerusalem';
  // Build weekly windows and exceptions. For emergency mode we merge normal weekly
  // with emergencyWeekly so emergency includes all normal slots plus any extra
  // emergency-only windows; similarly merge exceptions. Also append a small set
  // of default late-night/early-morning emergency-only windows so short-notice
  // emergency bookings can be offered even if provider didn't configure them.
  const defaultEmergencyExtras = [
    { start: '00:00', end: '06:00' }, // early-morning
    { start: '22:00', end: '23:59' }  // late-night
  ];

  const weekly = (() => {
    const base = a?.weekly || {};
    if (!isEmergency) return base;
    const emerg = a?.emergencyWeekly || {};
    const days = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
    const merged = {};
    for (const d of days) {
      const b = Array.isArray(base[d]) ? base[d].map(w => ({ start: w.start, end: w.end })) : [];
      const e = Array.isArray(emerg[d]) ? emerg[d].map(w => ({ start: w.start, end: w.end })) : [];
      // combine base + emergency windows + default extras (avoid duplicates by string)
      const combined = [...b, ...e, ...defaultEmergencyExtras];
      const seen = new Set();
      merged[d] = combined.filter(w => {
        const k = `${w.start}-${w.end}`;
        if (seen.has(k)) return false;
        seen.add(k);
        return true;
      });
    }
    return merged;
  })();

  const exceptions = (() => {
    const baseEx = Array.isArray(a?.exceptions) ? a.exceptions : [];
    if (!isEmergency) return baseEx;
    const emergEx = Array.isArray(a?.emergencyExceptions) ? a.emergencyExceptions : [];
    // Merge exceptions by date, combining windows when a date appears in both lists.
    const map = new Map();
    for (const ex of [...baseEx, ...emergEx]) {
      if (!ex || !ex.date) continue;
      const existing = map.get(ex.date) || { date: ex.date, windows: [] };
      const wins = Array.isArray(ex.windows) ? ex.windows.map(w => ({ start: w.start, end: w.end })) : [];
      // append wins, avoid duplicates
      const seen = new Set(existing.windows.map(w => `${w.start}-${w.end}`));
      for (const w of wins) {
        const k = `${w.start}-${w.end}`;
        if (!seen.has(k)) { existing.windows.push(w); seen.add(k); }
      }
      map.set(ex.date, existing);
    }
    return Array.from(map.values());
  })();

    // Determine lead threshold for emergency vs normal
    // Normal bookings use the global MIN_LEAD (default 48h). Emergency defaults
    // to a short-notice 120 minutes but will be overridden by the service setting
    // if present on the Service document.
    let leadMinutes = MIN_LEAD;
    if (isEmergency) {
      leadMinutes = 120; // emergency default (2 hours)
      try {
        const Service = require('../models/Service');
        const q = { provider: providerId, emergencyEnabled: true };
        const sid = (req.query.serviceId || '').toString();
        let svc = null;
        if (sid && sid.length === 24) {
          svc = await Service.findOne({ _id: sid, ...q }).select('emergencyLeadTimeMinutes');
        }
        if (!svc) {
          svc = await Service.findOne(q).select('emergencyLeadTimeMinutes');
        }
        if (svc && Number.isFinite(svc.emergencyLeadTimeMinutes)) {
          leadMinutes = Math.max(0, svc.emergencyLeadTimeMinutes);
        }
      } catch (_) {}
    }

    // Get bookings overlapping range
  const bookings = await Booking.find({
      provider: providerId,
      status: { $in: ['pending', 'confirmed'] },
      $or: [
        { 'schedule.startUtc': { $lte: to.toJSDate() }, 'schedule.endUtc': { $gte: from.toJSDate() } }
      ]
  }).select('schedule.startUtc schedule.endUtc status');

  // Precompute lead threshold in provider TZ
  const leadThresholdLocal = nowUtc.plus({ minutes: leadMinutes }).setZone(tz);

    const days = [];
    for (let cursor = from.setZone(tz).startOf('day'); cursor <= to.setZone(tz).endOf('day'); cursor = cursor.plus({ days: 1 })) {
      const dateKey = cursor.toFormat('yyyy-MM-dd');
      // Determine base windows for the day
      const ex = exceptions.find(e => e.date === dateKey);
      let windows = [];
      if (ex) {
        windows = (ex.windows || []).map(w => ({ start: w.start, end: w.end }));
      } else {
        const dayName = cursor.toFormat('cccc').toLowerCase();
        windows = (weekly?.[dayName] || []).map(w => ({ start: w.start, end: w.end }));
      }
      // If emergency and windows are empty after falling back, provide a minimal short-notice window late-night
      if (isEmergency && (!windows || windows.length === 0)) {
        // Provide a narrow window from 22:00-23:59 as a final fallback
        windows = [{ start: '22:00', end: '23:59' }];
      }
      if (!windows.length) {
        // Even if no available windows, we may still expose booked slots for clarity
        // Compute booked step slots intersecting this day (not clipped to windows)
        const dayStart = DateTime.fromISO(`${dateKey}T00:00`, { zone: tz });
        const dayEnd = dayStart.plus({ days: 1 });
        const dayIv = Interval.fromDateTimes(dayStart, dayEnd);
    const bookedSlots = [];
    for (const b of bookings) {
          const bs = DateTime.fromJSDate(b.schedule.startUtc).setZone(tz);
          const be = DateTime.fromJSDate(b.schedule.endUtc).setZone(tz);
          let bi = Interval.fromDateTimes(bs, be);
          if (!bi || !bi.isValid) continue;
          bi = bi.intersection(dayIv);
          if (!bi) continue;
          let s = bi.start;
          while (s.plus({ minutes: step }) <= bi.end) {
      bookedSlots.push({ start: s.toFormat('HH:mm'), end: s.plus({ minutes: step }).toFormat('HH:mm'), status: b.status });
            s = s.plus({ minutes: step });
          }
        }
        days.push({ date: dateKey, slots: [], booked: bookedSlots });
        continue;
      }

      // Convert windows to intervals
      let free = windows.map(w => {
        const s = DateTime.fromISO(`${dateKey}T${w.start}`, { zone: tz });
        const e = DateTime.fromISO(`${dateKey}T${w.end}`, { zone: tz });
        return Interval.fromDateTimes(s, e);
      }).filter(iv => iv.isValid && iv.length('minutes') > 0);

      // Subtract bookings
      for (const b of bookings) {
        const bs = DateTime.fromJSDate(b.schedule.startUtc).setZone(tz);
        const be = DateTime.fromJSDate(b.schedule.endUtc).setZone(tz);
        const biv = Interval.fromDateTimes(bs, be);
        // If no overlap with this day, skip
        if (!biv || !biv.isValid) continue;
        const newFree = [];
        for (const iv of free) {
          const overlap = iv.intersection(biv);
          if (!overlap) { newFree.push(iv); continue; }
          // Split iv - overlap
          if (iv.start < overlap.start) {
            newFree.push(Interval.fromDateTimes(iv.start, overlap.start));
          }
          if (overlap.end < iv.end) {
            newFree.push(Interval.fromDateTimes(overlap.end, iv.end));
          }
        }
        free = newFree.filter(iv => iv.length('minutes') > 0);
        if (!free.length) break;
      }

  // Apply lead threshold (remove slots starting before lead time)
      free = free.map(iv => {
        if (iv.end <= leadThresholdLocal) return null;
        const start = iv.start < leadThresholdLocal ? leadThresholdLocal : iv.start;
        return Interval.fromDateTimes(start, iv.end);
      }).filter(Boolean).filter(iv => iv.length('minutes') > 0);

      // Discretize into step-minute slots (start..start+step)
      const slots = [];
      for (const iv of free) {
        let s = iv.start;
        while (s.plus({ minutes: step }) <= iv.end) {
          slots.push({ start: s.toFormat('HH:mm'), end: s.plus({ minutes: step }).toFormat('HH:mm') });
          s = s.plus({ minutes: step });
        }
      }

      // Also include booked slots for this day (discretized by step) for UI legend/visuals
      const dayStart = DateTime.fromISO(`${dateKey}T00:00`, { zone: tz });
      const dayEnd = dayStart.plus({ days: 1 });
      const dayIv = Interval.fromDateTimes(dayStart, dayEnd);
    const bookedSlots = [];
    for (const b of bookings) {
        const bs = DateTime.fromJSDate(b.schedule.startUtc).setZone(tz);
        const be = DateTime.fromJSDate(b.schedule.endUtc).setZone(tz);
        let bi = Interval.fromDateTimes(bs, be);
        if (!bi || !bi.isValid) continue;
        bi = bi.intersection(dayIv);
        if (!bi) continue;
        let s = bi.start;
        while (s.plus({ minutes: step }) <= bi.end) {
      bookedSlots.push({ start: s.toFormat('HH:mm'), end: s.plus({ minutes: step }).toFormat('HH:mm'), status: b.status });
          s = s.plus({ minutes: step });
        }
      }

      days.push({ date: dateKey, slots, booked: bookedSlots });
    }

    return ok(res, { timezone: tz, step, days });
  } catch (e) {
    console.error('getResolvedAvailability error', e);
    return error(res, 400, 'Failed to resolve availability');
  }
}

module.exports.getResolvedAvailability = getResolvedAvailability;

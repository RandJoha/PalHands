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
    const normWeekly = (w) => {
      const days = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
      const out = {};
      const src = (w && typeof w === 'object') ? w : {};
      for (const d of days) {
        const arr = Array.isArray(src[d]) ? src[d] : [];
        out[d] = arr.filter(Boolean).map(x => ({
          start: String((x && x.start) || ''),
          end: String((x && x.end) || '')
        })).filter(w => w.start && w.end);
      }
      return out;
    };
    const normExceptions = (list) => {
      const src = Array.isArray(list) ? list : [];
      return src.map(e => ({
        date: String((e && e.date) || ''),
        windows: Array.isArray(e && e.windows) ? e.windows.map(w => ({ start: String(w.start||''), end: String(w.end||'') })).filter(w => w.start && w.end) : []
      })).filter(e => e.date);
    };

    const data = {
      provider: providerId,
      timezone: req.body && req.body.timezone ? String(req.body.timezone) : 'Asia/Jerusalem',
      weekly: normWeekly(req.body && req.body.weekly),
      emergencyWeekly: normWeekly(req.body && req.body.emergencyWeekly),
      exceptions: normExceptions(req.body && req.body.exceptions),
      emergencyExceptions: normExceptions(req.body && req.body.emergencyExceptions),
    };
    const a = await Availability.findOneAndUpdate({ provider: providerId }, { $set: data }, { upsert: true, new: true, setDefaultsOnInsert: true });
    return ok(res, a, 'Availability saved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to save availability');
  }
}

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
    console.log('🔍 getResolvedAvailability called');
    const providerId = req.params.providerId;
    const step = Math.max(parseInt(req.query.step) || 30, 10); // minutes
  const MIN_LEAD = getMinutes('BOOKING_MIN_LEAD_MINUTES', 2880);
  const isEmergency = String(req.query.emergency || 'false').toLowerCase() === 'true';
    
    console.log('📋 Request params:', {
      providerId,
      step,
      isEmergency,
      queryParams: req.query,
      MIN_LEAD
    });
    
    // Validate providerId format
    if (!providerId || providerId.length !== 24) {
      console.log('❌ Invalid providerId format:', providerId);
      return error(res, 400, 'Invalid provider ID format');
    }
    const nowUtc = DateTime.utc();

    const fromStr = (req.query.from || nowUtc.toISODate());
    const toStr = req.query.to || nowUtc.plus({ days: 30 }).toISODate();
    console.log('📅 Date parsing:', { fromStr, toStr });
    let from = DateTime.fromISO(fromStr, { zone: 'utc' });
    let to = DateTime.fromISO(toStr, { zone: 'utc' });
    console.log('📅 Parsed dates:', { from: from.isValid ? from.toISO() : 'invalid', to: to.isValid ? to.toISO() : 'invalid' });
    if (!from.isValid || !to.isValid) {
      console.log('❌ Invalid date range:', { from: fromStr, to: toStr });
      return error(res, 400, 'Invalid date range');
    }
    if (to.diff(from, 'days').days > 62) {
      to = from.plus({ days: 62 });
    }

    // Ensure provider supports emergency if requested (use ProviderService flags)
    if (isEmergency) {
      console.log('🚨 Emergency mode requested, checking provider support...');
      try {
        const ProviderService = require('../models/ProviderService');
        const sid = (req.query.serviceId || '').toString();
        let hasEmergencySupport = false;
        
        if (sid && sid.length === 24) {
          const ps = await ProviderService.findOne({ provider: providerId, service: sid })
            .select('status publishable emergencyEnabled');
          console.log('🔍 ProviderService found:', !!ps, ps ? { status: ps.status, publishable: ps.publishable, emergencyEnabled: ps.emergencyEnabled } : 'none');
          if (ps && ps.status === 'active' && ps.publishable === true && ps.emergencyEnabled === true) {
            hasEmergencySupport = true;
          }
        } else {
          const psAny = await ProviderService.exists({ provider: providerId, status: 'active', publishable: true, emergencyEnabled: true });
          console.log('🔍 Any ProviderService with emergency enabled:', !!psAny);
          if (psAny) {
            hasEmergencySupport = true;
          }
        }
        
        // If no ProviderService support found, check if provider has emergency availability data
        if (!hasEmergencySupport) {
          console.log('🔍 No ProviderService emergency support, checking availability data...');
          const a = await Availability.findOne({ provider: providerId });
          if (a && a.emergencyWeekly) {
            const hasEmergencySlots = Object.values(a.emergencyWeekly).some(day => Array.isArray(day) && day.length > 0);
            console.log('🔍 Provider has emergency availability data:', hasEmergencySlots);
            if (hasEmergencySlots) {
              hasEmergencySupport = true;
            }
          }
        }
        
        if (!hasEmergencySupport) {
          console.log('⚠️ No emergency support found, returning empty availability');
          return ok(res, { timezone: 'Asia/Jerusalem', step, days: [] });
        }
      } catch (e) {
        console.log('❌ ProviderService check error:', e.message);
        console.log('⚠️ Returning empty availability due to error');
        return ok(res, { timezone: 'Asia/Jerusalem', step, days: [] });
      }
    }

    // Optional: service-specific gating (only expose slots if ProviderService is active+publishable when serviceId provided)
    const ProviderService = require('../models/ProviderService');
    const pid = (req.query.serviceId || '').toString();
    if (pid && pid.length === 24) {
      try {
        const ps = await ProviderService.findOne({ provider: providerId, service: pid });
        if (!ps || ps.status !== 'active' || ps.publishable !== true) {
          return ok(res, { timezone: 'Asia/Jerusalem', step, days: [] });
        }
      } catch (_) {}
    }

    // Load availability + optional provider-service overrides
    console.log('🔎 Looking for availability for provider:', providerId);
    let a = await Availability.findOne({ provider: providerId });
    console.log('📅 Availability found:', !!a, a ? 'Has weekly data' : 'No availability document');
    
    // If no availability data found, create basic test data
    if (!a) {
      console.log('⚠️ No availability data found, creating basic test availability');
      a = await Availability.findOneAndUpdate(
        { provider: providerId },
        {
          provider: providerId,
          timezone: 'Asia/Jerusalem',
          weekly: {
            monday: [{ start: '09:00', end: '17:00' }],
            tuesday: [{ start: '09:00', end: '17:00' }],
            wednesday: [{ start: '09:00', end: '17:00' }],
            thursday: [{ start: '09:00', end: '17:00' }],
            friday: [{ start: '09:00', end: '17:00' }],
            saturday: [],
            sunday: []
          },
          emergencyWeekly: {
            monday: [{ start: '18:00', end: '20:00' }],
            tuesday: [{ start: '18:00', end: '20:00' }],
            wednesday: [{ start: '18:00', end: '20:00' }],
            thursday: [{ start: '18:00', end: '20:00' }],
            friday: [{ start: '18:00', end: '20:00' }],
            saturday: [],
            sunday: []
          },
          exceptions: [],
          emergencyExceptions: []
        },
        { upsert: true, new: true }
      );
      console.log('✅ Created test availability for provider:', providerId);
    }
    
    const tz = a?.timezone || 'Asia/Jerusalem';
    
    let psDoc = null;
    const sidForMerge = (req.query.serviceId || '').toString();
    console.log('🔍 Looking for ProviderService:', { providerId, serviceId: sidForMerge });
    if (sidForMerge && sidForMerge.length === 24) {
      try {
        psDoc = await ProviderService.findOne({ provider: providerId, service: sidForMerge })
          .select('weeklyOverrides exceptionOverrides emergencyWeeklyOverrides emergencyExceptionOverrides');
        console.log('📋 ProviderService found:', !!psDoc);
        if (psDoc) {
          console.log('📋 weeklyOverrides:', psDoc.weeklyOverrides);
          console.log('📋 emergencyWeeklyOverrides:', psDoc.emergencyWeeklyOverrides);
        } else {
          console.log('⚠️ No ProviderService found for provider:', providerId, 'service:', sidForMerge);
        }
      } catch (e) { 
        console.log('❌ ProviderService query error:', e.message);
        psDoc = null; 
      }
    } else {
      console.log('⚠️ Invalid serviceId for ProviderService lookup:', sidForMerge);
    }
    // Build weekly windows and exceptions. For emergency mode we merge normal weekly
    // with emergencyWeekly (if present) and additive per-service emergency overrides.
    // No implicit default time windows are added.

    const weekly = (() => {
      const base = a?.weekly || {};
      const days = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
      const merged = {};
      for (const d of days) {
        const b = Array.isArray(base[d]) ? base[d].map(w => ({ start: w.start, end: w.end })) : [];
        // per-service normal overrides replace base for that day if provided (complete schedule)
        const o = psDoc && psDoc.weeklyOverrides && Array.isArray(psDoc.weeklyOverrides[d])
          ? psDoc.weeklyOverrides[d].map(w => ({ start: w.start, end: w.end }))
          : null;
        let combined = o ? o : b; // Use override if present, otherwise use base
        if (isEmergency) {
          const emerg = a?.emergencyWeekly || {};
          const e = Array.isArray(emerg[d]) ? emerg[d].map(w => ({ start: w.start, end: w.end })) : [];
          const eo = psDoc && psDoc.emergencyWeeklyOverrides && Array.isArray(psDoc.emergencyWeeklyOverrides[d])
            ? psDoc.emergencyWeeklyOverrides[d].map(w => ({ start: w.start, end: w.end }))
            : [];
          combined = [...combined, ...e, ...eo]; // Add emergency slots on top
        }
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
      const map = new Map();
      const addList = (list) => {
        for (const ex of list || []) {
          if (!ex || !ex.date) continue;
          const existing = map.get(ex.date) || { date: ex.date, windows: [] };
          const wins = Array.isArray(ex.windows) ? ex.windows.map(w => ({ start: w.start, end: w.end })) : [];
          const seen = new Set(existing.windows.map(w => `${w.start}-${w.end}`));
          for (const w of wins) {
            const k = `${w.start}-${w.end}`;
            if (!seen.has(k)) { existing.windows.push(w); seen.add(k); }
          }
          map.set(ex.date, existing);
        }
      };
      // base exceptions
      addList(baseEx);
      // per-service normal overrides
      if (psDoc && Array.isArray(psDoc.exceptionOverrides)) addList(psDoc.exceptionOverrides);
      if (isEmergency) {
        const emergEx = Array.isArray(a?.emergencyExceptions) ? a.emergencyExceptions : [];
        addList(emergEx);
        if (psDoc && Array.isArray(psDoc.emergencyExceptionOverrides)) addList(psDoc.emergencyExceptionOverrides);
      }
      return Array.from(map.values());
    })();

  // Determine lead threshold for emergency vs normal
  // Normal bookings use the global MIN_LEAD (default 48h). Emergency defaults
  // to 2 hours (120 minutes) but will be overridden by ProviderService
  // (preferred) or Service document (fallback) when available.
    let leadMinutes = MIN_LEAD;
    if (isEmergency) {
      leadMinutes = 120; // Default 2-hour lead time for emergency mode
      try {
        const ProviderService = require('../models/ProviderService');
        const Service = require('../models/Service');
        const sid = (req.query.serviceId || '').toString();
        if (sid && sid.length === 24) {
          const ps = await ProviderService.findOne({ provider: providerId, service: sid })
            .select('emergencyLeadTimeMinutes');
          if (ps && Number.isFinite(ps.emergencyLeadTimeMinutes)) {
            leadMinutes = Math.max(0, ps.emergencyLeadTimeMinutes);
          } else {
            const svc = await Service.findById(sid).select('emergencyLeadTimeMinutes');
            if (svc && Number.isFinite(svc.emergencyLeadTimeMinutes)) {
              leadMinutes = Math.max(0, svc.emergencyLeadTimeMinutes);
            }
          }
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
  // No implicit windows if empty; providers must configure availability in dashboard
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

    console.log('📊 Returning resolved availability:', { 
      timezone: tz, 
      step, 
      daysCount: days.length,
      sampleDay: days.length > 0 ? days[0] : null 
    });
    
    return ok(res, { timezone: tz, step, days });
  } catch (e) {
    console.error('❌ getResolvedAvailability error:', e);
    console.error('❌ Error details:', {
      message: e.message,
      stack: e.stack,
      providerId: req.params.providerId,
      query: req.query
    });
    return error(res, 400, `Failed to resolve availability: ${e.message}`);
  }
}

module.exports = { 
  getAvailability, 
  upsertAvailability, 
  getResolvedAvailability 
};

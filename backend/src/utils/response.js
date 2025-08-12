// Unified response helpers
const ok = (res, data = {}, message = 'OK', code = 'OK') =>
  res.status(200).json({ success: true, code, message, data });

const created = (res, data = {}, message = 'Created', code = 'CREATED') =>
  res.status(201).json({ success: true, code, message, data });

const error = (res, status = 500, message = 'Internal server error', details = [], code = 'ERROR') =>
  res.status(status).json({ success: false, code, message, details });

module.exports = { ok, created, error };

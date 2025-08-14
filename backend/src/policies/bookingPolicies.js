// Phase 1.5: RBAC/ABAC helpers for bookings
function normalizeId(ref) {
  if (!ref) return null;
  // If populated document, use its _id; else assume it's an ObjectId/string
  return ref._id ? ref._id.toString() : ref.toString?.();
}

module.exports = {
  canView(user, booking) {
    if (!user || !booking) return false;
    if (user.role === 'admin') return true;
    const clientId = normalizeId(booking.client);
    const providerId = normalizeId(booking.provider);
    const userId = user._id.toString();
    return clientId === userId || providerId === userId;
  },
  allowedStatusFor(user, booking) {
    const allowed = new Set();
    if (!user || !booking) return allowed;
    const clientId = normalizeId(booking.client);
    const providerId = normalizeId(booking.provider);
    const userId = user._id.toString();
    if (user.role === 'client' && clientId === userId) {
      allowed.add('cancelled');
    }
    if (user.role === 'provider' && providerId === userId) {
      ['confirmed','in_progress','completed','cancelled','disputed'].forEach(s=>allowed.add(s));
    }
    return allowed;
  }
};

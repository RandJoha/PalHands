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
    // Admin can set any status
    if (user.role === 'admin') {
      ['pending','confirmed','completed','cancelled'].forEach(s=>allowed.add(s));
      return allowed;
    }
    const clientId = normalizeId(booking.client);
    const providerId = normalizeId(booking.provider);
    const userId = user._id.toString();
    if (user.role === 'client' && clientId === userId) {
      allowed.add('cancelled');
    }
    if (user.role === 'provider' && providerId === userId) {
      ['confirmed','completed','cancelled'].forEach(s=>allowed.add(s));
    }
    return allowed;
  },
  canCancelDirectly(booking, minutesUntilStart, thresholdMinutes) {
    if (!booking) return false;
    if (['completed','cancelled'].includes(booking.status)) return false;
    return minutesUntilStart >= thresholdMinutes;
  },
  clientCanCancel(user, booking) {
    if (!user || user.role !== 'client') return false;
    const uid = user._id.toString();
    return uid === (booking.client?._id?.toString?.() || booking.client?.toString?.());
  },
  providerCanAct(user, booking) {
    if (!user || user.role !== 'provider') return false;
    const uid = user._id.toString();
    return uid === (booking.provider?._id?.toString?.() || booking.provider?.toString?.());
  }
};

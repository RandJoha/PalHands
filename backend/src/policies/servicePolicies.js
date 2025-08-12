// Phase 1.5: RBAC/ABAC helpers for services
module.exports = {
  canCreate(user) {
  // Only admins can create services
  return user && user.role === 'admin';
  },
  canModify(user, service) {
    if (!user || !service) return false;
    if (user.role === 'admin') return true;
    return service.provider?.toString?.() === user._id.toString();
  }
};

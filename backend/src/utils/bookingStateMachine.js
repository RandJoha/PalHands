/**
 * Finite State Machine for Booking Status Transitions
 * Ensures only valid transitions are allowed based on business rules
 */

// Valid booking statuses
const BOOKING_STATUSES = {
  PENDING: 'pending',
  CONFIRMED: 'confirmed',
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
  DISPUTED: 'disputed'
};

// Valid state transitions
const VALID_TRANSITIONS = {
  [BOOKING_STATUSES.PENDING]: [
    BOOKING_STATUSES.CONFIRMED,
    BOOKING_STATUSES.CANCELLED
  ],
  [BOOKING_STATUSES.CONFIRMED]: [
    BOOKING_STATUSES.IN_PROGRESS,
    BOOKING_STATUSES.CANCELLED
  ],
  [BOOKING_STATUSES.IN_PROGRESS]: [
    BOOKING_STATUSES.COMPLETED,
    BOOKING_STATUSES.DISPUTED
  ],
  [BOOKING_STATUSES.COMPLETED]: [
    BOOKING_STATUSES.DISPUTED
  ],
  [BOOKING_STATUSES.CANCELLED]: [], // Terminal state
  [BOOKING_STATUSES.DISPUTED]: [] // Terminal state - resolved by admin
};

// Role-based transition permissions
const ROLE_PERMISSIONS = {
  client: {
    [BOOKING_STATUSES.PENDING]: [BOOKING_STATUSES.CANCELLED],
    [BOOKING_STATUSES.CONFIRMED]: [BOOKING_STATUSES.CANCELLED],
    [BOOKING_STATUSES.COMPLETED]: [BOOKING_STATUSES.DISPUTED]
  },
  provider: {
    [BOOKING_STATUSES.PENDING]: [BOOKING_STATUSES.CONFIRMED, BOOKING_STATUSES.CANCELLED],
    [BOOKING_STATUSES.CONFIRMED]: [BOOKING_STATUSES.IN_PROGRESS, BOOKING_STATUSES.CANCELLED],
    [BOOKING_STATUSES.IN_PROGRESS]: [BOOKING_STATUSES.COMPLETED, BOOKING_STATUSES.DISPUTED],
    [BOOKING_STATUSES.COMPLETED]: [BOOKING_STATUSES.DISPUTED]
  },
  admin: {
    // Admin can transition from any state to any valid next state
    [BOOKING_STATUSES.PENDING]: [BOOKING_STATUSES.CONFIRMED, BOOKING_STATUSES.CANCELLED],
    [BOOKING_STATUSES.CONFIRMED]: [BOOKING_STATUSES.IN_PROGRESS, BOOKING_STATUSES.CANCELLED],
    [BOOKING_STATUSES.IN_PROGRESS]: [BOOKING_STATUSES.COMPLETED, BOOKING_STATUSES.CANCELLED, BOOKING_STATUSES.DISPUTED],
    [BOOKING_STATUSES.COMPLETED]: [BOOKING_STATUSES.DISPUTED],
    [BOOKING_STATUSES.CANCELLED]: [],
    [BOOKING_STATUSES.DISPUTED]: [BOOKING_STATUSES.COMPLETED, BOOKING_STATUSES.CANCELLED]
  }
};

/**
 * Check if a status transition is valid
 * @param {string} fromStatus - Current booking status
 * @param {string} toStatus - Desired booking status
 * @returns {boolean} - Whether transition is valid
 */
function isValidTransition(fromStatus, toStatus) {
  if (!fromStatus || !toStatus) return false;
  if (fromStatus === toStatus) return false; // No-op transitions not allowed
  
  const validNextStates = VALID_TRANSITIONS[fromStatus];
  return validNextStates && validNextStates.includes(toStatus);
}

/**
 * Check if a user role is allowed to make a specific transition
 * @param {string} userRole - User role (client, provider, admin)
 * @param {string} fromStatus - Current booking status
 * @param {string} toStatus - Desired booking status
 * @returns {boolean} - Whether user can make this transition
 */
function isRoleAllowed(userRole, fromStatus, toStatus) {
  if (!userRole || !fromStatus || !toStatus) return false;
  
  const rolePermissions = ROLE_PERMISSIONS[userRole];
  if (!rolePermissions) return false;
  
  const allowedTransitions = rolePermissions[fromStatus];
  return allowedTransitions && allowedTransitions.includes(toStatus);
}

/**
 * Validate a booking status transition
 * @param {Object} options - Validation options
 * @param {string} options.fromStatus - Current booking status
 * @param {string} options.toStatus - Desired booking status
 * @param {string} options.userRole - User role making the request
 * @param {Object} options.booking - Booking object (for additional validation)
 * @param {Object} options.user - User object making the request
 * @returns {Object} - Validation result with success flag and error message
 */
function validateTransition({ fromStatus, toStatus, userRole, booking, user }) {
  // Basic validation
  if (!fromStatus || !toStatus) {
    return {
      success: false,
      error: 'Missing required status parameters'
    };
  }

  // Check if transition is valid in the state machine
  if (!isValidTransition(fromStatus, toStatus)) {
    return {
      success: false,
      error: `Invalid transition from ${fromStatus} to ${toStatus}`
    };
  }

  // Check role permissions
  if (!isRoleAllowed(userRole, fromStatus, toStatus)) {
    return {
      success: false,
      error: `${userRole} role not allowed to transition from ${fromStatus} to ${toStatus}`
    };
  }

  // Additional business rule validations
  if (booking && user) {
    // Check ownership for client/provider specific transitions
    if (userRole === 'client') {
      const clientId = booking.client?._id?.toString() || booking.client?.toString();
      if (clientId !== user._id.toString()) {
        return {
          success: false,
          error: 'Client can only modify their own bookings'
        };
      }
    }

    if (userRole === 'provider') {
      const providerId = booking.provider?._id?.toString() || booking.provider?.toString();
      if (providerId !== user._id.toString()) {
        return {
          success: false,
          error: 'Provider can only modify bookings for their services'
        };
      }
    }

    // Time-based validations
    if (toStatus === BOOKING_STATUSES.IN_PROGRESS) {
      const now = new Date();
      const scheduledStart = new Date(booking.schedule.startUtc);
      const timeDiff = Math.abs(now - scheduledStart) / (1000 * 60); // minutes
      
      // Allow starting up to 30 minutes before/after scheduled time
      if (timeDiff > 30) {
        return {
          success: false,
          error: 'Booking can only be started within 30 minutes of scheduled time'
        };
      }
    }

    // Prevent cancellation too close to start time (unless admin)
    if (toStatus === BOOKING_STATUSES.CANCELLED && userRole !== 'admin') {
      const now = new Date();
      const scheduledStart = new Date(booking.schedule.startUtc);
      const hoursUntilStart = (scheduledStart - now) / (1000 * 60 * 60);
      
      // Require at least 2 hours notice for cancellation
      if (hoursUntilStart < 2) {
        return {
          success: false,
          error: 'Bookings cannot be cancelled less than 2 hours before start time'
        };
      }
    }
  }

  return {
    success: true,
    error: null
  };
}

/**
 * Get allowed next statuses for a booking based on current state and user role
 * @param {string} currentStatus - Current booking status
 * @param {string} userRole - User role
 * @returns {Array} - Array of allowed next statuses
 */
function getAllowedNextStatuses(currentStatus, userRole) {
  if (!currentStatus || !userRole) return [];
  
  const rolePermissions = ROLE_PERMISSIONS[userRole];
  if (!rolePermissions) return [];
  
  return rolePermissions[currentStatus] || [];
}

module.exports = {
  BOOKING_STATUSES,
  VALID_TRANSITIONS,
  ROLE_PERMISSIONS,
  isValidTransition,
  isRoleAllowed,
  validateTransition,
  getAllowedNextStatuses
};

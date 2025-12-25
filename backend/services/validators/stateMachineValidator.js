/**
 * State Machine Validators
 * 
 * Enforces valid status transitions for Leads, Tasks, and Tickets
 */

// ============================================================================
// TICKET STATE MACHINE
// ============================================================================

export const TicketTransitions = {
  OPEN: ['IN_PROGRESS', 'CLOSED'],
  IN_PROGRESS: ['RESOLVED', 'OPEN'],
  RESOLVED: ['CLOSED'],
  CLOSED: [], // Terminal state
};

/**
 * Validates ticket status transition
 * @param {string} currentStatus - Current ticket status
 * @param {string} newStatus - Desired ticket status
 * @param {string} userRole - User's role (ADMIN can override)
 * @returns {boolean} True if transition is allowed
 * @throws {Error} If transition is invalid
 */
export function validateTicketTransition(currentStatus, newStatus, userRole) {
  if (currentStatus === newStatus) {
    return true; // No-op is always valid
  }

  const allowedTransitions = TicketTransitions[currentStatus];

  if (!allowedTransitions) {
    throw new Error(`Invalid current ticket status: ${currentStatus}`);
  }

  if (!allowedTransitions.includes(newStatus)) {
    // Admin can override for audit/correction purposes
    if (userRole !== 'ADMIN') {
      throw new Error(
        `Cannot transition ticket from ${currentStatus} to ${newStatus}. ` +
        `Allowed transitions: ${allowedTransitions.join(', ')}`
      );
    }

    // Log admin override
    console.warn(
      `⚠️  ADMIN OVERRIDE: Ticket status ${currentStatus} → ${newStatus}`
    );
  }

  return true;
}

/**
 * Get allowed next states for a ticket
 * @param {string} currentStatus - Current status
 * @returns {string[]} Array of allowed next statuses
 */
export function getTicketAllowedNextStates(currentStatus) {
  return TicketTransitions[currentStatus] || [];
}

// ============================================================================
// LEAD STATE MACHINE
// ============================================================================

export const LeadTransitions = {
  NEW: ['PENDING', 'CONTACTED', 'UNQUALIFIED'],
  PENDING: ['CONTACTED', 'UNQUALIFIED'],
  CONTACTED: ['QUALIFIED', 'UNQUALIFIED'],
  QUALIFIED: ['CONVERTED', 'UNQUALIFIED'],
  CONVERTED: [], // Read-only terminal
  UNQUALIFIED: [], // Terminal (archived)
};

/**
 * Validates lead status transition
 * Prevents transitions FROM converted leads
 * @param {string} currentStatus - Current lead status
 * @param {string} newStatus - Desired lead status
 * @param {string} userRole - User's role
 * @param {boolean} isConverted - Whether lead is already converted
 * @returns {boolean} True if transition is allowed
 * @throws {Error} If transition is invalid
 */
export function validateLeadTransition(
  currentStatus,
  newStatus,
  userRole,
  isConverted = false
) {
  if (currentStatus === newStatus) {
    return true; // No-op is valid
  }

  // Prevent any status changes on converted leads (except admin)
  if (isConverted && userRole !== 'ADMIN') {
    throw new Error(
      'Cannot modify a converted lead. Only admins can edit converted leads for audit purposes.'
    );
  }

  const allowedTransitions = LeadTransitions[currentStatus];

  if (!allowedTransitions) {
    throw new Error(`Invalid current lead status: ${currentStatus}`);
  }

  if (!allowedTransitions.includes(newStatus)) {
    if (userRole !== 'ADMIN') {
      throw new Error(
        `Cannot transition lead from ${currentStatus} to ${newStatus}. ` +
        `Allowed transitions: ${allowedTransitions.join(', ')}`
      );
    }

    console.warn(
      `⚠️  ADMIN OVERRIDE: Lead status ${currentStatus} → ${newStatus}`
    );
  }

  return true;
}

/**
 * Check if a lead is in a terminal state
 * @param {string} status - Lead status
 * @returns {boolean}
 */
export function isLeadTerminal(status) {
  return ['CONVERTED', 'UNQUALIFIED'].includes(status);
}

/**
 * Get allowed next states for a lead
 * @param {string} currentStatus - Current status
 * @returns {string[]} Array of allowed next statuses
 */
export function getLeadAllowedNextStates(currentStatus) {
  return LeadTransitions[currentStatus] || [];
}

// ============================================================================
// TASK STATE MACHINE
// ============================================================================

export const TaskTransitions = {
  NOT_STARTED: ['IN_PROGRESS', 'CANCELLED'],
  IN_PROGRESS: ['COMPLETED', 'CANCELLED'],
  COMPLETED: [], // Terminal
  CANCELLED: [], // Terminal
};

/**
 * Validates task status transition
 * @param {string} currentStatus - Current task status
 * @param {string} newStatus - Desired task status
 * @param {string} userRole - User's role (ADMIN can override)
 * @returns {boolean} True if transition is allowed
 * @throws {Error} If transition is invalid
 */
export function validateTaskTransition(currentStatus, newStatus, userRole) {
  if (currentStatus === newStatus) {
    return true; // No-op is valid
  }

  const allowedTransitions = TaskTransitions[currentStatus];

  if (!allowedTransitions) {
    throw new Error(`Invalid current task status: ${currentStatus}`);
  }

  if (!allowedTransitions.includes(newStatus)) {
    if (userRole !== 'ADMIN') {
      throw new Error(
        `Cannot transition task from ${currentStatus} to ${newStatus}. ` +
        `Allowed transitions: ${allowedTransitions.join(', ')}`
      );
    }

    console.warn(
      `⚠️  ADMIN OVERRIDE: Task status ${currentStatus} → ${newStatus}`
    );
  }

  return true;
}

/**
 * Check if a task is in a terminal state
 * @param {string} status - Task status
 * @returns {boolean}
 */
export function isTaskTerminal(status) {
  return ['COMPLETED', 'CANCELLED'].includes(status);
}

/**
 * Get allowed next states for a task
 * @param {string} currentStatus - Current status
 * @returns {string[]} Array of allowed next statuses
 */
export function getTaskAllowedNextStates(currentStatus) {
  return TaskTransitions[currentStatus] || [];
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Generate a readable transition error message
 * @param {string} entityType - LEAD, TICKET, TASK
 * @param {string} currentStatus - Current status
 * @param {string} newStatus - Desired status
 * @param {string[]} allowedStates - Allowed next states
 * @returns {string} Formatted error message
 */
export function formatTransitionError(
  entityType,
  currentStatus,
  newStatus,
  allowedStates
) {
  return (
    `Invalid ${entityType} status transition\n` +
    `  Current: ${currentStatus}\n` +
    `  Attempted: ${newStatus}\n` +
    `  Allowed: ${allowedStates.length > 0 ? allowedStates.join(', ') : 'None (terminal state)'}`
  );
}

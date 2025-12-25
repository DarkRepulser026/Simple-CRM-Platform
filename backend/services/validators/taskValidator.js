/**
 * Task Entity Relationship Validator
 * 
 * Enforces XOR invariant: A task must belong to exactly ONE parent entity
 * Valid: contact OR account OR lead (not multiple)
 */

/**
 * Validates that task has exactly one parent entity
 * @param {Object} taskData - Task data to validate
 * @throws {Error} If relationship constraint is violated
 */
export function validateTaskRelationship(taskData) {
  const relationships = [
    taskData.contactId,
    taskData.accountId,
    taskData.leadId,
  ].filter(Boolean);

  if (relationships.length === 0) {
    throw new Error(
      'Task must be linked to exactly ONE entity (contact, account, or lead). None provided.'
    );
  }

  if (relationships.length > 1) {
    throw new Error(
      `Task violates XOR constraint: must belong to exactly ONE entity, but found ${relationships.length}. ` +
      `This is a data integrity issue. Contact support if this occurs.`
    );
  }

  return true;
}

/**
 * Validates task before creation
 * @param {Object} taskData - Raw task input
 * @returns {boolean} True if valid
 * @throws {Error} If validation fails
 */
export function validateTaskCreation(taskData) {
  // Validate XOR relationship
  validateTaskRelationship(taskData);

  // Validate required fields
  if (!taskData.subject || taskData.subject.trim().length === 0) {
    throw new Error('Task subject is required and cannot be empty');
  }

  if (!taskData.organizationId) {
    throw new Error('Task must belong to an organization');
  }

  if (!taskData.ownerId) {
    throw new Error('Task must have an owner');
  }

  // Validate status if provided
  const validStatuses = ['NOT_STARTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
  if (taskData.status && !validStatuses.includes(taskData.status)) {
    throw new Error(`Invalid task status: ${taskData.status}`);
  }

  // Validate priority if provided
  const validPriorities = ['HIGH', 'NORMAL', 'LOW'];
  if (taskData.priority && !validPriorities.includes(taskData.priority)) {
    throw new Error(`Invalid task priority: ${taskData.priority}`);
  }

  return true;
}

/**
 * Validates task before update
 * Ensures that XOR relationship is maintained during updates
 * @param {Object} existingTask - Current task data
 * @param {Object} updates - Updates to apply
 * @returns {boolean} True if valid
 * @throws {Error} If validation fails
 */
export function validateTaskUpdate(existingTask, updates) {
  // If updating relationships, validate XOR
  if (
    updates.contactId !== undefined ||
    updates.accountId !== undefined ||
    updates.leadId !== undefined
  ) {
    const newTaskData = {
      contactId: updates.contactId ?? existingTask.contactId,
      accountId: updates.accountId ?? existingTask.accountId,
      leadId: updates.leadId ?? existingTask.leadId,
    };

    validateTaskRelationship(newTaskData);
  }

  // Validate status if provided
  const validStatuses = ['NOT_STARTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
  if (updates.status && !validStatuses.includes(updates.status)) {
    throw new Error(`Invalid task status: ${updates.status}`);
  }

  // Validate priority if provided
  const validPriorities = ['HIGH', 'NORMAL', 'LOW'];
  if (updates.priority && !validPriorities.includes(updates.priority)) {
    throw new Error(`Invalid task priority: ${updates.priority}`);
  }

  return true;
}

/**
 * Get parent entity info for a task
 * @param {Object} task - Task with relationships populated
 * @returns {Object} { type, id, name, entityData }
 */
export function getTaskParentEntity(task) {
  if (task.contactId && task.contact) {
    return {
      type: 'CONTACT',
      id: task.contactId,
      name: `${task.contact.firstName} ${task.contact.lastName}`,
      entity: task.contact,
    };
  }

  if (task.accountId && task.account) {
    return {
      type: 'ACCOUNT',
      id: task.accountId,
      name: task.account.name,
      entity: task.account,
    };
  }

  if (task.leadId && task.lead) {
    return {
      type: 'LEAD',
      id: task.leadId,
      name: `${task.lead.firstName} ${task.lead.lastName}`,
      entity: task.lead,
    };
  }

  return null;
}

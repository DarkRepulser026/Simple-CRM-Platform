import prisma from '../lib/prismaClient.js';

export const createActivityLogEntry = async ({ action, entityType, entityId, description, userId, organizationId, metadata = null }) => {
  try {
    const data = { action, entityType, entityId, description, userId, organizationId };
    if (metadata) data.metadata = metadata;
    return await prisma.activityLog.create({ data });
  } catch (e) {
    console.error('createActivityLogEntry error:', e);
    // Non-blocking: swallowing error is safer than failing API call, but log for investigation
    return null;
  }
};

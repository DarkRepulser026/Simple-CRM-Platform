import prisma from './prismaClient.js';

export const ALLOWED_PERMISSIONS = [
  'VIEW_CONTACTS','CREATE_CONTACTS','EDIT_CONTACTS','DELETE_CONTACTS','VIEW_LEADS','CREATE_LEADS','EDIT_LEADS','DELETE_LEADS','CONVERT_LEADS',
  'VIEW_TICKETS','CREATE_TICKETS','EDIT_TICKETS','DELETE_TICKETS','ASSIGN_TICKETS','RESOLVE_TICKETS',
  'VIEW_TASKS','CREATE_TASKS','EDIT_TASKS','DELETE_TASKS','ASSIGN_TASKS',
  'VIEW_DASHBOARD','VIEW_REPORTS','MANAGE_USERS','MANAGE_ROLES','MANAGE_ORGANIZATION','VIEW_AUDIT_LOGS'
];

export const normalizeRoleType = (value) => {
  if (!value) return null;
  const v = String(value).toUpperCase().replace(/[^A-Z_]/g, '_');
  const allowed = ['ADMIN', 'MANAGER', 'AGENT', 'VIEWER'];
  return allowed.includes(v) ? v : null;
};

export const normalizePermissionsArray = (arr) => {
  if (!arr || !Array.isArray(arr)) return [];
  const mapped = arr.map((p) => String(p).toUpperCase().replace(/[^A-Z_]/g, '_'));
  const invalid = mapped.filter(p => !ALLOWED_PERMISSIONS.includes(p));
  if (invalid.length) return null; // invalid permissions present
  return mapped;
};

export const getUserPermissions = async (prismaClient, userId, organizationId) => {
  const userOrg = await prismaClient.userOrganization.findFirst({ where: { userId, organizationId } });
  if (!userOrg) return [];
  const roleType = userOrg.role;
  const role = await prismaClient.userRole.findFirst({ where: { organizationId, roleType } });
  if (!role) return [];
  return role.permissions || [];
};

export default { ALLOWED_PERMISSIONS, normalizePermissionsArray, normalizeRoleType, getUserPermissions };

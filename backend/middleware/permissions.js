import prisma from '../lib/prismaClient.js';
import { getUserPermissions as getUserPermissionsLib } from '../lib/permissions.js';

export const getUserPermissions = async (userId, organizationId) => getUserPermissionsLib(prisma, userId, organizationId);

export const authorize = (requiredPermissions) => {
  return async (req, res, next) => {
    try {
      const userId = req.user && req.user.id;
      const orgId = req.organizationId;
      if (!userId || !orgId) return res.status(403).json({ message: 'Forbidden' });
      const permissions = await getUserPermissions(userId, orgId);
      const hasPermission = requiredPermissions.some(p => permissions.includes(p));
      if (!hasPermission) return res.status(403).json({ message: 'Forbidden: insufficient permissions' });
      next();
    } catch (e) {
      console.error('Authorization check error:', e);
      return res.status(500).json({ message: 'Authorization error' });
    }
  };
};

export const authorizeGlobalAdmin = (requiredPermissions) => {
  return async (req, res, next) => {
    try {
      const userId = req.user && req.user.id;
      if (!userId) return res.status(403).json({ message: 'Forbidden' });
      
      // Check if user is admin in ANY organization
      const adminRole = await prisma.userOrganization.findFirst({
        where: {
          userId,
          role: 'ADMIN'
        },
        include: { userRole: true }
      });
      
      if (!adminRole) return res.status(403).json({ message: 'Forbidden: must be admin in at least one organization' });
      
      // Check permissions from the admin role
      const permissions = (adminRole.userRole?.permissions || []).map(p => typeof p === 'string' ? p : String(p));
      
      // If user is ADMIN, allow them (ADMIN has all permissions)
      if (adminRole.role === 'ADMIN') {
        return next();
      }
      
      const hasPermission = requiredPermissions.some(p => permissions.includes(p));
      if (!hasPermission) return res.status(403).json({ message: 'Forbidden: insufficient permissions' });
      next();
    } catch (e) {
      console.error('Global authorization check error:', e);
      return res.status(500).json({ message: 'Authorization error' });
    }
  };
};

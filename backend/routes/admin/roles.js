import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';
import { createActivityLogEntry } from '../../services/activityService.js';
import { normalizeRoleType, normalizePermissionsArray } from '../../lib/permissions.js';

const router = express.Router();

// Apply middleware to all routes in this router
router.use(authenticateToken);
router.use(requireOrganization);

// GET / - List roles for an organization
router.get('/', async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
    
    const total = await prisma.userRole.count({ 
      where: { organizationId: req.organizationId } 
    });
    
    let roles = await prisma.userRole.findMany({ 
      where: { organizationId: req.organizationId }, 
      skip: (page - 1) * limit, 
      take: limit, 
      orderBy: { createdAt: 'desc' } 
    });
    
    roles = roles.map(r => ({ 
      ...r, 
      permissions: (r.permissions || []).map(p => String(p).toLowerCase()) 
    }));
    
    return res.json({ 
      roles, 
      pagination: { 
        page, 
        limit, 
        total, 
        totalPages: Math.ceil(total / limit), 
        hasNext: page * limit < total, 
        hasPrev: page > 1 
      } 
    });
  } catch (err) {
    console.error('List roles error:', err);
    res.status(500).json({ message: err.message });
  }
});

// POST / - Create a new role
router.post('/', authorize(['MANAGE_ROLES']), async (req, res) => {
  try {
    const { name, description, roleType, permissions, isDefault, isActive } = req.body;
    if (!name) return res.status(400).json({ message: 'Name is required' });
    
    const normalizedRoleType = normalizeRoleType(roleType);
    if (!normalizedRoleType) return res.status(400).json({ message: 'Invalid roleType' });
    
    const perms = normalizePermissionsArray(permissions);
    if (perms === null) return res.status(400).json({ message: 'Invalid permissions array' });
    
    const created = await prisma.userRole.create({ 
      data: { 
        name, 
        description, 
        roleType: normalizedRoleType, 
        permissions: perms, 
        organizationId: req.organizationId, 
        isDefault: !!isDefault, 
        isActive: isActive !== false 
      } 
    });
    
    await createActivityLogEntry({ 
      action: 'ROLE_CREATED', 
      entityType: 'UserRole', 
      entityId: created.id, 
      description: `${req.user.email} created role ${created.name}`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });
    
    created.permissions = (created.permissions || []).map(p => String(p).toLowerCase());
    res.status(201).json(created);
  } catch (err) {
    console.error('Create role error:', err);
    res.status(500).json({ message: err.message });
  }
});

// PUT /:id - Update a role
router.put('/:id', authorize(['MANAGE_ROLES']), async (req, res) => {
  try {
    const id = req.params.id;
    const existing = await prisma.userRole.findUnique({ where: { id } });
    
    if (!existing || existing.organizationId !== req.organizationId) {
      return res.status(404).json({ message: 'Role not found' });
    }
    
    const data = {};
    if (req.body.name) data.name = req.body.name;
    if (req.body.description !== undefined) data.description = req.body.description;
    
    if (req.body.roleType) {
      const normalized = normalizeRoleType(req.body.roleType);
      if (!normalized) return res.status(400).json({ message: 'Invalid roleType' });
      data.roleType = normalized;
    }
    
    if (req.body.permissions !== undefined) {
      const perms2 = normalizePermissionsArray(req.body.permissions);
      if (perms2 === null) return res.status(400).json({ message: 'Invalid permissions array' });
      data.permissions = perms2;
    }
    
    if (req.body.isDefault !== undefined) data.isDefault = !!req.body.isDefault;
    if (req.body.isActive !== undefined) data.isActive = !!req.body.isActive;
    
    const updated = await prisma.userRole.update({ where: { id }, data });
    
    const oldValues = { 
      name: existing.name, 
      roleType: existing.roleType, 
      permissions: existing.permissions, 
      description: existing.description, 
      isDefault: existing.isDefault, 
      isActive: existing.isActive 
    };
    const newValues = { ...data };
    
    await createActivityLogEntry({ 
      action: 'ROLE_UPDATED', 
      entityType: 'UserRole', 
      entityId: updated.id, 
      description: `${req.user.email} updated role ${updated.name}`, 
      userId: req.user.id, 
      organizationId: req.organizationId, 
      metadata: { oldValues, newValues } 
    });
    
    res.json(updated);
  } catch (err) {
    console.error('Update role error:', err);
    res.status(500).json({ message: err.message });
  }
});

// DELETE /:id - Delete a role
router.delete('/:id', authorize(['MANAGE_ROLES']), async (req, res) => {
  try {
    const id = req.params.id;
    const existing = await prisma.userRole.findUnique({ where: { id } });
    
    if (!existing || existing.organizationId !== req.organizationId) {
      return res.status(404).json({ message: 'Role not found' });
    }
    
    if (existing.isDefault) {
      return res.status(400).json({ message: 'Cannot delete default role' });
    }
    
    await prisma.userRole.delete({ where: { id } });
    
    await createActivityLogEntry({ 
      action: 'ROLE_DELETED', 
      entityType: 'UserRole', 
      entityId: id, 
      description: `${req.user.email} deleted role ${existing.name}`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });
    
    res.json({ success: true });
  } catch (err) {
    console.error('Delete role error:', err);
    res.status(500).json({ message: err.message });
  }
});

export default router;

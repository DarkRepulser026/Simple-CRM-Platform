import express from 'express';
import path from 'path';
import fs from 'fs';
import multer from 'multer';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { getUserPermissions } from '../../middleware/permissions.js';

const router = express.Router();
const uploadsDir = path.join(process.cwd(), 'uploads');
const upload = multer({ dest: 'uploads/temp/' });

// Apply middleware
router.use(authenticateToken);
router.use(requireOrganization);

// POST / - Upload attachment
router.post('/', upload.single('file'), async (req, res) => {
  try {
    const { entityType, entityId } = req.body;
    if (!entityType || !entityId) return res.status(400).json({ message: 'entityType and entityId required' });
    if (!req.file) return res.status(400).json({ message: 'file is required' });

    const permissionMap = {
      ticket: 'CREATE_TICKETS',
      contact: 'CREATE_CONTACTS',
      lead: 'CREATE_LEADS',
      task: 'CREATE_TASKS',
      account: 'CREATE_CONTACTS'
    };
    const requiredPermission = permissionMap[entityType] || 'CREATE_TICKETS';
    const perms = await getUserPermissions(req.user.id, req.organizationId);
    if (!perms.includes(requiredPermission)) return res.status(403).json({ message: 'Forbidden' });

    const filename = req.file.originalname || req.file.filename;
    const targetDir = path.join(uploadsDir, req.organizationId);
    if (!fs.existsSync(targetDir)) fs.mkdirSync(targetDir, { recursive: true });
    const targetPath = path.join(targetDir, `${Date.now()}-${filename}`);
    fs.renameSync(req.file.path, targetPath);

    const url = `/uploads/${req.organizationId}/${path.basename(targetPath)}`;
    const saved = await prisma.attachment.create({
      data: {
        filename,
        mimeType: req.file.mimetype,
        url,
        size: req.file.size,
        uploadedBy: req.user.id,
        organizationId: req.organizationId,
        entityType,
        entityId,
      }
    });
    res.status(201).json(saved);
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ message: error.message });
  }
});

// GET / - List attachments
router.get('/', async (req, res) => {
  try {
    const { entityType, entityId } = req.query;
    if (!entityType || !entityId) return res.status(400).json({ message: 'entityType and entityId required' });
    
    const permissionMap = {
      ticket: 'VIEW_TICKETS',
      contact: 'VIEW_CONTACTS',
      lead: 'VIEW_LEADS',
      task: 'VIEW_TASKS',
      account: 'VIEW_CONTACTS'
    };
    const requiredPermission = permissionMap[entityType] || 'VIEW_TICKETS';
    const perms = await getUserPermissions(req.user.id, req.organizationId);
    if (!perms.includes(requiredPermission)) return res.status(403).json({ message: 'Forbidden' });

    const attachments = await prisma.attachment.findMany({
      where: { entityType: String(entityType), entityId: String(entityId), organizationId: req.organizationId }
    });
    res.json(attachments);
  } catch (error) {
    console.error('List attachments error:', error);
    res.status(500).json({ message: error.message });
  }
});

// GET /:id - Get metadata
router.get('/:id', async (req, res) => {
  try {
    const att = await prisma.attachment.findUnique({ where: { id: req.params.id } });
    if (!att) return res.status(404).json({ message: 'Not found' });
    if (att.organizationId !== req.organizationId) return res.status(403).json({ message: 'Forbidden' });
    res.json(att);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /:id/download - Download file
router.get('/:id/download', async (req, res) => {
  try {
    const att = await prisma.attachment.findUnique({ where: { id: req.params.id } });
    if (!att) return res.status(404).json({ message: 'Not found' });
    if (att.organizationId !== req.organizationId) return res.status(403).json({ message: 'Forbidden' });
    
    const filePath = path.join(uploadsDir, att.organizationId, path.basename(att.url));
    if (!fs.existsSync(filePath)) return res.status(404).json({ message: 'file not found' });
    res.sendFile(filePath);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

export default router;

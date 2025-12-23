import express from 'express';
import bcrypt from 'bcryptjs';
import prisma from '../../lib/prismaClient.js';
import { requireCustomer } from '../../lib/customerMiddleware.js';

const router = express.Router();

// Apply middleware
router.use(requireCustomer);

// GET / - Get customer profile
router.get('/', async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      include: { customerProfile: true }
    });

    if (!user) return res.status(404).json({ error: 'User not found' });

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      type: user.type,
      profile: user.customerProfile
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to retrieve profile' });
  }
});

// PUT / - Update customer profile
router.put('/', async (req, res) => {
  try {
    const { name, phone, companyName, address, city, state, postalCode, country } = req.body;

    if (name) {
      await prisma.user.update({
        where: { id: req.userId },
        data: { name }
      });
    }

    const profileData = {};
    if (phone !== undefined) profileData.phone = phone;
    if (companyName !== undefined) profileData.companyName = companyName;
    if (address !== undefined) profileData.address = address;
    if (city !== undefined) profileData.city = city;
    if (state !== undefined) profileData.state = state;
    if (postalCode !== undefined) profileData.postalCode = postalCode;
    if (country !== undefined) profileData.country = country;

    if (Object.keys(profileData).length > 0) {
      await prisma.customerProfile.upsert({
        where: { userId: req.userId },
        create: { userId: req.userId, ...profileData },
        update: profileData
      });
    }

    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      include: { customerProfile: true }
    });

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      type: user.type,
      profile: user.customerProfile
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// PUT /password - Change password
router.put('/password', async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Current password and new password are required' });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ error: 'New password must be at least 8 characters long' });
    }

    const user = await prisma.user.findUnique({ where: { id: req.userId } });
    if (!user || !user.passwordHash) {
      return res.status(400).json({ error: 'Cannot change password for this account' });
    }

    const isPasswordValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    const salt = await bcrypt.genSalt(10);
    const newPasswordHash = await bcrypt.hash(newPassword, salt);

    await prisma.user.update({
      where: { id: req.userId },
      data: {
        passwordHash: newPasswordHash,
        tokenVersion: { increment: 1 }
      }
    });

    res.json({ success: true, message: 'Password changed successfully. Please log in again.' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Failed to change password' });
  }
});

// GET /tickets-summary - Get tickets summary
router.get('/tickets-summary', async (req, res) => {
  try {
    const [totalCount, openCount, resolvedCount, closedCount] = await Promise.all([
      prisma.ticket.count({ where: { customerId: req.userId } }),
      prisma.ticket.count({ where: { customerId: req.userId, status: 'OPEN' } }),
      prisma.ticket.count({ where: { customerId: req.userId, status: 'RESOLVED' } }),
      prisma.ticket.count({ where: { customerId: req.userId, status: 'CLOSED' } })
    ]);

    res.json({
      totalCount,
      openCount,
      resolvedCount,
      closedCount,
      inProgressCount: totalCount - openCount - resolvedCount - closedCount
    });
  } catch (error) {
    console.error('Get tickets summary error:', error);
    res.status(500).json({ error: 'Failed to retrieve tickets summary' });
  }
});

export default router;

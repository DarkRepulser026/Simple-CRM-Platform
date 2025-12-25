import { expect } from 'chai';
import { normalizePermissionsArray, normalizeRoleType, getUserPermissions, ALLOWED_PERMISSIONS } from '../../lib/permissions.js';

describe('Permissions helpers unit tests', function() {
  describe('normalizePermissionsArray', function() {
    it('returns [] for undefined or null', function() {
      expect(normalizePermissionsArray(undefined)).to.deep.equal([]);
      expect(normalizePermissionsArray(null)).to.deep.equal([]);
    });

    it('normalizes and validates permission strings', function() {
      const input = ['view_contacts', 'create-contacts', 'EDIT Contacts'];
      const out = normalizePermissionsArray(input);
      expect(out).to.include('VIEW_CONTACTS');
      expect(out).to.include('CREATE_CONTACTS');
      expect(out).to.include('EDIT_CONTACTS');
    });

    it('returns null if invalid permissions present', function() {
      const res = normalizePermissionsArray(['VIEW_CONTACTS', 'NONSENSE_PERMISSION']);
      expect(res).to.equal(null);
    });
  });

  describe('normalizeRoleType', function() {
    it('normalizes various role input to allowed types', function() {
      expect(normalizeRoleType('admin')).to.equal('ADMIN');
      expect(normalizeRoleType('Manager')).to.equal('MANAGER');
      expect(normalizeRoleType('agENT')).to.equal('AGENT');
      expect(normalizeRoleType(' viewer ')).to.equal('VIEWER');
    });

    it('returns null for invalid role', function() {
      expect(normalizeRoleType('helLo')).to.equal(null);
      expect(normalizeRoleType('')).to.equal(null);
      expect(normalizeRoleType(null)).to.equal(null);
    });
  });

  describe('getUserPermissions (unit with mock prisma client)', function() {
    it('returns [] when user not in org', async function() {
      const prismaMock = {
        userOrganization: { findFirst: async () => null },
        userRole: { findFirst: async () => null }
      };
      const perms = await getUserPermissions(prismaMock, 'notfound', 'org1');
      expect(perms).to.deep.equal([]);
    });

    it('returns role permissions when present', async function() {
      const prismaMock = {
        userOrganization: { findFirst: async ({ where }) => ({ userId: where.userId, organizationId: where.organizationId, role: 'AGENT' }) },
        userRole: { findFirst: async ({ where }) => ({ permissions: ['VIEW_CONTACTS', 'CREATE_CONTACTS'] }) }
      };
      const perms = await getUserPermissions(prismaMock, 'user1', 'org1');
      expect(perms).to.include('VIEW_CONTACTS');
      expect(perms).to.include('CREATE_CONTACTS');
    });

    it('returns [] when user role has no permissions', async function() {
      const prismaMock = {
        userOrganization: { findFirst: async ({ where }) => ({ userId: where.userId, organizationId: where.organizationId, role: 'AGENT' }) },
        userRole: { findFirst: async ({ where }) => ({ permissions: [] }) }
      };
      const perms = await getUserPermissions(prismaMock, 'user1', 'org1');
      expect(perms).to.deep.equal([]);
    });
  });
});

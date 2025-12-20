/**
 * Organization Matcher
 * Auto-matches customers to organizations based on email domain
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Extract domain from email address
 * @param {string} email - Email address
 * @returns {string} - Domain part of email
 */
function extractDomain(email) {
  if (!email || !email.includes('@')) {
    return null;
  }
  return email.split('@')[1].toLowerCase();
}

/**
 * Check if email domain is a generic/public domain
 * @param {string} domain - Email domain
 * @returns {boolean} - True if generic domain
 */
function isGenericDomain(domain) {
  const genericDomains = [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'icloud.com',
    'aol.com',
    'protonmail.com',
    'mail.com',
    'zoho.com',
    'yandex.com',
    'gmx.com',
    'live.com',
    'msn.com',
  ];
  return genericDomains.includes(domain.toLowerCase());
}

/**
 * Find organization by email domain
 * @param {string} email - Customer email address
 * @returns {Promise<Object|null>} - Organization object or null
 */
async function findOrganizationByEmail(email) {
  const domain = extractDomain(email);
  
  if (!domain || isGenericDomain(domain)) {
    return null;
  }

  try {
    // Find active domain mapping with auto-assign enabled
    const domainMapping = await prisma.organizationDomain.findFirst({
      where: {
        domain: domain,
        isActive: true,
        autoAssign: true,
      },
      include: {
        organization: true,
      },
      orderBy: {
        priority: 'desc', // Higher priority first
      },
    });

    if (domainMapping && domainMapping.organization.isActive) {
      return domainMapping.organization;
    }

    // Fallback: Check if Organization.domain matches (for backward compatibility)
    const organization = await prisma.organization.findFirst({
      where: {
        domain: domain,
        isActive: true,
      },
    });

    return organization;
  } catch (error) {
    console.error('Error finding organization by domain:', error);
    return null;
  }
}

/**
 * Find organization by company name (fuzzy match)
 * @param {string} companyName - Company name from customer registration
 * @returns {Promise<Object|null>} - Organization object or null
 */
async function findOrganizationByName(companyName) {
  if (!companyName || companyName.trim().length < 3) {
    return null;
  }

  try {
    // Exact match first
    let organization = await prisma.organization.findFirst({
      where: {
        name: {
          equals: companyName,
          mode: 'insensitive',
        },
        isActive: true,
      },
    });

    // If no exact match, try contains
    if (!organization) {
      organization = await prisma.organization.findFirst({
        where: {
          name: {
            contains: companyName,
            mode: 'insensitive',
          },
          isActive: true,
        },
      });
    }

    return organization;
  } catch (error) {
    console.error('Error finding organization by name:', error);
    return null;
  }
}

/**
 * Auto-match customer to organization
 * @param {string} email - Customer email
 * @param {string} companyName - Customer company name (optional)
 * @returns {Promise<Object|null>} - Matched organization or null
 */
async function autoMatchOrganization(email, companyName = null) {
  // Try domain matching first (most accurate)
  let organization = await findOrganizationByEmail(email);

  // If no domain match and company name provided, try name matching
  if (!organization && companyName) {
    organization = await findOrganizationByName(companyName);
  }

  return organization;
}

/**
 * Assign customer to organization
 * @param {string} userId - Customer user ID
 * @param {string} organizationId - Organization ID
 * @param {string} assignedBy - Admin user ID who assigned
 * @returns {Promise<Object>} - Updated customer profile
 */
async function assignCustomerToOrganization(userId, organizationId, assignedBy = null) {
  try {
    const customerProfile = await prisma.customerProfile.update({
      where: { userId },
      data: {
        organizationId,
        assignedAt: new Date(),
        assignedBy,
      },
      include: {
        user: true,
        organization: true,
      },
    });

    // Log the assignment
    if (organizationId) {
      await prisma.activityLog.create({
        data: {
          action: 'CUSTOMER_ASSIGNED',
          entityType: 'CustomerProfile',
          entityId: customerProfile.id,
          description: `Customer ${customerProfile.user.name} assigned to organization ${customerProfile.organization?.name || organizationId}`,
          userId: assignedBy,
          organizationId,
          metadata: {
            customerId: userId,
            customerEmail: customerProfile.user.email,
          },
        },
      });
    }

    return customerProfile;
  } catch (error) {
    console.error('Error assigning customer to organization:', error);
    throw error;
  }
}

/**
 * Get unassigned customers (no organization)
 * @returns {Promise<Array>} - Array of unassigned customer profiles
 */
async function getUnassignedCustomers() {
  try {
    return await prisma.customerProfile.findMany({
      where: {
        organizationId: null,
        isActive: true,
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
            createdAt: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  } catch (error) {
    console.error('Error getting unassigned customers:', error);
    throw error;
  }
}

/**
 * Get customers by organization
 * @param {string} organizationId - Organization ID
 * @returns {Promise<Array>} - Array of customer profiles
 */
async function getCustomersByOrganization(organizationId) {
  try {
    return await prisma.customerProfile.findMany({
      where: {
        organizationId,
        isActive: true,
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
            createdAt: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  } catch (error) {
    console.error('Error getting customers by organization:', error);
    throw error;
  }
}

/**
 * Get all domain mappings for an organization
 * @param {string} organizationId - Organization ID
 * @returns {Promise<Array>} - Array of domain mappings
 */
async function getOrganizationDomains(organizationId) {
  try {
    return await prisma.organizationDomain.findMany({
      where: { organizationId },
      orderBy: { priority: 'desc' },
    });
  } catch (error) {
    console.error('Error getting organization domains:', error);
    throw error;
  }
}

/**
 * Get all active auto-assign domain mappings
 * @returns {Promise<Array>} - Array of active domain mappings with organizations
 */
async function getActiveAutoAssignDomains() {
  try {
    return await prisma.organizationDomain.findMany({
      where: {
        isActive: true,
        autoAssign: true,
      },
      include: {
        organization: {
          select: {
            id: true,
            name: true,
            isActive: true,
          },
        },
      },
      orderBy: [
        { priority: 'desc' },
        { domain: 'asc' },
      ],
    });
  } catch (error) {
    console.error('Error getting active auto-assign domains:', error);
    throw error;
  }
}

module.exports = {
  extractDomain,
  isGenericDomain,
  findOrganizationByEmail,
  findOrganizationByName,
  autoMatchOrganization,
  assignCustomerToOrganization,
  getUnassignedCustomers,
  getCustomersByOrganization,
  getOrganizationDomains,
  getActiveAutoAssignDomains,
};

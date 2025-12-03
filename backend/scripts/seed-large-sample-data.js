import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';
import { findOrCreateDefaultOrgAndUser } from '../lib/db.js';

dotenv.config();

const DEFAULTS = {
  USERS: parseInt(process.env.SEED_USERS || '50', 10),
  CONTACTS: parseInt(process.env.SEED_CONTACTS || '500', 10),
  LEADS: parseInt(process.env.SEED_LEADS || '500', 10),
  TASKS: parseInt(process.env.SEED_TASKS || '1000', 10),
  TICKETS: parseInt(process.env.SEED_TICKETS || '300', 10),
  TICKET_MESSAGES: parseInt(process.env.SEED_TICKET_MESSAGES || '800', 10),
  ATTACHMENTS: parseInt(process.env.SEED_ATTACHMENTS || '200', 10)
};

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randFromArray(arr) {
  return arr[randInt(0, arr.length - 1)];
}

const firstNames = ['Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Faiza', 'Grace', 'Heidi', 'Ivy', 'Jack', 'Ken', 'Liam', 'Mia', 'Noah', 'Olivia', 'Paul', 'Quinn', 'Rita', 'Steve', 'Tina', 'Uma', 'Victor'];
const lastNames = ['Smith', 'Jones', 'Brown', 'Davis', 'Wilson', 'Taylor', 'Anderson', 'Thomas', 'Jackson', 'White', 'Harris', 'Martin'];
const domains = ['example.com', 'acme.example', 'beta.example', 'demo.org'];
const streets = ['Main St', 'Market St', 'Broadway', 'First Ave'];

async function createUsers(orgId, count) {
  // create many users
  const emails = [];
  const usersData = [];
  for (let i = 0; i < count; i++) {
    const first = randFromArray(firstNames);
    const last = randFromArray(lastNames);
    const email = `${first.toLowerCase()}.${last.toLowerCase()}.${i}@${randFromArray(domains)}`;
    emails.push(email);
    usersData.push({ email, name: `${first} ${last}` });
  }
  // insert skipping duplicates
  await prisma.user.createMany({ data: usersData, skipDuplicates: true });
  const users = await prisma.user.findMany({ where: { email: { in: emails } } });
  return users;
}

async function createUserOrganizations(orgId, users) {
  const data = users.map(u => ({ userId: u.id, organizationId: orgId, role: 'VIEWER' }));
  const batchSize = 1000;
  for (let i = 0; i < data.length; i += batchSize) {
    const chunk = data.slice(i, i + batchSize);
    try {
      await prisma.userOrganization.createMany({ data: chunk, skipDuplicates: true });
    } catch (err) {
      // If two processes create the same join entries concurrently, skip errors
      console.warn('createMany userOrganization chunk failed, falling back to single inserts', err.message);
      for (const d of chunk) {
        try {
          await prisma.userOrganization.create({ data: d });
        } catch (err2) {
          // ignore duplicates or other errors
        }
      }
    }
  }
}

async function createAccounts(orgId) {
  const data = [
    { name: 'Acme Inc', type: 'Customer', website: 'https://acme.example', organizationId: orgId },
    { name: 'Beta LLC', type: 'Partner', website: 'https://beta.example', organizationId: orgId },
    { name: 'Gamma Co', type: 'Customer', website: 'https://gamma.example', organizationId: orgId }
  ];
  await prisma.account.createMany({ data, skipDuplicates: true });
  const accounts = await prisma.account.findMany({ where: { organizationId: orgId } });
  return accounts;
}

async function createContacts(orgId, ownerIds, count) {
  const contactData = [];
  for (let i = 0; i < count; i++) {
    const first = randFromArray(firstNames);
    const last = randFromArray(lastNames);
    const email = `${first.toLowerCase()}.${last.toLowerCase()}.${i}@contacts.${randFromArray(domains)}`;
    const ownerId = randFromArray(ownerIds);
    contactData.push({
      firstName: first,
      lastName: last,
      email,
      phone: `+1-555-${randInt(1000, 9999)}`,
      street: `${randInt(10, 999)} ${randFromArray(streets)}`,
      city: 'Metropolis',
      state: 'CA',
      postalCode: `9${randInt(10000, 99999)}`,
      ownerId,
      organizationId: orgId
    });
  }
  // create in batches to avoid massive single insertion
  const batchSize = 1000;
  for (let i = 0; i < contactData.length; i += batchSize) {
    const chunk = contactData.slice(i, i + batchSize);
    await prisma.contact.createMany({ data: chunk, skipDuplicates: true });
  }
  const contacts = await prisma.contact.findMany({ where: { organizationId: orgId } });
  return contacts;
}

async function createLeads(orgId, ownerIds, count) {
  const leadData = [];
  for (let i = 0; i < count; i++) {
    const first = randFromArray(firstNames);
    const last = randFromArray(lastNames);
    const email = `${first.toLowerCase()}.${last.toLowerCase()}.${i}@leads.${randFromArray(domains)}`;
    const ownerId = randFromArray(ownerIds);
    leadData.push({
      firstName: first,
      lastName: last,
      email,
      phone: `+1-555-${randInt(1000, 9999)}`,
      company: `Company-${randInt(1, 200)}`,
      ownerId,
      organizationId: orgId
    });
  }
  const batchSize = 1000;
  for (let i = 0; i < leadData.length; i += batchSize) {
    const chunk = leadData.slice(i, i + batchSize);
    await prisma.lead.createMany({ data: chunk, skipDuplicates: true });
  }
  const leads = await prisma.lead.findMany({ where: { organizationId: orgId } });
  return leads;
}

async function createTasks(orgId, ownerIds, createdByIds, contactIds, leadIds, accountIds, count) {
  const taskData = [];
  const priorities = ['HIGH', 'NORMAL', 'LOW'];
  const statuses = ['NOT_STARTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
  for (let i = 0; i < count; i++) {
    const subject = `Task ${i + 1} - ${randFromArray(['Follow up', 'Call', 'Email', 'Schedule meeting'])}`;
    const ownerId = randFromArray(ownerIds);
    const createdById = randFromArray(createdByIds);
    const linkType = randInt(0, 2);
    let contactId = null;
    let leadId = null;
    let accountId = null;
    if (linkType === 0 && contactIds.length > 0) contactId = randFromArray(contactIds);
    if (linkType === 1 && leadIds.length > 0) leadId = randFromArray(leadIds);
    if (linkType === 2 && accountIds.length > 0) accountId = randFromArray(accountIds);

    let dueDate = null;
    if (Math.random() > 0.7) {
      dueDate = new Date(Date.now() + randInt(1, 30) * 24 * 60 * 60 * 1000);
    }
    taskData.push({
      subject,
      description: `${subject} — generated for pagination testing`,
      status: randFromArray(statuses),
      priority: randFromArray(priorities),
      dueDate,
      ownerId,
      createdById,
      contactId,
      leadId,
      accountId,
      organizationId: orgId
    });
  }
  const batchSize = 500;
  for (let i = 0; i < taskData.length; i += batchSize) {
    const chunk = taskData.slice(i, i + batchSize);
    await prisma.task.createMany({ data: chunk, skipDuplicates: true });
  }
  const tasks = await prisma.task.findMany({ where: { organizationId: orgId } });
  return tasks;
}

async function createTickets(orgId, ownerIds, count) {
  const ticketData = [];
  const priorities = ['LOW', 'NORMAL', 'HIGH', 'URGENT'];
  const statuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
  for (let i = 0; i < count; i++) {
    const subject = `Ticket ${i + 1} - ${randFromArray(['Login issue', 'Bug report', 'Feature request', 'Billing'])}`;
    const ownerId = randFromArray(ownerIds);
    ticketData.push({
      subject,
      description: `Automatically generated ticket ${i + 1}`,
      status: randFromArray(statuses),
      priority: randFromArray(priorities),
      ownerId,
      organizationId: orgId
    });
  }
  const batchSize = 500;
  for (let i = 0; i < ticketData.length; i += batchSize) {
    const chunk = ticketData.slice(i, i + batchSize);
    await prisma.ticket.createMany({ data: chunk, skipDuplicates: true });
  }
  const tickets = await prisma.ticket.findMany({ where: { organizationId: orgId } });
  return tickets;
}

async function createTicketMessages(tickets, authorIds, count) {
  // create some messages distributed among tickets
  const msgData = [];
  for (let i = 0; i < count; i++) {
    const ticket = randFromArray(tickets);
    const authorId = randFromArray(authorIds);
    msgData.push({
      ticketId: ticket.id,
      authorId,
      content: `Auto message ${i + 1} for ticket ${ticket.id}`
    });
  }
  const batchSize = 1000;
  for (let i = 0; i < msgData.length; i += batchSize) {
    const chunk = msgData.slice(i, i + batchSize);
    await prisma.ticketMessage.createMany({ data: chunk });
  }
  const messages = await prisma.ticketMessage.findMany({ where: { ticketId: { in: tickets.map(t => t.id) } } });
  return messages;
}

async function createAttachments(orgId, userIds, contactIds, leadIds, ticketIds, count) {
  const attachData = [];
  const entityOptions = [];
  if (contactIds.length) entityOptions.push('Contact');
  if (leadIds.length) entityOptions.push('Lead');
  if (ticketIds.length) entityOptions.push('Ticket');

  for (let i = 0; i < count; i++) {
    const uploadedBy = randFromArray(userIds);
    const entityType = randFromArray(entityOptions);
    let entityId = null;
    if (entityType === 'Contact') entityId = randFromArray(contactIds);
    if (entityType === 'Lead') entityId = randFromArray(leadIds);
    if (entityType === 'Ticket') entityId = randFromArray(ticketIds);
    attachData.push({
      filename: `file-${i + 1}.txt`,
      mimeType: 'text/plain',
      url: `https://example.com/files/file-${i + 1}.txt`,
      size: randInt(100, 10000),
      uploadedBy,
      entityType,
      entityId,
      organizationId: orgId
    });
  }
  const batchSize = 1000;
  for (let i = 0; i < attachData.length; i += batchSize) {
    const chunk = attachData.slice(i, i + batchSize);
    await prisma.attachment.createMany({ data: chunk });
  }
  const attachments = await prisma.attachment.findMany({ where: { organizationId: orgId } });
  return attachments;
}

async function createActivityLogs(orgId, userIds, count) {
  const actData = [];
  for (let i = 0; i < count; i++) {
    actData.push({
      action: `ACTION_${randInt(1, 10)}`,
      entityType: 'AUTOGEN',
      entityId: `${randInt(1000, 99999)}`,
      description: `Autogen activity ${i + 1}`,
      userId: randFromArray(userIds),
      organizationId: orgId
    });
  }
  const batchSize = 1000;
  for (let i = 0; i < actData.length; i += batchSize) {
    const chunk = actData.slice(i, i + batchSize);
    await prisma.activityLog.createMany({ data: chunk });
  }
  const logs = await prisma.activityLog.findMany({ where: { organizationId: orgId } });
  return logs;
}

async function main() {
  try {
    console.log('Starting large seeding process...');
    const { org, user } = await findOrCreateDefaultOrgAndUser();
    const orgId = process.env.ORG_ID || org.id;
    console.log('Target org id:', orgId);

    // 1) Create users
    const users = await createUsers(orgId, DEFAULTS.USERS);
    const userIds = users.map(u => u.id);
    // ensure the main admin is in list
    const admin = user;
    if (!userIds.includes(admin.id)) userIds.push(admin.id);
    // Add all created users to the organization
    await createUserOrganizations(orgId, users);

    // 2) Create accounts
    const accounts = await createAccounts(orgId);
    const accountIds = accounts.map(a => a.id);

    // 3) Create contacts
    const contacts = await createContacts(orgId, userIds, DEFAULTS.CONTACTS);
    const contactIds = contacts.map(c => c.id);

    // 4) Create leads
    const leads = await createLeads(orgId, userIds, DEFAULTS.LEADS);
    const leadIds = leads.map(l => l.id);

    // 5) Create tasks
    const tasks = await createTasks(orgId, userIds, userIds, contactIds, leadIds, accountIds, DEFAULTS.TASKS);

    // 6) Create tickets
    const tickets = await createTickets(orgId, userIds, DEFAULTS.TICKETS);
    const ticketIds = tickets.map(t => t.id);

    // 7) Create ticket messages
    const messages = await createTicketMessages(tickets, userIds, DEFAULTS.TICKET_MESSAGES);

    // 8) Create attachments
    const attachments = await createAttachments(orgId, userIds, contactIds, leadIds, ticketIds, DEFAULTS.ATTACHMENTS);

    // 9) Activity logs
    const logs = await createActivityLogs(orgId, userIds, 400);

    console.log('Large seed complete: ', {
      users: users.length,
      accounts: accounts.length,
      contacts: contacts.length,
      leads: leads.length,
      tasks: DEFAULTS.TASKS,
      tickets: tickets.length,
      ticketMessages: messages.length,
      attachments: attachments.length,
      activityLogs: logs.length
    });
  } catch (err) {
    console.error('Error in large seed process:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();

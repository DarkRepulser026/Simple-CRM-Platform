import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

let transporter = null;

// Mail driver choices: 'smtp' (default), 'console' (no-op), or 'ses-smtp' (AWS SES via SMTP interface)
const MAIL_DRIVER = (process.env.MAIL_DRIVER || 'smtp').toLowerCase();

if (MAIL_DRIVER === 'console') {
  transporter = null; // logging only
} else if ((MAIL_DRIVER === 'smtp' || MAIL_DRIVER === 'ses-smtp') && process.env.SMTP_HOST && process.env.SMTP_USER) {
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });
}

function _getFrom() {
  return process.env.MAIL_FROM || `no-reply@${process.env.APP_DOMAIN || 'example.com'}`;
}

const defaultAppName = process.env.APP_NAME || 'Our App';

export async function sendInviteEmail(to, link, role) {
  const from = _getFrom();
  const subject = `You're invited to join ${defaultAppName}`;
  const html = `
    <p>Hello,</p>
    <p>You have been invited to join ${defaultAppName} as <strong>${role}</strong>.</p>
    <p>Please click the link below to accept the invite:</p>
    <p><a href="${link}">${link}</a></p>
    <p>This link will expire in 48 hours.</p>
  `;
  const text = `You have been invited to join ${defaultAppName} as ${role}. Accept: ${link}`;

  if (!transporter) {
    console.log(`Sending invite (no SMTP): ${to} -> ${link}`);
    return Promise.resolve({ ok: true, debug: true });
  }
  return transporter.sendMail({ from, to, subject, html, text });
}

export async function sendWelcomeEmail(to, name, organizationName) {
  const from = _getFrom();
  const subject = `Welcome to ${defaultAppName}`;
  const html = `
    <p>Hello ${name || ''},</p>
    <p>Welcome to ${defaultAppName}${organizationName ? ` at ${organizationName}` : ''}.</p>
    <p>You can sign in at <a href="${process.env.APP_BASE_URL || 'http://localhost:3000'}">${process.env.APP_BASE_URL || 'http://localhost:3000'}</a>.</p>
    <p>Thanks,</p>
    <p>The ${defaultAppName} Team</p>
  `;
  const text = `Welcome to ${defaultAppName}. Sign in at ${process.env.APP_BASE_URL || 'http://localhost:3000'}`;

  if (!transporter) {
    console.log(`Sending welcome (no SMTP): ${to}`);
    return Promise.resolve({ ok: true, debug: true });
  }
  return transporter.sendMail({ from, to, subject, html, text });
}

export default { sendInviteEmail, sendWelcomeEmail };

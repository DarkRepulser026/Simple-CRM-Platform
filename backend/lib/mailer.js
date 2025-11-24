import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

let transporter = null;

if (process.env.SMTP_HOST && process.env.SMTP_USER) {
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

export async function sendInviteEmail(to, link, role) {
  const from = process.env.MAIL_FROM || 'no-reply@example.com';
  const subject = `You're invited to join ${process.env.APP_NAME || 'Our App'}`;
  const html = `
    <p>Hello,</p>
    <p>You have been invited to join ${process.env.APP_NAME || 'our app'} as <strong>${role}</strong>.</p>
    <p>Please click the link below to accept the invite:</p>
    <p><a href="${link}">${link}</a></p>
    <p>This link will expire in 48 hours.</p>
  `;

  if (!transporter) {
    // Fallback: log to console for dev
    console.log(`Sending invite (no SMTP configured): ${to} -> ${link}`);
    return Promise.resolve({ ok: true, debug: true });
  }

  return transporter.sendMail({ from, to, subject, html });
}

export default { sendInviteEmail };

import dotenv from 'dotenv';
dotenv.config();
import mailer from '../lib/mailer.js';

const to = process.env.TEST_MAIL_TO || process.argv[2];
if (!to) {
  console.error('Usage: node scripts/test-mail.js <to-email>\nor set TEST_MAIL_TO in .env');
  process.exit(1);
}

(async () => {
  try {
    console.log('Sending test invite...');
    const link = `${process.env.APP_BASE_URL || 'http://localhost:3000'}/test-link`;
    await mailer.sendInviteEmail(to, link, 'VIEWER');
    await mailer.sendWelcomeEmail(to, 'Test User', process.env.TEST_ORG_NAME || 'Test Org');
    console.log('Test emails sent (or logged).');
  } catch (err) {
    console.error('Error sending test emails:', err);
    process.exit(1);
  }
})();

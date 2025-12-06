# Backend API Server

A Node.js API server using Express.js and Prisma ORM with PostgreSQL.

## Features

- **Authentication**: JWT-based authentication with Google OAuth 2.0
- **Organizations**: Multi-tenant organization support
- **CRM Entities**: Complete CRUD for Contacts, Leads, Tasks, and Tickets
- **Dashboard**: Statistics and activity tracking
- **Database**: PostgreSQL with Prisma ORM

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Set up Google OAuth:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing one
   - Enable the Google+ API
   - Create OAuth 2.0 credentials (Client ID and Client Secret)
  - Add authorized redirect URI: `http://localhost:3001/auth/google/callback`

3. Configure environment variables:
   - Copy `.env.example` to `.env`
   - Fill in your Google OAuth credentials:
     ```
     GOOGLE_CLIENT_ID="your-client-id"
     GOOGLE_CLIENT_SECRET="your-client-secret"
     ```
   - Generate secure secrets for JWT and session:
     ```bash
     # Generate JWT secret (64 characters)
     openssl rand -base64 48

     # Generate session secret (32 characters)
     openssl rand -hex 32
     ```

4. Set up the database:
   - Ensure PostgreSQL is running, or start one with Docker Compose
   - Start database with Docker Compose (recommended for local dev):
     ```bash
     cd backend
     docker compose up -d
     # Confirm container is healthy
     docker compose ps
     ```
   - Update `DATABASE_URL` in `.env` if needed (default maps to `localhost:5433`)
   - Run migrations and generate Prisma client:
     ```bash
     # Recommended scripts
     npm run prisma:migrate
     npm run prisma:generate
     ```

5. Start the server:
   ```bash
   npm start
   # or for development
   npm run dev
   ```

  ## Health-check & automated server start test

  You can verify the server starts and the `/health` endpoint responds by running the built-in test helper. It starts the server in a child process, polls the `/health` endpoint and shuts the server down when it detects a healthy response.

  ```bash
  # Starts the server and polls /health; uses `node index.js` under the hood
  npm run server:test
  ```

## API Endpoints

### Authentication
- `GET /auth/google` - Initiate Google OAuth login
- `GET /auth/google/callback` - Google OAuth callback (handled automatically)
- `GET /auth/google/failure` - OAuth failure redirect
- `POST /auth/logout` - Logout
- `GET /auth/me` - Get current user information

### Organizations
## Prisma Client

The backend exposes a single Prisma Client instance that other files import from `backend/lib/prismaClient.js`.

Useful npm scripts are available in `backend/package.json` for migrations and generating the Prisma client:

- `npm run prisma:migrate` — applies migrations and updates the schema
- `npm run prisma:generate` — generates the Prisma Client
- `npm run prisma:studio` — launches Prisma Studio
- `npm run prisma:seed` — runs a seed script (`prisma/seed.js`) to populate initial data and creates debug test accounts
 - `npm run grant-admin -- ORG_ID=<orgId> ADMIN_EMAIL=<email>` — Grants full admin permissions for an org and assigns the user as admin (dev script)
 - `npm run seed-demo -- ORG_ID=<orgId> ADMIN_EMAIL=<email>` — Seeds sample accounts, contacts, leads, tasks, and tickets for the organization (dev script)
 - `npm run seed-large -- ORG_ID=<orgId> ADMIN_EMAIL=<email> [SEED_USERS=100 SEED_CONTACTS=1000 ...]` — Populates large volumes of sample data for pagination and performance testing. Supports env vars for counts: `SEED_USERS`, `SEED_CONTACTS`, `SEED_LEADS`, `SEED_TASKS`, `SEED_TICKETS`, `SEED_TICKET_MESSAGES`, `SEED_ATTACHMENTS`. Also creates test debug accounts.
 - `npm run seed-clean -- ORG_ID=<orgId> SEED_CLEAN_CONFIRM=<token> [KEEP_ORG=true]` — Wipes seeded test data for a given organization. This will delete accounts, contacts, leads, tasks, tickets, ticket messages, attachments, activity logs, user roles, invitations, and userOrganization entries for the targeted organization, and optionally delete the organization itself. By default the script keeps the `admin@example.com` user. Requires a safety confirmation token set via `SEED_CLEAN_CONFIRM` (see script output for the exact token). Use `KEEP_ORG=true` to preserve the organization record.

### Debug Test Accounts

When you run `npm run prisma:seed` or `npm run seed-large`, the following test accounts are automatically created with full permissions:

| Email | Password | Role | Permissions |
|-------|----------|------|-------------|
| `admin@example.com` | (mocked auth) | ADMIN | All permissions (26 total) |
| `manager@example.com` | (mocked auth) | MANAGER | Most permissions except org management (22 total) |
| `agent@example.com` | (mocked auth) | AGENT | Limited to daily operations (17 total) |
| `user@example.com` | (mocked auth) | VIEWER | Read-only access (5 total) |

These accounts are automatically granted permissions and linked to test roles with appropriate access levels. Use them for development and testing without needing to manually run `grant-admin` scripts.

## Using from other runtimes (e.g., Flutter `lib/`)

If you're building a Flutter client in the project's `lib/` folder, it communicates with this backend via HTTP API calls. Example Flutter snippet to fetch contacts:

```dart
// Example using `http` package
final response = await http.get(
  Uri.parse('http://localhost:3001/contacts'),
  headers: {
    'Authorization': 'Bearer <token>',
    'X-Organization-ID': '<orgId>'
  }
);
``` 

Prisma ORM works on the backend (Node.js) and isn't used directly in Flutter. Use the API endpoints above from `lib/`.

- `GET /organizations` - List user's organizations
- `POST /organizations` - Create new organization
- `GET /organizations/:id` - Get organization details
- `PUT /organizations/:id` - Update organization
- `DELETE /organizations/:id` - Delete organization

### Accounts
- `GET /accounts` - List accounts within the organization (requires X-Organization-ID)
- `POST /accounts` - Create an account (requires `CREATE_CONTACTS` permission)
- `GET /accounts/:id` - Get account details (requires `VIEW_CONTACTS` permission)
- `PUT /accounts/:id` - Update account (requires `EDIT_CONTACTS` permission)
- `DELETE /accounts/:id` - Delete account (requires `DELETE_CONTACTS` permission)

### Contacts
- `GET /contacts` - List contacts (requires X-Organization-ID header)
- `POST /contacts` - Create contact
- `GET /contacts/:id` - Get contact details
- `PUT /contacts/:id` - Update contact
- `DELETE /contacts/:id` - Delete contact

### Leads
- `GET /leads` - List leads
- `POST /leads` - Create lead
- `GET /leads/:id` - Get lead details
- `PUT /leads/:id` - Update lead
- `DELETE /leads/:id` - Delete lead

### Tasks
- `GET /tasks` - List tasks
- `POST /tasks` - Create task
- `GET /tasks/:id` - Get task details
- `PUT /tasks/:id` - Update task
- `DELETE /tasks/:id` - Delete task

### Tickets
- `GET /tickets` - List tickets
- `POST /tickets` - Create ticket
- `GET /tickets/:id` - Get ticket details
- `PUT /tickets/:id` - Update ticket
- `DELETE /tickets/:id` - Delete ticket
- `POST /tickets/:id/messages` - Add message to ticket
### Attachments
- `POST /attachments` - Upload attachment (multipart/form-data `file` + `entityType` + `entityId`) - Requires corresponding `CREATE_*` permission for the entity (ticket/lead/contact/task).
- `GET /attachments?entityType=<type>&entityId=<id>` - List attachments for an entity - Requires `VIEW_*` permission for that entity.
- `GET /attachments/:id` - Get attachment metadata
- `GET /attachments/:id/download` - Download attachment file

### Invitation Flow
- `POST /organizations/:id/invite` - Create a single-use invitation for an email and role (requires `MANAGE_USERS` permission). Body: `{ "email": "user@example.com", "role": "ADMIN" }`. Server saves hashed token and sends invite email (or logs invite link).
- `POST /invite/accept` - Accept an invite using token and optional name. Body: `{ "token": "<token>", "name": "Full Name" }`. Server verifies token, creates user if needed, associates them with the organization, grants the invited role, and returns a JWT and user info on success.
 - `GET /organizations/:id/invitations` - List pending invitations (requires `MANAGE_USERS` permission). Returns invites that are not accepted or revoked.
 - `POST /admin/invitations/:id/revoke` - Revoke an outstanding invitation (requires `MANAGE_USERS` permission). Marks the invite as revoked and prevents reuse. Logs activity for audit.
 - `POST /admin/view-as/:userId` - Admin impersonation (view-as). Returns a short-lived JWT token for the target user. Requires `MANAGE_USERS` permission and logs activity.
 - `POST /invite/accept` - Accept an invite using token and optional name. Body: `{ "token": "<token>", "name": "Full Name" }`. Server verifies token, creates user if needed, associates them with the organization, grants the invited role, and returns a JWT and user info on success. If the invited role is `ADMIN`, the server also sets an `httpOnly` cookie named `admin_session` containing the JWT to support admin session flows.

### Dashboard
- `GET /dashboard` - Get dashboard statistics

### Activity Logs
- `GET /activity_logs` - List activity/audit logs (requires `VIEW_AUDIT_LOGS` permission). Supports query parameters: `page`, `limit`, `entityType`, `entityId`, `userId`, `search`.

The response includes the following structure for each log:
- `id`, `activityType` (string), `description`, `userId`, `userName`, `entityId`, `entityType`, `entityName`, `organizationId`, `createdAt`
- `metadata` (JSON) — optional additional details
- `oldValues` and `newValues` — optional top-level fields that contain pre-update and post-update data (when available). These are also included under `metadata.oldValues` / `metadata.newValues`.

## Authentication

### Google OAuth Flow

1. **Initiate Login**: Redirect user to `GET /auth/google`
2. **Google Consent**: User grants permission on Google's site
3. **Callback**: Google redirects to `GET /auth/google/callback`
4. **Token Response**: Server returns JWT token and user info

### API Usage

All endpoints except `/auth/*` require:
- `Authorization: Bearer <jwt_token>` header
- `X-Organization-ID: <organization_id>` header (for organization-scoped endpoints)

### Example Login Flow

```javascript
// 1. Redirect user to Google OAuth
window.location.href = 'http://localhost:3000/auth/google';

// 2. After callback, you'll receive:
{
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "name": "User Name",
    "profileImage": "https://..."
  },
  "token": "jwt-token-here"
}

// 3. Use token for subsequent requests
fetch('/api/contacts', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'X-Organization-ID': 'org-id'
  }
});
```

## Testing

Run the database connection test:
```bash
node test-db.js
```

To run the full integration test suite (mocha):

```bash
cd backend
npm install
npm test
```

The tests will start the server in a child process, run a series of integration tests against the HTTP endpoints, and clean up created resources when possible.

## Environment Variables

- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret key for JWT tokens (generate with `openssl rand -base64 48`)
- `GOOGLE_CLIENT_ID` - Google OAuth client ID from Google Cloud Console
- `GOOGLE_CLIENT_SECRET` - Google OAuth client secret (keep secure!)
 - `GOOGLE_REDIRECT_URI` - OAuth callback URL (default: http://localhost:3001/auth/google/callback)
- `SESSION_SECRET` - Session secret for Passport (generate with `openssl rand -hex 32`)
- `PORT` - Server port (default: 3000)

### Email / SMTP / SES

- `MAIL_DRIVER` - How the app sends mail: `smtp` (default), `console` (do not send, logs only), or `ses-smtp` (use AWS SES via SMTP credentials). Default: `smtp`.
- `SMTP_HOST` - Hostname for SMTP (e.g. `smtp.sendgrid.net` or AWS SES SMTP endpoint like `email-smtp.us-east-1.amazonaws.com`).
- `SMTP_PORT` - SMTP port (default: `587`).
- `SMTP_SECURE` - `true` if using TLS on connect (465). If false, STARTTLS is used.
- `SMTP_USER` - SMTP username (for SES this is the SMTP user credentials, not IAM keys).
- `SMTP_PASS` - SMTP password.
- `MAIL_FROM` - "from" email address used for outgoing mail (default `no-reply@example.com`).
- `APP_BASE_URL` - The web app base URL used in invite links (default: `http://localhost:3000`).
- `SEND_WELCOME_EMAILS` - Set to `true` to automatically send a welcome email when an admin creates a user via the `POST /users` endpoint.

If you're using AWS SES, you can either use SES's SMTP interface (recommended for simplicity) and set the SMTP_* variables OR use the SES SMTP endpoint and credentials. SES SMTP credentials can be generated from the AWS console.

To test email sending locally without actual mail delivery, set `MAIL_DRIVER=console`.

## Security Notes

- Never commit `.env` file to version control
- Use strong, randomly generated secrets for JWT_SECRET and SESSION_SECRET
- Keep GOOGLE_CLIENT_SECRET secure and rotate periodically
- In production, use HTTPS and set secure cookies

## Database Schema

The API uses Prisma with the following main models:
- User, Organization, UserOrganization
- Contact, Lead, Task, Ticket, TicketMessage
- ActivityLog, UserRole, Permission

See `prisma/schema.prisma` for the complete schema.
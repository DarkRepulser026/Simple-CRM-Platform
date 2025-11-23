1) High-level architecture (web only)
Backend: Node.js + Express + Prisma + PostgreSQL

Frontend: Single-page app (Flutter Dart) served at https://app.example.com (customer) and https://admin.example.com (admin UI) — can be same domain/subdomain.

Auth:

Customers → OAuth (Google) → backend verifies tokens and issues customer JWT or session cookie.

Admins → Admins can be invited via `POST /organizations/:id/invite` (requires `MANAGE_USERS`). The server issues a single-use signed invite token which is sent by email (SMTP if configured). When the invite is accepted and the role is `ADMIN`, the server sets an `httpOnly` `admin_session` cookie (secure, sameSite) for the admin UI session and returns a JWT in JSON for API usage.

Admin actions use admin cookie; view-as returns read-only user data (no session switching). All admin writes use admin endpoints that record adminId in audit logs.

2) Customer OAuth (web) — recommended flow

Use authorization code flow with PKCE on the browser client.

Browser obtains code and sends it to backend POST /auth/oauth/callback with provider and code.

Backend exchanges code for tokens using client secret (server-only) and verifies the id_token signature via provider JWKS.

Backend upserts User + OAuthAccount, stores idTokenClaims (minimal), writes AuditLog: LOGIN_OAUTH, then issues customer session:

Option A (recommended for web): set cookie user_session (httpOnly, secure, samesite) and return redirect to app.

Option B: return JWT in JSON (less secure for web if stored in localStorage).

Important: Keep admin and user cookies separate (admin_session vs user_session) and on separate subdomains if you want strict isolation, e.g., admin.example.com vs app.example.com. Cookies scoped to subdomain avoid accidental overlap.

3) Front-end web UX notes

Admin UI

Login page: only email input + “Send magic link” button.

After clicking magic link, the browser is redirected to /admin with secure cookie set. Admin UI reads session implicitly on server API calls.

Always show a prominent banner when viewing-as: “Viewing as {user.email} — read-only”.

Admin action buttons (create ticket, reset password, etc.) call /admin/action/... endpoints — require admin cookies.

Customer UI

“Sign in with Google” button triggers PKCE auth; when finished, backend sets user_session cookie.


### Invitation Flow (current implementation)

- `POST /organizations/:id/invite` creates an invite token for a given email and role (requires `MANAGE_USERS`). The server stores a hashed token, expiry, and `createdBy` ID and sends an invitation email when SMTP is configured. If SMTP is not configured the invite link is logged to the console for development.
- `GET /organizations/:id/invitations` lists pending (not accepted & not revoked) invites for an organization (requires `MANAGE_USERS`).
- `POST /admin/invitations/:id/revoke` marks an outstanding invite as revoked and records an `INVITE_REVOKED` activity log (requires `MANAGE_USERS`).
- `POST /invite/accept` validates a single-use token, creates the user if necessary, associates them with the organization, and assigns the invited role. If the invited role is `ADMIN`, the server additionally sets an `httpOnly admin_session` cookie so the admin browser can be session-authenticated.
- The system supports token revocation via an integer `tokenVersion` on the `User` model; tokens include the `tokenVersion` and the server rejects tokens whose version no longer matches the DB record. The server increments `tokenVersion` when a user's role changes or when an admin revokes an invite impacting that user.
- Admins also have a `POST /admin/view-as/:userId` route that returns a short-lived JWT for the target user. The front-end supports `impersonateWithToken` and `stopImpersonation` flows to start and end impersonated sessions and logs `IMPERSONATION` events.
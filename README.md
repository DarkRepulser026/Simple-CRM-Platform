# Main Project - CRM Platform

A full-stack CRM application serving as a unified contact, lead, account, and ticket management system. The backend runs on Node.js/Express with PostgreSQL, while the frontend is built with Flutter and compiles to web, mobile, and desktop.

## Interesting Techniques

This project demonstrates several production-grade patterns:

- **[Token versioning for auth revocation](https://tools.ietf.org/html/rfc7519)**: Implements logout-all by incrementing a `tokenVersion` counter on the user record. [JWT](https://tools.ietf.org/html/rfc7519) payloads include this version, and the server validates it on each request. This allows instantaneous revocation of all sessions without token blacklists or cache management.

- **[Service locator pattern with lazy singletons](https://en.wikipedia.org/wiki/Service_locator_pattern)**: Uses `get_it` for dependency injection in Flutter. Services are registered as lazy singletons and initialized on-demand, keeping startup time fast while ensuring single instances throughout the app lifecycle.

- **[Platform-specific conditional compilation](https://dart.dev/guides/libraries/library-private-elements)**: Leverages Dart's `if (dart.library.html)` syntax to provide web-specific implementations (Google Sign-In) while maintaining a single codebase across Android, iOS, macOS, Windows, and Linux.

- **[Role-based access control with custom permissions](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)**: Defines custom roles per organization with granular permission assignment. The server checks both the user's role and the specific permissions before allowing operations.

- **[Rate limiting on authentication endpoints](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html#protect-against-brute-force-attacks)**: Uses `express-rate-limit` to cap failed login attempts to 5 per 15-minute window per IP, defending against credential stuffing.

- **[Material Design 3 theming with color seeding](https://material.io/blog/material-3-for-flutter)**: Generates a full Material Design color system from a single seed color, creating a cohesive, accessible design system across the entire Flutter app.

## Technologies & Libraries

**Backend:**
- [Express.js v5.1.0](https://expressjs.com/) — minimalist web framework
- [Prisma v6.18.0](https://www.prisma.io/) — type-safe ORM for PostgreSQL
- [Passport.js](http://www.passportjs.org/) — modular authentication; configured with Google OAuth 2.0
- [bcryptjs](https://www.npmjs.com/package/bcryptjs) — password hashing with salt rounds
- [jsonwebtoken (JWT)](https://www.npmjs.com/package/jsonwebtoken) — stateless auth tokens
- [express-rate-limit](https://www.npmjs.com/package/express-rate-limit) — middleware for rate limiting
- [Nodemailer](https://nodemailer.com/about/) — email delivery; used for invitations and notifications
- [Multer](https://www.npmjs.com/package/multer) — multipart file uploads
- Testing: Mocha, Chai, Supertest

**Frontend:**
- [Flutter SDK v3.8.1](https://flutter.dev) — cross-platform framework compiling to web, iOS, Android, macOS, Windows, Linux
- [Material Design 3](https://material.io/blog/material-3-for-flutter) — design system and components
- [get_it](https://pub.dev/packages/get_it) — service locator for dependency injection
- [google_sign_in](https://pub.dev/packages/google_sign_in) — OAuth 2.0 authentication
- [http](https://pub.dev/packages/http) — HTTP client for API calls
- [jwt_decoder](https://pub.dev/packages/jwt_decoder) — JWT token parsing
- [Font Awesome Flutter](https://pub.dev/packages/font_awesome_flutter) — icon library
- [fl_chart](https://pub.dev/packages/fl_chart) — charting and visualizations
- [file_picker](https://pub.dev/packages/file_picker) — native file selection
- [shared_preferences](https://pub.dev/packages/shared_preferences) — local persistent storage
- [intl](https://pub.dev/packages/intl) — internationalization and localization

## Project Structure

```
main_project/
├── backend/                          # Node.js/Express API server
│   ├── middleware/                   # Auth, permissions, validation, rate limiting
│   ├── routes/                       # Endpoint handlers (auth, CRM, tickets, admin)
│   ├── services/                     # Business logic and data operations
│   ├── prisma/                       # Database schema and migrations
│   └── scripts/                      # Utilities for seeding and management
├── lib/                              # Flutter source code
│   ├── screens/                      # UI screens (auth, dashboard, contacts, etc.)
│   ├── widgets/                      # Reusable UI components
│   ├── services/                     # API clients, auth, storage, domain logic
│   ├── navigation/                   # Routing and route guards
│   ├── models/                       # Data classes and serialization
│   └── utils/                        # Helpers and utilities
├── web/                              # Flutter web artifacts
├── android/, ios/, macos/, windows/, linux/  # Platform-specific code
├── pubspec.yaml                      # Flutter dependencies
├── package.json                      # Root-level npm scripts for coordination
└── ARCHITECTURE.md                   # Detailed system design documentation
```

**Key backend directories:**
- [middleware/](backend/middleware) — Auth token validation, permission checks, request validation, rate limiting
- [routes/auth/](backend/routes/auth) — Staff/customer login, Google OAuth, logout, token refresh, invitations
- [routes/crm/](backend/routes/crm) — Contacts, leads, accounts (ownership, soft-delete support)
- [routes/tickets/](backend/routes/tickets) — Support ticket lifecycle and messaging
- [prisma/](backend/prisma) — PostgreSQL schema, migration history, seed data scripts
- [services/](backend/services) — Shared business logic (activity logging, soft-delete operations)

**Key frontend directories:**
- [lib/screens/](lib/screens) — Full pages (LoginScreen, DashboardScreen, ContactsScreen, etc.)
- [lib/widgets/](lib/widgets) — Reusable components (ActivityLogWidget, RoleAssignmentWidget, PaginatedListView)
- [lib/services/](lib/services) — Dependency-injected services for API calls, authentication, domain operations
- [lib/navigation/](lib/navigation) — Route definitions and guards (e.g., requiring auth before dashboard)
- [lib/models/](lib/models) — Serializable data classes with JSON conversion

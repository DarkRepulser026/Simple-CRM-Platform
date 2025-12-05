# Running the Project (Dev)
## Prerequisites

- Node.js (v18+) and npm
- Flutter SDK (3.24.0+ recommended)
- Dart SDK (comes with Flutter)
- PostgreSQL instance (local or Docker)
- For Google OAuth: a valid Google OAuth `Client ID` and `Client Secret` configured in the backend `.env` and the authorized redirect URI: `http://localhost:3001/auth/google/callback` (backend server callback)

---

## 1) Start PostgreSQL (optional: Docker)

If you don't have a local Postgres instance, use Docker Compose from the `backend` directory. This only starts the database and related infrastructure; the backend app is started via `npm`.

Windows / PowerShell / macOS / Linux (if Docker is installed):

```bash
cd backend
# start the database in the background using Docker Compose
docker compose up -d
```

Then confirm the DB container is healthy:

```bash
docker compose ps
```

If you already have a local Postgres instance running, make sure `DATABASE_URL` in `backend/.env` points to it.

## 2) Start the backend server (Node)

Open a shell, then run the following from the `backend/` folder. The app listens on `PORT`, default 3000 — we recommend setting `PORT=3001` to avoid conflicts with the Flutter web dev server on 3000.

Windows (cmd.exe):

```bat
cd backend
npm install
set PORT=3001
npm run prisma:migrate
npm run prisma:generate
npm run prisma:seed
npm run seed-large
# start the server in dev mode (nodemon)
npm run dev:backend
```

Windows PowerShell:

```powershell
cd backend
npm install
$env:PORT = "3001"
npm run prisma:migrate
npm run prisma:generate
npm run prisma:seed
npm run seed-large
npm run dev:backend
```

macOS / Linux (bash / zsh):

```bash
cd backend
npm install
export PORT=3001
npm run prisma:migrate
npm run prisma:generate
npm run prisma:seed
npm run seed-large
npm run dev:backend
```

Optional: start the server without nodemon (production-like):

```bash
npm start
```

Verify the backend is running and responding by using the health endpoint or the built-in helper:

```bash
npm run server:test
# or use curl
curl http://localhost:3001/health
```

---

## 3) Start the Flutter Web App (using `flutter run`)

From the root of the repository (one directory up from `backend`), run:

```bash
flutter pub get
# Windows cmd.exe
flutter run -d chrome --web-port=3000

# Windows PowerShell
flutter run -d chrome --web-port=3000

# macOS / Linux
flutter run -d chrome --web-port=3000
```

Notes:
- `API_BASE_URL` is a compile-time constant (see `lib/services/api/api_config.dart`) and defaults to `http://localhost:3001` in development. Use `--dart-define` to override the backend host.
- `GOOGLE_CLIENT_ID` should match the `GOOGLE_CLIENT_ID` in your `backend/.env` (Google OAuth must be configured in the project console), or OAuth flows will fail.

---

## 4) Common workflows

Start backend (Node) and Flutter in two terminals:

Terminal 1: Backend

```bash
cd backend
npm install
set PORT=3001  # or export PORT=3001 for POSIX shells
npm run dev:backend
```

Terminal 2: Frontend

```bash
# from repo root
flutter pub get
flutter run -d chrome --web-port=3000
```

---

## 5) Troubleshooting & Tips

- If OAuth doesn't work, verify `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, and `GOOGLE_REDIRECT_URI` are correct in `backend/.env` and the redirect URI is whitelisted in Google Cloud Console.
- If the web client cannot hit the backend, check CORS and `API_BASE_URL`. The dev server uses `http://localhost:3001` by default.
- If you prefer to access the backend from a device on your network, set a host like `http://<your-ip>:3001` and update `API_BASE_URL` and `GOOGLE_REDIRECT_URI` accordingly.
- For a clean local dev reset, use the `backend` scripts to re-run migrations and the `seed-demo` script to seed sample data.

---

### Run in separate terminals (manual)

If you prefer separate terminals instead of a combined `npm run dev`, run each of the two scripts manually in their own terminal windows/tabs:

Terminal 1 (backend):

```bash
# from repo root
npm run dev:backend
```

Terminal 2 (frontend):

```bash
# from repo root
npm run dev:frontend
```

These are the same `dev:backend` and `dev:frontend` scripts declared in the root `package.json` and run the backend or frontend independently.

### Run in separate terminals (VS Code)

You can also use Visual Studio Code tasks that open separate terminals automatically. The repo includes a `.vscode/tasks.json` with three tasks:

- `Dev Backend` - runs the backend in its own terminal
- `Dev Frontend` - runs the Flutter frontend in a separate terminal
- `Dev: Start both` - runs both tasks in parallel, each in dedicated terminals

To run these, open the Command Palette and select `Tasks: Run Task`, then choose `Dev Backend`, `Dev Frontend`, or `Dev: Start both`. Each runs in its own terminal pane.


---

## Quick summary (Windows cmd.exe)

```bat
cd backend
set PORT=3001
npm install
npm run prisma:migrate
npm run prisma:generate
npm run prisma:seed
npm run dev
# In another terminal
cd ..
flutter pub get
flutter run -d chrome --web-port=3000
```

---


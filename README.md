# Main Project - CRM Application

A full-stack CRM application with Flutter frontend and Node.js/Express backend. Manage contacts, leads, accounts, and support tickets.

## Table of Contents

- [Quick Start](#quick-start)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Running the Application](#running-the-application)
- [Development Workflow](#development-workflow)
- [Database Management](#database-management)
- [Architecture](#architecture)
- [Contributing](#contributing)

## Quick Start

### Fastest Way to Run (All in One)

```bash
# Terminal 1 - Backend
npm run dev:backend

# Terminal 2 - Frontend
npm run dev:frontend
```

Or use VS Code task:
```bash
Dev: Start both      # Runs backend and frontend in parallel
```

## System Requirements

### Backend
- **Node.js** 18.x or later
- **npm** or **yarn**
- **PostgreSQL** 14 or later
- **.env file** with database credentials

### Frontend
- **Flutter SDK** 3.8.1 or later
- **Dart SDK** (included with Flutter)
- **Chrome browser** (for web development)
- Optional: Android Studio, Xcode, Visual Studio for other platforms

### Verification

```bash
# Check Flutter setup
flutter doctor

# Check Node.js
node --version
npm --version

# Check PostgreSQL
psql --version
```

## Installation

### 1. Clone Repository

```bash
git clone <repository-url>
cd main_project
```

### 2. Database Setup (Docker)

```bash
cd backend

# Start PostgreSQL container
docker-compose up -d

# Verify PostgreSQL is running
docker-compose ps
```

**Docker Credentials (from docker-compose.yml):**
- Username: `postgres`
- Password: `mypassword`
- Database: `main_project`
- Port: `5432`

### 3. Backend Setup

```bash
cd backend

# Install Node dependencies
npm install

# Create .env file with database URL
echo "DATABASE_URL=postgresql://postgres:mypassword@localhost:5432/main_project" > .env
echo "GOOGLE_CLIENT_ID=your_google_client_id" >> .env
echo "GOOGLE_CLIENT_SECRET=your_google_client_secret" >> .env
echo "PORT=3001" >> .env
```

**Required Environment Variables:**
- `DATABASE_URL`: PostgreSQL connection string (matches docker-compose)
- `GOOGLE_CLIENT_ID`: Google OAuth Client ID
- `GOOGLE_CLIENT_SECRET`: Google OAuth Client Secret
- `PORT`: Backend port (default: 3001)

### 4. Initialize Database

```bash
cd backend

# Run migrations
npm run prisma:migrate

# Seed initial data
npm run seed-production

# View database (optional)
npm run prisma:studio
```

### 5. Frontend Setup

```bash
# From project root
flutter pub get
```

## Running the Application

### Option 1: VS Code Tasks (Recommended)

```bash
# Open command palette (Ctrl+Shift+P or Cmd+Shift+P)
> Tasks: Run Task
> Dev: Start both
```

This starts:
- Backend on `http://localhost:3001`
- Frontend on `http://localhost:3000`

### Option 2: Manual - Multiple Terminals

**Terminal 1 - Backend:**
```bash
npm run dev:backend
# Runs on http://localhost:3001
# Watch mode enabled - auto-restarts on file changes
```

**Terminal 2 - Frontend:**
```bash
npm run dev:frontend
# Runs on http://localhost:3000
# Hot reload enabled
```

### Option 3: Production Build

**Backend:**
```bash
cd backend
npm start
```

**Frontend - Web:**
```bash
flutter build web --release
# Outputs to build/web/
# Serve with: python -m http.server 3000
```

**Frontend - Other Platforms:**
```bash
flutter build apk          # Android
flutter build ios          # iOS (macOS only)
flutter build windows      # Windows desktop
flutter build macos        # macOS desktop
flutter build linux        # Linux desktop
```

## Development Workflow

### Code Quality

```bash
# Frontend
flutter analyze           # Lint code
flutter format .          # Format Dart code

# Backend
npm run lint             # Check lint rules
npm run format           # Format JavaScript code
```

### Testing

```bash
# Frontend
flutter test

# Backend
npm test                 # Run all tests
npm run test:watch      # Watch mode
```

### Common Development Tasks

**View Database:**
```bash
cd backend
npm run prisma:studio
# Opens at http://localhost:5555
```

**Check User Permissions:**
```bash
cd backend
node scripts/check-permissions.js
```

**Test API Endpoints:**
```bash
cd backend
node scripts/test-api.js
```

## Database Management

### Seeding Data

```bash
cd backend

# Seed production data
npm run seed-production
```

### Database Maintenance

```bash
# Reset entire database
npm run db:reset

# Generate Prisma client
npm run prisma:generate

# Create new migration
npm run prisma:migrate -- --name migration_name
```

## Project Structure

```
main_project/
├── backend/                 # Node.js/Express API
│   ├── routes/
│   ├── middleware/
│   ├── services/
│   ├── lib/
│   ├── prisma/
│   │   ├── schema.prisma
│   │   └── migrations/
│   ├── scripts/
│   ├── app.js
│   ├── server.js
│   └── package.json
├── lib/                     # Flutter application
│   ├── screens/
│   ├── widgets/
│   ├── services/
│   ├── models/
│   ├── navigation/
│   └── main.dart
├── pubspec.yaml            # Flutter dependencies
└── ARCHITECTURE.md         # System architecture details
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed system architecture, database schema, and API documentation.

## Troubleshooting

### Backend Issues

**Port already in use:**
```bash
# Find process on port 3001
lsof -i :3001                    # macOS/Linux
netstat -ano | findstr :3001     # Windows

# Kill process
kill -9 <PID>
```

**Database connection failed:**
- Verify PostgreSQL Docker container is running: `docker-compose ps`
- Check `DATABASE_URL` in `.env` matches docker-compose credentials
- Restart containers: `docker-compose restart`

**Docker PostgreSQL issues:**
```bash
cd backend

# View logs
docker-compose logs postgres

# Restart containers
docker-compose restart

# Remove and recreate (fresh database)
docker-compose down -v
docker-compose up -d
```

**Migration errors:**
```bash
cd backend
npm run prisma:migrate -- --skip-generate
```

### Frontend Issues

**Chrome not found:**
```bash
flutter config --chrome-device-vm-service-port=54321
flutter run -d chrome
```

**Port 3000 already in use:**
```bash
flutter run -d chrome --web-port=3001
```

**Hot reload not working:**
```bash
flutter run -d chrome --no-fast-start
```

## Docker

The project includes Docker Compose for PostgreSQL database management.

### Docker Commands

```bash
cd backend

# Start PostgreSQL container
docker-compose up -d

# View running containers
docker-compose ps

# View logs
docker-compose logs postgres

# Stop containers
docker-compose down

# Remove containers and volumes (reset database)
docker-compose down -v

# Rebuild containers
docker-compose up -d --build
```

### Docker Compose Configuration

- **PostgreSQL Image**: postgres:15
- **Container Name**: main_project_db
- **Username**: postgres
- **Password**: mypassword
- **Database**: main_project
- **Port**: 5432
- **Data Volume**: pgdata (persists between restarts)

### Environment Variables for Docker

When using Docker, update `.env` with:
```bash
DATABASE_URL=postgresql://postgres:mypassword@localhost:5432/main_project
```

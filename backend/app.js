import express from 'express';
import cors from 'cors';
import session from 'express-session';
import passport from 'passport';
import cookieParser from 'cookie-parser';
import path from 'path';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import prisma from './lib/prismaClient.js';
import routes from './routes/index.js';

const app = express();

// Passport configuration
const PORT = process.env.PORT || 3001;
const GOOGLE_REDIRECT_URI = process.env.GOOGLE_REDIRECT_URI || `http://localhost:${PORT}/api/auth/staff/google/callback`;

passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  callbackURL: GOOGLE_REDIRECT_URI
  },
  async (accessToken, refreshToken, profile, done) => {
    try {
      let user = await prisma.user.findUnique({
        where: { googleId: profile.id }
      });

      if (!user) {
        const existingUser = await prisma.user.findUnique({
          where: { email: profile.emails[0].value }
        });

        if (existingUser) {
          user = await prisma.user.update({
            where: { id: existingUser.id },
            data: { googleId: profile.id }
          });
        } else {
          user = await prisma.user.create({
            data: {
              email: profile.emails[0].value,
              name: profile.displayName,
              googleId: profile.id,
              profileImage: profile.photos[0]?.value
            }
          });
        }
      }
      return done(null, user);
    } catch (error) {
      return done(error, null);
    }
  }
));

passport.serializeUser((user, done) => {
  done(null, user.id);
});

passport.deserializeUser(async (id, done) => {
  try {
    const user = await prisma.user.findUnique({ where: { id } });
    done(null, user);
  } catch (error) {
    done(error, null);
  }
});

// CORS configuration
const corsOptions = {
  origin: function (origin, callback) {
    const allowed = [
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'http://localhost:3001',
      undefined,
      null,
    ];
    if (!origin || allowed.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(null, true);
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Organization-ID', 'X-Requested-With'],
  exposedHeaders: ['X-Organization-ID'],
};

app.use(cors(corsOptions));

// Request logging
app.use((req, res, next) => {
  console.log(`Incoming request: ${req.method} ${req.path} Origin:${req.headers.origin || 'none'}`);
  next();
});

app.use(express.json());
app.use(cookieParser());

// Health check
app.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: 'ok', database: 'connected', timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(503).json({ status: 'error', database: 'disconnected', error: error.message });
  }
});

// Debug headers
app.get('/debug/headers', (req, res) => {
  res.json({
    headers: req.headers,
    method: req.method,
    url: req.url,
    ip: req.ip
  });
});

app.use(session({
  secret: process.env.SESSION_SECRET || 'your-session-secret',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    maxAge: 24 * 60 * 60 * 1000
  }
}));

app.use(passport.initialize());
app.use(passport.session());

// Static files
const uploadsDir = path.join(process.cwd(), 'uploads');
app.use('/uploads', express.static(uploadsDir));

// API Routes
app.use('/api', routes);

// Health check
app.get('/health', async (req, res) => {
  try {
    await prisma.$connect();
    res.json({ status: 'Healthy', details: { database: 'up' } });
    await prisma.$disconnect();
  } catch (e) {
    res.status(500).json({ status: 'Unhealthy', message: e.message, details: { database: 'down' } });
  }
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err && (err.stack || err));
  if (res.headersSent) return next(err);
  res.status(500).json({ 
    message: 'Internal server error', 
    error: err && err.message ? err.message : String(err) 
  });
});

export default app;

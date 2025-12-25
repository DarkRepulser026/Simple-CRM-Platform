import rateLimit from 'express-rate-limit';

const baseRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 requests per windowMs
  message: 'Too many authentication attempts, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
});

export const customerAuthLimiter = (req, res, next) => {
  // We enable it in test to pass the rate limiting test, 
  // but we might need to be careful with other tests.
  return baseRateLimiter(req, res, next);
};

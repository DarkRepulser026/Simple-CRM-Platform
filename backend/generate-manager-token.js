import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Generate token for manager
const managerToken = jwt.sign(
  { id: 'cmjjesjqu000f3z88lfy9mpzh', email: 'manager@example.com', tokenVersion: 0 },
  JWT_SECRET,
  { expiresIn: '24h' }
);

console.log('Manager Token:');
console.log(managerToken);
console.log('\nTest with:');
console.log(`curl -H "Authorization: Bearer ${managerToken}" -H "X-Organization-ID: cmjjesjnc00003z88liyk6z91" http://localhost:3001/api/crm/contacts`);

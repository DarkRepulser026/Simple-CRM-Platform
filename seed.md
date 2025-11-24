# 1. Login / Authenticate using your Google mocked auth
# Sends a POST request to /auth/google to receive a JWT token.
$ TOKEN=$(curl -s -X POST "http://localhost:3001/auth/google" \
    -H "Content-Type: application/json" \
    -d '{"email":"minecraftthanhloi@gmail.com", "name":"Root Admin", "googleId":"minecraftthanhloi@gmail.com"}' | jq -r .token)

# 2. Fetch organizations accessible by the authenticated user
curl -s -X GET "http://localhost:3001/organizations" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json"

# 3. Send an invitation to join an organization
curl -i -X POST "http://localhost:3001/organizations/cmi6fq45q00003zf4p7j4mkhf/invite" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-Organization-ID: cmi6fq45q00003zf4p7j4mkhf" \
    -H "Content-Type: application/json" \
    -d '{"email":"minecraftthanhloi@gmail.com","role":"ADMIN"}'

# 4. Invitation acceptance URL
http://localhost:3000/invite/accept?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6Im1pbmVjcmFmdHRoYW5obG9pQGdtYWlsLmNvbSIsIm9yZ0lkIjoiY21pNmZxNDVxMDAwMDN6ZjRwN2o0bWtoZiIsInJvbGUiOiJBRE1JTiIsImNyZWF0ZWRCeSI6ImNtaTZnMHJpMDAwMDAzejhzYjZkcmJlMHMiLCJpYXQiOjE3NjM4NTMyNjAsImV4cCI6MTc2NDAyNjA2MH0.vKKTyj3VQrZfoUgktX6L9bbvwFq1BpAIW1Pu29fZRrs

# 1. Authenticate
TOKEN=$(curl -s -X POST "http://localhost:3001/auth/google" \
  -H "Content-Type: application/json" \
  -d '{"email":"minecraftthanhloi@gmail.com","name":"Root Admin","googleId":"minecraftthanhloi@gmail.com"}' | jq -r .token)
# 2. Load organizations
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3001/organizations | jq 
# note the organization id from the response

# 3. Grant admin permissions using your npm script
ORG_ID=cmi6fq45q00003zf4p7j4mkhf ADMIN_EMAIL=minecraftthanhloi@gmail.com npm run grant-admin

# 4. Seed demo data into the DF organization
ORG_ID=cmi6fq45q00003zf4p7j4mkhf ADMIN_EMAIL=minecraftthanhloi@gmail.com npm run seed-demo

# 5. Validate permissions using a custom script
ORG_ID=cmi6fq45q00003zf4p7j4mkhf ADMIN_EMAIL=minecraftthanhloi@gmail.com node scripts/check-permissions.js
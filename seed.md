$ TOKEN=$(curl -s -X POST "http://localhost:3001/auth/google" \
    -H "Content-Type: application/json" \
    -d '{"email":"minecraftthanhloi@gmail.com", "name":"Root Admin", "googleId":"minecraftthanhloi@gmail.com"}' | jq -r .token)

curl -s -X GET "http://localhost:3001/organizations" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json"


curl -i -X POST "http://localhost:3001/organizations/cmi6fq45q00003zf4p7j4mkhf/invite" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-Organization-ID: cmi6fq45q00003zf4p7j4mkhf" \
    -H "Content-Type: application/json" \
    -d '{"email":"minecraftthanhloi@gmail.com","role":"ADMIN"}'

http://localhost:3000/invite/accept?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6Im1pbmVjcmFmdHRoYW5obG9pQGdtYWlsLmNvbSIsIm9yZ0lkIjoiY21pNmZxNDVxMDAwMDN6ZjRwN2o0bWtoZiIsInJvbGUiOiJBRE1JTiIsImNyZWF0ZWRCeSI6ImNtaTZnMHJpMDAwMDAzejhzYjZkcmJlMHMiLCJpYXQiOjE3NjM4NTMyNjAsImV4cCI6MTc2NDAyNjA2MH0.vKKTyj3VQrZfoUgktX6L9bbvwFq1BpAIW1Pu29fZRrs

TOKEN=$(curl -s -X POST "http://localhost:3001/auth/google" \
  -H "Content-Type: application/json" \
  -d '{"email":"minecraftthanhloi@gmail.com","name":"Root Admin","googleId":"minecraftthanhloi@gmail.com"}' | jq -r .token)

curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3001/organizations | jq 
# note the organization id from the response

# Grant admin for your org and user
ORG_ID=cmi6fq45q00003zf4p7j4mkhf ADMIN_EMAIL=minecraftthanhloi@gmail.com npm run grant-admin

# Seed demo data into the organization
ORG_ID=cmi6fq45q00003zf4p7j4mkhf ADMIN_EMAIL=minecraftthanhloi@gmail.com npm run seed-demo
# Database Reset and Seed Script
# Run this to get a fresh database with test data

Write-Host "🔄 Resetting Database & Seeding Fresh Data..." -ForegroundColor Cyan
Write-Host ""

# Change to backend directory
Set-Location -Path "$PSScriptRoot\backend"

# Step 1: Reset database (delete all data)
Write-Host "Step 1: Resetting database..." -ForegroundColor Yellow
npm run db:reset

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Database reset failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Seed fresh data
Write-Host "Step 2: Seeding fresh data..." -ForegroundColor Yellow
npm run db:seed

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Database seeding failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Database reset and seeded successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Test Credentials:" -ForegroundColor Cyan
Write-Host "  Staff Login: admin@example.com / password123" -ForegroundColor White
Write-Host "  Customer 1: john@acme.com / password123 (Acme Corp)" -ForegroundColor White
Write-Host "  Customer 2: jane@techstart.io / password123 (TechStart)" -ForegroundColor White
Write-Host "  Customer 3: customer@gmail.com / password123 (Unassigned)" -ForegroundColor White
Write-Host ""

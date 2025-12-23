#!/bin/bash

# Database Reset and Seed Script
# Run this to get a fresh database with test data

echo "🔄 Resetting Database & Seeding Fresh Data..."
echo ""

# Change to backend directory
cd "$(dirname "$0")/backend" || exit 1

# Step 1: Reset database (delete all data)
echo "Step 1: Resetting database..."
npm run db:reset

if [ $? -ne 0 ]; then
    echo "❌ Database reset failed!"
    exit 1
fi

echo ""

# Step 2: Seed fresh data
echo "Step 2: Seeding fresh data..."
npm run db:seed

if [ $? -ne 0 ]; then
    echo "❌ Database seeding failed!"
    exit 1
fi

echo ""
echo "✅ Database reset and seeded successfully!"
echo ""
echo "📝 Test Credentials:"
echo "  Staff Login: admin@example.com / password123"
echo "  Customer 1: john@acme.com / password123 (Acme Corp)"
echo "  Customer 2: jane@techstart.io / password123 (TechStart)"
echo "  Customer 3: customer@gmail.com / password123 (Unassigned)"
echo ""

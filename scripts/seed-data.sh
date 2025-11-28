#!/bin/bash

# Script to seed initial data for testing
# Usage: ./scripts/seed-data.sh

API_URL="http://localhost:8088"
REDIS_SERVICE="redis-driver"

echo "⏳ Waiting for services to stabilize (5s)..."
sleep 5

# 1. Create Test User
echo "👤 Creating Test User (test@uit.edu.vn)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/users" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@uit.edu.vn",
    "password": "password123",
    "fullName": "Test User",
    "phone": "0909000111"
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" ]]; then
  echo "✅ User created successfully."
elif [[ "$BODY" == *"already exists"* ]]; then
  echo "⚠️ User already exists, skipping creation."
else
  echo "❌ Failed to create user. HTTP $HTTP_CODE"
  echo "Response: $BODY"
fi

# 2. Seed Drivers into Redis
echo "🚖 Seeding 100 Drivers into Redis (Ho Chi Minh City area)..."

# Center: HCM City (106.660172, 10.762622)
# Radius: ~2-3km

# We use a pipeline to speed up Redis insertion
REDIS_COMMANDS=""

for i in {1..100}; do
  # Generate random offsets (-0.02 to +0.02 degrees is roughly +/- 2km)
  LAT_OFFSET=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); print (rand() * 0.04) - 0.02}')
  LNG_OFFSET=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); print (rand() * 0.04) - 0.02}')
  
  LAT=$(awk "BEGIN {print 10.762622 + $LAT_OFFSET}")
  LNG=$(awk "BEGIN {print 106.660172 + $LNG_OFFSET}")
  
  DRIVER_ID="driver_$i"
  
  # Redis Protocol commands
  # GEOADD driver_locations LNG LAT MEMBER
  REDIS_COMMANDS+="GEOADD driver_locations $LNG $LAT $DRIVER_ID"$'\n'
  # HSET driver_status MEMBER "ONLINE"
  REDIS_COMMANDS+="HSET driver_status $DRIVER_ID ONLINE"$'\n'
done

# Execute via docker compose
echo "$REDIS_COMMANDS" | docker compose exec -T $REDIS_SERVICE redis-cli --pipe

echo "✅ Drivers seeded successfully!"
echo "🚀 Environment is ready for testing."

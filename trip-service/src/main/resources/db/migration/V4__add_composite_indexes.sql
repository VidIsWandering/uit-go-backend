-- V4__add_composite_indexes.sql
-- Composite indexes for common query patterns to optimize database performance

-- Composite index for passenger queries filtered by status and ordered by creation time
-- Optimizes: SELECT * FROM trips WHERE passenger_id = ? AND status = ? ORDER BY created_at DESC
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trips_passenger_status_created 
ON trips(passenger_id, status, created_at DESC);

-- Composite index for driver queries filtered by status and ordered by creation time
-- Optimizes: SELECT * FROM trips WHERE driver_id = ? AND status = ? ORDER BY created_at DESC
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trips_driver_status_created 
ON trips(driver_id, status, created_at DESC);

-- Composite index for passenger queries ordered by creation time (without status filter)
-- Optimizes: SELECT * FROM trips WHERE passenger_id = ? ORDER BY created_at DESC
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trips_passenger_created 
ON trips(passenger_id, created_at DESC);

-- Composite index for driver queries ordered by creation time (without status filter)
-- Optimizes: SELECT * FROM trips WHERE driver_id = ? ORDER BY created_at DESC
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trips_driver_created 
ON trips(driver_id, created_at DESC);

-- Comment: CONCURRENTLY allows index creation without blocking writes
-- These indexes improve query performance for passenger/driver history endpoints

-- Migration: Add version column for Optimistic Locking
-- Date: 2025-11-29
-- Purpose: Enable concurrent access control to prevent race conditions
-- when multiple drivers attempt to accept the same trip simultaneously

ALTER TABLE trips ADD COLUMN version INTEGER DEFAULT 0 NOT NULL;

-- Create index on frequently updated columns for better performance
CREATE INDEX idx_trips_status_version ON trips(status, version);

COMMENT ON COLUMN trips.version IS 'Optimistic locking version number - auto-incremented by JPA on each update';

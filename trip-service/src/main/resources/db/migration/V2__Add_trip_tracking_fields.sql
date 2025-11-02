-- Add new columns to trips table for enhanced tracking

ALTER TABLE trips
ADD COLUMN IF NOT EXISTS rating INTEGER,
ADD COLUMN IF NOT EXISTS comment TEXT,
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE;

-- Add check constraint for rating (1-5)
ALTER TABLE trips
ADD CONSTRAINT rating_check CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5));

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_trips_passenger_id ON trips(passenger_id);
CREATE INDEX IF NOT EXISTS idx_trips_driver_id ON trips(driver_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_created_at ON trips(created_at);
CREATE INDEX IF NOT EXISTS idx_trips_passenger_status ON trips(passenger_id, status);
CREATE INDEX IF NOT EXISTS idx_trips_driver_status ON trips(driver_id, status);
CREATE INDEX IF NOT EXISTS idx_trips_driver_created ON trips(driver_id, created_at);

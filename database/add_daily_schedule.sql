-- Add daily_schedule table for nursery daily programs
CREATE TABLE IF NOT EXISTS daily_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nursery_id UUID REFERENCES nurseries(id) ON DELETE CASCADE,
    time_slot VARCHAR(10) NOT NULL,
    activity_name VARCHAR(255) NOT NULL,
    description TEXT,
    participant_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_daily_schedule_nursery ON daily_schedule(nursery_id);

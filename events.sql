-- First, make sure pg_cron extension is installed
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- List all installed extensions
SELECT * FROM pg_extension;

-- Create a test table to demonstrate pg_cron
CREATE TABLE IF NOT EXISTS cron_test_logs (
    id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create a function that inserts a test message
CREATE OR REPLACE FUNCTION log_test_message(job_name TEXT)
RETURNS void AS $$
BEGIN
    INSERT INTO cron_test_logs (message)
    VALUES (job_name || ' executed at ' || CURRENT_TIMESTAMP);
END;
$$ LANGUAGE plpgsql;

-- Run every minute
SELECT cron.schedule('test_every_minute', '* * * * *', 'SELECT log_test_message(''test_every_minute'')');

-- To check scheduled jobs:
SELECT * FROM cron.job;

-- To check job runs and their status:
SELECT * FROM cron.job_run_details ORDER BY start_time DESC;

-- To check the results:
SELECT * FROM cron_test_logs ORDER BY created_at DESC;

-- To delete a scheduled job:
SELECT cron.unschedule('test_every_minute');



-- CLEAR DATABASE FOR FRESH REFERRAL TESTING
-- Remove all user data for clean test environment

TRUNCATE TABLE user_tasks CASCADE;
TRUNCATE TABLE withdrawals CASCADE;
DELETE FROM users;

-- Reset any sequences if needed
-- This ensures we start with a clean slate for testing
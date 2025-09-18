-- NUCLEAR DATABASE RESET - Remove all corrupted referral system components
-- Remove the broken trigger and function
DROP TRIGGER IF EXISTS on_user_referral ON users CASCADE;
DROP FUNCTION IF EXISTS process_referral() CASCADE;

-- Clear all user data completely
TRUNCATE TABLE users RESTART IDENTITY CASCADE;

-- Additional cleanup to ensure fresh start
DROP TRIGGER IF EXISTS on_new_user_referral ON users CASCADE;
DROP FUNCTION IF EXISTS on_new_user_referral() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user_referral() CASCADE;
DROP FUNCTION IF EXISTS process_new_user_referral() CASCADE;
DROP FUNCTION IF EXISTS update_referral_stats() CASCADE;

-- Remove any leftover referral-related functions
DROP FUNCTION IF EXISTS process_referral_trigger() CASCADE;
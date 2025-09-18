-- Fix user_tasks table to use user_wallet instead of user_id
-- This matches the existing database functions that reference user_wallet

-- First check if user_wallet column exists
DO $$
BEGIN
    -- Add user_wallet column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_tasks' 
                   AND column_name = 'user_wallet') THEN
        ALTER TABLE user_tasks ADD COLUMN user_wallet TEXT;
    END IF;
    
    -- Remove user_id column if it exists and is different from user_wallet
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'user_tasks' 
               AND column_name = 'user_id') THEN
        ALTER TABLE user_tasks DROP COLUMN user_id;
    END IF;
END $$;

-- Create unique constraint to prevent duplicate task completions
ALTER TABLE user_tasks DROP CONSTRAINT IF EXISTS user_tasks_user_wallet_task_id_unique;
ALTER TABLE user_tasks ADD CONSTRAINT user_tasks_user_wallet_task_id_unique 
UNIQUE (user_wallet, task_id);
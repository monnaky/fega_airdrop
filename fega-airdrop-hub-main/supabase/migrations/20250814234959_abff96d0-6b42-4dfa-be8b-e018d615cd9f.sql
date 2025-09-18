-- First, let's check the current foreign key constraints and fix them
-- Remove the foreign key constraint from task_completions to profiles if it exists
ALTER TABLE task_completions DROP CONSTRAINT IF EXISTS task_completions_user_id_fkey;

-- Add proper foreign key constraint to auth.users instead of profiles
-- This ensures we can always create task completions for authenticated users
ALTER TABLE task_completions 
ADD CONSTRAINT task_completions_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;
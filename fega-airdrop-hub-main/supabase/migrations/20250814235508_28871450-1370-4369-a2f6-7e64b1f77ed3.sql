-- Remove foreign key constraint from task_completions to profiles
-- This allows task completions to work independently of profiles
ALTER TABLE task_completions DROP CONSTRAINT IF EXISTS task_completions_user_id_fkey;

-- Clean up any existing invalid data
DELETE FROM task_completions 
WHERE user_id NOT IN (SELECT id FROM auth.users);

-- Add constraint to auth.users instead (which always exists for authenticated users)
-- But first let's check if the constraint name is different
ALTER TABLE task_completions 
ADD CONSTRAINT task_completions_user_id_auth_fkey 
FOREIGN KEY (user_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;
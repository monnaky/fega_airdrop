-- Clean up invalid task completions and fix the foreign key constraint
-- First, remove invalid task completions that reference non-existent users
DELETE FROM task_completions 
WHERE user_id NOT IN (SELECT id FROM auth.users);

-- Now we can safely add the foreign key constraint to auth.users
ALTER TABLE task_completions 
ADD CONSTRAINT task_completions_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;
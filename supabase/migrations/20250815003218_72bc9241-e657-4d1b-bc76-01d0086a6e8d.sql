-- Fix the tasks table constraint issue
-- First check what constraints exist
SELECT constraint_name, constraint_type FROM information_schema.table_constraints 
WHERE table_name = 'tasks' AND constraint_type = 'CHECK';

-- Drop any problematic check constraints and recreate them properly
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_task_type_check;

-- Add proper task type constraint that supports all the types we need
ALTER TABLE public.tasks ADD CONSTRAINT tasks_task_type_check 
CHECK (task_type IN ('twitter', 'youtube', 'instagram', 'tiktok', 'telegram', 'website', 'discord', 'medium', 'reddit'));
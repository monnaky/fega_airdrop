-- First check what task types exist
SELECT DISTINCT task_type FROM tasks;

-- Update any invalid task types to valid ones
UPDATE public.tasks SET task_type = 'twitter' WHERE task_type NOT IN ('twitter', 'youtube', 'instagram', 'tiktok', 'telegram', 'website', 'discord', 'medium', 'reddit');

-- Now we can safely add the constraint
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_task_type_check;
ALTER TABLE public.tasks ADD CONSTRAINT tasks_task_type_check 
CHECK (task_type IN ('twitter', 'youtube', 'instagram', 'tiktok', 'telegram', 'website', 'discord', 'medium', 'reddit'));
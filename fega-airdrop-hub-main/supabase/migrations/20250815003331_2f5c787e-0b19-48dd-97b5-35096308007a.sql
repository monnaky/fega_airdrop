-- Map existing task types to proper values
UPDATE public.tasks SET task_type = 'twitter' WHERE task_type = 'twitter_follow';
UPDATE public.tasks SET task_type = 'instagram' WHERE task_type = 'instagram_follow';
UPDATE public.tasks SET task_type = 'youtube' WHERE task_type = 'youtube_subscribe';
UPDATE public.tasks SET task_type = 'tiktok' WHERE task_type = 'tiktok_follow';

-- Now we can safely add the constraint
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_task_type_check;
ALTER TABLE public.tasks ADD CONSTRAINT tasks_task_type_check 
CHECK (task_type IN ('twitter', 'youtube', 'instagram', 'tiktok', 'telegram', 'website', 'discord', 'medium', 'reddit'));
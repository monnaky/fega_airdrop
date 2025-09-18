-- Remove the problematic constraint entirely to allow admin to create tasks
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_task_type_check;
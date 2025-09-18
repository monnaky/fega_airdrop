-- Update existing tasks with new FEGA social media links
UPDATE tasks SET 
  task_url = 'https://x.com/fegatoken',
  title = 'Follow @FegaToken on Twitter',
  description = 'Follow our official Twitter account for the latest updates',
  reward_tokens = 200
WHERE task_type = 'twitter';

UPDATE tasks SET 
  task_url = 'https://www.youtube.com/@fegatoken',
  title = 'Subscribe to our YouTube Channel',
  description = 'Subscribe to our YouTube channel for tutorials and news',
  reward_tokens = 200
WHERE task_type = 'youtube';

UPDATE tasks SET 
  task_url = 'https://www.instagram.com/fega.token/',
  title = 'Follow us on Instagram',
  description = 'Follow our Instagram for behind-the-scenes content',
  reward_tokens = 200
WHERE task_type = 'instagram';

UPDATE tasks SET 
  task_url = 'https://www.tiktok.com/@fega.token1?lang=en',
  title = 'Follow on TikTok',
  description = 'Follow our TikTok for fun and engaging content',
  reward_tokens = 200
WHERE task_type = 'tiktok';

-- Insert/Update Telegram task
INSERT INTO tasks (title, description, task_type, task_url, reward_tokens, is_active)
VALUES (
  'Join our Telegram',
  'Join our Telegram community for real-time updates',
  'telegram',
  'https://t.me/YourTelegramChannel',
  200,
  true
) ON CONFLICT (task_type) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  task_url = EXCLUDED.task_url,
  reward_tokens = EXCLUDED.reward_tokens,
  is_active = EXCLUDED.is_active;
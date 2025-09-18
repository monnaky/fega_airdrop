-- Update existing tasks with new FEGA URLs and increased rewards (200 each)
UPDATE tasks SET 
  task_url = 'https://x.com/fegatoken',
  title = 'Follow @FegaToken on Twitter',
  description = 'Follow our official Twitter account for the latest updates',
  reward_tokens = 200
WHERE task_type = 'twitter_follow';

UPDATE tasks SET 
  task_url = 'https://www.youtube.com/@fegatoken',
  title = 'Subscribe to our YouTube Channel', 
  description = 'Subscribe to our YouTube channel for tutorials and news',
  reward_tokens = 200
WHERE task_type = 'youtube_subscribe';

UPDATE tasks SET 
  task_url = 'https://www.instagram.com/fega.token/',
  title = 'Follow us on Instagram',
  description = 'Follow our Instagram for behind-the-scenes content', 
  reward_tokens = 200
WHERE task_type = 'instagram_follow';

UPDATE tasks SET 
  task_url = 'https://www.tiktok.com/@fega.token1?lang=en',
  title = 'Follow on TikTok',
  description = 'Follow our TikTok for fun and engaging content',
  reward_tokens = 200  
WHERE task_type = 'tiktok_follow';

UPDATE tasks SET 
  task_url = 'https://t.me/YourTelegramChannel',
  title = 'Join our Telegram',
  description = 'Join our Telegram community for real-time updates',
  reward_tokens = 200
WHERE task_type = 'telegram_join';
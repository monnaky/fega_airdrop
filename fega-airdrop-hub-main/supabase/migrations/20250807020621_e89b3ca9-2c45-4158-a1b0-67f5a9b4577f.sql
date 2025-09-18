-- Delete existing tasks and recreate with proper data
DELETE FROM tasks WHERE task_type IN ('twitter', 'youtube', 'instagram', 'tiktok', 'telegram');

-- Insert all required FEGA social media tasks
INSERT INTO tasks (title, description, task_type, task_url, reward_tokens, is_active) VALUES
('Follow @FegaToken on Twitter', 'Follow our official Twitter account for the latest updates', 'twitter', 'https://x.com/fegatoken', 200, true),
('Subscribe to our YouTube Channel', 'Subscribe to our YouTube channel for tutorials and news', 'youtube', 'https://www.youtube.com/@fegatoken', 200, true),
('Follow us on Instagram', 'Follow our Instagram for behind-the-scenes content', 'instagram', 'https://www.instagram.com/fega.token/', 200, true),
('Follow on TikTok', 'Follow our TikTok for fun and engaging content', 'tiktok', 'https://www.tiktok.com/@fega.token1?lang=en', 200, true),
('Join our Telegram', 'Join our Telegram community for real-time updates', 'telegram', 'https://t.me/YourTelegramChannel', 200, true);
-- Full system reset - Clear all data but keep table structure
TRUNCATE TABLE 
  withdrawals, 
  user_tasks, 
  referrals, 
  users, 
  admins, 
  tasks, 
  settings,
  claims,
  error_logs
RESTART IDENTITY CASCADE;

-- Re-insert essential default settings using key-value structure
INSERT INTO settings (key, value) VALUES 
('referral_reward', '50'),
('claim_cooldown', '24'),
('min_withdrawal_amount', '1000'),
('claim_gas_fee', '0.001'),
('weekly_claim_amount', '100'),
('referral_bonus', '50');

-- Re-insert default tasks
INSERT INTO tasks (name, type, description, reward, link) VALUES 
('Follow FEGA on Twitter', 'social', 'Follow our official Twitter account to stay updated', 1000, 'https://twitter.com/fegaofficial'),
('Join FEGA Telegram', 'social', 'Join our Telegram community for the latest news', 1500, 'https://t.me/fegaofficial'),
('Like and Retweet FEGA Post', 'social', 'Engage with our latest Twitter post', 800, 'https://twitter.com/fegaofficial'),
('Subscribe to FEGA YouTube', 'social', 'Subscribe to our YouTube channel', 1200, 'https://youtube.com/fegaofficial');
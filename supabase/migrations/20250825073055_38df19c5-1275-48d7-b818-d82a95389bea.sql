-- Clean up all test/dummy data from production tables
DELETE FROM user_tasks;
DELETE FROM referrals;
DELETE FROM claims;
UPDATE users SET balance = 0;
DELETE FROM tasks WHERE name LIKE '%Test%' OR name LIKE '%Demo%' OR name LIKE '%Sample%';
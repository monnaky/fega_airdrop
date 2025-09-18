-- Clear all user data and transactions for fresh production test
TRUNCATE TABLE withdrawals, user_tasks, users RESTART IDENTITY CASCADE;
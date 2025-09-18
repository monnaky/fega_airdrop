-- PHASE 1: Clear all data for fresh testing
TRUNCATE TABLE withdrawals, user_tasks, users, referrals RESTART IDENTITY CASCADE;

-- PHASE 2: Add gas fee feature
ALTER TABLE settings ADD COLUMN IF NOT EXISTS claim_gas_fee NUMERIC DEFAULT 0.001;

-- Set default gas fee value
INSERT INTO settings (key, value) VALUES ('claim_gas_fee', '0.001')
ON CONFLICT (key) DO UPDATE SET value = '0.001';
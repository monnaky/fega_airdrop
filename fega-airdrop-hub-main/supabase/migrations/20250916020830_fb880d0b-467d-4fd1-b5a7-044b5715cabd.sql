-- STEP 1 TEST: Manual referral system test
-- Insert User A
INSERT INTO users (wallet_address) VALUES ('0xUSER_A');

-- Insert User B with User A as referrer
INSERT INTO users (wallet_address, referrer_id) VALUES ('0xUSER_B', (SELECT id FROM users WHERE wallet_address = '0xUSER_A'));

-- Now manually update User A's referral stats (since no trigger exists)
UPDATE users 
SET referrals_count = referrals_count + 1,
    referral_earnings = referral_earnings + 50,
    balance = balance + 50
WHERE wallet_address = '0xUSER_A';
-- Add missing weekly_claim_last column to users table
ALTER TABLE users ADD COLUMN weekly_claim_last TIMESTAMP WITH TIME ZONE;
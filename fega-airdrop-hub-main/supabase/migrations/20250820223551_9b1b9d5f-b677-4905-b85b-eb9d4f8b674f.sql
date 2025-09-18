-- Complete the wallet-only authentication migration
-- Make wallet columns the primary ones and fix constraints

-- Update referrals table to make wallet columns required and old columns nullable
ALTER TABLE public.referrals ALTER COLUMN referrer_id DROP NOT NULL;
ALTER TABLE public.referrals ALTER COLUMN referred_id DROP NOT NULL;
ALTER TABLE public.referrals ALTER COLUMN referrer_wallet SET NOT NULL;
ALTER TABLE public.referrals ALTER COLUMN referred_wallet SET NOT NULL;

-- Update task_completions to make wallet_address required and user_id nullable
ALTER TABLE public.task_completions ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.task_completions ALTER COLUMN wallet_address SET NOT NULL;

-- Update claims to make wallet_address required and user_id nullable
ALTER TABLE public.claims ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.claims ALTER COLUMN wallet_address SET NOT NULL;

-- Add unique constraints for wallet-based operations
CREATE UNIQUE INDEX IF NOT EXISTS idx_referrals_referred_wallet ON public.referrals(referred_wallet);
CREATE UNIQUE INDEX IF NOT EXISTS idx_task_completions_wallet_task ON public.task_completions(wallet_address, task_id);

-- Create a function to increment profile values safely
CREATE OR REPLACE FUNCTION public.increment_profile_tokens(
  p_wallet_address text,
  p_token_increment integer,
  p_task_increment integer DEFAULT 1
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE profiles 
  SET 
    total_tokens_earned = total_tokens_earned + p_token_increment,
    total_tasks_completed = total_tasks_completed + p_task_increment
  WHERE wallet_address = p_wallet_address;
END;
$$;

-- Create a function to increment referral counts
CREATE OR REPLACE FUNCTION public.increment_referral_count(
  p_wallet_address text,
  p_token_increment integer DEFAULT 500
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE profiles 
  SET 
    referral_count = referral_count + 1,
    total_tokens_earned = total_tokens_earned + p_token_increment
  WHERE wallet_address = p_wallet_address;
END;
$$;
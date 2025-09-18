-- First, clean up existing data before making wallet_address required
-- Delete any task_completions that don't have a wallet_address
DELETE FROM public.task_completions WHERE wallet_address IS NULL;

-- Delete any claims that don't have a wallet_address  
DELETE FROM public.claims WHERE wallet_address IS NULL;

-- Now make wallet_address required for task_completions
ALTER TABLE public.task_completions ALTER COLUMN wallet_address SET NOT NULL;

-- Make wallet_address required for claims
ALTER TABLE public.claims ALTER COLUMN wallet_address SET NOT NULL;

-- Add unique constraints for wallet-based operations
CREATE UNIQUE INDEX IF NOT EXISTS idx_referrals_referred_wallet ON public.referrals(referred_wallet) WHERE referred_wallet IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_task_completions_wallet_task ON public.task_completions(wallet_address, task_id);
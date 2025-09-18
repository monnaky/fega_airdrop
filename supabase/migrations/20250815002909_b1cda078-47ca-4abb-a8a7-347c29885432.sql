-- Remove the unique constraint on wallet_address to allow multiple profiles for same wallet initially
-- We'll handle wallet uniqueness in the application logic instead
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_wallet_address_unique;

-- Add a unique constraint on user_id instead to ensure one profile per authenticated user
ALTER TABLE public.profiles ADD CONSTRAINT profiles_user_id_unique UNIQUE (user_id);
-- Create RPC function to handle user creation/retrieval with proper security
CREATE OR REPLACE FUNCTION public.get_or_create_user_by_wallet(p_wallet_address text)
RETURNS SETOF public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    user_record public.users;
BEGIN
    SELECT * INTO user_record FROM public.users WHERE wallet_address = p_wallet_address;

    IF user_record IS NULL THEN
        INSERT INTO public.users (wallet_address) VALUES (p_wallet_address)
        RETURNING * INTO user_record;
    END IF;

    RETURN NEXT user_record;
END;
$$;
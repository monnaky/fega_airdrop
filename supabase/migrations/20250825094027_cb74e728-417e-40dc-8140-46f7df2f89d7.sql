-- Create withdrawals table
CREATE TABLE public.withdrawals (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.withdrawals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for withdrawals
CREATE POLICY "Users can insert their own withdrawals"
ON public.withdrawals FOR INSERT
WITH CHECK (user_id IN (SELECT id FROM users WHERE wallet_address = current_setting('app.current_wallet', true)));

CREATE POLICY "Users can view their own withdrawals"
ON public.withdrawals FOR SELECT
USING (user_id IN (SELECT id FROM users WHERE wallet_address = current_setting('app.current_wallet', true)));

CREATE POLICY "Admins can manage all withdrawals"
ON public.withdrawals FOR ALL
USING (current_setting('app.current_wallet', true) = 'ADMIN_WALLET_ADDRESS')
WITH CHECK (true);

-- Function to request withdrawal
CREATE OR REPLACE FUNCTION public.request_withdrawal(p_wallet_address TEXT, p_amount NUMERIC)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_balance NUMERIC;
  v_withdrawal_id UUID;
BEGIN
  -- Find user
  SELECT id, balance INTO v_user_id, v_balance
  FROM users
  WHERE wallet_address = p_wallet_address;

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not found');
  END IF;

  -- Check balance
  IF v_balance < p_amount THEN
    RETURN json_build_object('success', false, 'error', 'Insufficient balance');
  END IF;

  -- Deduct balance
  UPDATE users
  SET balance = balance - p_amount
  WHERE id = v_user_id;

  -- Create withdrawal
  INSERT INTO withdrawals (user_id, amount)
  VALUES (v_user_id, p_amount)
  RETURNING id INTO v_withdrawal_id;

  RETURN json_build_object(
    'success', true,
    'withdrawal_id', v_withdrawal_id,
    'amount', p_amount,
    'status', 'pending'
  );
END;
$$;

-- Function to process withdrawal
CREATE OR REPLACE FUNCTION public.process_withdrawal(p_withdrawal_id UUID, p_action TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_action NOT IN ('approve', 'reject') THEN
    RETURN json_build_object('success', false, 'error', 'Invalid action');
  END IF;

  UPDATE withdrawals
  SET status = CASE 
                 WHEN p_action = 'approve' THEN 'approved'
                 ELSE 'rejected'
               END
  WHERE id = p_withdrawal_id;

  RETURN json_build_object('success', true, 'withdrawal_id', p_withdrawal_id, 'status', p_action);
END;
$$;
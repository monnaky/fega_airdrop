-- Create admin settings update function
CREATE OR REPLACE FUNCTION public.admin_update_settings(
  weekly_claim_amount NUMERIC,
  referral_bonus NUMERIC, 
  min_withdrawal NUMERIC
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  admin_email TEXT;
BEGIN
  -- Get current user's email
  SELECT email INTO admin_email 
  FROM auth.users 
  WHERE id = auth.uid();
  
  -- Check if user is admin (replace with your admin email)
  IF admin_email IS NULL OR admin_email NOT IN ('admin@fega.io', 'support@fega.io') THEN
    RETURN json_build_object('success', false, 'error', 'Unauthorized access');
  END IF;
  
  -- Update settings
  INSERT INTO settings (key, value) VALUES ('weekly_claim_amount', weekly_claim_amount::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = weekly_claim_amount::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('referral_bonus', referral_bonus::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = referral_bonus::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('min_withdrawal_amount', min_withdrawal::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = min_withdrawal::TEXT;
  
  RETURN json_build_object('success', true, 'message', 'Settings updated successfully');
END;
$$;

-- Create admin data retrieval function
CREATE OR REPLACE FUNCTION public.get_admin_data()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  admin_email TEXT;
  result json;
BEGIN
  -- Get current user's email
  SELECT email INTO admin_email 
  FROM auth.users 
  WHERE id = auth.uid();
  
  -- Check if user is admin
  IF admin_email IS NULL OR admin_email NOT IN ('admin@fega.io', 'support@fega.io') THEN
    RETURN json_build_object('success', false, 'error', 'Unauthorized access');
  END IF;
  
  -- Get comprehensive admin data
  WITH user_stats AS (
    SELECT 
      u.id,
      u.wallet_address,
      u.balance,
      u.referral_count,
      u.created_at as user_created,
      COUNT(DISTINCT ut.task_id) as completed_tasks,
      COALESCE(SUM(t.reward), 0) as total_earned
    FROM users u
    LEFT JOIN user_tasks ut ON u.wallet_address = ut.user_wallet
    LEFT JOIN tasks t ON ut.task_id = t.id
    GROUP BY u.id, u.wallet_address, u.balance, u.referral_count, u.created_at
  ),
  withdrawal_data AS (
    SELECT 
      w.id as withdrawal_id,
      w.amount,
      w.status,
      w.created_at as withdrawal_created,
      u.wallet_address
    FROM withdrawals w
    JOIN users u ON w.user_id = u.id
    ORDER BY w.created_at DESC
  ),
  platform_stats AS (
    SELECT 
      COUNT(DISTINCT u.id) as total_users,
      SUM(u.balance) as total_balance,
      COUNT(DISTINCT ut.id) as total_task_completions,
      COUNT(DISTINCT w.id) as total_withdrawals,
      COALESCE(SUM(CASE WHEN w.status = 'pending' THEN w.amount ELSE 0 END), 0) as pending_withdrawals
    FROM users u
    LEFT JOIN user_tasks ut ON u.wallet_address = ut.user_wallet
    LEFT JOIN withdrawals w ON w.user_id = u.id
  )
  SELECT json_build_object(
    'success', true,
    'users', (SELECT json_agg(row_to_json(user_stats)) FROM user_stats),
    'withdrawals', (SELECT json_agg(row_to_json(withdrawal_data)) FROM withdrawal_data),
    'stats', (SELECT row_to_json(platform_stats) FROM platform_stats)
  ) INTO result;
  
  RETURN result;
END;
$$;

-- Create admin withdrawal processing function
CREATE OR REPLACE FUNCTION public.admin_process_withdrawal(
  withdrawal_id UUID,
  new_status TEXT
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  admin_email TEXT;
  withdrawal_amount NUMERIC;
  withdrawal_user_id UUID;
  current_status TEXT;
BEGIN
  -- Get current user's email
  SELECT email INTO admin_email 
  FROM auth.users 
  WHERE id = auth.uid();
  
  -- Check if user is admin
  IF admin_email IS NULL OR admin_email NOT IN ('admin@fega.io', 'support@fega.io') THEN
    RETURN json_build_object('success', false, 'error', 'Unauthorized access');
  END IF;
  
  -- Validate status
  IF new_status NOT IN ('approved', 'rejected') THEN
    RETURN json_build_object('success', false, 'error', 'Invalid status. Must be approved or rejected');
  END IF;
  
  -- Get withdrawal details
  SELECT amount, user_id, status INTO withdrawal_amount, withdrawal_user_id, current_status
  FROM withdrawals 
  WHERE id = withdrawal_id;
  
  IF withdrawal_amount IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Withdrawal not found');
  END IF;
  
  IF current_status != 'pending' THEN
    RETURN json_build_object('success', false, 'error', 'Withdrawal already processed');
  END IF;
  
  -- If rejecting, refund the amount to user's balance
  IF new_status = 'rejected' THEN
    UPDATE users 
    SET balance = balance + withdrawal_amount::INTEGER
    WHERE id = withdrawal_user_id;
  END IF;
  
  -- Update withdrawal status
  UPDATE withdrawals 
  SET status = new_status
  WHERE id = withdrawal_id;
  
  RETURN json_build_object(
    'success', true, 
    'withdrawal_id', withdrawal_id,
    'status', new_status,
    'amount', withdrawal_amount
  );
END;
$$;
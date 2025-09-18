CREATE OR REPLACE FUNCTION public.complete_task_enhanced(p_wallet_address text, p_task_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id UUID;
  v_task_reward INTEGER;
  v_existing_completion BOOLEAN;
BEGIN
  -- Find user ID from wallet address
  SELECT id INTO v_user_id 
  FROM users 
  WHERE wallet_address = p_wallet_address;
  
  -- If user doesn't exist, create them
  IF v_user_id IS NULL THEN
    INSERT INTO users (wallet_address) 
    VALUES (p_wallet_address)
    RETURNING id INTO v_user_id;
  END IF;
  
  -- Check if task is already completed
  SELECT EXISTS(
    SELECT 1 FROM user_tasks 
    WHERE user_wallet = p_wallet_address 
    AND task_id = p_task_id
  ) INTO v_existing_completion;
  
  IF v_existing_completion THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Task already completed'
    );
  END IF;
  
  -- Get task reward amount
  SELECT reward INTO v_task_reward 
  FROM tasks 
  WHERE id = p_task_id;
  
  IF v_task_reward IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Task not found'
    );
  END IF;
  
  -- Insert task completion record
  INSERT INTO user_tasks (user_wallet, task_id)
  VALUES (p_wallet_address, p_task_id);
  
  -- Update user balance
  UPDATE users 
  SET balance = balance + v_task_reward
  WHERE id = v_user_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Task completed successfully!',
    'reward', v_task_reward
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$function$
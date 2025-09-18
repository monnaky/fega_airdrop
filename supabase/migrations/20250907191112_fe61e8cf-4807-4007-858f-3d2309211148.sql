-- Create get_withdrawal_status function for withdrawal countdown
CREATE OR REPLACE FUNCTION public.get_withdrawal_status(p_wallet_address TEXT)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  next_saturday TIMESTAMP WITH TIME ZONE;
  curr_time TIMESTAMP WITH TIME ZONE;
  countdown_hours INTEGER;
  is_available BOOLEAN;
BEGIN
  curr_time := NOW();
  
  -- Calculate next Saturday 00:00 UTC
  next_saturday := date_trunc('week', curr_time) + INTERVAL '6 days';
  
  -- If current time is past this Saturday, move to next Saturday
  IF curr_time >= next_saturday THEN
    next_saturday := next_saturday + INTERVAL '7 days';
  END IF;
  
  -- Calculate countdown hours
  countdown_hours := EXTRACT(EPOCH FROM (next_saturday - curr_time)) / 3600;
  
  -- Check if withdrawal is available (within 1 hour window on Saturday)
  is_available := (curr_time >= next_saturday AND curr_time <= next_saturday + INTERVAL '1 hour');
  
  RETURN json_build_object(
    'next_available_date', next_saturday,
    'is_available', is_available,
    'countdown_hours', FLOOR(countdown_hours)
  );
END;
$function$
-- Fix the security warning by setting proper search path
CREATE OR REPLACE FUNCTION public.calculate_referral_earnings(referrer_profile_id uuid)
RETURNS integer AS $$
DECLARE
  total_earnings integer := 0;
BEGIN
  -- Count successful referrals (those who have completed at least one task)
  SELECT COUNT(DISTINCT r.referred_id) * 50 INTO total_earnings
  FROM referrals r
  INNER JOIN task_completions tc ON tc.user_id = (
    SELECT user_id FROM profiles WHERE id = r.referred_id
  )
  WHERE r.referrer_id = referrer_profile_id;
  
  RETURN COALESCE(total_earnings, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public';
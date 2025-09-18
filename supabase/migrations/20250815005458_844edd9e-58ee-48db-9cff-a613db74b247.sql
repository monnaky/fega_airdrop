-- Fix existing profile with null user_id and update referral tracking
-- First, update the existing profile to have the correct user_id
UPDATE public.profiles 
SET user_id = '4f3904ae-4591-427b-bcab-cae67f12c9c5' 
WHERE wallet_address = '0x19d9edb0d6b6635bb24062537d6478cedf6a0874' AND user_id IS NULL;

-- Add a function to calculate referral earnings properly
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
$$ LANGUAGE plpgsql SECURITY DEFINER;
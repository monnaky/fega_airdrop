-- Fix critical security vulnerability: Add user_id to profiles table and implement proper RLS
-- This addresses the exposed wallet addresses and user activity data

-- First, add user_id column to profiles table to link with auth.users
ALTER TABLE public.profiles ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Update existing profiles to have a user_id (this will need to be handled manually in production)
-- For now, we'll update the table structure and existing data will need migration

-- Create index for performance
CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);

-- Drop the old public policy and create secure user-specific policies
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can update profiles" ON public.profiles;

-- Create secure RLS policies for profiles
CREATE POLICY "Users can view their own profile" 
ON public.profiles 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own profile" 
ON public.profiles 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" 
ON public.profiles 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Fix claims table RLS
DROP POLICY IF EXISTS "Claims are viewable by everyone" ON public.claims;
DROP POLICY IF EXISTS "Anyone can insert claims" ON public.claims;

CREATE POLICY "Users can view their own claims" 
ON public.claims 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own claims" 
ON public.claims 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Fix task_completions table RLS  
DROP POLICY IF EXISTS "Task completions are viewable by everyone" ON public.task_completions;
DROP POLICY IF EXISTS "Anyone can insert task completions" ON public.task_completions;

CREATE POLICY "Users can view their own task completions" 
ON public.task_completions 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own task completions" 
ON public.task_completions 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Fix referrals table RLS
DROP POLICY IF EXISTS "Referrals are viewable by everyone" ON public.referrals;
DROP POLICY IF EXISTS "Anyone can insert referrals" ON public.referrals;

CREATE POLICY "Users can view referrals they made" 
ON public.referrals 
FOR SELECT 
USING (auth.uid() = referrer_id);

CREATE POLICY "Users can view referrals they received" 
ON public.referrals 
FOR SELECT 
USING (auth.uid() = referred_id);

CREATE POLICY "Users can create referrals they initiated" 
ON public.referrals 
FOR INSERT 
WITH CHECK (auth.uid() = referrer_id);

-- Create security definer function for admin access (to avoid recursion)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  -- For now, we'll use a simple check - in production you'd want proper role management
  -- This function will be enhanced with proper role checking later
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Admin policies for legitimate admin access (using security definer function)
CREATE POLICY "Admins can view all profiles" 
ON public.profiles 
FOR SELECT 
USING (public.is_admin());

CREATE POLICY "Admins can view all claims" 
ON public.claims 
FOR SELECT 
USING (public.is_admin());

CREATE POLICY "Admins can view all task completions" 
ON public.task_completions 
FOR SELECT 
USING (public.is_admin());

CREATE POLICY "Admins can view all referrals" 
ON public.referrals 
FOR SELECT 
USING (public.is_admin());
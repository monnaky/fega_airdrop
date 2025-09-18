-- Create profiles table for user data
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  wallet_address TEXT NOT NULL UNIQUE,
  referred_by UUID REFERENCES public.profiles(id),
  referral_count INTEGER NOT NULL DEFAULT 0,
  total_tasks_completed INTEGER NOT NULL DEFAULT 0,
  total_tokens_earned INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create tasks table for admin-managed tasks
CREATE TABLE public.tasks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  task_type TEXT NOT NULL CHECK (task_type IN ('twitter_follow', 'telegram_join', 'youtube_subscribe', 'instagram_follow', 'tiktok_follow', 'custom')),
  task_url TEXT NOT NULL,
  reward_tokens INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create task_completions table to track user task completions
CREATE TABLE public.task_completions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  completion_date DATE NOT NULL DEFAULT CURRENT_DATE,
  completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(user_id, task_id, completion_date)
);

-- Create claims table to track weekly claims
CREATE TABLE public.claims (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  tokens_claimed INTEGER NOT NULL DEFAULT 1000,
  referral_bonus INTEGER NOT NULL DEFAULT 0,
  transaction_hash TEXT,
  claim_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(user_id, claim_date)
);

-- Create referrals table to track referral connections
CREATE TABLE public.referrals (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  referred_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  tokens_earned INTEGER NOT NULL DEFAULT 200,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(referred_id)
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "Users can view their own profile" 
ON public.profiles 
FOR SELECT 
USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update their own profile" 
ON public.profiles 
FOR UPDATE 
USING (auth.uid()::text = id::text);

CREATE POLICY "Users can insert their own profile" 
ON public.profiles 
FOR INSERT 
WITH CHECK (auth.uid()::text = id::text);

-- Create policies for tasks (public read, admin write)
CREATE POLICY "Tasks are viewable by everyone" 
ON public.tasks 
FOR SELECT 
USING (true);

CREATE POLICY "Only admins can modify tasks" 
ON public.tasks 
FOR ALL 
USING (false)
WITH CHECK (false);

-- Create policies for task_completions
CREATE POLICY "Users can view their own task completions" 
ON public.task_completions 
FOR SELECT 
USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert their own task completions" 
ON public.task_completions 
FOR INSERT 
WITH CHECK (auth.uid()::text = user_id::text);

-- Create policies for claims
CREATE POLICY "Users can view their own claims" 
ON public.claims 
FOR SELECT 
USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert their own claims" 
ON public.claims 
FOR INSERT 
WITH CHECK (auth.uid()::text = user_id::text);

-- Create policies for referrals
CREATE POLICY "Users can view their referrals" 
ON public.referrals 
FOR SELECT 
USING (auth.uid()::text = referrer_id::text OR auth.uid()::text = referred_id::text);

CREATE POLICY "Users can insert referrals" 
ON public.referrals 
FOR INSERT 
WITH CHECK (auth.uid()::text = referred_id::text);

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Insert default tasks
INSERT INTO public.tasks (title, description, task_type, task_url, reward_tokens) VALUES
('Follow FEGA on Twitter', 'Follow our official Twitter account for updates', 'twitter_follow', 'https://twitter.com/fegatoken', 50),
('Join FEGA Telegram', 'Join our Telegram community', 'telegram_join', 'https://t.me/fegatoken', 50),
('Subscribe to FEGA YouTube', 'Subscribe to our YouTube channel', 'youtube_subscribe', 'https://youtube.com/@fegatoken', 75),
('Follow FEGA on Instagram', 'Follow us on Instagram', 'instagram_follow', 'https://instagram.com/fegatoken', 50),
('Follow FEGA on TikTok', 'Follow our TikTok account', 'tiktok_follow', 'https://tiktok.com/@fegatoken', 50);
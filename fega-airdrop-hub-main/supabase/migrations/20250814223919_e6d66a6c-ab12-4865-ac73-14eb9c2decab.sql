-- Create platform_settings table for admin settings
CREATE TABLE public.platform_settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  setting_key TEXT NOT NULL UNIQUE,
  setting_value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Create policies - only admins can access settings
CREATE POLICY "Only admins can view settings"
ON public.platform_settings
FOR SELECT
USING (is_admin());

CREATE POLICY "Only admins can insert settings"
ON public.platform_settings
FOR INSERT
WITH CHECK (is_admin());

CREATE POLICY "Only admins can update settings"
ON public.platform_settings
FOR UPDATE
USING (is_admin());

CREATE POLICY "Only admins can delete settings"
ON public.platform_settings
FOR DELETE
USING (is_admin());

-- Insert default settings
INSERT INTO public.platform_settings (setting_key, setting_value, description) VALUES
('base_reward', '100', 'Base reward amount for tasks'),
('referral_bonus', '50', 'Bonus amount for referrals'),
('claim_fee', '0.001', 'Fee for claiming tokens'),
('admin_wallet', '0x19d9Edb0D6B6635bB24062537d6478CedF6a0874', 'Admin wallet address');

-- Add trigger for updated_at
CREATE TRIGGER update_platform_settings_updated_at
BEFORE UPDATE ON public.platform_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
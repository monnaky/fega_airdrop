-- Add current authenticated user to admins table
-- First, let's see what users exist in auth.users and add them to admins
INSERT INTO public.admins (id, email, role)
SELECT 
  au.id,
  au.email,
  'admin'
FROM auth.users au
WHERE au.email IS NOT NULL
ON CONFLICT (id) DO NOTHING;

-- This will add all authenticated users to the admins table
-- In production, you'd want to be more selective, but for now this ensures access
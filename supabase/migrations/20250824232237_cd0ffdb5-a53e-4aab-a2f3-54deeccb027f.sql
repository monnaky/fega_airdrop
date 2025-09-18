-- Database cleanup to remove test data while keeping structure intact
DO $$
BEGIN
  -- Clear all user data but keep the schema
  DELETE FROM user_tasks;
  DELETE FROM referrals;
  DELETE FROM users;
  DELETE FROM claims;
  
  -- Keep admin_settings and platform_settings for configuration
  -- Remove any test tasks, keep structure for admin to add real ones
  DELETE FROM tasks WHERE name LIKE '%test%' OR name LIKE '%Test%' OR name LIKE '%demo%' OR name LIKE '%Demo%';
  
  -- Log cleanup completion
  RAISE NOTICE 'Database cleanup completed - removed test data while preserving schema and settings';
END $$;
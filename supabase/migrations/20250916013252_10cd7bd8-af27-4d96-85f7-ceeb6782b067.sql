-- Final attempt: Ensure trigger exists through manual verification
DO $$ 
BEGIN
    -- Check if trigger exists, create if not
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'on_user_referral' 
        AND tgrelid = 'users'::regclass
    ) THEN
        -- Create the trigger
        EXECUTE 'CREATE TRIGGER on_user_referral AFTER INSERT ON users FOR EACH ROW EXECUTE FUNCTION process_referral()';
        RAISE NOTICE 'Trigger on_user_referral created successfully';
    ELSE
        RAISE NOTICE 'Trigger on_user_referral already exists';
    END IF;
END $$;
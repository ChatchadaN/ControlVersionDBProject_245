

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_update_package_device_combine]
       @limit_id int,
       @package_group varchar(MAX),
       @package_name varchar(MAX),
       @device_name varchar(MAX),
       @limit_of_lot int,
       @is_enable bit,
       @updated_by varchar(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert history log
    INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
        ([record_at], [record_class], [login_name], [hostname], [appname], [command_text])
    SELECT GETDATE(),
           '4',
           ORIGINAL_LOGIN(),
           HOST_NAME(),
           APP_NAME(),
           'EXEC [dbo].[sp_set_update_package_device_combine] @package_group = ''' 
           + @package_group + ''', @package_name = ''' 
           + @package_name + ''', @device_name = ''' 
           + @device_name + ''', @limit_of_lot = ''' 
           + CONVERT(varchar, @limit_of_lot) + ''', @is_enable = ''' 
           + CONVERT(varchar, @is_enable) + ''', @updated_at = ''' 
           + CONVERT(varchar, GETDATE()) + ''', @updated_by = ''' 
           + @updated_by + '''';

    -- Update record if conditions are met
    IF (@limit_id <> 0 AND @package_group IS NOT NULL AND @package_name IS NOT NULL 
        AND @device_name IS NOT NULL AND @limit_of_lot IS NOT NULL 
        AND @is_enable IN (0, 1) AND @updated_by IS NOT NULL)
    BEGIN
        UPDATE APCSProDWH.tg.condition_mix_limit_lot WITH (ROWLOCK)
        SET package_group = @package_group,
            package_name = @package_name,
            device_name = @device_name,
            limit_of_lot = @limit_of_lot,
            is_enable = @is_enable,
			update_at = GETDATE(),
            update_by = @updated_by
        WHERE limit_id = @limit_id;
    END
END


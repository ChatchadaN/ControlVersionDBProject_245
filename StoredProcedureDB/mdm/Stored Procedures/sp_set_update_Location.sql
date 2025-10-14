
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_update_Location]

	@id AS INT,
	@name AS VARCHAR(MAX),
	@headquarter_id AS INT,
	@address AS VARCHAR(MAX),
	@updated_by AS INT

AS
BEGIN
    SET NOCOUNT ON;

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at], [record_class], [login_name], [hostname], [appname], [command_text])
		SELECT 
			GETDATE(),
			'4',
			ORIGINAL_LOGIN(),
			HOST_NAME(),
			APP_NAME(),
			'EXEC [dbo].[sp_set_add_Location] @id = ''' + CONVERT(varchar, @id) + ''', @name = ''' + @name + '''
			, @headquarter_id = ''' + CONVERT(varchar, @headquarter_id) + ''', @address = ''' + @address + '''
			, @updated_at = ''' + CONVERT(varchar, GETDATE(), 120) + ''', @updated_by = ''' + CONVERT(varchar, @updated_by) + ''''; 

    -- Update record if conditions are met
    --IF (@name IS NOT NULL AND @address IS NOT NULL AND @id IS NOT NULL)
	IF (@name IS NOT NULL AND @id IS NOT NULL)
    BEGIN
        UPDATE [APCSProDB].[trans].[locations] WITH (ROWLOCK)
        SET name = @name,
            headquarter_id = @headquarter_id,
            address = @address,
			updated_at = GETDATE(),
            updated_by = @updated_by
        WHERE id = @id;
    END
END
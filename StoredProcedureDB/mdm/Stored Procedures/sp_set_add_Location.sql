

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_add_Location]
	-- Add the parameters for the stored procedure here
	@id AS INT,
	@name AS VARCHAR(MAX),
	@headquarter_id AS INT,
	@address AS VARCHAR(MAX),
	@created_by AS INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE	@Locid AS INT = 0
	IF (CONVERT(INT, @id) = 999999)
		BEGIN
		--SET @id = (SELECT COUNT (*) + 1 FROM [APCSProDB].[trans].[locations])
		SET @Locid = (SELECT TOP 1 id + 1 FROM [APCSProDB].[trans].[locations] order by id desc)
	END
	
	IF (@Locid <> 0 AND @id <> 0)
		BEGIN

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at], [record_class], [login_name], [hostname], [appname], [command_text])
		SELECT 
			GETDATE(),
			'4',
			ORIGINAL_LOGIN(),
			HOST_NAME(),
			APP_NAME(),
			'EXEC [dbo].[sp_set_add_Location] @id = ''' + CONVERT(varchar, @Locid) + ''', @name = ''' + @name + '''
			, @headquarter_id = ''' + CONVERT(varchar, @headquarter_id) + ''', @address = ''' + @address + '''
			, @created_at = ''' + CONVERT(varchar, GETDATE(), 120) + ''', @created_by = ''' + CONVERT(varchar, @created_by) + ''''; 



	BEGIN TRANSACTION
	BEGIN TRY
	--SET IDENTITY_INSERT [APCSProDWH].[tg].[condition_mix_limit_lot] ON;
		INSERT INTO [APCSProDB].[trans].[locations]
			   ([id]
			   ,[name]
			   ,[headquarter_id]
			   ,[address]
			   ,[x]
			   ,[y]
			   ,[z]
			   ,[depth]
			   ,[queue]
			   ,[wh_code]
			   ,[created_at]
			   ,[created_by]
			   ,[updated_at]
			   ,[updated_by]
			   )
		 VALUES
			   (@Locid
			   ,@name
			   ,@headquarter_id
			   ,@address
			   ,NULL
			   ,NULL
			   ,NULL
			   ,NULL
			   ,NULL
			   ,NULL
			   ,GETDATE()
			   ,@created_by
			   ,NULL
			   ,NULL
			   )
		COMMIT; 
			--SET IDENTITY_INSERT [APCSProDWH].[tg].[condition_mix_limit_lot] OFF;
		END TRY

		BEGIN CATCH
			ROLLBACK;
			SELECT 'FALSE' AS Is_Pass ,'Register fail. !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
		END CATCH
	END
END
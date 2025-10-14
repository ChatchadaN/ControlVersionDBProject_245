
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_add_package_device_combine]
	-- Add the parameters for the stored procedure here
	--@Limit_id  AS INT,
	@package_group AS VARCHAR(MAX),
	@package_name AS VARCHAR(MAX),
	@device_name AS VARCHAR(MAX),
	@limit_of_lot AS INT,
	@is_enable bit,
	@create_by varchar(MAX)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE	@id AS INT = 0
	--IF (@Limit_id = 9999)
	--	BEGIN
	--	SET @id = (SELECT TOP 1 limit_id + 1  FROM [APCSProDWH].[tg].[condition_mix_limit_lot] order by limit_id desc)
	--	--SELECT 'FALSE' AS Is_Pass,'Material Set is duplicate. !!' AS Error_Message_ENG,N'Material Set ไม่สามารถลงทะเบียนซ้ำกันได้ !!' AS Error_Message_THA
	--	--RETURN
	--END
	
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
        ([record_at], [record_class], [login_name], [hostname], [appname], [command_text])
    SELECT GETDATE(),
           '4',
           ORIGINAL_LOGIN(),
           HOST_NAME(),
           APP_NAME(),
           'EXEC [dbo].[sp_set_add_package_device_combine] @package_group = ''' 
           + @package_group + ''', @package_name = ''' 
           + @package_name + ''', @device_name = ''' 
           + @device_name + ''', @limit_of_lot = ''' 
           + CONVERT(varchar, @limit_of_lot) + ''', @is_enable = ''' 
           + CONVERT(varchar, @is_enable) + ''', @create_at = ''' 
           + CONVERT(varchar, GETDATE()) + ''', @create_by = ''' 
           + @create_by + '''';

	BEGIN TRANSACTION
	BEGIN TRY
	--SET IDENTITY_INSERT [APCSProDWH].[tg].[condition_mix_limit_lot] ON;
		INSERT INTO [APCSProDWH].[tg].[condition_mix_limit_lot]
			   ([package_group]
			   ,[package_name]
			   ,[device_name]
			   ,[limit_of_lot]
			   ,[is_enable]
			   ,[create_at]
			   ,[create_by]
			   ,[update_at]
			   ,[update_by]
			   ,[started_at]
			   ,[ended_at])		   
		 VALUES
			   (@package_group
			   ,@package_name
			   ,@device_name
			   ,@limit_of_lot
			   ,@is_enable
			   ,GETDATE()
			   ,@create_by
			   ,NULL
			   ,NULL
			   ,NULL
			   ,NULL)
		COMMIT; 
		--SET IDENTITY_INSERT [APCSProDWH].[tg].[condition_mix_limit_lot] OFF;
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Register fail. !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
	END CATCH
	
END

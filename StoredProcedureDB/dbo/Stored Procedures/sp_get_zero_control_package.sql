-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_zero_control_package]
	-- Add the parameters for the stored procedure here
	@package varchar(20) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[sp_get_zero_control_package] @job = '''+ @package + ''''

	IF @package != ''
	BEGIN
		IF @package in ('TO263-3','TO263-3F','TO263-5','TO263-5F','TO263-7','TO263-9','HRP5','HRP7','TO252-5')
		BEGIN
			select '1' as Status --1 : is enabled
		END
		ELSE
		BEGIN
			select '0' as Status --2 : is disabled
		END
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Status ,'SELECT DATA ERROR !!' AS Error_Message_ENG,N'ไม่ได้ส่งค่า ข้อมูล Package มา !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END
    

END

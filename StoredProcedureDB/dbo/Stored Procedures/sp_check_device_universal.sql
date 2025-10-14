-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_check_device_universal]
	-- Add the parameters for the stored procedure here
	@device varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @TypeName_Val char(20)

	--SELECT @TypeName_Val = [Type_Name] FROM [StoredProcedureDB].[dbo].[IS_UNIV_STD_M] where Type_Name = @device  --close 2023/07/20 time : 16.51 by Aomsin

	SELECT @TypeName_Val = universal_tp_rank FROM APCSProDB.method.device_names WHERE name = @device

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
		,'EXEC [dbo].[sp_check_device_universal] @lotno = ''' + @device + ''',@device = ''' + ''''

	BEGIN TRY 
	IF @TypeName_Val != ' ' 
	BEGIN
		SELECT 'TRUE' AS Status ,'Device is Universal !!' AS Error_Message_ENG,N'ค้นหาข้อมูลสำเร็จ !!' AS Error_Message_THA
	    RETURN
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Status ,'Device is not Universal !!' AS Error_Message_ENG,N'ไม่พบข้อมูล !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END
	END TRY
	BEGIN CATCH 
		SELECT 'FALSE' AS Status ,'ERROR !!' AS Error_Message_ENG,N'ไม่เข้า Function Check Data !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH

END

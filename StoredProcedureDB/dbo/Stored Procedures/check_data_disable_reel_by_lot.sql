
-- =============================================
-- Author:		<Author,,Name Vanatjaya P. Aomsin>
-- Create date: <Create Date,2024/03/27, Time : 14.22>
-- Description:	<Description,for tp cellcon check data a lot is disable reel,>
-- =============================================
CREATE PROCEDURE [dbo].[check_data_disable_reel_by_lot]
	-- Add the parameters for the stored procedure here
	 @lotno varchar(10) = ''
	,@mcno char(10) = ''
AS
BEGIN
	DECLARE @max_count_reel_all int = null
	DECLARE @max_reel int = null
	
	select @max_reel = MAX(no_reel) from APCSProDB.trans.label_issue_records 
	where lot_no = @lotno and type_of_label = 0
	select @max_count_reel_all = Count(no_reel) from APCSProDB.trans.label_issue_records 
	where lot_no = @lotno and type_of_label in (0,3)

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
		)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [dbo].[check_data_disable_reel_by_lot] @lotno_standard = ''' + @lotno 
		  + ''', @mcno = ''' + @mcno + ''''
		, @lotno

	IF @max_reel = @max_count_reel_all
	BEGIN
		
		SELECT 'TRUE' AS Status ,'There is a last disable reel' AS Error_Message_ENG,N'มีการ Disable Reel สุดท้าย !!' AS Error_Message_THA,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Status ,'No disable reel' AS Error_Message_ENG,N'ไม่มีการ Disable Reel สุดท้าย !!' AS Error_Message_THA,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

END

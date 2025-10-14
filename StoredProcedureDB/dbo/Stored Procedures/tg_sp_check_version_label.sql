-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_check_version_label]
	-- Add the parameters for the stored procedure here
	 @lotno varchar(10) = ''
	,@Type_label int = 0
	,@reel_number char(3) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--DECLARE @check_version int = 0
    -- Insert statements for procedure here
	

	IF @lotno != ''
	BEGIN
		IF @reel_number = '0'
		BEGIN
			select no_reel,version from APCSProDB.trans.label_issue_records where lot_no = @lotno and type_of_label = @Type_label
		END
		ELSE
		BEGIN
			select no_reel,version from APCSProDB.trans.label_issue_records where lot_no = @lotno and type_of_label = @Type_label
			and no_reel = @reel_number
		END
		
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Status ,'SELECT DATA ERROR !!' AS Error_Message_ENG,N'ไม่พบข้อมูล lotno นี้' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

END

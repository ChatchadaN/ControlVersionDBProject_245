-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_check_flow_tp]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Process_Value char(20) = ''
    -- Insert statements for procedure here
	select 
    @Process_Value =  [processes].[name] 
	from [APCSProDB].[trans].[lots] with (NOLOCK) 
	inner join [APCSProDB].[method].[processes] with (NOLOCK) on [lots].[act_process_id] = [processes].[id]
	WHERE lot_no = @lotno

	IF @Process_Value != 'TP'
	BEGIN
		SELECT 'FALSE' AS Status ,'WIP STATE ERROR !!' AS Error_Message_ENG,N'Lotno นี้ไม่ใช้ WIP ที่จะผลิต Process นี้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END
	ELSE
	BEGIN
		SELECT 'TRUE' AS Status ,'WIP STATE CORRECT !!' AS Error_Message_ENG,N'Lotno นี้ สามารถผลิตงานที่ Process นี้ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

END

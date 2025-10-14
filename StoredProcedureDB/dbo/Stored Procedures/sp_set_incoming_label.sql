-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_incoming_label]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
	,@empNo char(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	---- ########## VERSION 001 ##########
	EXEC [StoredProcedureDB].[dbo].[sp_set_incoming_label_backup20221209] @lotno = @lotno
		, @empNo = @empNo;
	---- ########## VERSION 001 ##########	

	------ ########## VERSION 002 ##########
	--EXEC [StoredProcedureDB].[dbo].[sp_set_incoming_label_new20221209] @lotno = @lotno
	--	, @empNo = @empNo;
	---- ########## VERSION 002 ##########	
END

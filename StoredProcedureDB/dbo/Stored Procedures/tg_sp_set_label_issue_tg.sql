-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,2022/03/15 time : 13.51,update stock class = 01 all table>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_label_issue_tg]
	-- Add the parameters for the stored procedure here
	 @lotno_standard varchar(10) = ''
	,@empno char(6) = ' ' --edit @empno form char 5 is char 6
	,@machine_id_val int = null

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	---- ########## VERSION 001 ##########
	-- call 2022/12/07 Time : 16.35
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_label_issue_tg_backup20221208] @lotno_standard = @lotno_standard
	--	, @empno = @empno
	---- ########## VERSION 001 ##########

	---- ########## VERSION 002 ##########
	---- call new store create 2022/12/07 Time : 09.30
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_label_issue_tg_new] @lotno_standard = @lotno_standard
		, @empno = @empno
		, @machine_id_val = @machine_id_val
	---- ########## VERSION 002 ##########

END

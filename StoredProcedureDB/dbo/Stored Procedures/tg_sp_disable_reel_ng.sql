-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_disable_reel_ng]
	-- Add the parameters for the stored procedure here
	 @lotno_standard varchar(10) = ''
	 --,@reel_no int = 0 
	 ,@reel_no NVARCHAR(max) = ''
	 ,@count_reel_ng int = 0
	 ,@qty_input int = 0 --qty_out_before
	 ,@qty_good int = 0
	 ,@emp_no char(6) = ''
	 ,@state int = 0  --1 = web , 0 = cellcon
AS
BEGIN
	
	SET NOCOUNT ON;

	------ ########## VERSION 001 ##########
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_disable_reel_ng_ver_001]
	--	@lotno_standard = @lotno_standard, 
	--	@reel_no = @reel_no,
	--	@count_reel_ng = @count_reel_ng,
	--	@qty_input = @qty_input,
	--	@qty_good = @qty_good, 
	--	@emp_no = @emp_no,
	--	@state = @state;
	------ ########## VERSION 001 ##########

	---- ########## VERSION 002 ##########
	EXEC [StoredProcedureDB].[dbo].[tg_sp_disable_reel_ng_ver_002]
		@lotno_standard = @lotno_standard, 
		@reel_no = @reel_no,
		@count_reel_ng = @count_reel_ng,
		@qty_input = @qty_input,
		@qty_good = @qty_good, 
		@emp_no = @emp_no,
		@state = @state;
	---- ########## VERSION 002 ##########
END

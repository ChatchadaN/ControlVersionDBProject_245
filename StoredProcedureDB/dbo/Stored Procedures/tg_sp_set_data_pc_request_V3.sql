-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,Test New Version >
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_data_pc_request_V3] 
	-- Add the parameters for the stored procedure here
	 @newlot varchar(10)
	,@new_qty int = 0
	,@out_out_flag char(5) = ''
	,@pdcd_Adjust char(5) = '' --add parameter 2021/07/06
	,@hasuu_qty_After int = 0
	,@lot_hasuu_1 varchar(10) = ''
	,@lot_hasuu_2 varchar(10) = ''
	,@lot_hasuu_3 varchar(10) = ''
	,@lot_hasuu_4 varchar(10) = ''
	,@lot_hasuu_5 varchar(10) = ''
	,@empno char(6) = ''
	
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--call new store create 2022/12/07 Time : 09.33
	------------------------------------------------------------------------------------------------
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_pc_request_V3_new] @newlot	= @newlot
	,@new_qty	= @new_qty
	,@out_out_flag	= @out_out_flag
	,@pdcd_Adjust	= @pdcd_Adjust
	,@hasuu_qty_After	= @hasuu_qty_After
	,@lot_hasuu_1	= @lot_hasuu_1
	,@lot_hasuu_2	= @lot_hasuu_2
	,@lot_hasuu_3	= @lot_hasuu_3
	,@lot_hasuu_4	= @lot_hasuu_4
	,@lot_hasuu_5	= @lot_hasuu_5
	,@empno	 = @empno
	------------------------------------------------------------------------------------------------

	--call store current create 2022/12/07 Time : 16.35
	------------------------------------------------------------------------------------------------
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_pc_request_V3_backup20220812] @newlot  = @newlot
	--,@new_qty	= @new_qty
	--,@out_out_flag	= @out_out_flag
	--,@pdcd_Adjust	= @pdcd_Adjust
	--,@hasuu_qty_After	= @hasuu_qty_After
	--,@lot_hasuu_1	= @lot_hasuu_1
	--,@lot_hasuu_2	= @lot_hasuu_2
	--,@lot_hasuu_3	= @lot_hasuu_3
	--,@lot_hasuu_4	= @lot_hasuu_4
	--,@lot_hasuu_5	= @lot_hasuu_5
	--,@empno	 = @empno
	------------------------------------------------------------------------------------------------


END

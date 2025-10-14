-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, update 2022/02/01,time : 16.06>
-- Description:	<Description,use hasuu stock in and pc request sample lot (E,H)  ,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_sample_lot]
	-- Add the parameters for the stored procedure here
	 @lotno_standard varchar(10) 
	,@lotno_standard_qty int = 0
	,@empno char(6) = ''
	,@pc_inst_code_val int = 0
	,@is_ajd_qty_standard_tube int = 0  --add parameter support work tube 2022/06/20 time : 13.53
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--call new store create 2022/12/07 Time : 09.35
	------------------------------------------------------------------------------------------------
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_sample_lot_new]  @lotno_standard  =  @lotno_standard
	,@lotno_standard_qty  = @lotno_standard_qty
	,@empno  = @empno
	,@pc_inst_code_val  = @pc_inst_code_val
	,@is_ajd_qty_standard_tube  = @is_ajd_qty_standard_tube
	------------------------------------------------------------------------------------------------

	--call store current create 2022/12/07 Time : 16.34
	------------------------------------------------------------------------------------------------
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_sample_lot_backup20221208]  @lotno_standard  =  @lotno_standard
	--,@lotno_standard_qty  = @lotno_standard_qty
	--,@empno  = @empno
	--,@pc_inst_code_val  = @pc_inst_code_val
	--,@is_ajd_qty_standard_tube  = @is_ajd_qty_standard_tube
	------------------------------------------------------------------------------------------------


END

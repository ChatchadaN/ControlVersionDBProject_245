-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_qty_hasuu_after_run_v2]
	-- Add the parameters for the stored procedure here
	 @standard_lot varchar(10) = ''
	,@hasuu_lot varchar(10) = ''
	,@qty_hasuu_before INT = 0
	,@qty_hasuu_now INT = 0
	,@qty_pass_now INT = 0
	--add parameter 2022/02/01 time : 13.23
	,@is_insp int = 0  --is_insp = 1
	--add parameter 2022/03/01 time : 11.07
	,@is_map varchar(5) = '' --is_map = MAP
	--add parameter 2022/03/04 time : 13.27
	,@is_web_lsms int = 0
	--add parameter 2022/03/23 time : 09.31
	,@qty_shipment_now int = 0
	--add paramter 2022/06/29 time : 09.19
	,@is_instock char(1) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--call new store create 2022/12/07 Time : 09.37
	------------------------------------------------------------------------------------------------
	EXEC [StoredProcedureDB].[dbo].[tg_sp_update_qty_hasuu_after_run_v3] @standard_lot = @standard_lot
	,@hasuu_lot = @hasuu_lot
	,@qty_hasuu_before = @qty_hasuu_before
	,@qty_hasuu_now = @qty_hasuu_now
	,@qty_pass_now = @qty_pass_now
	,@is_insp = @is_insp
	,@is_map = @is_map
	,@is_web_lsms = @is_web_lsms
	,@qty_shipment_now = @qty_shipment_now
	,@is_instock = @is_instock
	------------------------------------------------------------------------------------------------

	--call store current create 2022/12/07 Time : 16.32
	------------------------------------------------------------------------------------------------
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_update_qty_hasuu_after_run_v2_backup20221208] @standard_lot = @standard_lot
	--,@hasuu_lot = @hasuu_lot
	--,@qty_hasuu_before = @qty_hasuu_before
	--,@qty_hasuu_now = @qty_hasuu_now
	--,@qty_pass_now = @qty_pass_now
	--,@is_insp = @is_insp
	--,@is_map = @is_map
	--,@is_web_lsms = @is_web_lsms
	--,@qty_shipment_now = @qty_shipment_now
	--,@is_instock = @is_instock
	------------------------------------------------------------------------------------------------

END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,2022/03/15-time : 13.49, update stock class = 01 all table>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_auto_continue_lot_V3]
	-- Add the parameters for the stored procedure here
	@lotno_standard varchar(10) = ' '
	,@hasuu_lot varchar(10) = ' '
	,@hasuu_qty int = 0
	,@lotno_standard_qty int = 0
	,@empno varchar(6) = ' '
	,@MNo_Hasuu char(10) = ' '
	,@package_loths varchar(10) = ''
	,@device_loths varchar(20) = ' '
	--add parameter 2021/11/10
	,@process_name varchar(5) = ''
	--add parameter 2022/02/02 time : 09.19
	,@machine_name varchar(15) = ''
	--add parameter 2022/03/16 time : 10.57
	,@machine_id int = 0
	--add parameter 2023/09/11 time : 16.20
	,@continue_lot_mode varchar(1) = ''  --1 is mode continue lot, 0 is not mode continue lot, blank is by pass

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	---- ########## VERSION 001 ##########
	-- call 2022/12/07 Time : 16.35
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_auto_continue_lot_V3_backup20221208] @lotno_standard = @lotno_standard
	--	, @hasuu_lot = @hasuu_lot
	--	, @hasuu_qty = @hasuu_qty
	--	, @lotno_standard_qty = @lotno_standard_qty
	--	, @empno = @empno
	--	, @MNo_Hasuu = @MNo_Hasuu
	--	, @package_loths = @package_loths
	--	, @device_loths	= @device_loths
	--	, @process_name	= @process_name
	--	, @machine_name	= @machine_name
	--	, @machine_id  = @machine_id
	---- ########## VERSION 001 ##########

	---- ########## VERSION 002 ##########
	--call new store create 2022/12/07 Time : 09.32
	------------------------------------------------------------------------------------------------
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_auto_continue_lot_V3_new] @lotno_standard	= @lotno_standard
	,@hasuu_lot	= @hasuu_lot
	,@hasuu_qty	= @hasuu_qty
	,@lotno_standard_qty  = @lotno_standard_qty
	,@empno	= @empno
	,@MNo_Hasuu		= @MNo_Hasuu
	,@package_loths	= @package_loths
	,@device_loths	= @device_loths
	,@process_name	= @process_name
	,@machine_name	= @machine_name
	,@machine_id  = @machine_id
	,@continue_lot_mode = @continue_lot_mode
	------------------------------------------------------------------------------------------------
	---- ########## VERSION 002 ##########
END

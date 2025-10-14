-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_lot]
	-- Add the parameters for the stored procedure here
	@lotno0 VARCHAR(10) ='',
	@lotno1 VARCHAR(10) ='',
	@lotno2 VARCHAR(10) ='',
	@lotno3 VARCHAR(10)='',
	@lotno4 VARCHAR(10)='',
	@lotno5 VARCHAR(10)='',
	@lotno6 VARCHAR(10)='',
	@lotno7 VARCHAR(10)='',
	@lotno8 VARCHAR(10)='',
	@lotno9 VARCHAR(10)='',
	@package char(10),
	@device char(20),
	@rank char(5),
	@total_pcs int,
	@hasuu_tatal int,  
	@empno char(6) = '',
	@newlotno varchar(10),
	@carrierNo varchar(11) = ''   --add parameter #2023/11/14 time : 15.53 by Aomsin
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	---- ########## VERSION 001 ##########
	-- call 2022/12/07 Time : 16.35
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_lot_backup20221208] @lotno0 = @lotno0
	--	, @lotno1 = @lotno1
	--	, @lotno2 = @lotno2
	--	, @lotno3 = @lotno3
	--	, @lotno4 = @lotno4
	--	, @lotno5 = @lotno5
	--	, @lotno6 = @lotno6
	--	, @lotno7 = @lotno7
	--	, @lotno8 = @lotno8
	--	, @lotno9 = @lotno9
	--	, @package = @package
	--	, @device = @device
	--	, @rank = @rank
	--	, @total_pcs = @total_pcs
	--	, @hasuu_tatal = @hasuu_tatal
	--	, @empno = @empno
	--	, @newlotno = @newlotno
	---- ########## VERSION 001 ##########
	
	------ ########## VERSION 002 ##########
	----call new store create 2022/12/07 Time : 09.33
	--------------------------------------------------------------------------------------------------
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_lot_new] @lotno0  = @lotno0
	--,@lotno1  = @lotno1
	--,@lotno2  = @lotno2
	--,@lotno3  = @lotno3
	--,@lotno4  = @lotno4
	--,@lotno5  = @lotno5
	--,@lotno6  = @lotno6
	--,@lotno7  = @lotno7
	--,@lotno8  = @lotno8
	--,@lotno9  = @lotno9
	--,@package = @package
	--,@device  = @device
	--,@rank  = @rank
	--,@total_pcs  = @total_pcs
	--,@hasuu_tatal  = @hasuu_tatal
	--,@empno  = @empno
	--,@newlotno  = @newlotno
	--------------------------------------------------------------------------------------------------
	------ ########## VERSION 002 ##########

	---- ########## VERSION 003 ##########
	--call new store create 2023/02/14 Time : 14.50
	------------------------------------------------------------------------------------------------
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_lot_new_003] @lotno0  = @lotno0
		, @lotno1  = @lotno1
		, @lotno2  = @lotno2
		, @lotno3  = @lotno3
		, @lotno4  = @lotno4
		, @lotno5  = @lotno5
		, @lotno6  = @lotno6
		, @lotno7  = @lotno7
		, @lotno8  = @lotno8
		, @lotno9  = @lotno9
		, @package = @package
		, @device  = @device
		, @rank  = @rank
		, @total_pcs  = @total_pcs
		, @hasuu_tatal  = @hasuu_tatal
		, @empno  = @empno
		, @newlotno  = @newlotno
		, @carrierNo = @carrierNo
	------------------------------------------------------------------------------------------------
	---- ########## VERSION 003 ##########
END

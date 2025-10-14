-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Edit Data : 2022/01/13 Time : 14.09 By Aomsin 
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_new_dlot_rework]
	-- Add the parameters for the stored procedure here
	 @hasuu_lotno VARCHAR(10) =''
	,@package char(10)
	,@device char(20)
	,@rank char(5)
	,@total_pcs int --qty hasuu all
	,@empno char(6) = ''
	,@newlotno varchar(10)
	,@carrier_no_set varchar(11) = '' --add parameter 2022/05/04 time : 09.30
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--call new store create 2022/12/07 Time : 09.35
	------------------------------------------------------------------------------------------------
	EXEC [StoredProcedureDB].[dbo].[tg_sp_new_dlot_rework_new] @hasuu_lotno  = @hasuu_lotno
	,@package  = @package
	,@device  = @device
	,@rank  = @rank
	,@total_pcs  = @total_pcs
	,@empno  = @empno
	,@newlotno  = @newlotno
	,@carrier_no_set  = @carrier_no_set
	------------------------------------------------------------------------------------------------

	--call store current create 2022/12/07 Time : 16.29--
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_new_dlot_rework_backup20221208] @hasuu_lotno  = @hasuu_lotno
	--,@package  = @package
	--,@device  = @device
	--,@rank  = @rank
	--,@total_pcs  = @total_pcs
	--,@empno  = @empno
	--,@newlotno  = @newlotno
	--,@carrier_no_set  = @carrier_no_set

	
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, update 2022/02/01,time : 16.06>
-- Description:	<Description,use hasuu stock in and pc request sample lot (E,H)  ,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_in_stock_nomix]
	-- Add the parameters for the stored procedure here
	 @lotno_standard varchar(10) 
	,@lotno_standard_qty int
	,@empno char(6) = ''

	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--call new store create 2022/12/07 Time : 15.44
	------------------------------------------------------------------------------------------------
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_in_stock_nomix_new] @lotno_standard = @lotno_standard
	,@lotno_standard_qty = @lotno_standard_qty
	,@empno = @empno
	------------------------------------------------------------------------------------------------

	--call store current create 2022/12/07 Time : 16.30
	------------------------------------------------------------------------------------------------
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_in_stock_nomix_backup20221208] @lotno_standard = @lotno_standard
	--,@lotno_standard_qty = @lotno_standard_qty
	--,@empno = @empno
	------------------------------------------------------------------------------------------------


END

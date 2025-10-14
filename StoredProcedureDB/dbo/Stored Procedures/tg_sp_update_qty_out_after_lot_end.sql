-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_qty_out_after_lot_end] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
	,@qty_ship int = 0
	,@qty_hasuu_now_value int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE APCSProDB.trans.lots 
	SET qty_hasuu = @qty_hasuu_now_value
	,qty_out = @qty_ship
	where lot_no = @lotno

END

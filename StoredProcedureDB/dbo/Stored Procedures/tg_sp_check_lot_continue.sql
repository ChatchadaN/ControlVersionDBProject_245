-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_check_lot_continue]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Lotno_id int 
	DECLARE @Lotno_combine_id int

    -- Insert statements for procedure here
	select @Lotno_id = id from APCSProDB.trans.lots where lot_no = @lotno

	select @Lotno_combine_id = lot_id from APCSProDB.trans.lot_combine where lot_id = @Lotno_id

	IF @Lotno_combine_id != 0
	BEGIN
		select @Lotno_combine_id as lot_id
	END

END

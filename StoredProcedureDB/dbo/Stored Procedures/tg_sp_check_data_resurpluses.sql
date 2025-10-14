-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_check_data_resurpluses]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @lotno != ''
	BEGIN
		select case when original_lot_id is null or original_lot_id = '' then '0' 
				else original_lot_id end as original_lot_id
		from APCSProDB.trans.surpluses 
		where serial_no = @lotno
	END


END

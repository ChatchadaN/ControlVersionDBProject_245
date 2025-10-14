-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_test_table_by_bass]
	@LotNo_List LotNo_List READONLY
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	select lot_no,wip_state from APCSProDB.trans.lots
	where lot_no in (select lot_no from @LotNo_List)

	if ((select count(lot_no) from @LotNo_List) > 10)
	begin
		select '> 10'
	end
		
END

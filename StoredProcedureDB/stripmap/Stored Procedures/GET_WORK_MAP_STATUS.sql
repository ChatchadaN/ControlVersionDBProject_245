-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[GET_WORK_MAP_STATUS]
	-- Add the parameters for the stored procedure here
	@WORK_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select
		WK.map_state as STATUS,
		LO.process_state as LOT_STATUS
	from APCSProDB.trans.works as WK with(nolock)
	inner join APCSProDB.trans.lots as LO with(nolock) on LO.id = WK.lot_id
	where WK.id = @WORK_ID
	
	return @@ROWCOUNT
END

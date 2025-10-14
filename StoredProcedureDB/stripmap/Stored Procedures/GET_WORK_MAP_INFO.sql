-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[GET_WORK_MAP_INFO]
	-- Add the parameters for the stored procedure here
	@WORK_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select WK.id as WORK_NO, SB.x as X, SB.y as Y, SB.bin_id as BIN_ID, PR.id as LAY_NO
	from APCSProDB.trans.works as WK with(nolock)
	inner join APCSProDB.trans.sub_works as SB with(nolock) on SB.work_id = WK.id
	inner join APCSProDB.trans.lots as LO with(nolock) on LO.id = WK.lot_id
	inner join APCSProDB.method.device_flows as DF with(nolock) on DF.device_slip_id = LO.device_slip_id and DF.step_no = LO.step_no
	inner join APCSProDB.method.jobs as JB with(nolock) on JB.id = DF.job_id
	inner join APCSProDB.method.processes as PR with(nolock) on PR.id = JB.process_id
	where WK.id = @WORK_ID
	order by SB.y, SB.x
	
	return @@ROWCOUNT
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[GET_OPERATION_INFO]
	-- Add the parameters for the stored procedure here
	@TICKET_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select
		DF.device_slip_id as TICKET_ID,
		DF.step_no as OPE_SEQ,
		PR.name as LAYER_NAME,
		JB.name as PROCESS_NAME,
		0 as QC_GATE,
		DF.recipe as RECIPE,
		'' as TEST_RECIPE
	from APCSProDB.method.device_flows as DF with(nolock)
	inner join APCSProDB.method.jobs as JB with(nolock) on JB.id = DF.job_id
	inner join APCSProDB.method.processes as PR with(nolock) on PR.id = JB.process_id
	where DF.device_slip_id = @TICKET_ID
	
	return @@ROWCOUNT
END

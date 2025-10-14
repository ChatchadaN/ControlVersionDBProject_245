-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[GET_WORK_INFO_BY_WORK_NO]
	-- Add the parameters for the stored procedure here
	@WORK_NO	INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select
		WK.id as WORK_NO, WK.work_no as SERIAL_NO,
		LO.id as LOT_ID,
		LO.lot_no as LOT_NO,
		LO.device_slip_id as TICKET_ID,
		LO.step_no as OPE_SEQ,
		DN.name as PRD_NAME,
		DN.assy_name as ASSY_NAME,
		JB.name as PROCESS_NAME,
		LO.quality_state as JUDGE,
		LO.process_state as STATUS,
		MC.id as TOOL_ID,
		MC.name as TOOL_NAME,
		US.id as USER_ID,
		US.name as USERNAME,
		0 as QC_GATE,
		NULL as BATCH_SET,
		LO.qty_in as IN_QTY,
		LO.qty_pass as PASS_QTY,
		LO.qty_fail as FAIL_QTY
	from APCSProDB.trans.works as WK with(nolock)
	inner join APCSProDB.trans.lots as LO with(nolock) on  LO.id = WK.lot_id
	inner join APCSProDB.method.device_names as DN with(nolock) on DN.id = LO.act_device_name_id
	inner join APCSProDB.method.device_flows as DF with(nolock) on DF.device_slip_id = LO.device_slip_id and DF.step_no = LO.step_no
	inner join APCSProDB.method.jobs as JB with(nolock) on JB.id = DF.job_id
	inner join APCSProDB.mc.machines as MC with(nolock) on MC.id = LO.machine_id
	inner join APCSProDB.man.users as US with(nolock) on US.id = LO.updated_by
    WHERE WK.id = @WORK_NO

	return @@ROWCOUNT
END

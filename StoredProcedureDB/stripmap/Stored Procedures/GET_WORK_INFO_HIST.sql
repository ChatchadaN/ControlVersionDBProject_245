-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[GET_WORK_INFO_HIST]
	-- Add the parameters for the stored procedure here
	@WORK_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select
		WK.id as WORK_NO,
		WK.work_no as SERIAL_NO,
		LO.id as LOT_ID,
		LO.lot_no as LOT_NO,
		LO.device_slip_id as TICKET_ID,
		LPR.step_no as OPE_SEQ,
		DN.name as PRD_NAME,
		DN.assy_name as ASSY_NAME,
		JB.name as PROCESS_NAME,
		WUR.use_state as JUDGE,
		WK.map_state as STATUS,
		MC.id as TOOL_ID,
		MC.name as TOOL_NAME,
		US.id as USER_ID,
		US.name as USERNAME,
		0 as QC_GATE,
		'' as BATCH_SET,
		WUR.recorded_at as EVENT_TIME,
		WUR.id as HISTORY_ID,
		WUR.record_class as CATEGORY,
		case when BEFORE_FAIL.before_fails is null then DN.strip_row_number*DN.strip_column_number else DN.strip_row_number*DN.strip_column_number - BEFORE_FAIL.before_fails end as IN_QTY,
		case when ALL_FAIL.all_fails is null then DN.strip_row_number*DN.strip_column_number else DN.strip_row_number*DN.strip_column_number - ALL_FAIL.all_fails end as PASS_QTY,
		case when ACT_FAIL.act_fails is null then 0 else ACT_FAIL.act_fails end as FAIL_QTY,
		case when NOCHIP_FAIL.nochip_fails is null then 0 else NOCHIP_FAIL.nochip_fails end as NOCOUNT_QTY,
		'' as COMMENT
	from APCSProDB.trans.lots as LO with(nolock)
	inner join APCSProDB.method.device_names as DN with(nolock) on DN.id = LO.act_device_name_id
	inner join APCSProDB.trans.lot_process_records as LPR with(nolock) on LPR.lot_id = LO.id and LPR.record_class = 1
	inner join APCSProDB.method.jobs as JB with(nolock) on JB.id = LPR.job_id
	inner join APCSProDB.trans.works as WK with(nolock) on WK.lot_id = LO.id
	inner join APCSProDB.trans.work_update_records as WUR with(nolock) on WUR.work_id = WK.id and WUR.recorded_at >= LPR.recorded_at and WUR.job_id = JB.id and WUR.record_class >= 100
	inner join APCSProDB.man.users as US with(nolock) on US.id = LPR.updated_by
	inner join APCSProDB.mc.machines as MC with(nolock) on MC.id = LPR.machine_id
	left outer join ( 
		select WFR.update_record_id, WFR.work_id, SUM(WFR.pcs) as before_fails
		from APCSProDB.trans.work_fail_records as WFR with(nolock) 
		group by WFR.update_record_id, WFR.work_id) as BEFORE_FAIL on BEFORE_FAIL.update_record_id < WUR.id and BEFORE_FAIL.work_id = WUR.work_id
	left outer join ( 
		select WFR.update_record_id, WFR.work_id, SUM(WFR.pcs) as all_fails
		from APCSProDB.trans.work_fail_records as WFR with(nolock) 
		group by WFR.update_record_id, WFR.work_id) as ALL_FAIL on ALL_FAIL.update_record_id <= WUR.id and ALL_FAIL.work_id = WUR.work_id
	left outer join (
		select WFR.update_record_id, WFR.work_id, SUM(WFR.pcs) as act_fails
		from APCSProDB.trans.work_fail_records as WFR with(nolock)
		inner join APCSProDB.mc.bin_definitions as BD with(nolock) on BD.id = WFR.fail_bin_id and BD.die_quality = 1
		group by WFR.update_record_id, WFR.work_id) as ACT_FAIL on ACT_FAIL.update_record_id = WUR.id and ACT_FAIL.work_id = WUR.work_id
	left outer join (
		select WFR.update_record_id, WFR.work_id, SUM(WFR.pcs) as nochip_fails
		from APCSProDB.trans.work_fail_records as WFR with(nolock)
		inner join APCSProDB.mc.bin_definitions as BD with(nolock) on BD.id = WFR.fail_bin_id and BD.die_quality != 1
		group by WFR.update_record_id, WFR.work_id) as NOCHIP_FAIL on NOCHIP_FAIL.update_record_id = WUR.id and NOCHIP_FAIL.work_id = WUR.work_id
	where WK.id = @WORK_ID
	
	return @@ROWCOUNT
END

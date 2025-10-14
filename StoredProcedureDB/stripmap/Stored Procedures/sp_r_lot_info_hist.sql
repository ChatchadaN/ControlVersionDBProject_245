-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_lot_info_hist]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@WORK_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + 'WK.id as WORK_ID, ';
	SET @CMD_TEXT += N'	' + 'WK.work_no as WORK_NO, ';
	SET @CMD_TEXT += N'	' + 'LO.id as LOT_ID, ';
	SET @CMD_TEXT += N'	' + 'LO.lot_no as LOT_NO, ';
	SET @CMD_TEXT += N'	' + 'LO.device_slip_id as DEVICE_SLIP_ID, ';
	SET @CMD_TEXT += N'	' + 'LPR.step_no as STEP_NO, ';
	SET @CMD_TEXT += N'	' + 'LPR.quality_state as QUALITY_STATE, ';
	SET @CMD_TEXT += N'	' + 'case LPR.record_class when 2 then CONVERT(tinyint,0) when 23 then CONVERT(tinyint,100) else LPR.process_state end as PROCESS_STATE, ';
	SET @CMD_TEXT += N'	' + 'DN.name as DEVICE_NAME, ';
	SET @CMD_TEXT += N'	' + 'DN.assy_name as ASSY_NAME, ';
	SET @CMD_TEXT += N'	' + 'JB.name as JOB_NAME, ';
	SET @CMD_TEXT += N'	' + 'WUR.use_state as USE_STATE, ';
	SET @CMD_TEXT += N'	' + 'WUR.map_state as MAP_STATE, ';
	SET @CMD_TEXT += N'	' + 'case when MC.id is null then -1 else MC.id end as MACHINE_ID, ';
	SET @CMD_TEXT += N'	' + 'case when MC.name is null then ''Unknown'' else MC.name end as MACHINE_NAME, ';
	SET @CMD_TEXT += N'	' + 'case when US.id is null then -1 else US.id end as USER_ID, ';
	SET @CMD_TEXT += N'	' + 'case when US.name is null then ''Unknown'' else US.name end as USER_NAME, ';
	SET @CMD_TEXT += N'	' + '0 as QC_GATE, ';
	SET @CMD_TEXT += N'	' + ''''' as BATCH_SET, ';
	SET @CMD_TEXT += N'	' + 'case when WUR.recorded_at is null then LPR.recorded_at else WUR.recorded_at end as RECORDED_AT, ';
	SET @CMD_TEXT += N'	' + 'case when WUR.id is null then LPR.id else CONVERT(bigint,WUR.id) end as HISTORY_ID, ';
	SET @CMD_TEXT += N'	' + 'WUR.record_class as MAP_RECORD_CLASS, ';
	SET @CMD_TEXT += N'	' + 'LPR.record_class as LOT_RECORD_CLASS, ';
	SET @CMD_TEXT += N'	' + '-1 as IN_QTY, ';
	SET @CMD_TEXT += N'	' + '-1 as PASS_QTY, ';
	SET @CMD_TEXT += N'	' + '-1 as FAIL_QTY, ';
	SET @CMD_TEXT += N'	' + '-1 as OTHER_QTY, ';
	SET @CMD_TEXT += N'	' + ''''' as COMMENT ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.lot_process_records as LPR with(nolock) ';
	SET @CMD_TEXT += N'inner join ( ';
	SET @CMD_TEXT += N'		select ';
	SET @CMD_TEXT += N'	' + '	case when max(Before_LPR.id) is null then 0 else max(Before_LPR.id) end as max_id, ';
	SET @CMD_TEXT += N'	' + '	LPR.id, ';
	SET @CMD_TEXT += N'	' + '	LPR.lot_id '; 
	SET @CMD_TEXT += N'		from ' + @DATABASE_NAME + '.trans.lot_process_records as LPR with(nolock) ';
	SET @CMD_TEXT += N'		left outer join ' + @DATABASE_NAME + '.trans.lot_process_records as Before_LPR with(nolock)on Before_LPR.id < LPR.id and Before_LPR.lot_id = LPR.lot_id ';
	SET @CMD_TEXT += N'		group by LPR.id, LPR.lot_id) as Before_LPR on Before_LPR.id = LPR.id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.lots as LO with(nolock)on LO.id = LPR.lot_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_names as DN with(nolock) on DN.id = LO.act_device_name_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.jobs as JB with(nolock) on JB.id = LPR.job_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.works as WK with(nolock) on WK.lot_id = LO.id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.users as US with(nolock) on US.id = LPR.updated_by ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.mc.machines as MC with(nolock) on MC.id = LPR.machine_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.trans.work_update_records as WUR with(nolock)on WUR.work_id = Wk.id and (WUR.id > Before_LPR.max_id and WUR.id <= Before_LPR.id) ';
	SET @CMD_TEXT += N'where WK.id = ' + CONVERT(varchar,@WORK_ID) + ' ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END

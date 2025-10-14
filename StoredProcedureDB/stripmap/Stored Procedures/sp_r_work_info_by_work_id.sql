-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_work_info_by_work_id]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME	NVARCHAR(128),
	@WORK_ID		INT

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
	SET @CMD_TEXT += N'	' + 'LO.step_no as STEP_NO, ';
	SET @CMD_TEXT += N'	' + 'DN.name as DEVICE_NAME, ';
	SET @CMD_TEXT += N'	' + 'DN.assy_name as ASSY_NAME, ';
	SET @CMD_TEXT += N'	' + 'JB.name as JOB_NAME, ';
	SET @CMD_TEXT += N'	' + 'LO.quality_state as QUALITY_STATE, ';
	SET @CMD_TEXT += N'	' + 'LO.process_state as PROCESS_STATE, ';
	SET @CMD_TEXT += N'	' + 'WK.map_state as MAP_STATE, ';
	SET @CMD_TEXT += N'	' + 'WK.use_state as USE_STATE, ';
	SET @CMD_TEXT += N'	' + 'MC.id as MACHINE_ID, ';
	SET @CMD_TEXT += N'	' + 'MC.name as MACHINE_NAME, ';
	SET @CMD_TEXT += N'	' + 'US.id as USER_ID, ';
	SET @CMD_TEXT += N'	' + 'US.name as USER_NAME, ';
	SET @CMD_TEXT += N'	' + '0 as QC_GATE, ';
	SET @CMD_TEXT += N'	' + 'NULL as BATCH_SET, ';
    SET @CMD_TEXT += N'	' + 'case when ( DN.strip_column_number * DN.strip_row_number ) is null then 0 ';
	SET @CMD_TEXT += N'	' + 'else DN.strip_column_number * DN.strip_row_number end as IN_QTY, ';
	SET @CMD_TEXT += N'	' + 'case when GOOD.pass_qty is null then 0 ';
	SET @CMD_TEXT += N'	' + 'else GOOD.pass_qty end as PASS_QTY, ';
	SET @CMD_TEXT += N'	' + 'case when FAIL.fail_qty is null then 0 ';
	SET @CMD_TEXT += N'	' + 'else FAIL.fail_qty end as FAIL_QTY, ';
	SET @CMD_TEXT += N'	' + 'case when OTHER.other_qty is null then 0 ';
	SET @CMD_TEXT += N'	' + 'else OTHER.other_qty end as OTHER_QTY ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.works as WK with(nolock) ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.lots as LO with(nolock) on  LO.id = WK.lot_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_names as DN with(nolock) on DN.id = LO.act_device_name_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_flows as DF with(nolock) on DF.device_slip_id = LO.device_slip_id and DF.step_no = LO.step_no ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.jobs as JB with(nolock) on JB.id = DF.job_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.mc.machines as MC with(nolock) on MC.id = LO.machine_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.users as US with(nolock) on US.id = LO.updated_by ';
	SET @CMD_TEXT += N'		left outer join ( select GOOD.work_id, COUNT ( GOOD.id ) as pass_qty ';
	SET @CMD_TEXT += N'		from ' + @DATABASE_NAME + '.trans.sub_works as GOOD with ( NOLOCK ) ';
	SET @CMD_TEXT += N'		inner join ' + @DATABASE_NAME + '.mc.bin_definitions as BIN with ( NOLOCK ) ';
	SET @CMD_TEXT += N'			on BIN.id = GOOD.bin_id and BIN.die_quality = 0 group by GOOD.work_id ) as GOOD on GOOD.work_id = WK.id ';
	SET @CMD_TEXT += N'		left outer join ( select FAIL.work_id, COUNT ( FAIL.id ) as fail_qty ';
	SET @CMD_TEXT += N'		from ' + @DATABASE_NAME + '.trans.sub_works as FAIL with ( NOLOCK ) ';
	SET @CMD_TEXT += N'		inner join ' + @DATABASE_NAME + '.mc.bin_definitions as BIN with ( NOLOCK ) ';
	SET @CMD_TEXT += N'			on BIN.id = FAIL.bin_id and BIN.die_quality = 1 group by FAIL.work_id ) as FAIL on FAIL.work_id = WK.id ';
	SET @CMD_TEXT += N'		left outer join ( select OTHER.work_id, COUNT ( OTHER.id ) as other_qty ';
	SET @CMD_TEXT += N'		from ' + @DATABASE_NAME + '.trans.sub_works as OTHER with ( NOLOCK ) ';
	SET @CMD_TEXT += N'		inner join ' + @DATABASE_NAME + '.mc.bin_definitions as BIN with ( NOLOCK ) ';
	SET @CMD_TEXT += N'			on BIN.id = OTHER.bin_id and BIN.die_quality > = 2 group by OTHER.work_id ) as OTHER on OTHER.work_id = WK.id ';
    SET @CMD_TEXT += N'WHERE WK.id = ' + CONVERT(varchar,@WORK_ID) + ' ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END

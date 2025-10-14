-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_cru_lot_mapedit_end]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@PASS_QTY	INT,
	@FAIL_QTY	INT,
	@USER_ID	INT,
	@WORK_NO	INT,
	@RECORD_ID	INT,
	@COMMENT_ID	INT

AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @DAY_ID INT
	DECLARE @CMD_TEXT NVARCHAR(MAX) = '';
	DECLARE @CMD_PARA NVARCHAR(MAX) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + '@DAY_ID = D.id ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.days as D ';
	SET @CMD_TEXT += N'where D.date_value = CONVERT(DATE,GETDATE()) ';

	SET @CMD_PARA = N'@DAY_ID INT OUTPUT';
	EXECUTE sp_executesql @CMD_TEXT, @CMD_PARA, @DAY_ID OUTPUT

   	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'update ';
	SET @CMD_TEXT += N'LO SET ';
	SET @CMD_TEXT += N' ' + 'LO.quality_state = 0, '
	SET @CMD_TEXT += N' ' + 'LO.qty_pass = LO.qty_pass + ' + CONVERT(varchar,@PASS_QTY) + ', ';
	SET @CMD_TEXT += N' ' + 'LO.qty_last_pass = LO.qty_pass + ' + CONVERT(varchar,@PASS_QTY) + ', ';
	SET @CMD_TEXT += N' ' + 'LO.qty_pass_step_sum = LO.qty_pass + ' + CONVERT(varchar,@PASS_QTY) + ', ';
	SET @CMD_TEXT += N' ' + 'LO.qty_fail = LO.qty_fail + ' + CONVERT(varchar,@FAIL_QTY) + ', ';
	SET @CMD_TEXT += N' ' + 'LO.qty_last_fail = ' + CONVERT(varchar,@FAIL_QTY) + ', ';
	SET @CMD_TEXT += N' ' + 'LO.qty_fail_step_sum = ' + CONVERT(varchar,@FAIL_QTY) + ', ';
	SET @CMD_TEXT += N' ' + 'LO.updated_by = ' + CONVERT(varchar,@USER_ID) + ' ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.lots as LO ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.works as WK on WK.lot_id = LO.id ';
    SET @CMD_TEXT += N'where WK.id = ' + CONVERT(varchar,@WORK_NO) + ' ';
	EXECUTE(@CMD_TEXT)

	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'insert ';
	SET @CMD_TEXT += N' ' + @DATABASE_NAME + '.trans.lot_process_records ';
	SET @CMD_TEXT += N'( ';
	SET @CMD_TEXT += N' ' + 'id, ';
	SET @CMD_TEXT += N' ' + 'day_id, ';
	SET @CMD_TEXT += N' ' + 'recorded_at, ';
	SET @CMD_TEXT += N' ' + 'operated_by, ';
	SET @CMD_TEXT += N' ' + 'record_class, ';
	SET @CMD_TEXT += N' ' + 'lot_id, ';
	SET @CMD_TEXT += N' ' + 'process_id, ';
	SET @CMD_TEXT += N' ' + 'job_id, ';
	SET @CMD_TEXT += N' ' + 'step_no, ';
	SET @CMD_TEXT += N' ' + 'qty_in, ';
	SET @CMD_TEXT += N' ' + 'qty_pass, ';
	SET @CMD_TEXT += N' ' + 'qty_fail, ';
	SET @CMD_TEXT += N' ' + 'qty_last_pass, ';
	SET @CMD_TEXT += N' ' + 'qty_last_fail, ';
	SET @CMD_TEXT += N' ' + 'qty_pass_step_sum, ';
	SET @CMD_TEXT += N' ' + 'qty_fail_step_sum, ';
	SET @CMD_TEXT += N' ' + 'qty_divided, ';
	SET @CMD_TEXT += N' ' + 'qty_hasuu, ';
	SET @CMD_TEXT += N' ' + 'qty_out, ';
	SET @CMD_TEXT += N' ' + 'machine_id, ';
	SET @CMD_TEXT += N' ' + 'process_job_id, ';
	SET @CMD_TEXT += N' ' + 'is_onlined, ';
	SET @CMD_TEXT += N' ' + 'wip_state, ';
	SET @CMD_TEXT += N' ' + 'process_state, ';
	SET @CMD_TEXT += N' ' + 'quality_state, ';
	SET @CMD_TEXT += N' ' + 'first_ins_state, ';
	SET @CMD_TEXT += N' ' + 'final_ins_state, ';
	SET @CMD_TEXT += N' ' + 'is_special_flow, ';
	SET @CMD_TEXT += N' ' + 'special_flow_id, ';
	SET @CMD_TEXT += N' ' + 'is_temp_devided, ';
	SET @CMD_TEXT += N' ' + 'temp_devided_count, ';
	SET @CMD_TEXT += N' ' + 'container_no, ';
	SET @CMD_TEXT += N' ' + 'std_time_sum, ';
	SET @CMD_TEXT += N' ' + 'pass_plan_time, ';
	SET @CMD_TEXT += N' ' + 'pass_plan_time_up, ';
	SET @CMD_TEXT += N' ' + 'origin_material_id, ';
	SET @CMD_TEXT += N' ' + 'qc_comment_id, ';
	SET @CMD_TEXT += N' ' + 'qc_memo_id, ';
	SET @CMD_TEXT += N' ' + 'created_at, ';
	SET @CMD_TEXT += N' ' + 'created_by, ';
	SET @CMD_TEXT += N' ' + 'updated_at, ';
	SET @CMD_TEXT += N' ' + 'updated_by ';
	SET @CMD_TEXT += N') ';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N' ' + CONVERT(varchar,@RECORD_ID) + ', ';
	SET @CMD_TEXT += N' ' + CONVERT(varchar,@DAY_ID) + ', ';
	SET @CMD_TEXT += N' ' + 'GETDATE(), ';
	SET @CMD_TEXT += N' ' + CONVERT(varchar,@USER_ID) + ', ';
	SET @CMD_TEXT += N' ' + '41, ';
	SET @CMD_TEXT += N' ' + 'LO.id, ';
	SET @CMD_TEXT += N' ' + 'LO.act_process_id, ';
	SET @CMD_TEXT += N' ' + 'LO.act_job_id, ';
	SET @CMD_TEXT += N' ' + 'LO.step_no, ';
	SET @CMD_TEXT += N' ' + 'LO.qty_in, ';
	SET @CMD_TEXT += N' ' + 'LO.qty_pass, ';
	SET @CMD_TEXT += N' ' + 'LO.qty_fail, ';
	SET @CMD_TEXT += N' ' + 'LO.qty_last_pass, ';
	SET @CMD_TEXT += N' ' + 'LO.qty_last_fail, ';
	SET @CMD_TEXT += N' ' + 'LO.qty_pass_step_sum, ';
	SET @CMD_TEXT += N' ' + 'LO.qty_fail_step_sum, ';
	SET @CMD_TEXT += N' ' + 'LO.qty_divided, ';
	SET @CMD_TEXT += N' ' + 'LO.qty_hasuu, ';
	SET @CMD_TEXT += N' ' + 'LO.qty_out, ';
	SET @CMD_TEXT += N' ' + 'LO.machine_id, ';
	SET @CMD_TEXT += N' ' + 'LO.process_job_id, ';
	SET @CMD_TEXT += N' ' + '0, ';
	SET @CMD_TEXT += N' ' + 'LO.wip_state, ';
	SET @CMD_TEXT += N' ' + 'LO.process_state, ';
	SET @CMD_TEXT += N' ' + 'LO.quality_state, ';
	SET @CMD_TEXT += N' ' + 'LO.first_ins_state, ';
	SET @CMD_TEXT += N' ' + 'LO.final_ins_state, ';
	SET @CMD_TEXT += N' ' + 'LO.is_special_flow, ';
	SET @CMD_TEXT += N' ' + 'LO.special_flow_id, ';
	SET @CMD_TEXT += N' ' + 'LO.is_temp_devided, ';
	SET @CMD_TEXT += N' ' + 'LO.temp_devided_count, ';
	SET @CMD_TEXT += N' ' + 'LO.container_no, ';
	SET @CMD_TEXT += N' ' + 'LO.std_time_sum, ';
	SET @CMD_TEXT += N' ' + 'LO.pass_plan_time, ';
	SET @CMD_TEXT += N' ' + 'LO.pass_plan_time_up, ';
	SET @CMD_TEXT += N' ' + 'LO.origin_material_id, ';
	SET @CMD_TEXT += N' ' + CONVERT(varchar,@COMMENT_ID) + ', ';
	SET @CMD_TEXT += N' ' + 'LO.qc_memo_id, ';
	SET @CMD_TEXT += N' ' + 'LO.created_at, ';
	SET @CMD_TEXT += N' ' + 'LO.created_by, ';
	SET @CMD_TEXT += N' ' + 'LO.updated_at, ';
	SET @CMD_TEXT += N' ' + 'LO.updated_by ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.lots as LO ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.works as WK on WK.lot_id = LO.id ';
	SET @CMD_TEXT += N'where WK.id = ' + CONVERT(varchar,@WORK_NO) + ' ';
	EXECUTE(@CMD_TEXT)	

	return @@ROWCOUNT
END

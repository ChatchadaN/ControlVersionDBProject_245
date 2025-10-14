-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[UPDATE_LOT_QTY]
	-- Add the parameters for the stored procedure here
	@PASS_QTY	INT,
	@FAIL_QTY	INT,
	@USER_ID	INT,
	@WORK_NO	INT,
	@RECORD_ID	INT

AS
BEGIN
	
	DECLARE @DAY_ID INT

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select @DAY_ID = D.id
	from APCSProDB.trans.days as D 
	where D.date_value = CONVERT(DATE,GETDATE())

    -- Insert statements for procedure here
	update LO SET
		 LO.qty_pass = LO.qty_pass + @PASS_QTY,
		 LO.qty_last_pass = LO.qty_pass + @PASS_QTY,
		 LO.qty_pass_step_sum = LO.qty_pass + @PASS_QTY,
		 LO.qty_fail = LO.qty_fail + @FAIL_QTY,
		 LO.qty_last_fail = @FAIL_QTY,
		 LO.qty_fail_step_sum = @FAIL_QTY,
		 LO.updated_by = @USER_ID
	FROM APCSProDB.trans.lots as LO
	inner join APCSProDB.trans.works as WK on WK.lot_id = LO.id
    WHERE WK.id = @WORK_NO

	insert APCSProDB.trans.lot_process_records
	(
		id,
		day_id,
		recorded_at,
		operated_by,
		record_class,
		lot_id,
		process_id,
		job_id,
		step_no,
		qty_in,
		qty_pass,
		qty_fail,
		qty_last_pass,
		qty_last_fail,
		qty_pass_step_sum,
		qty_fail_step_sum,
		qty_divided,
		qty_hasuu,
		qty_out,
		machine_id,
		process_job_id,
		is_onlined,
		wip_state,
		process_state,
		quality_state,
		first_ins_state,
		final_ins_state,
		is_special_flow,
		special_flow_id,
		is_temp_devided,
		temp_devided_count,
		container_no,
		std_time_sum,
		pass_plan_time,
		pass_plan_time_up,
		origin_material_id,
		qc_comment_id,
		qc_memo_id,
		created_at,
		created_by,
		updated_at,
		updated_by
	)
	select
		@RECORD_ID,
		@DAY_ID,
		GETDATE(),
		@USER_ID,
		40,
		LO.id,
		LO.act_process_id,
		LO.act_job_id,
		LO.step_no,
		LO.qty_in,
		LO.qty_pass,
		LO.qty_fail,
		LO.qty_last_pass,
		LO.qty_last_fail,
		LO.qty_pass_step_sum,
		LO.qty_fail_step_sum,
		LO.qty_divided,
		LO.qty_hasuu,
		LO.qty_out,
		LO.machine_id,
		LO.process_job_id,
		0,
		LO.wip_state,
		LO.process_state,
		LO.quality_state,
		LO.first_ins_state,
		LO.final_ins_state,
		LO.is_special_flow,
		LO.special_flow_id,
		LO.is_temp_devided,
		LO.temp_devided_count,
		LO.container_no,
		LO.std_time_sum,
		LO.pass_plan_time,
		LO.pass_plan_time_up,
		LO.origin_material_id,
		LO.qc_comment_id,
		LO.qc_memo_id,
		LO.created_at,
		LO.created_by,
		LO.updated_at,
		LO.updated_by
	from APCSProDB.trans.lots as LO
	inner join APCSProDB.trans.works as WK on WK.lot_id = LO.id
	where WK.id = @WORK_NO
		
	return @@ROWCOUNT
END

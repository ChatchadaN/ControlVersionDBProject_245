
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_move_flow]
	-- Add the parameters for the stored procedure here
	  @lot_id int
	, @device_slip_id int
	, @step_no int
	, @updated_at varchar(50)
	, @updated_by int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @r INT = 0;

    -- Insert statements for procedure here
	UPDATE [APCSProDB].[trans].[lots]
	SET 
		
		[step_no] = case when (CONVERT(varchar(50),@step_no) = '') then NULL else @step_no end 
        ,[act_process_id] = case when (CONVERT(varchar(50),flow.act_process_id) = '') then NULL else flow.act_process_id  end
	    ,[act_job_id] = case when (CONVERT(varchar(50),flow.job_id) = '') then NULL else flow.job_id  end
		,[wip_state] = 20
		,[process_state] = 0
		,[quality_state] = 0
		,[first_ins_state] = 0
		,[final_ins_state] = 0
		,[updated_at] = case when (@updated_at = '') then GETDATE() else CONVERT(DATETIME, @updated_at) end
		,[updated_by] = case when (CONVERT(varchar(50),@updated_by) = '') then NULL else @updated_by end
		From [APCSProDB].[trans].[lots] As translot
	INNER JOIN  (SELECT *FROM [APCSProDB].[method].[device_flows] where device_slip_id = @device_slip_id and step_no = @step_no ) As flow
	ON  translot.device_slip_id =flow.device_slip_id 
	WHERE translot.id  = @lot_id

	INSERT INTO [APCSProDB].[trans].[lot_process_records]([id]
      ,[day_id]
      ,[recorded_at]
      ,[operated_by]
      ,[record_class]
      ,[lot_id]
      ,[process_id]
      ,[job_id]
      ,[step_no]
      ,[qty_in]
      ,[qty_pass]
      ,[qty_fail]
      ,[qty_last_pass]
      ,[qty_last_fail]
      ,[qty_pass_step_sum]
      ,[qty_fail_step_sum]
      ,[qty_divided]
      ,[qty_hasuu]
      ,[qty_out]
      ,[recipe]
      ,[recipe_version]
      ,[machine_id]
      ,[position_id]
      ,[process_job_id]
      ,[is_onlined]
      ,[dbx_id]
      ,[wip_state]
      ,[process_state]
      ,[quality_state]
      ,[first_ins_state]
      ,[final_ins_state]
      ,[is_special_flow]
      ,[special_flow_id]
      ,[is_temp_devided]
      ,[temp_devided_count]
      ,[container_no]
      ,[extend_data]
      ,[std_time_sum]
      ,[pass_plan_time]
      ,[pass_plan_time_up]
      ,[origin_material_id]
      ,[treatment_time]
      ,[wait_time]
      ,[qc_comment_id]
      ,[qc_memo_id]
      ,[created_at]
      ,[created_by]
      ,[updated_at]
      ,[updated_by])
		SELECT [nu].[id] + row_number() over (order by [lots].[id])
		, [days].[id] [day_id]
		, GETDATE() as [recorded_at]
		, 1 as [operated_by]
		, 20 as [record_class]
		, [lots].[id] as [lot_id]
		, [act_process_id] as [process_id]
		, [act_job_id] as [job_id]
		, [step_no]
		, [qty_in]
		, [qty_pass]
		, [qty_fail]
		, [qty_last_pass]
		, [qty_last_fail]
		, [qty_pass_step_sum]
		, [qty_fail_step_sum]
		, [qty_divided]
		, [qty_hasuu]
		, [qty_out]
		, NULL as [recipe]
		, 1 as [recipe_version]
		, [machine_id]
		, NULL as [position_id]
		, [process_job_id]
		, 0 as [is_onlined]
		, 0 as [dbx_id]
		, [wip_state]
		, [process_state]
		, [quality_state]
		, [first_ins_state]
		, [final_ins_state]
		, [is_special_flow]
		, [special_flow_id]
		, [is_temp_devided]
		, [temp_devided_count]
		, [container_no]
		, NULL as [extend_data]
		, [std_time_sum]
		, [pass_plan_time]
		, [pass_plan_time_up]
		, [origin_material_id]
		, NULL as [treatment_time]
		, NULL as [wait_time]
		, [qc_comment_id]
		, [qc_memo_id]
		, [created_at]
		, [created_by]
		, GETDATE() as [updated_at]
		, [updated_by] = case when (CONVERT(varchar(50),@updated_by) = '') then NULL else @updated_by end
		FROM [APCSProDB].[trans].[lots] 
		INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
		INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
		WHERE [lots].[id] = @lot_id

		SET @r = @@ROWCOUNT
		 UPDATE [APCSProDB].[trans].[numbers]
		 SET [id] = [id] + @r
		 WHERE [name] = 'lot_process_records.id'

END



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_move_flow_ver_003]
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
	DECLARE @is_special_flow int = null;
	DECLARE @special_flow_id int = null;
	DECLARE @max_step_no int = null;
	DECLARE @bstep_no int = null;
	DECLARE @nstep_no int = null;

    -- Insert statements for procedure here
	--Find step_no special_flows
	SET @max_step_no = (SELECT max(step_no) FROM [APCSProDB].[method].[device_flows] WHERE device_slip_id = (select device_slip_id from APCSProDB.trans.lots where id = @lot_id) AND is_skipped != 1)
	SELECT @bstep_no = step_no,@nstep_no = next_step_no FROM [APCSProDB].[method].[device_flows] WHERE device_slip_id = (select device_slip_id from APCSProDB.trans.lots where id = @lot_id) AND is_skipped != 1 AND step_no = @step_no

	IF (@step_no != @max_step_no)
		BEGIN
			SELECT TOP 1 @special_flow_id = id
			FROM [APCSProDB].[trans].[special_flows]
			WHERE [special_flows].[lot_id] = @lot_id
				AND [special_flows].[step_no] > @bstep_no AND [special_flows].[step_no] < @nstep_no
			ORDER BY [special_flows].[step_no]
		END
	ELSE
		BEGIN
			SELECT TOP 1 @special_flow_id = id
			FROM [APCSProDB].[trans].[special_flows]
			WHERE [special_flows].[lot_id] = @lot_id
				AND [special_flows].[step_no] > @step_no
			ORDER BY [special_flows].[step_no]
		END
	
	IF (@special_flow_id IS NOT NULL)
		BEGIN
			SET @is_special_flow = 0
			SET @special_flow_id = @special_flow_id
		END
	ELSE
		BEGIN
			SET @is_special_flow = 0
			SET @special_flow_id = 0
		END
	--Find step_no special_flows

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
		,[is_special_flow] = @is_special_flow
		,[special_flow_id] = @special_flow_id
		,[machine_id] = -1
	FROM [APCSProDB].[trans].[lots] AS translot
	INNER JOIN [APCSProDB].[method].[device_flows] AS flow ON translot.device_slip_id = flow.device_slip_id
	WHERE translot.id  = @lot_id
		AND translot.device_slip_id = @device_slip_id 
		AND flow.step_no = @step_no

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


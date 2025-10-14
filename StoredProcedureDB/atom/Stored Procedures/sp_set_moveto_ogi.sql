-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_moveto_ogi]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @qty_in INT
	DECLARE @step_no INT
	DECLARE @process_id INT
	DECLARE @job_id INT
	DECLARE @qty_fail INT
	DECLARE @lot_id INT

	DECLARE @r INT = 0;

    -- Insert statements for procedure here
	IF EXISTS(select [lots].[lot_no]
		from [APCSProDB].[trans].[lots]
		inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
		where [lots].[lot_no] = @lot_no
		and [lots].[wip_state] = 20
		and [packages].[is_enabled] = 1
		and [jobs].[name] = 'OUT GOING INSP')
	BEGIN
		select top(1) @lot_id = [lots].[id]
		, @qty_in =[lots].[qty_in]
		, @step_no = [device_flows].[step_no]
		, @process_id = [device_flows].[act_process_id]
		, @job_id = [device_flows].[job_id]
		, @qty_fail = [lots].[qty_fail]
		from [APCSProDB].[trans].[lots]
		inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
		where [APCSProDB].[trans].[lots].[lot_no] = @lot_no
		and [APCSProDB].[method].[device_flows].[step_no] > [APCSProDB].[trans].[lots].[step_no]
		and [APCSProDB].[method].[device_flows].[is_skipped] = 0
		and [APCSProDB].[method].[jobs].[name] = 'OUT GOING INSP'
		order by [APCSProDB].[method].[device_flows].[step_no]

		update [APCSProDB].[trans].[lots]
		set [step_no] = @step_no
		, [act_process_id] = @process_id
		, [act_job_id] = @job_id
		, [qty_pass] = @qty_in-(@qty_fail)
		, [qty_fail] = @qty_fail
		, [process_state] = 0
		, [quality_state] = 0
		, [first_ins_state] = 0
		, [final_ins_state] = 0
		, [updated_at] = GETDATE()
		--, [updated_by] = @user_id
		where [lots].[id] = @lot_id

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
		, -1 as [machine_id]
		, NULL as [position_id]
		, [process_job_id]
		, 0 as [is_onlined]
		, 0 as [dbx_id]
		, [wip_state]
		, 0 as [process_state]
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
		, 1 as [updated_by]
		FROM [APCSProDB].[trans].[lots] 
		INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
		INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
		WHERE [lots].[id] = @lot_id

		SET @r = @@ROWCOUNT
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = [id] + @r
			WHERE [name] = 'lot_process_records.id'

		select 'PRO' as [status]
	END
	ELSE
	BEGIN
		select top(1) @lot_id = [lots].[id]
		, @qty_in =[lots].[qty_in]
		, @step_no = [device_flows].[step_no]
		, @process_id = [device_flows].[act_process_id]
		, @job_id = [device_flows].[job_id]
		, @qty_fail = [lots].[qty_fail]
		from [APCSProDB].[trans].[lots]
		inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
		where [APCSProDB].[trans].[lots].[lot_no] = @lot_no
		and [APCSProDB].[method].[device_flows].[step_no] > [APCSProDB].[trans].[lots].[step_no]
		and [APCSProDB].[method].[device_flows].[is_skipped] = 0
		and [APCSProDB].[method].[jobs].[name] in ('OUT GOING INSP','O/G')
		order by [APCSProDB].[method].[device_flows].[step_no]

		update [APCSProDB].[trans].[lots]
		set [step_no] = @step_no
		, [act_process_id] = @process_id
		, [act_job_id] = @job_id
		, [qty_pass] = @qty_in-(@qty_fail)
		, [qty_fail] = @qty_fail
		, [process_state] = 0
		, [quality_state] = 0
		, [first_ins_state] = 0
		, [final_ins_state] = 0
		, [updated_at] = GETDATE()
		--, [updated_by] = @user_id
		where [lots].[id] = @lot_id

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
		, -1 as [machine_id]
		, NULL as [position_id]
		, [process_job_id]
		, 0 as [is_onlined]
		, 0 as [dbx_id]
		, [wip_state]
		, 0 as [process_state]
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
		, 1 as [updated_by]
		FROM [APCSProDB].[trans].[lots] 
		INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
		INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
		WHERE [lots].[id] = @lot_id

		SET @r = @@ROWCOUNT
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = [id] + @r
			WHERE [name] = 'lot_process_records.id'

		select 'NO PRO' as [status]
	END
END

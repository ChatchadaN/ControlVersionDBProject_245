-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_lots_operator]
	-- Add the parameters for the stored procedure here
	@lot_id INT
	, @qty_last_pass INT
	, @qty_last_fail INT
	, @start_time DATETIME
	, @machine_id INT
	, @user_id INT
	, @container_no VARCHAR(20) = NULL
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

	DECLARE @step_now INT
	DECLARE @step_last INT
	DECLARE @id_condition INT
	-- @id_condition = 2 : step_no = max step
	-- @id_condition = 1 : step_no in device slip > step_no 

	DECLARE @r INT = 0;

	-- check max step_no of device silps.
	select @step_now = step_no 
	from [APCSProDB].[trans].[lots]
	where [APCSProDB].[trans].[lots].[id] = @lot_id

	select @step_last = max([device_flows].[step_no])
	from [APCSProDB].[trans].[lots]
	inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
	where [APCSProDB].[trans].[lots].[id] = @lot_id
	
	IF( @step_now = @step_last)
		BEGIN
			SET @id_condition = 2
		END
	ELSE
		BEGIN
			SET @id_condition = 1
		END

    -- Insert statements for procedure here
	IF(@id_condition = 1)
	BEGIN
			select top(1) @qty_in =[lots].[qty_in]
			, @step_no = [device_flows].[step_no]
			, @process_id = [device_flows].[act_process_id]
			, @job_id = [device_flows].[job_id]
			, @qty_fail = [lots].[qty_fail]
			from [APCSProDB].[trans].[lots]
			inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
			inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
			where [APCSProDB].[trans].[lots].[id] = @lot_id
			and [APCSProDB].[method].[device_flows].[step_no] > [APCSProDB].[trans].[lots].[step_no]
			and [APCSProDB].[method].[device_flows].[is_skipped] = 0
			order by [APCSProDB].[method].[device_flows].[step_no]
	END
	ELSE IF(@id_condition = 2)
	BEGIN
		select top(1)  @qty_in = [lots].[qty_in]
		, @step_no = [device_flows].[step_no]
		, @process_id = [device_flows].[act_process_id]
		, @job_id = [device_flows].[job_id]
		, @qty_fail = [lots].[qty_fail]
		from [APCSProDB].[trans].[lots]
		inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		where [APCSProDB].[trans].[lots].[id] = @lot_id
		and [APCSProDB].[method].[device_flows].[step_no] = @step_last
		and [APCSProDB].[method].[device_flows].[is_skipped] = 0
		order by [APCSProDB].[method].[device_flows].[step_no]
	END

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
      ,[updated_by]
	  ,[carrier_no])
	SELECT [nu].[id] + row_number() over (order by [lots].[id])
	, [days].[id] [day_id]
	, @start_time as [recorded_at]
	, @user_id as [operated_by]
	--, 31 as [record_class]
	, 1 as [record_class]
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
	, @machine_id as [machine_id]
	, NULL as [position_id]
	, [process_job_id]
	, 0 as [is_onlined]
	, 0 as [dbx_id]
	, [wip_state]	
	, 2 as [process_state]
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
	, @user_id as [updated_by]
	, @container_no as [carrier_no]
	--, [carrier_no]
	FROM [APCSProDB].[trans].[lots] 
	INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
	INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
	WHERE [lots].[id] = @lot_id

	SET @r = @@ROWCOUNT
		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = [id] + @r
		WHERE [name] = 'lot_process_records.id'

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
      ,[updated_by]
	  ,[carrier_no])
	SELECT [nu].[id] + row_number() over (order by [lots].[id])
	, [days].[id] [day_id]
	, GETDATE() as [recorded_at]
	, @user_id as [operated_by]
	--, 32 as [record_class]
	, 2 as [record_class]
	, [lots].[id] as [lot_id]
	, [act_process_id] as [process_id]
	, [act_job_id] as [job_id]
	, [step_no]
	, [qty_in]
	, [qty_pass]
	, [qty_fail]
	, @qty_last_pass as [qty_last_pass]
	, @qty_last_fail as [qty_last_fail]
	, [qty_pass_step_sum]
	, [qty_fail_step_sum]
	, [qty_divided]
	, [qty_hasuu]
	, [qty_out]
	, NULL as [recipe]
	, 1 as [recipe_version]
	, @machine_id as [machine_id]
	, NULL as [position_id]
	, [process_job_id]
	, 0 as [is_onlined]
	, 0 as [dbx_id]
	, [wip_state]
	--, case when [wip_state] = '10' then '20' else [wip_state] end as [wip_state]
	, 2 as [process_state]
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
	, @user_id as [updated_by]
	--, [carrier_no]
	, @container_no as [carrier_no]
	FROM [APCSProDB].[trans].[lots] 
	INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
	INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
	WHERE [lots].[id] = @lot_id

	SET @r = @@ROWCOUNT
		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = [id] + @r
		WHERE [name] = 'lot_process_records.id'

	IF(@id_condition = 1)
	BEGIN
		IF EXISTS(select *
		from [APCSProDB].[trans].[lots]
		inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
		where [lots].[id] = @lot_id
		and [packages].[is_carrier_controlled] = 1)
		BEGIN
			update [APCSProDB].[trans].[lots]
			set [step_no] = @step_no
			, [act_process_id] = @process_id
			, [act_job_id] = @job_id
			, [qty_pass] = @qty_in-(@qty_fail+@qty_last_fail)
			, [qty_fail] = @qty_fail+@qty_last_fail
			, [process_state] = 0
			, [quality_state] = 0
			, [first_ins_state] = 0
			, [final_ins_state] = 0
			, [updated_at] = GETDATE()
			, [updated_by] = @user_id
			, [carrier_no] = @container_no
			, [next_carrier_no] = NULL
			where [lots].[id] = @lot_id
		END
		ELSE
		BEGIN
			update [APCSProDB].[trans].[lots]
			set [step_no] = @step_no
			, [act_process_id] = @process_id
			, [act_job_id] = @job_id
			, [qty_pass] = @qty_in-(@qty_fail+@qty_last_fail)
			, [qty_fail] = @qty_fail+@qty_last_fail
			, [process_state] = 0
			, [quality_state] = 0
			, [first_ins_state] = 0
			, [final_ins_state] = 0
			, [updated_at] = GETDATE()
			, [updated_by] = @user_id
			--, [carrier_no] = @container_no
			where [lots].[id] = @lot_id
		END
	END
	ELSE IF(@id_condition = 2)
	BEGIN
		IF EXISTS(select *
		from [APCSProDB].[trans].[lots]
		inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
		where [lots].[id] = @lot_id
		and [packages].[is_carrier_controlled] = 1)
		BEGIN
			update [APCSProDB].[trans].[lots]
			set [step_no] = @step_no
			, [act_process_id] = @process_id
			, [act_job_id] = @job_id
			, [qty_pass] = @qty_in-(@qty_fail+@qty_last_fail)
			, [qty_fail] = @qty_fail+@qty_last_fail
			, [process_state] = 0
			, [quality_state] = 0
			, [first_ins_state] = 0
			, [final_ins_state] = 0
			, [wip_state] = 100 
			, [updated_at] = GETDATE()
			, [updated_by] = @user_id
			, [carrier_no] = @container_no
			, [next_carrier_no] = NULL
			where [lots].[id] = @lot_id
		END
		ELSE
		BEGIN
			update [APCSProDB].[trans].[lots]
			set [step_no] = @step_no
			, [act_process_id] = @process_id
			, [act_job_id] = @job_id
			, [qty_pass] = @qty_in-(@qty_fail+@qty_last_fail)
			, [qty_fail] = @qty_fail+@qty_last_fail
			, [process_state] = 0
			, [quality_state] = 0
			, [first_ins_state] = 0
			, [final_ins_state] = 0
			, [wip_state] = 100
			, [updated_at] = GETDATE()
			, [updated_by] = @user_id
			--, [carrier_no] = @container_no
			where [lots].[id] = @lot_id
		END
	END
END

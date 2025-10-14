-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_ver_005]
	-- Add the parameters for the stored procedure here
	@lot_id int
	, @is_special_flow int
	, @step_no int = NULL
	, @flow_pattern_id int = NULL
	, @machine_id int = -1
	, @recipe varchar(20) = NULL
	, @user_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	---------------------------------------------------------------------------
	-- Log exec
    ---------------------------------------------------------------------------	
	insert into [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	select GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'exec [atom].[sp_set_trans_special_flow_ver_005] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') 
			+ ''', @is_special_flow = ''' + ISNULL(CAST(@is_special_flow AS varchar),'')
			+ ''', @step_no = ''' + ISNULL(CAST(@step_no AS varchar),'') 
			+ ''', @flow_pattern_id = '''+ ISNULL(CAST(@flow_pattern_id AS varchar),'') 
			+ ''', @machine_id = ''' + ISNULL(CAST(@machine_id AS varchar),'') 
			+ ''', @recipe = ''' + ISNULL(CAST(@recipe AS varchar),'')
			+ ''', @user_id = ''' + ISNULL(CAST(@user_id AS varchar),'') + ''''
		, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = @lot_id)

	--declare @lot_id int = 2  
	--	, @is_special_flow int = 1
	--	, @step_no int = 100
	--	, @flow_pattern_id int = 1198 --1198 --1828
	--	, @machine_id int = -1
	--	, @user_id int = 1339
	--	, @recipe VARCHAR(20) = NULL
	---------------------------------------------------------------------------
	--(1) Declare
    ---------------------------------------------------------------------------	
	declare @q1_step_no int = 0
		, @q1_back_step_no int = 0
		, @q1_back_step_no_master int = 0
		, @flow_type int = 0  --0:not step_no  1:master  2:special
		, @flow_type_stepno int = 0  --0:not step_no  1:master  2:special
		, @check_flow int = NULL
		, @status_add_flow int = 0
		, @step_no_now int = 0
		, @status_addnow int = 0
		, @count_flow int = 0
		, @exec_run int = 0
		, @status_flow int = 0
		, @update_spid int = 0
		, @chk_step_no int = 0
		, @r_sf int = 0 --special_flows
		, @r_lsf int = 0 --lot_special_flows
		, @r_lpr int = 0  --lot_process_records
		, @result int = 0
		, @maxstepc int = 0
		, @flow_typec int = 0
		, @result_nowlast int = 0
	---------------------------------------------------------------------------
	--(1) Declare table
    ---------------------------------------------------------------------------	
	declare @table_flow table (
		step_no int,
		back_step_no int,
		back_step_no_master int,
		flow_type int,
		status_add_flow int,
		step_no_now int
	)
	declare @table_recipe table (
		job_id int,
		job_name varchar(30),
		recipe varchar(20)
	)
	---------------------------------------------------------------------------
	--(1) Check parameter is_special_flow, Check wip
    ---------------------------------------------------------------------------	
	-- Check is_special_flow
	if (@is_special_flow not in (0,1))
	begin
		select 'FALSE' AS Is_Pass 
			, 'is_special_flow is not 0 and 1. !!' AS Error_Message_ENG
			, N'is_special_flow ที่ส่งมาไม่ใช่ 0 และ 1 !!' AS Error_Message_THA 
			, '' AS Handling
		return
	end
	-- Check wip_state
	if ((select [wip_state] from [APCSProDB].[trans].[lots] where id = @lot_id) not in (0,10,20))
	begin
		select 'FALSE' AS Is_Pass 
			, 'Wip state is invalid. !!' AS Error_Message_ENG
			, N'Wip state ไม่ถูกต้อง !!' AS Error_Message_THA 
			, '' AS Handling
		return
	end
	-- Check process_state
	if (@is_special_flow = 1)
	begin
		if ((select [process_state] from [APCSProDB].[trans].[lots] where id = @lot_id) not in (0,100))
		begin
			select 'FALSE' AS Is_Pass 
				, 'Process State is invalid. !!' AS Error_Message_ENG
				, N'Process State ไม่ถูกต้อง !!' AS Error_Message_THA 
				, '' AS Handling
			return
		end

		if ((select [is_special_flow] from [APCSProDB].[trans].[lots] where id = @lot_id) = 1)
		begin
			if ((select [process_state] from [APCSProDB].[trans].[special_flows] where lot_id = @lot_id 
				and id = (select [special_flow_id] from [APCSProDB].[trans].[lots] where id = @lot_id)) not in (0,100)
			)
			begin
				select 'FALSE' AS Is_Pass 
					, 'Process State is invalid. !!' AS Error_Message_ENG
					, N'Process State ไม่ถูกต้อง !!' AS Error_Message_THA 
					, '' AS Handling
				return
			end
		end
	end
	---------------------------------------------------------------------------
	--(2) Check count flow
    ---------------------------------------------------------------------------	
	SET @count_flow = (
		SELECT COUNT([flow_details].[job_id])
		FROM [APCSProDB].[method].[flow_details] WHERE [flow_details].[flow_pattern_id] = @flow_pattern_id
	)
	---------------------------------------------------------------------------
	--(3) Insert data flow to @table_flow
    ---------------------------------------------------------------------------	
	insert into @table_flow 
	(
		step_no
		, back_step_no
		, back_step_no_master
		, flow_type
		, status_add_flow
		, step_no_now
	)
	select [flow].[step_no]
		, isnull(lead([flow].[step_no]) over (order by [flow].[step_no]),0) as [back_step_no]
		, [flow].[back_step_no] as [back_step_no_master]
		, [flow].[flow_type]
		, case
			when [flow_current].[step_no] <= [flow].[step_no] then 1
			else 0 
		end as [status_add_flow]
		, [flow_current].[step_no] as [step_no_now]
	from (
		select step_no, 1 as flow_type, next_step_no as back_step_no
		from APCSProDB.method.device_flows 
		where device_slip_id = (select device_slip_id from APCSProDB.trans.lots where lots.id = @lot_id ) and is_skipped != 1
		union all
		select lot_special_flows.step_no, 2 as flow_type, special_flows.back_step_no
		from APCSProDB.trans.special_flows
		left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
		where special_flows.lot_id = @lot_id
	) as [flow]
	left join (
		select lots.id as lot_id, IIF(lot_special_flows.step_no is null,lots.step_no,lot_special_flows.step_no) as [step_no]
		from APCSProDB.trans.lots
		left join APCSProDB.trans.special_flows on lots.is_special_flow = 1
			and lots.special_flow_id = special_flows.id
		left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
			and special_flows.step_no = lot_special_flows.step_no
	) [flow_current] on [flow_current].[lot_id] = @lot_id;
	---------------------------------------------------------------------------
	--(4) Check step no
    ---------------------------------------------------------------------------	
	if (not exists(select 1 from @table_flow where step_no = @step_no))
	begin
		select 'FALSE' AS Is_Pass 
			, 'Step no not found. !!' AS Error_Message_ENG
			, N'ไม่พบ step_no !!' AS Error_Message_THA 
			, '' AS Handling
		return
	end
	---------------------------------------------------------------------------
	--(5) Check step no 1 can not add flow by add now (@is_special_flow = 1)
    ---------------------------------------------------------------------------	
	if (@step_no = (select min([step_no]) from @table_flow))
	begin
		if (@step_no = 1 and @is_special_flow = 1)
		begin
			select 'FALSE' AS Is_Pass 
				, 'Cannot add flow step no 1. !!' AS Error_Message_ENG
				, N'ไม่สามารถเพิ่ม flow step_no ที่ 1 ได้ !!' AS Error_Message_THA 
				, '' AS Handling
			return
		end
	end
	---------------------------------------------------------------------------
	--(6) recipe
    ---------------------------------------------------------------------------
	if (@recipe is null)
	begin
		insert into @table_recipe (
			job_id
			, job_name
			, recipe
		)
		SELECT [jobs].[id] as [job_id]
			, [jobs].[name] as [job_name]
			, (select recipe from [StoredProcedureDB].[atom].[fnc_get_recipe](@lot_id,[jobs].[id])) as [recipe]
		FROM [APCSProDB].[method].[flow_patterns]
		inner join [APCSProDB].[method].[flow_details]  on [flow_patterns].[id] = [flow_details].[flow_pattern_id]
		inner join [APCSProDB].[method].[jobs] on [flow_details].[job_id] = [jobs].[id]
		where [flow_patterns].[id] = @flow_pattern_id
	end
	---------------------------------------------------------------------------
	--(7) Set parameter (now,after)
    ---------------------------------------------------------------------------
	if (@is_special_flow = 1)
	begin
		---------------------------------------------------------------------------
		select @q1_step_no = [flow].[step_no]
			, @q1_back_step_no = [flow].[back_step_no]
			, @q1_back_step_no_master = [flow].[back_step_no_master]
			, @step_no_now = [flow].[step_no_now]
		from @table_flow as [flow]
		where [flow].[back_step_no] = @step_no

		if ((@step_no = (select min([step_no]) from @table_flow)))
		begin
			set @q1_step_no = 0
			set @q1_back_step_no = @step_no
			set @q1_back_step_no_master = @step_no
			set @step_no_now = @step_no
		end
		---------------------------------------------------------------------------
	end
	else if (@is_special_flow = 0) begin
		---------------------------------------------------------------------------
		select @q1_step_no = [flow].[step_no]
			, @q1_back_step_no = [flow].[back_step_no]
			, @q1_back_step_no_master = [flow].[back_step_no_master]
			, @step_no_now = [flow].[step_no_now]
		from @table_flow as [flow]
		where [flow].[step_no] = @step_no
		---------------------------------------------------------------------------
	end
	---------------------------------------------------------------------------
	--(8) Check add now by wip step no
	---------------------------------------------------------------------------	
	set @maxstepc = (select max([step_no]) from @table_flow)
	set @flow_typec = (select flow_type from @table_flow where step_no = @step_no)
	if (@is_special_flow = 1 and @step_no = @maxstepc and @flow_typec = 2)
	begin
		set @result_nowlast = 1;
	end
	else begin
		if (@is_special_flow = 1 and @step_no != @step_no_now)
		begin
			select 'FALSE' AS Is_Pass 
				, 'Cannot add flows that are not current step no. !!' AS Error_Message_ENG
				, N'ไม่สามารถเพิ่ม flow ที่ไม่ใช่ step no ปัจจุบันได้ !!' AS Error_Message_THA 
				, '' AS Handling
			return
		end
	end
	---------------------------------------------------------------------------
	--(9) Check add after
	---------------------------------------------------------------------------
	if (@result_nowlast = 0)
	begin
		if ((select [status_add_flow] from @table_flow where step_no = @step_no) != 1)
		begin
			select 'FALSE' AS Is_Pass 
				, 'Cannot add flow that are less than the current step no. !!' AS Error_Message_ENG
				, N'ไม่สามารถเพิ่ม flow ที่น้อยกว่า step_no ปัจจุบันได้ !!' AS Error_Message_THA 
				, '' AS Handling
			return
		end
	end

	begin transaction;
	begin try
		---------------------------------------------------------------------------
		--(10) Add now
		---------------------------------------------------------------------------
		if (@is_special_flow = 1)
		begin
			if (@result_nowlast = 0)
			begin
				if ((select flow_type from @table_flow where step_no = @step_no) = 1)
				begin
					----------------------------------------------------------------------------------
					insert into [APCSProDB].[trans].[special_flows]
					(
						[id]
						,[lot_id]
						,[step_no]
						,[back_step_no]
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
						,[is_exist_work]
						,[wip_state]
						,[process_state]
						,[quality_state]
						,[first_ins_state]
						,[final_ins_state]
						,[priority]
						,[finish_date_id]
						,[finished_at]
						,[machine_id]
						,[container_no]
						,[qc_comment_id]
						,[qc_memo_id]
						,[process_job_id]
						,[carried_at]
						,[is_special_flow]
						,[special_flow_id]
						,[instruction_reason_id]
						,[start_special_message_id]
						,[finish_special_message_id]
						,[holded_at]
						,[created_at]
						,[created_by]
						,[updated_at]
						,[updated_by]
						,[limit_time_state]
						,[map_edit_state]
						,[qty_p_nashi]
						,[qty_front_ng]
						,[qty_marker]
						,[qty_cut_frame]
						,[qty_combined]
						,[qty_frame_in]
						,[qty_frame_pass]
						,[qty_frame_fail]
						--,[exec_state]
					)
					select [nu].[id] + row_number() over (order by [lots].[id]) as [id]
						, [lots].[id] as [lot_id]
						, @q1_step_no + 1 as [step_no]
						, @q1_back_step_no_master as [back_step_no]
						, [lots].[qty_pass]
						, [lots].[qty_pass]
						, 0 as [qty_fail]
						, NULL as [qty_last_pass]
						, NULL as [qty_last_fail]
						, NULL as [qty_pass_step_sum]
						, NULL as [qty_fail_step_sum]
						, NULL as [qty_divided]
						, [qty_hasuu] as [qty_hasuu]
						, [qty_out] as [qty_out]
						, 0 as [is_exist_work]
						, 20 as [wip_state]
						, 0 as [process_state]
						, 0 as [quality_state]
						, 0 as [first_ins_state]
						, 0 as [final_ins_state]
						, [lots].[priority]
						, [lots].[finish_date_id]
						, [lots].[finished_at]
						, @machine_id as [machine_id]
						, [lots].[container_no]
						, NULL as [qc_comment_id]
						, NULL as [qc_memo_id]
						, NULL as [process_job_id]
						, [lots].[carried_at]
						, 0 as [is_special_flow_id]
						, NULL as [special_flow_id]
						, NULL as [instruction_reason_id]
						, NULL as [start_special_message_id]
						, NULL as [finish_special_message_id]
						, NULL as [holded_at]
						, GETDATE() as [created_at]
						, @user_id as [created_by]
						, NULL as [updated_at]
						, NULL as [updated_by]
						, NULL as [limit_time_state]
						, NULL as [map_edit_state]
						, [qty_p_nashi]
						, [qty_front_ng]
						, [qty_marker]
						, [qty_cut_frame]
						, [qty_combined]
						, [qty_frame_pass]
						, [qty_frame_pass]
						, [qty_frame_fail]
						--, 0 as [exec_state]
					from [APCSProDB].[trans].[lots] 
					inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'special_flows.id'
					where [lots].[id] = @lot_id

					SET @r_sf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_sf
					, @update_spid = [id] + @r_sf
					WHERE [name] = 'special_flows.id'


					insert into [APCSProDB].[trans].[lot_special_flows]
					(
						[id]
						,[special_flow_id]
						,[step_no]
						,[next_step_no]
						,[act_process_id]
						,[job_id]
						,[act_package_flow_id]
						,[permitted_machine_id]
						,[process_minutes]
						,[sum_process_minutes]
						,[recipe]
						,[ng_retest_permitted]
						,[is_skipped]
						,[material_set_id]
						,[jig_set_id]
						,[data_collection_id]
						,[yield_lcl]
						,[ng_category_cnt]
						,[label_issue_id]
					)
					select [nu].[id] + row_number() over (order by [flow_details].[flow_pattern_id]) as [id]
						, @update_spid as [special_flow_id]
						, @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id]) as [step_no]
						, case
							when row_number() over (order by [flow_details].[flow_pattern_id]) = @count_flow then @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id])
							else @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id]) + 1
						end as [next_step_no]
						, [jobs].[process_id] as [act_process_id]
						, [jobs].[id] as [job_id]
						, [lots].[act_package_id] as [act_package_flow_id]
						, 0 as [permitted_machine_id]
						, 0 as [process_minutes]
						, 0 as [sum_process_minutes]
						, IIF(@recipe is null,(select recipe from @table_recipe where job_id = [jobs].[id]),@recipe) AS [recipe]
						, 0 as [ng_retest_permitted]
						, 0 as [is_skipped]
						, NULL as [material_set_id]
						, NULL as [jig_set_id]
						, NULL as [data_collection_id]
						, NULL as [yield_lcl]
						, NULL as [ng_category_cnt]
						, 0 as [issue_label_type]
					from [APCSProDB].[method].[flow_details] 
					inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'lot_special_flows.id'
					inner join [APCSProDB].[method].[jobs] on [flow_details].[job_id] = [jobs].[id]
					inner join [APCSProDB].[trans].[lots] on [lots].[id] = @lot_id
					where [flow_details].[flow_pattern_id] = @flow_pattern_id

					SET @r_lsf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lsf
					WHERE [name] = 'lot_special_flows.id'

					insert into [APCSProDB].[trans].[lot_process_records]
					(
						[id]
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
						,[act_device_name_id]
						,[device_slip_id]
						,[order_id]
						,[abc_judgement]
						,[held_at]
						,[held_minutes_current]
						,[limit_time_state]
						,[map_edit_state]
						,[qty_frame_in]
						,[qty_frame_pass]
						,[qty_frame_fail]
						,[qty_frame_last_pass]
						,[qty_frame_last_fail]
						,[qty_frame_pass_step_sum]
						,[qty_frame_fail_step_sum]
						,[qty_p_nashi]
						,[qty_front_ng]
						,[qty_marker]
						,[qty_cut_frame]
						,[qty_combined]
					)
					SELECT [nu].[id] + row_number() over (order by [lots].[id])
						, [days].[id] [day_id]
						, GETDATE() as [recorded_at]
						, @user_id as [operated_by]
						, 25 as [record_class]
						, [lots].[id] as [lot_id]
						, [lot_special_flows].[act_process_id] as [process_id]
						--, [act_job_id] as [job_id]
						, [lot_special_flows].job_id as [job_id]
						, [lot_special_flows].[step_no]
						, [qty_pass] as [qty_in]
						, [qty_pass]
						, 0 as [qty_fail]
						, NULL as [qty_last_pass]
						, NULL as [qty_last_fail]
						, NULL as [qty_pass_step_sum]
						, NULL as [qty_fail_step_sum]
						, NULL as [qty_divided]
						, [qty_hasuu] as [qty_hasuu]
						, [qty_out] as [qty_out]
						, [lot_special_flows].[recipe] as [recipe]
						, 1 as [recipe_version]
						, @machine_id as [machine_id]
						, NULL as [position_id]
						, NULL as [process_job_id]
						, 0 as [is_onlined]
						, 0 as [dbx_id]
						, [lots].[wip_state]
						, [lots].[process_state]
						, [lots].[quality_state]
						, 0 as [first_ins_state]
						, 0 as [final_ins_state]
						, [is_special_flow]
						, @update_spid as [special_flow_id]
						, 0 as [is_temp_devided]
						, NULL as [temp_devided_count]
						, NULL as [container_no]
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
						, NULL as [act_device_name_id]
						, NULL as [device_slip_id]
						, NULL as [order_id]
						, NULL as [abc_judgement]
						, NULL as [held_at]
						, NULL as [held_minutes_current]
						, NULL as [limit_time_state]
						, NULL as [map_edit_state]
						, [qty_frame_pass] as [qty_frame_in]
						, [qty_frame_pass] as [qty_frame_pass]
						, NULL as [qty_frame_fail]
						, NULL as [qty_frame_last_pass]
						, NULL as [qty_frame_last_fail]
						, NULL as [qty_frame_pass_step_sum]
						, NULL as [qty_frame_fail_step_sum]
						, [qty_p_nashi]
						, [qty_front_ng]
						, [qty_marker]
						, [qty_cut_frame]
						, [qty_combined]
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
					INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
					INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = @update_spid
						--and [lot_special_flows].[step_no] between (@step_no) and ((@step_no - 1) + (@count_flow))
					WHERE [lots].[id] = @lot_id;

					SET @r_lpr = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lpr
					WHERE [name] = 'lot_process_records.id';

					set @result = 1;
					----------------------------------------------------------------------------------
				end
				else if ((select flow_type from @table_flow where step_no = @step_no) = 2)
				begin
					----------------------------------------------------------------------------------
					select @update_spid = [lot_special_flows].[special_flow_id]
					from [APCSProDB].[trans].[lot_special_flows]
					inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
					WHERE [special_flows].[lot_id] = @lot_id and [lot_special_flows].[step_no] = @step_no

					if (@update_spid != 0)
					begin
				
						if (@step_no > (select max(step_no)
						from APCSProDB.method.device_flows 
						where device_slip_id = (select device_slip_id from APCSProDB.trans.lots where lots.id = @lot_id ) and is_skipped != 1
						))
						begin
							update [APCSProDB].[trans].[lot_special_flows]
							set step_no = (step_no + @count_flow)
								, next_step_no = (next_step_no + @count_flow)
							where special_flow_id = @update_spid and step_no >= @step_no 
						end
						else 
						begin
							update [APCSProDB].[trans].[lot_special_flows]
							set step_no = (step_no + @count_flow)
								, next_step_no = (next_step_no + @count_flow)
							where special_flow_id = @update_spid and step_no between @step_no and @q1_back_step_no_master
						end
					end

					insert into [APCSProDB].[trans].[lot_special_flows]
					(
						[id]
						,[special_flow_id]
						,[step_no]
						,[next_step_no]
						,[act_process_id]
						,[job_id]
						,[act_package_flow_id]
						,[permitted_machine_id]
						,[process_minutes]
						,[sum_process_minutes]
						,[recipe]
						,[ng_retest_permitted]
						,[is_skipped]
						,[material_set_id]
						,[jig_set_id]
						,[data_collection_id]
						,[yield_lcl]
						,[ng_category_cnt]
						,[label_issue_id]
					)
					select [nu].[id] + row_number() over (order by [flow_details].[flow_pattern_id]) as [id]
						, @update_spid as [special_flow_id]
						, @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id]) as [step_no]
						, @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id]) + 1 as [next_step_no]
						, [jobs].[process_id] as [act_process_id]
						, [jobs].[id] as [job_id]
						, [lots].[act_package_id] as [act_package_flow_id]
						, 0 as [permitted_machine_id]
						, 0 as [process_minutes]
						, 0 as [sum_process_minutes]
						, IIF(@recipe is null,(select recipe from @table_recipe where job_id = [jobs].[id]),@recipe) AS [recipe]
						, 0 as [ng_retest_permitted]
						, 0 as [is_skipped]
						, NULL as [material_set_id]
						, NULL as [jig_set_id]
						, NULL as [data_collection_id]
						, NULL as [yield_lcl]
						, NULL as [ng_category_cnt]
						, 0 as [issue_label_type]
					from [APCSProDB].[method].[flow_details] 
					inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'lot_special_flows.id'
					inner join [APCSProDB].[method].[jobs] on [flow_details].[job_id] = [jobs].[id]
					inner join [APCSProDB].[trans].[lots] on [lots].[id] = @lot_id
					where [flow_details].[flow_pattern_id] = @flow_pattern_id

					SET @r_lsf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lsf
					WHERE [name] = 'lot_special_flows.id';

					if (@update_spid != 0)
					begin
						update [APCSProDB].[trans].[lot_process_records]
						set step_no = ([step_no] + @count_flow)
						where [lot_id] = @lot_id 
							and [record_class] = 25
							and [step_no] between @step_no 
							and (
								select max(step_no) from [APCSProDB].[trans].[lot_special_flows]
								where [special_flow_id] = @update_spid 
							);
					end

					insert into [APCSProDB].[trans].[lot_process_records]
					(
						[id]
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
						,[act_device_name_id]
						,[device_slip_id]
						,[order_id]
						,[abc_judgement]
						,[held_at]
						,[held_minutes_current]
						,[limit_time_state]
						,[map_edit_state]
						,[qty_frame_in]
						,[qty_frame_pass]
						,[qty_frame_fail]
						,[qty_frame_last_pass]
						,[qty_frame_last_fail]
						,[qty_frame_pass_step_sum]
						,[qty_frame_fail_step_sum]
						,[qty_p_nashi]
						,[qty_front_ng]
						,[qty_marker]
						,[qty_cut_frame]
						,[qty_combined]
					)
					SELECT [nu].[id] + row_number() over (order by [lots].[id])
						, [days].[id] [day_id]
						, GETDATE() as [recorded_at]
						, @user_id as [operated_by]
						, 25 as [record_class]
						, [lots].[id] as [lot_id]
						, [lot_special_flows].[act_process_id] as [process_id]
						--, [act_job_id] as [job_id]
						, [lot_special_flows].job_id as [job_id]
						, [lot_special_flows].[step_no]
						, [qty_pass] as [qty_in]
						, [qty_pass]
						, 0 as [qty_fail]
						, NULL as [qty_last_pass]
						, NULL as [qty_last_fail]
						, NULL as [qty_pass_step_sum]
						, NULL as [qty_fail_step_sum]
						, NULL as [qty_divided]
						, [qty_hasuu] as [qty_hasuu]
						, [qty_out] as [qty_out]
						, [lot_special_flows].[recipe] as [recipe]
						, 1 as [recipe_version]
						, @machine_id as [machine_id]
						, NULL as [position_id]
						, NULL as [process_job_id]
						, 0 as [is_onlined]
						, 0 as [dbx_id]
						, [lots].[wip_state]
						, [lots].[process_state]
						, [lots].[quality_state]
						, 0 as [first_ins_state]
						, 0 as [final_ins_state]
						, [is_special_flow]
						, @update_spid as [special_flow_id]
						, 0 as [is_temp_devided]
						, NULL as [temp_devided_count]
						, NULL as [container_no]
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
						, NULL as [act_device_name_id]
						, NULL as [device_slip_id]
						, NULL as [order_id]
						, NULL as [abc_judgement]
						, NULL as [held_at]
						, NULL as [held_minutes_current]
						, NULL as [limit_time_state]
						, NULL as [map_edit_state]
						, [qty_frame_pass] as [qty_frame_in]
						, [qty_frame_pass] as [qty_frame_pass]
						, NULL as [qty_frame_fail]
						, NULL as [qty_frame_last_pass]
						, NULL as [qty_frame_last_fail]
						, NULL as [qty_frame_pass_step_sum]
						, NULL as [qty_frame_fail_step_sum]
						, [qty_p_nashi]
						, [qty_front_ng]
						, [qty_marker]
						, [qty_cut_frame]
						, [qty_combined]
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
					INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
					INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = @update_spid
						and [lot_special_flows].[step_no] between (@step_no) and ((@step_no + @count_flow) - 1)
					WHERE [lots].[id] = @lot_id;

					SET @r_lpr = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lpr
					WHERE [name] = 'lot_process_records.id';
			
					set @result = 1;
					----------------------------------------------------------------------------------
				end
			end
			else begin
				----------------------------------------------------------------------------------
				insert into [APCSProDB].[trans].[special_flows]
				(
					[id]
					,[lot_id]
					,[step_no]
					,[back_step_no]
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
					,[is_exist_work]
					,[wip_state]
					,[process_state]
					,[quality_state]
					,[first_ins_state]
					,[final_ins_state]
					,[priority]
					,[finish_date_id]
					,[finished_at]
					,[machine_id]
					,[container_no]
					,[qc_comment_id]
					,[qc_memo_id]
					,[process_job_id]
					,[carried_at]
					,[is_special_flow]
					,[special_flow_id]
					,[instruction_reason_id]
					,[start_special_message_id]
					,[finish_special_message_id]
					,[holded_at]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by]
					,[limit_time_state]
					,[map_edit_state]
					,[qty_p_nashi]
					,[qty_front_ng]
					,[qty_marker]
					,[qty_cut_frame]
					,[qty_combined]
					,[qty_frame_in]
					,[qty_frame_pass]
					,[qty_frame_fail]
					--,[exec_state]
				)
				select [nu].[id] + row_number() over (order by [lots].[id]) as [id]
					, [lots].[id] as [lot_id]
					, @step_no + 1 as [step_no]
					, @q1_back_step_no_master as [back_step_no]
					, [lots].[qty_pass]
					, [lots].[qty_pass]
					, 0 as [qty_fail]
					, NULL as [qty_last_pass]
					, NULL as [qty_last_fail]
					, NULL as [qty_pass_step_sum]
					, NULL as [qty_fail_step_sum]
					, NULL as [qty_divided]
					, [qty_hasuu] as [qty_hasuu]
					, [qty_out] as [qty_out]
					, 0 as [is_exist_work]
					, 20 as [wip_state]
					, 0 as [process_state]
					, 0 as [quality_state]
					, 0 as [first_ins_state]
					, 0 as [final_ins_state]
					, [lots].[priority]
					, [lots].[finish_date_id]
					, [lots].[finished_at]
					, @machine_id as [machine_id]
					, [lots].[container_no]
					, NULL as [qc_comment_id]
					, NULL as [qc_memo_id]
					, NULL as [process_job_id]
					, [lots].[carried_at]
					, 0 as [is_special_flow_id]
					, NULL as [special_flow_id]
					, NULL as [instruction_reason_id]
					, NULL as [start_special_message_id]
					, NULL as [finish_special_message_id]
					, NULL as [holded_at]
					, GETDATE() as [created_at]
					, @user_id as [created_by]
					, NULL as [updated_at]
					, NULL as [updated_by]
					, NULL as [limit_time_state]
					, NULL as [map_edit_state]
					, [qty_p_nashi]
					, [qty_front_ng]
					, [qty_marker]
					, [qty_cut_frame]
					, [qty_combined]
					, [qty_frame_pass]
					, [qty_frame_pass]
					, [qty_frame_fail]
					--, 0 as [exec_state]
				from [APCSProDB].[trans].[lots] 
				inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'special_flows.id'
				where [lots].[id] = @lot_id

				SET @r_sf = @@ROWCOUNT
				UPDATE [APCSProDB].[trans].[numbers]
				SET [id] = [id] + @r_sf
				, @update_spid = [id] + @r_sf
				WHERE [name] = 'special_flows.id'

				insert into [APCSProDB].[trans].[lot_special_flows]
				(
					[id]
					,[special_flow_id]
					,[step_no]
					,[next_step_no]
					,[act_process_id]
					,[job_id]
					,[act_package_flow_id]
					,[permitted_machine_id]
					,[process_minutes]
					,[sum_process_minutes]
					,[recipe]
					,[ng_retest_permitted]
					,[is_skipped]
					,[material_set_id]
					,[jig_set_id]
					,[data_collection_id]
					,[yield_lcl]
					,[ng_category_cnt]
					,[label_issue_id]
				)
				select [nu].[id] + row_number() over (order by [flow_details].[flow_pattern_id]) as [id]
					, @update_spid as [special_flow_id]
					, @step_no + row_number() over (order by [flow_details].[flow_pattern_id]) as [step_no]
					, case
						when row_number() over (order by [flow_details].[flow_pattern_id]) = @count_flow then @step_no + row_number() over (order by [flow_details].[flow_pattern_id])
						else @step_no + row_number() over (order by [flow_details].[flow_pattern_id]) + 1
					end as [next_step_no]
					, [jobs].[process_id] as [act_process_id]
					, [jobs].[id] as [job_id]
					, [lots].[act_package_id] as [act_package_flow_id]
					, 0 as [permitted_machine_id]
					, 0 as [process_minutes]
					, 0 as [sum_process_minutes]
					, IIF(@recipe is null,(select recipe from @table_recipe where job_id = [jobs].[id]),@recipe) AS [recipe]
					, 0 as [ng_retest_permitted]
					, 0 as [is_skipped]
					, NULL as [material_set_id]
					, NULL as [jig_set_id]
					, NULL as [data_collection_id]
					, NULL as [yield_lcl]
					, NULL as [ng_category_cnt]
					, 0 as [issue_label_type]
				from [APCSProDB].[method].[flow_details] 
				inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'lot_special_flows.id'
				inner join [APCSProDB].[method].[jobs] on [flow_details].[job_id] = [jobs].[id]
				inner join [APCSProDB].[trans].[lots] on [lots].[id] = @lot_id
				where [flow_details].[flow_pattern_id] = @flow_pattern_id

				SET @r_lsf = @@ROWCOUNT
				UPDATE [APCSProDB].[trans].[numbers]
				SET [id] = [id] + @r_lsf
				WHERE [name] = 'lot_special_flows.id'

				insert into [APCSProDB].[trans].[lot_process_records]
				(
					[id]
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
					,[act_device_name_id]
					,[device_slip_id]
					,[order_id]
					,[abc_judgement]
					,[held_at]
					,[held_minutes_current]
					,[limit_time_state]
					,[map_edit_state]
					,[qty_frame_in]
					,[qty_frame_pass]
					,[qty_frame_fail]
					,[qty_frame_last_pass]
					,[qty_frame_last_fail]
					,[qty_frame_pass_step_sum]
					,[qty_frame_fail_step_sum]
					,[qty_p_nashi]
					,[qty_front_ng]
					,[qty_marker]
					,[qty_cut_frame]
					,[qty_combined]
				)
				SELECT [nu].[id] + row_number() over (order by [lots].[id])
					, [days].[id] [day_id]
					, GETDATE() as [recorded_at]
					, @user_id as [operated_by]
					, 25 as [record_class]
					, [lots].[id] as [lot_id]
					, [lot_special_flows].[act_process_id] as [process_id]
					--, [act_job_id] as [job_id]
					, [lot_special_flows].job_id as [job_id]
					, [lot_special_flows].[step_no]
					, [qty_pass] as [qty_in]
					, [qty_pass]
					, 0 as [qty_fail]
					, NULL as [qty_last_pass]
					, NULL as [qty_last_fail]
					, NULL as [qty_pass_step_sum]
					, NULL as [qty_fail_step_sum]
					, NULL as [qty_divided]
					, [qty_hasuu] as [qty_hasuu]
					, [qty_out] as [qty_out]
					, [lot_special_flows].[recipe] as [recipe]
					, 1 as [recipe_version]
					, @machine_id as [machine_id]
					, NULL as [position_id]
					, NULL as [process_job_id]
					, 0 as [is_onlined]
					, 0 as [dbx_id]
					, [lots].[wip_state]
					, [lots].[process_state]
					, [lots].[quality_state]
					, 0 as [first_ins_state]
					, 0 as [final_ins_state]
					, [is_special_flow]
					, @update_spid as [special_flow_id]
					, 0 as [is_temp_devided]
					, NULL as [temp_devided_count]
					, NULL as [container_no]
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
					, NULL as [act_device_name_id]
					, NULL as [device_slip_id]
					, NULL as [order_id]
					, NULL as [abc_judgement]
					, NULL as [held_at]
					, NULL as [held_minutes_current]
					, NULL as [limit_time_state]
					, NULL as [map_edit_state]
					, [qty_frame_pass] as [qty_frame_in]
					, [qty_frame_pass] as [qty_frame_pass]
					, NULL as [qty_frame_fail]
					, NULL as [qty_frame_last_pass]
					, NULL as [qty_frame_last_fail]
					, NULL as [qty_frame_pass_step_sum]
					, NULL as [qty_frame_fail_step_sum]
					, [qty_p_nashi]
					, [qty_front_ng]
					, [qty_marker]
					, [qty_cut_frame]
					, [qty_combined]
				FROM [APCSProDB].[trans].[lots] 
				INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
				INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
				INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = @update_spid
				WHERE [lots].[id] = @lot_id;

				SET @r_lpr = @@ROWCOUNT
				UPDATE [APCSProDB].[trans].[numbers]
				SET [id] = [id] + @r_lpr
				WHERE [name] = 'lot_process_records.id';
				set @result = 1;
				----------------------------------------------------------------------------------
			end
		end
		---------------------------------------------------------------------------
		--(11) Add after
		---------------------------------------------------------------------------
		if (@is_special_flow = 0)
		begin
			if ((select flow_type from @table_flow where step_no = @step_no) = 1)
			begin
				set @check_flow = (select top 1 flow_type from @table_flow where step_no > @step_no
				order by [step_no])

				if (@check_flow = 2)
				begin
					commit transaction;
					select 'FALSE' AS Is_Pass 
						, 'cannot add flow because next step no is special flow!!' AS Error_Message_ENG
						, N'step no ถัดไปเป็น special flow ไม่สามารถเพิ่ม flow ได้  !!' AS Error_Message_THA 
						, '' AS Handling
					return
				end
				else begin
					----------------------------------------------------------------------------------------------
					insert into [APCSProDB].[trans].[special_flows]
					(
						[id]
						,[lot_id]
						,[step_no]
						,[back_step_no]
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
						,[is_exist_work]
						,[wip_state]
						,[process_state]
						,[quality_state]
						,[first_ins_state]
						,[final_ins_state]
						,[priority]
						,[finish_date_id]
						,[finished_at]
						,[machine_id]
						,[container_no]
						,[qc_comment_id]
						,[qc_memo_id]
						,[process_job_id]
						,[carried_at]
						,[is_special_flow]
						,[special_flow_id]
						,[instruction_reason_id]
						,[start_special_message_id]
						,[finish_special_message_id]
						,[holded_at]
						,[created_at]
						,[created_by]
						,[updated_at]
						,[updated_by]
						,[limit_time_state]
						,[map_edit_state]
						,[qty_p_nashi]
						,[qty_front_ng]
						,[qty_marker]
						,[qty_cut_frame]
						,[qty_combined]
						,[qty_frame_in]
						,[qty_frame_pass]
						,[qty_frame_fail]
						--,[exec_state]
					)
					select [nu].[id] + row_number() over (order by [lots].[id]) as [id]
						, [lots].[id] as [lot_id]
						, @q1_step_no + 1 as [step_no]
						, @q1_back_step_no_master as [back_step_no]
						, [lots].[qty_pass]
						, [lots].[qty_pass]
						, 0 as [qty_fail]
						, NULL as [qty_last_pass]
						, NULL as [qty_last_fail]
						, NULL as [qty_pass_step_sum]
						, NULL as [qty_fail_step_sum]
						, NULL as [qty_divided]
						, [qty_hasuu] as [qty_hasuu]
						, [qty_out] as [qty_out]
						, 0 as [is_exist_work]
						, 20 as [wip_state]
						, 0 as [process_state]
						, 0 as [quality_state]
						, 0 as [first_ins_state]
						, 0 as [final_ins_state]
						, [lots].[priority]
						, [lots].[finish_date_id]
						, [lots].[finished_at]
						, @machine_id as [machine_id]
						, [lots].[container_no]
						, NULL as [qc_comment_id]
						, NULL as [qc_memo_id]
						, NULL as [process_job_id]
						, [lots].[carried_at]
						, 0 as [is_special_flow_id]
						, NULL as [special_flow_id]
						, NULL as [instruction_reason_id]
						, NULL as [start_special_message_id]
						, NULL as [finish_special_message_id]
						, NULL as [holded_at]
						, GETDATE() as [created_at]
						, @user_id as [created_by]
						, NULL as [updated_at]
						, NULL as [updated_by]
						, NULL as [limit_time_state]
						, NULL as [map_edit_state]
						, [qty_p_nashi]
						, [qty_front_ng]
						, [qty_marker]
						, [qty_cut_frame]
						, [qty_combined]
						, [qty_frame_pass]
						, [qty_frame_pass]
						, [qty_frame_fail]
						--, 0 as [exec_state]
					from [APCSProDB].[trans].[lots] 
					inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'special_flows.id'
					where [lots].[id] = @lot_id

					SET @r_sf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_sf
					, @update_spid = [id] + @r_sf
					WHERE [name] = 'special_flows.id'

					insert into [APCSProDB].[trans].[lot_special_flows]
					(
						[id]
						,[special_flow_id]
						,[step_no]
						,[next_step_no]
						,[act_process_id]
						,[job_id]
						,[act_package_flow_id]
						,[permitted_machine_id]
						,[process_minutes]
						,[sum_process_minutes]
						,[recipe]
						,[ng_retest_permitted]
						,[is_skipped]
						,[material_set_id]
						,[jig_set_id]
						,[data_collection_id]
						,[yield_lcl]
						,[ng_category_cnt]
						,[label_issue_id]
					)
					select [nu].[id] + row_number() over (order by [flow_details].[flow_pattern_id]) as [id]
						, @update_spid as [special_flow_id]
						, @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id]) as [step_no]
						, case
							when row_number() over (order by [flow_details].[flow_pattern_id]) = @count_flow then @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id])
							else @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id]) + 1
						end as [next_step_no]
						, [jobs].[process_id] as [act_process_id]
						, [jobs].[id] as [job_id]
						, [lots].[act_package_id] as [act_package_flow_id]
						, 0 as [permitted_machine_id]
						, 0 as [process_minutes]
						, 0 as [sum_process_minutes]
						, IIF(@recipe is null,(select recipe from @table_recipe where job_id = [jobs].[id]),@recipe) AS [recipe]
						, 0 as [ng_retest_permitted]
						, 0 as [is_skipped]
						, NULL as [material_set_id]
						, NULL as [jig_set_id]
						, NULL as [data_collection_id]
						, NULL as [yield_lcl]
						, NULL as [ng_category_cnt]
						, 0 as [issue_label_type]
					from [APCSProDB].[method].[flow_details] 
					inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'lot_special_flows.id'
					inner join [APCSProDB].[method].[jobs] on [flow_details].[job_id] = [jobs].[id]
					inner join [APCSProDB].[trans].[lots] on [lots].[id] = @lot_id
					where [flow_details].[flow_pattern_id] = @flow_pattern_id

					SET @r_lsf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lsf
					WHERE [name] = 'lot_special_flows.id'

					insert into [APCSProDB].[trans].[lot_process_records]
					(
						[id]
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
						,[act_device_name_id]
						,[device_slip_id]
						,[order_id]
						,[abc_judgement]
						,[held_at]
						,[held_minutes_current]
						,[limit_time_state]
						,[map_edit_state]
						,[qty_frame_in]
						,[qty_frame_pass]
						,[qty_frame_fail]
						,[qty_frame_last_pass]
						,[qty_frame_last_fail]
						,[qty_frame_pass_step_sum]
						,[qty_frame_fail_step_sum]
						,[qty_p_nashi]
						,[qty_front_ng]
						,[qty_marker]
						,[qty_cut_frame]
						,[qty_combined]
					)
					SELECT [nu].[id] + row_number() over (order by [lots].[id])
						, [days].[id] [day_id]
						, GETDATE() as [recorded_at]
						, @user_id as [operated_by]
						, 25 as [record_class]
						, [lots].[id] as [lot_id]
						, [lot_special_flows].[act_process_id] as [process_id]
						--, [act_job_id] as [job_id]
						, [lot_special_flows].job_id as [job_id]
						, [lot_special_flows].[step_no]
						, [qty_pass] as [qty_in]
						, [qty_pass]
						, 0 as [qty_fail]
						, NULL as [qty_last_pass]
						, NULL as [qty_last_fail]
						, NULL as [qty_pass_step_sum]
						, NULL as [qty_fail_step_sum]
						, NULL as [qty_divided]
						, [qty_hasuu] as [qty_hasuu]
						, [qty_out] as [qty_out]
						, [lot_special_flows].[recipe] as [recipe]
						, 1 as [recipe_version]
						, @machine_id as [machine_id]
						, NULL as [position_id]
						, NULL as [process_job_id]
						, 0 as [is_onlined]
						, 0 as [dbx_id]
						, [lots].[wip_state]
						, [lots].[process_state]
						, [lots].[quality_state]
						, 0 as [first_ins_state]
						, 0 as [final_ins_state]
						, [is_special_flow]
						, @update_spid as [special_flow_id]
						, 0 as [is_temp_devided]
						, NULL as [temp_devided_count]
						, NULL as [container_no]
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
						, NULL as [act_device_name_id]
						, NULL as [device_slip_id]
						, NULL as [order_id]
						, NULL as [abc_judgement]
						, NULL as [held_at]
						, NULL as [held_minutes_current]
						, NULL as [limit_time_state]
						, NULL as [map_edit_state]
						, [qty_frame_pass] as [qty_frame_in]
						, [qty_frame_pass] as [qty_frame_pass]
						, NULL as [qty_frame_fail]
						, NULL as [qty_frame_last_pass]
						, NULL as [qty_frame_last_fail]
						, NULL as [qty_frame_pass_step_sum]
						, NULL as [qty_frame_fail_step_sum]
						, [qty_p_nashi]
						, [qty_front_ng]
						, [qty_marker]
						, [qty_cut_frame]
						, [qty_combined]
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
					INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
					INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = @update_spid
						--and [lot_special_flows].[step_no] between (@step_no) and ((@step_no - 1) + (@count_flow))
					WHERE [lots].[id] = @lot_id;

					SET @r_lpr = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lpr
					WHERE [name] = 'lot_process_records.id';

					set @result = 1;
					----------------------------------------------------------------------------------------------
				end
			end
			else if ((select flow_type from @table_flow where step_no = @step_no) = 2)
			begin
				set @check_flow = (select top 1 flow_type from @table_flow where step_no > @step_no
				order by [step_no])

				if (@check_flow = 2)
				begin
					commit transaction;
					select 'FALSE' AS Is_Pass 
						, 'cannot add flow because next step no is special flow!!' AS Error_Message_ENG
						, N'step no ถัดไปเป็น special flow ไม่สามารถเพิ่ม flow ได้  !!' AS Error_Message_THA 
						, '' AS Handling
					return
				end
				else begin
					--------------------------------------------------------------------------------------
					if ((select flow_type from @table_flow where step_no = @step_no) = 1)
					begin
						insert into [APCSProDB].[trans].[special_flows]
						(
							[id]
							,[lot_id]
							,[step_no]
							,[back_step_no]
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
							,[is_exist_work]
							,[wip_state]
							,[process_state]
							,[quality_state]
							,[first_ins_state]
							,[final_ins_state]
							,[priority]
							,[finish_date_id]
							,[finished_at]
							,[machine_id]
							,[container_no]
							,[qc_comment_id]
							,[qc_memo_id]
							,[process_job_id]
							,[carried_at]
							,[is_special_flow]
							,[special_flow_id]
							,[instruction_reason_id]
							,[start_special_message_id]
							,[finish_special_message_id]
							,[holded_at]
							,[created_at]
							,[created_by]
							,[updated_at]
							,[updated_by]
							,[limit_time_state]
							,[map_edit_state]
							,[qty_p_nashi]
							,[qty_front_ng]
							,[qty_marker]
							,[qty_cut_frame]
							,[qty_combined]
							,[qty_frame_in]
							,[qty_frame_pass]
							,[qty_frame_fail]
							--,[exec_state]
						)
						select [nu].[id] + row_number() over (order by [lots].[id]) as [id]
							, [lots].[id] as [lot_id]
							, @q1_step_no + 1 as [step_no]
							, @q1_back_step_no_master as [back_step_no]
							, [lots].[qty_pass]
							, [lots].[qty_pass]
							, 0 as [qty_fail]
							, NULL as [qty_last_pass]
							, NULL as [qty_last_fail]
							, NULL as [qty_pass_step_sum]
							, NULL as [qty_fail_step_sum]
							, NULL as [qty_divided]
							, [qty_hasuu] as [qty_hasuu]
							, [qty_out] as [qty_out]
							, 0 as [is_exist_work]
							, 20 as [wip_state]
							, 0 as [process_state]
							, 0 as [quality_state]
							, 0 as [first_ins_state]
							, 0 as [final_ins_state]
							, [lots].[priority]
							, [lots].[finish_date_id]
							, [lots].[finished_at]
							, @machine_id as [machine_id]
							, [lots].[container_no]
							, NULL as [qc_comment_id]
							, NULL as [qc_memo_id]
							, NULL as [process_job_id]
							, [lots].[carried_at]
							, 0 as [is_special_flow_id]
							, NULL as [special_flow_id]
							, NULL as [instruction_reason_id]
							, NULL as [start_special_message_id]
							, NULL as [finish_special_message_id]
							, NULL as [holded_at]
							, GETDATE() as [created_at]
							, @user_id as [created_by]
							, NULL as [updated_at]
							, NULL as [updated_by]
							, NULL as [limit_time_state]
							, NULL as [map_edit_state]
							, [qty_p_nashi]
							, [qty_front_ng]
							, [qty_marker]
							, [qty_cut_frame]
							, [qty_combined]
							, [qty_frame_pass]
							, [qty_frame_pass]
							, [qty_frame_fail]
							--, 0 as [exec_state]
						from [APCSProDB].[trans].[lots] 
						inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'special_flows.id'
						where [lots].[id] = @lot_id

						SET @r_sf = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r_sf
						, @update_spid = [id] + @r_sf
						WHERE [name] = 'special_flows.id'


						insert into [APCSProDB].[trans].[lot_special_flows]
						(
							[id]
							,[special_flow_id]
							,[step_no]
							,[next_step_no]
							,[act_process_id]
							,[job_id]
							,[act_package_flow_id]
							,[permitted_machine_id]
							,[process_minutes]
							,[sum_process_minutes]
							,[recipe]
							,[ng_retest_permitted]
							,[is_skipped]
							,[material_set_id]
							,[jig_set_id]
							,[data_collection_id]
							,[yield_lcl]
							,[ng_category_cnt]
							,[label_issue_id]
						)
						select [nu].[id] + row_number() over (order by [flow_details].[flow_pattern_id]) as [id]
							, @update_spid as [special_flow_id]
							, @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id]) as [step_no]
							, case
								when row_number() over (order by [flow_details].[flow_pattern_id]) = @count_flow then @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id])
								else @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id]) + 1
							end as [next_step_no]
							, [jobs].[process_id] as [act_process_id]
							, [jobs].[id] as [job_id]
							, [lots].[act_package_id] as [act_package_flow_id]
							, 0 as [permitted_machine_id]
							, 0 as [process_minutes]
							, 0 as [sum_process_minutes]
							, IIF(@recipe is null,(select recipe from @table_recipe where job_id = [jobs].[id]),@recipe) AS [recipe]
							, 0 as [ng_retest_permitted]
							, 0 as [is_skipped]
							, NULL as [material_set_id]
							, NULL as [jig_set_id]
							, NULL as [data_collection_id]
							, NULL as [yield_lcl]
							, NULL as [ng_category_cnt]
							, 0 as [issue_label_type]
						from [APCSProDB].[method].[flow_details] 
						inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'lot_special_flows.id'
						inner join [APCSProDB].[method].[jobs] on [flow_details].[job_id] = [jobs].[id]
						inner join [APCSProDB].[trans].[lots] on [lots].[id] = @lot_id
						where [flow_details].[flow_pattern_id] = @flow_pattern_id

						SET @r_lsf = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r_lsf
						WHERE [name] = 'lot_special_flows.id'

						insert into [APCSProDB].[trans].[lot_process_records]
						(
							[id]
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
							,[act_device_name_id]
							,[device_slip_id]
							,[order_id]
							,[abc_judgement]
							,[held_at]
							,[held_minutes_current]
							,[limit_time_state]
							,[map_edit_state]
							,[qty_frame_in]
							,[qty_frame_pass]
							,[qty_frame_fail]
							,[qty_frame_last_pass]
							,[qty_frame_last_fail]
							,[qty_frame_pass_step_sum]
							,[qty_frame_fail_step_sum]
							,[qty_p_nashi]
							,[qty_front_ng]
							,[qty_marker]
							,[qty_cut_frame]
							,[qty_combined]
						)
						SELECT [nu].[id] + row_number() over (order by [lots].[id])
							, [days].[id] [day_id]
							, GETDATE() as [recorded_at]
							, @user_id as [operated_by]
							, 25 as [record_class]
							, [lots].[id] as [lot_id]
							, [lot_special_flows].[act_process_id] as [process_id]
							--, [act_job_id] as [job_id]
							, [lot_special_flows].job_id as [job_id]
							, [lot_special_flows].[step_no]
							, [qty_pass] as [qty_in]
							, [qty_pass]
							, 0 as [qty_fail]
							, NULL as [qty_last_pass]
							, NULL as [qty_last_fail]
							, NULL as [qty_pass_step_sum]
							, NULL as [qty_fail_step_sum]
							, NULL as [qty_divided]
							, [qty_hasuu] as [qty_hasuu]
							, [qty_out] as [qty_out]
							, [lot_special_flows].[recipe] as [recipe]
							, 1 as [recipe_version]
							, @machine_id as [machine_id]
							, NULL as [position_id]
							, NULL as [process_job_id]
							, 0 as [is_onlined]
							, 0 as [dbx_id]
							, [lots].[wip_state]
							, [lots].[process_state]
							, [lots].[quality_state]
							, 0 as [first_ins_state]
							, 0 as [final_ins_state]
							, [is_special_flow]
							, @update_spid as [special_flow_id]
							, 0 as [is_temp_devided]
							, NULL as [temp_devided_count]
							, NULL as [container_no]
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
							, NULL as [act_device_name_id]
							, NULL as [device_slip_id]
							, NULL as [order_id]
							, NULL as [abc_judgement]
							, NULL as [held_at]
							, NULL as [held_minutes_current]
							, NULL as [limit_time_state]
							, NULL as [map_edit_state]
							, [qty_frame_pass] as [qty_frame_in]
							, [qty_frame_pass] as [qty_frame_pass]
							, NULL as [qty_frame_fail]
							, NULL as [qty_frame_last_pass]
							, NULL as [qty_frame_last_fail]
							, NULL as [qty_frame_pass_step_sum]
							, NULL as [qty_frame_fail_step_sum]
							, [qty_p_nashi]
							, [qty_front_ng]
							, [qty_marker]
							, [qty_cut_frame]
							, [qty_combined]
						FROM [APCSProDB].[trans].[lots] 
						INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
						INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
						INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = @update_spid
							--and [lot_special_flows].[step_no] between (@step_no) and ((@step_no - 1) + (@count_flow))
						WHERE [lots].[id] = @lot_id;

						SET @r_lpr = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r_lpr
						WHERE [name] = 'lot_process_records.id';

						set @result = 1;
					end
					else if ((select flow_type from @table_flow where step_no = @step_no) = 2)
					begin
					
						update [APCSProDB].[trans].[lot_special_flows]
							set next_step_no = next_step_no + 1
						from [APCSProDB].[trans].[lot_special_flows]
						inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id and [lot_special_flows].[step_no] = @step_no

						select @update_spid = [lot_special_flows].[special_flow_id]
						from [APCSProDB].[trans].[lot_special_flows]
						inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id and [lot_special_flows].[step_no] = @step_no

						insert into [APCSProDB].[trans].[lot_special_flows]
						(
							[id]
							,[special_flow_id]
							,[step_no]
							,[next_step_no]
							,[act_process_id]
							,[job_id]
							,[act_package_flow_id]
							,[permitted_machine_id]
							,[process_minutes]
							,[sum_process_minutes]
							,[recipe]
							,[ng_retest_permitted]
							,[is_skipped]
							,[material_set_id]
							,[jig_set_id]
							,[data_collection_id]
							,[yield_lcl]
							,[ng_category_cnt]
							,[label_issue_id]
						)
						select [nu].[id] + row_number() over (order by [flow_details].[flow_pattern_id]) as [id]
							, @update_spid as [special_flow_id]
							, @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id]) as [step_no]
							, case
								when row_number() over (order by [flow_details].[flow_pattern_id]) = @count_flow then @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id])
								else @q1_step_no + row_number() over (order by [flow_details].[flow_pattern_id]) + 1
							end as [next_step_no]
							, [jobs].[process_id] as [act_process_id]
							, [jobs].[id] as [job_id]
							, [lots].[act_package_id] as [act_package_flow_id]
							, 0 as [permitted_machine_id]
							, 0 as [process_minutes]
							, 0 as [sum_process_minutes]
							, IIF(@recipe is null,(select recipe from @table_recipe where job_id = [jobs].[id]),@recipe) AS [recipe]
							, 0 as [ng_retest_permitted]
							, 0 as [is_skipped]
							, NULL as [material_set_id]
							, NULL as [jig_set_id]
							, NULL as [data_collection_id]
							, NULL as [yield_lcl]
							, NULL as [ng_category_cnt]
							, 0 as [issue_label_type]
						from [APCSProDB].[method].[flow_details] 
						inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'lot_special_flows.id'
						inner join [APCSProDB].[method].[jobs] on [flow_details].[job_id] = [jobs].[id]
						inner join [APCSProDB].[trans].[lots] on [lots].[id] = @lot_id
						where [flow_details].[flow_pattern_id] = @flow_pattern_id

						SET @r_lsf = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r_lsf
						WHERE [name] = 'lot_special_flows.id';

						insert into [APCSProDB].[trans].[lot_process_records]
						(
							[id]
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
							,[act_device_name_id]
							,[device_slip_id]
							,[order_id]
							,[abc_judgement]
							,[held_at]
							,[held_minutes_current]
							,[limit_time_state]
							,[map_edit_state]
							,[qty_frame_in]
							,[qty_frame_pass]
							,[qty_frame_fail]
							,[qty_frame_last_pass]
							,[qty_frame_last_fail]
							,[qty_frame_pass_step_sum]
							,[qty_frame_fail_step_sum]
							,[qty_p_nashi]
							,[qty_front_ng]
							,[qty_marker]
							,[qty_cut_frame]
							,[qty_combined]
						)
						SELECT [nu].[id] + row_number() over (order by [lots].[id])
							, [days].[id] [day_id]
							, GETDATE() as [recorded_at]
							, @user_id as [operated_by]
							, 25 as [record_class]
							, [lots].[id] as [lot_id]
							, [lot_special_flows].[act_process_id] as [process_id]
							--, [act_job_id] as [job_id]
							, [lot_special_flows].job_id as [job_id]
							, [lot_special_flows].[step_no]
							, [qty_pass] as [qty_in]
							, [qty_pass]
							, 0 as [qty_fail]
							, NULL as [qty_last_pass]
							, NULL as [qty_last_fail]
							, NULL as [qty_pass_step_sum]
							, NULL as [qty_fail_step_sum]
							, NULL as [qty_divided]
							, [qty_hasuu] as [qty_hasuu]
							, [qty_out] as [qty_out]
							, [lot_special_flows].[recipe] as [recipe]
							, 1 as [recipe_version]
							, @machine_id as [machine_id]
							, NULL as [position_id]
							, NULL as [process_job_id]
							, 0 as [is_onlined]
							, 0 as [dbx_id]
							, [lots].[wip_state]
							, [lots].[process_state]
							, [lots].[quality_state]
							, 0 as [first_ins_state]
							, 0 as [final_ins_state]
							, [is_special_flow]
							, @update_spid as [special_flow_id]
							, 0 as [is_temp_devided]
							, NULL as [temp_devided_count]
							, NULL as [container_no]
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
							, NULL as [act_device_name_id]
							, NULL as [device_slip_id]
							, NULL as [order_id]
							, NULL as [abc_judgement]
							, NULL as [held_at]
							, NULL as [held_minutes_current]
							, NULL as [limit_time_state]
							, NULL as [map_edit_state]
							, [qty_frame_pass] as [qty_frame_in]
							, [qty_frame_pass] as [qty_frame_pass]
							, NULL as [qty_frame_fail]
							, NULL as [qty_frame_last_pass]
							, NULL as [qty_frame_last_fail]
							, NULL as [qty_frame_pass_step_sum]
							, NULL as [qty_frame_fail_step_sum]
							, [qty_p_nashi]
							, [qty_front_ng]
							, [qty_marker]
							, [qty_cut_frame]
							, [qty_combined]
						FROM [APCSProDB].[trans].[lots] 
						INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
						INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
						INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = @update_spid
							and [lot_special_flows].[step_no] between (@step_no + 1) and ((@step_no + 1) + @count_flow)
						WHERE [lots].[id] = @lot_id;

						SET @r_lpr = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r_lpr
						WHERE [name] = 'lot_process_records.id';

						set @result = 1;

					end
					--------------------------------------------------------------------------------------
				end
			end
		end
		---------------------------------------------------------------------------
		--(12) update trans.lots
		---------------------------------------------------------------------------
		if (@is_special_flow = 1)
		begin
			if ((select is_special_flow from APCSProDB.trans.lots where id = @lot_id) != 1)
			begin
				update APCSProDB.trans.lots
				set is_special_flow = 1
					, special_flow_id = @update_spid
					, quality_state = 4
					, updated_at = GETDATE()
					, updated_by = @user_id
				where id = @lot_id
			end
		end
		else if (@is_special_flow = 0)
		begin
			if ((select is_special_flow from APCSProDB.trans.lots where id = @lot_id) != 1)
			begin
				update APCSProDB.trans.lots
				set special_flow_id = @update_spid
					, updated_at = GETDATE()
					, updated_by = @user_id
				where id = @lot_id
			end
		end
		---------------------------------------------------------------------------
		--(13) success
		---------------------------------------------------------------------------
		--commit transaction;
		if (@result = 1)
		begin
			commit transaction;
			select 'TRUE' AS Is_Pass 
				, '' AS Error_Message_ENG
				, '' AS Error_Message_THA 
				, '' AS Handling
			return
		end
	end try
	begin catch
		rollback transaction;
		---------------------------------------------------------------------------
		-- Log exec
		---------------------------------------------------------------------------	
		insert into [StoredProcedureDB].[dbo].[exec_sp_history]
		(
			[record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no]
		)
		select GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'rollback exec [atom].[sp_set_trans_special_flow_ver_005] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') 
				+ ''', @is_special_flow = ''' + ISNULL(CAST(@is_special_flow AS varchar),'')
				+ ''', @step_no = ''' + ISNULL(CAST(@step_no AS varchar),'') 
				+ ''', @flow_pattern_id = '''+ ISNULL(CAST(@flow_pattern_id AS varchar),'') 
				+ ''', @machine_id = ''' + ISNULL(CAST(@machine_id AS varchar),'') 
				+ ''', @recipe = ''' + ISNULL(CAST(@recipe AS varchar),'')
				+ ''', @user_id = ''' + ISNULL(CAST(@user_id AS varchar),'') + ''''
			, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = @lot_id)

		select 'FALSE' as Is_Pass 
			, 'Update fail. !!' as Error_Message_ENG
			, N'การบันทึกข้อมูลผิดพลาด !!' as Error_Message_THA 
			, '' as Handling
	end catch;
	--------------------------------------------------------------------
END
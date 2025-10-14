-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_ver_003]
	-- Add the parameters for the stored procedure here
	@lot_id INT
	, @step_no INT
	, @back_step_no INT
	, @user_id INT
	, @flow_pattern_id INT
	, @is_special_flow INT
	, @machine_id int = -1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [atom].[sp_set_trans_special_flow_3] @lot_id = ''' + CAST(@lot_id AS varchar) + ''', @step_no = ''' + CAST(@step_no AS varchar) + ''', @back_step_no = ''' 
		+ CAST(@back_step_no AS varchar) +''', @user_id = ''' + CAST(@user_id AS varchar) +''', @flow_pattern_id = '''+ CAST(@flow_pattern_id AS varchar) + ''', @is_special_flow = ''' 
		+ CAST(@is_special_flow AS varchar) + ''', @machine_id = ''' + CAST(@machine_id AS varchar) +''''

	DECLARE @r INT = 0;
	DECLARE @special_flow_id INT;
	DECLARE @step_no_now INT;
	DECLARE @device_slip_id INT;
	DECLARE @step_no_before INT = NULL;
	DECLARE @is_special_flow_now INT;
	DECLARE @fstep_no INT = NULL;
	DECLARE @special_flow_id_up INT;
	DECLARE @step_no_up INT = NULL;
	DECLARE @next_step_no_up INT = NULL;
	DECLARE @step_id_up INT = NULL;
	DECLARE @spstep_no INT = NULL;
	DECLARE @process_state INT = NULL;
	DECLARE @special_flow_id_is_null INT = NULL;

	--START add now process_state ต้องเท่ากับ 0
	SET @process_state = (SELECT process_state FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id)
	--process_state
	IF(@is_special_flow = 1 and @process_state != 0) 
		BEGIN
			SELECT 3 as status_id --process_state ไม่ใช่ WIP
		RETURN 
		END
	--END add now process_state ต้องเท่ากับ 0

	--START IF step no = 1 not now 
	IF(@step_no = 1)
		BEGIN
			--SET flow after
			SET @is_special_flow = 0
		END
	--END IF step no = 1 not now

	IF (@is_special_flow = 1) 
		BEGIN
			--START Check step before
			SELECT @fstep_no = [step_no]
			FROM (SELECT [device_flows].[step_no]
					, [next_step_no]
					, [device_flows].[is_skipped]
					, [jobs].[name] AS job_name
					, 0 AS [is_sp]
				FROM [APCSProDB].[method].[device_flows]
				INNER JOIN [APCSProDB].[method].[jobs] ON [device_flows].[job_id] = [jobs].[id]
				WHERE [device_flows].[device_slip_id] = (SELECT [device_slip_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id) 
					AND [device_flows].[is_skipped] != 1 AND [step_no] != @step_no

				UNION ALL

				SELECT [lot_special_flows].[step_no]
  					, [next_step_no]
					, [lot_special_flows].[is_skipped]
					, [jobs].[name] AS job_name
					, 1 AS [is_sp]	
				FROM [APCSProDB].[trans].[lot_special_flows]
				INNER JOIN [APCSProDB].[method].[jobs] ON [lot_special_flows].[job_id] = [jobs].[id]
				INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
				WHERE [special_flows].[lot_id] = @lot_id
			) AS table1
			WHERE [next_step_no] = @step_no
			ORDER BY [step_no]
			--END Check step before

			--START Check step before last special flow
			IF(EXISTS (SELECT MAX([lot_special_flows].[step_no]) FROM [APCSProDB].[trans].[special_flows]
						INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [lot_id] = @lot_id AND ([special_flows].[step_no] - @fstep_no) >= 1 AND ([special_flows].[step_no] - @fstep_no) < 100))
			BEGIN
				--find last special flow of step no
				SELECT @spstep_no = MAX([lot_special_flows].[step_no]) FROM [APCSProDB].[trans].[special_flows]
				INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
				WHERE [lot_id] = @lot_id AND ([special_flows].[step_no] - @fstep_no) >= 1 AND ([special_flows].[step_no] - @fstep_no) < 100;
				
				--set step no if have data
				IF (@spstep_no IS NOT NULL)
					BEGIN
						SET @fstep_no = @spstep_no
					END
			END
			--END Check step before last special flow

			--START IF step no start at 100
			IF (@fstep_no is null and @step_no = 100)
				BEGIN
					SET @spstep_no = NULL;
					SELECT @spstep_no = MAX([lot_special_flows].[step_no]) FROM [APCSProDB].[trans].[special_flows]
					INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
					WHERE [lot_id] = @lot_id AND [special_flows].[step_no] >= 1 AND [special_flows].[step_no] <= 99 ;
					
					IF (@fstep_no IS NULL AND @step_no = 100 AND @spstep_no IS NULL)
						BEGIN
							SET @fstep_no = 0
						END
					ELSE
						BEGIN
							SET @fstep_no = @spstep_no
						END	
						--SET @fstep_no = 0
				END
			--END IF step no start at 100
		END
	ELSE 
		BEGIN
			--select @fstep_no = [step_no]
			--from (select [device_flows].[step_no]
			--		, [next_step_no]
			--		, [device_flows].[is_skipped]
			--		, [jobs].[name] as job_name
			--		, 0 as [is_sp]
			--	from [APCSProDB].[method].[device_flows]
			--	inner join [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
			--	where [device_flows].[device_slip_id] = (select device_slip_id from [APCSProDB].[trans].[lots] where [lots].[id] = @lot_id) 
			--		and  [device_flows].[is_skipped] != 1

			--	UNION ALL

			--	select [lot_special_flows].[step_no]
  	--				, [next_step_no]
			--		, [lot_special_flows].[is_skipped]
			--		, [jobs].[name] as job_name
			--		, 1 as [is_sp]	
			--	from [APCSProDB].[trans].[lot_special_flows]
			--	inner join [APCSProDB].[method].[jobs] on [lot_special_flows].[job_id] = [jobs].[id]
			--	inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
			--	where [special_flows].[lot_id] = @lot_id
			--) as table1
			--where [step_no] = @step_no
			--order by [step_no]

			--SET step no 
			SET @fstep_no = @step_no
		END

	SET @step_no = @fstep_no;
	-->> Check step no
	SET @fstep_no = @step_no + 1
	

	IF (NOT EXISTS (SELECT [step_no]
			FROM (SELECT [device_flows].[step_no]
					, [next_step_no]
					, [device_flows].[is_skipped]
					, [jobs].[name] AS job_name
					, 0 AS [is_sp]
				FROM [APCSProDB].[method].[device_flows]
				INNER JOIN [APCSProDB].[method].[jobs] ON [device_flows].[job_id] = [jobs].[id]
				WHERE [device_flows].[device_slip_id] = (SELECT [device_slip_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id) 
					AND [device_flows].[is_skipped] != 1 AND [step_no] != @fstep_no

				UNION ALL

				SELECT [lot_special_flows].[step_no]
  					, [next_step_no]
					, [lot_special_flows].[is_skipped]
					, [jobs].[name] AS job_name
					, 1 AS [is_sp]	
				FROM [APCSProDB].[trans].[lot_special_flows]
				INNER JOIN [APCSProDB].[method].[jobs] ON [lot_special_flows].[job_id] = [jobs].[id]
				INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
				WHERE [special_flows].[lot_id] = @lot_id
			) AS table1
			WHERE [step_no] = @fstep_no))
		BEGIN
			-- check 
			SELECT @step_no_now = [step_no], @is_special_flow_now = [is_special_flow], @special_flow_id_is_null = [special_flow_id]
			FROM [APCSProDB].[trans].[lots] 
			WHERE [id] = @lot_id

			IF(@is_special_flow = 0)
			BEGIN
				SELECT @special_flow_id_up = [special_flows].[id]
					,@step_no_up = [lot_special_flows].[step_no]
					,@next_step_no_up = [next_step_no]
					,@step_id_up = [lot_special_flows].[id]
				FROM [APCSProDB].[trans].[special_flows]
				INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
				WHERE [lot_id] = @lot_id AND [lot_special_flows].[step_no] = @step_no AND [next_step_no] = @step_no
			END
			
			IF (@special_flow_id_up IS NULL AND @step_no_up IS NULL AND @next_step_no_up IS NULL AND @step_id_up IS NULL)
				-- new flow
				BEGIN
					INSERT INTO [APCSProDB].[trans].[special_flows]
					([id]
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
					SELECT [nu].[id] + row_number() over (order by [lots].[id])
						, [lots].[id]
						, @step_no + 1
						, @back_step_no
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
						, NULL as [qty_combined]
						, [qty_frame_pass]
						, [qty_frame_pass]
						, [qty_frame_fail]
						--, 0 as [exec_state]
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'special_flows.id'
					WHERE [lots].[id] = @lot_id

					SET @r = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r
					, @special_flow_id = [id] + @r
					WHERE [name] = 'special_flows.id'

					INSERT INTO [APCSProDB].[trans].[lot_special_flows]
					([id]
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
					SELECT [nu].[id] + row_number() over (order by [flow_details].[flow_pattern_id])
						, @special_flow_id
						, @step_no + row_number() over (order by [flow_details].[flow_pattern_id])
						, @step_no + row_number() over (order by [flow_details].[flow_pattern_id]) + 1
						, [jobs].[process_id]
						, [jobs].[id]
						, [lots].[act_package_id] AS [act_package_flow_id]
						, 0 AS [permitted_machine_id]
						, 0 AS [process_minutes]
						, 0 AS [sum_process_minutes]
						--, NULL AS [recipe]
						, isnull((select f.recipe from [APCSProDB].[trans].[lots] as l 
								inner join [APCSProDB].[method].[device_flows] as f 
									on f.device_slip_id = l.device_slip_id 
								inner join [APCSProDB].[method].[jobs] as j 
									on j.id = f.job_id
							where l.id = @lot_id and j.id = [jobs].[id]),NULL) AS [recipe]
						, 0 AS [ng_retest_permitted]
						, 0 AS [is_skipped]
						, NULL AS [material_set_id]
						, NULL AS [jig_set_id]
						, NULL AS [data_collection_id]
						, NULL AS [yield_lcl]
						, NULL AS [ng_category_cnt]
						, 0 AS [issue_label_type]
					FROM [APCSProDB].[method].[flow_details] 
					INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_special_flows.id'
					INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
					INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
					WHERE [flow_details].[flow_pattern_id] = @flow_pattern_id

					SET @r = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r
					WHERE [name] = 'lot_special_flows.id'

					UPDATE [APCSProDB].[trans].[lot_special_flows]
					SET [next_step_no] = @step_no + @r
					WHERE [special_flow_id] = @special_flow_id AND [next_step_no] = @step_no + @r + 1


					IF (@is_special_flow = 1)
						BEGIN
							UPDATE [APCSProDB].[trans].[lots]
							SET [quality_state] = 4
								, [is_special_flow] = 1
								, [special_flow_id] = @special_flow_id
								, [updated_at] = GETDATE()
								, [updated_by] = @user_id
							WHERE [lots].[id] = @lot_id;
						END
					ELSE
						BEGIN
							IF (@step_no = @step_no_now and @is_special_flow_now = 0)
								BEGIN
									UPDATE [APCSProDB].[trans].[lots]
									SET [special_flow_id] = @special_flow_id
										, [updated_at] = GETDATE()
										, [updated_by] = @user_id
									WHERE [lots].[id] = @lot_id;
								END
							ELSE
								BEGIN
									IF (@is_special_flow_now = 0 and (@special_flow_id_is_null = 0 or @special_flow_id_is_null is null))
										BEGIN
											UPDATE [APCSProDB].[trans].[lots]
											SET [special_flow_id] = @special_flow_id
												, [updated_at] = GETDATE()
												, [updated_by] = @user_id
											WHERE [lots].[id] = @lot_id;
										END
								END
							
						END

					INSERT INTO [APCSProDB].[trans].[lot_process_records]
					([id]
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
						,[qty_combined])
					SELECT [nu].[id] - 1 + row_number() over (order by [lots].[id])
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
						, 20 as [wip_state]
						, 0 as [process_state]
						, [quality_state]
						, 0 as [first_ins_state]
						, 0 as [final_ins_state]
						, [is_special_flow]
						, @special_flow_id as [special_flow_id]
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
						, NULL as [qty_combined]
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
					INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
					INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = @special_flow_id
					WHERE [lots].[id] = @lot_id

					SET @r = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r
					WHERE [name] = 'lot_process_records.id';

					Select 1 as status_id --add flow สำเร็จ
				END
				-- new flow
			ELSE
				-- have +1
				BEGIN
					IF @next_step_no_up = @step_no
						BEGIN
							UPDATE [APCSProDB].[trans].[special_flows]
							SET [back_step_no] = @back_step_no
							WHERE [id] = @special_flow_id_up AND [lot_id] = @lot_id;

							UPDATE [APCSProDB].[trans].[lot_special_flows]
							SET [next_step_no] = @step_no + 1
							WHERE [id] = @step_id_up AND [special_flow_id] = @special_flow_id_up;

							SET @special_flow_id = @special_flow_id_up
							
							INSERT INTO [APCSProDB].[trans].[lot_special_flows]
							([id]
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
							SELECT [nu].[id] + row_number() over (order by [flow_details].[flow_pattern_id])
								, @special_flow_id
								, @step_no + row_number() over (order by [flow_details].[flow_pattern_id])
								, @step_no + row_number() over (order by [flow_details].[flow_pattern_id]) + 1
								, [jobs].[process_id]
								, [jobs].[id]
								, [lots].[act_package_id] AS [act_package_flow_id]
								, 0 AS [permitted_machine_id]
								, 0 AS [process_minutes]
								, 0 AS [sum_process_minutes]
								--, NULL AS [recipe]
								, isnull((select f.recipe from [APCSProDB].[trans].[lots] as l 
									inner join [APCSProDB].[method].[device_flows] as f 
										on f.device_slip_id = l.device_slip_id 
									inner join [APCSProDB].[method].[jobs] as j 
										on j.id = f.job_id
								where l.id = @lot_id and j.id = [jobs].[id]),NULL) AS [recipe]
								, 0 AS [ng_retest_permitted]
								, 0 AS [is_skipped]
								, NULL AS [material_set_id]
								, NULL AS [jig_set_id]
								, NULL AS [data_collection_id]
								, NULL AS [yield_lcl]
								, NULL AS [ng_category_cnt]
								, 0 AS [issue_label_type]
							FROM [APCSProDB].[method].[flow_details] 
							INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_special_flows.id'
							INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
							INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
							WHERE [flow_details].[flow_pattern_id] = @flow_pattern_id

							SET @r = @@ROWCOUNT
							UPDATE [APCSProDB].[trans].[numbers]
							SET [id] = [id] + @r
							WHERE [name] = 'lot_special_flows.id'

							UPDATE [APCSProDB].[trans].[lot_special_flows]
							SET [next_step_no] = @step_no + @r
							WHERE [special_flow_id] = @special_flow_id AND [next_step_no] = @step_no + @r + 1


							IF (@is_special_flow = 1)
								BEGIN
									UPDATE [APCSProDB].[trans].[lots]
									SET [quality_state] = 4
										, [is_special_flow] = 1
										, [special_flow_id] = @special_flow_id
										, [updated_at] = GETDATE()
										, [updated_by] = @user_id
									WHERE [lots].[id] = @lot_id;
								END
							ELSE
								BEGIN
									IF (@step_no = @step_no_now and @is_special_flow_now = 0)
										BEGIN
											UPDATE [APCSProDB].[trans].[lots]
											SET [special_flow_id] = @special_flow_id
												, [updated_at] = GETDATE()
												, [updated_by] = @user_id
											WHERE [lots].[id] = @lot_id;
										END
								END

								
							INSERT INTO [APCSProDB].[trans].[lot_process_records]
							([id]
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
								,[qty_combined])
							SELECT [nu].[id] - 1 + row_number() over (order by [lots].[id])
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
								, 20 as [wip_state]
								, 0 as [process_state]
								, [quality_state]
								, 0 as [first_ins_state]
								, 0 as [final_ins_state]
								, [is_special_flow]
								, @special_flow_id as [special_flow_id]
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
								, [lots].[qty_p_nashi]
								, [lots].[qty_front_ng]
								, [lots].[qty_marker]
								, [lots].[qty_cut_frame]
								, NULL as [qty_combined]
							FROM [APCSProDB].[trans].[lots] 
							INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
							INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
							INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = @special_flow_id
								AND [lot_special_flows].[step_no] > @step_no
							WHERE [lots].[id] = @lot_id

							SET @r = @@ROWCOUNT
							UPDATE [APCSProDB].[trans].[numbers]
							SET [id] = [id] + @r
							WHERE [name] = 'lot_process_records.id';

							SELECT 1 as status_id --add flow สำเร็จ
						END
					ELSE
						BEGIN
							SELECT 2 as status_id --ไม่สามารถ add flow ได้
						END
				END
				-- have +1	
		END
	ELSE
		BEGIN
			SELECT 2 as status_id --ไม่สามารถ add flow ได้
		END
END

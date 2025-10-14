-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_v4]
	-- Add the parameters for the stored procedure here
	@lot_id INT
	, @step_no INT = NULL
	, @back_step_no INT = NULL --No Use
	, @user_id INT
	, @flow_pattern_id INT = NULL
	, @is_special_flow INT
	, @machine_id INT = -1
	, @recipe VARCHAR(20) = NULL
	, @numadd INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	--------------------------------------------------27/12/2021 10.03-------------------------------------------------

	---- PD add
	IF (@numadd IS NOT NULL)
		BEGIN
			IF(@numadd = 1)
				BEGIN
					SET @flow_pattern_id = 1198 --FL 100% INSP
				END
			IF(@numadd = 2)
				BEGIN
					SET @flow_pattern_id = 1199 --100% X-Ray
				END
			IF(@numadd = 3)
				BEGIN
					SET @flow_pattern_id = 1267 --FT 100% INSP
				END
			IF(@numadd = 4)
				BEGIN
					SET @flow_pattern_id = 1499 -- TP Rework
				END
			IF(@numadd = 5)
				BEGIN
					SET @flow_pattern_id = 1667 -- Aging TP Rework
				END
			IF(@numadd = 6)
				BEGIN
					SET @flow_pattern_id = 1673 -- TP Aging Rework
				END
			IF(@numadd = 7)
				BEGIN
					SET @flow_pattern_id = 1726 -- Test Evaluation
				END
			IF(@numadd = 8)
				BEGIN
					SET @flow_pattern_id = 1798 -- DB Inspection
				END
			IF(@numadd = 9)
				BEGIN
					SET @flow_pattern_id = 1745 -- WB Inspection
				END
			IF(@numadd = 10)
				BEGIN
					SET @flow_pattern_id = 696 -- DC 100% INSP.
				END
			IF(@numadd = 11)
				BEGIN
					SET @flow_pattern_id = 1841 -- Marker
				END
			IF(@numadd = 12)
				BEGIN
					SET @flow_pattern_id = 1827 -- Wafer AOI
				END
			IF(@numadd = 13)
				BEGIN
					SET @flow_pattern_id = 1829 -- X-RAY Period Check
				END
			IF(@numadd = 14)
				BEGIN
					SET @flow_pattern_id = 1830 -- Solder Test
				END
			IF(@numadd = 15)
				BEGIN
					SET @flow_pattern_id = 1818 -- Sampling SAT
				END
			IF(@numadd = 16)
				BEGIN
					SET @flow_pattern_id = 1819 -- Keep Good Sample
				END
			IF(@numadd = 17)
				BEGIN
					SET @flow_pattern_id = 1820 -- Keep NG Sample
				END
			IF(@numadd = 18)
				BEGIN
					SET @flow_pattern_id = 1832 -- Change Tube
				END
		END
	---- PD add

	--<< log exec
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no])
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [atom].[sp_set_trans_special_flow_v4_new] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') + ''', @step_no = ''' + ISNULL(CAST(@step_no AS varchar),'') + ''', @back_step_no = ''' 
			+ ISNULL(CAST(@back_step_no AS varchar),'') +''', @user_id = ''' + ISNULL(CAST(@user_id AS varchar),'') +''', @flow_pattern_id = '''+ ISNULL(CAST(@flow_pattern_id AS varchar),'') + ''', @is_special_flow = ''' 
			+ ISNULL(CAST(@is_special_flow AS varchar),'') +''', @machine_id = ''' + ISNULL(CAST(@machine_id AS varchar),'') + ''', @recipe = '''
			+ ISNULL(CAST(@recipe AS varchar),'') +''''
		--, 'EXEC [atom].[sp_set_trans_special_flow_v5] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') + ''', @step_no = ''' + ISNULL(CAST(@step_no AS varchar),'') + ''', @back_step_no = ''' 
		--	+ ISNULL(CAST(@back_step_no AS varchar),'') +''', @user_id = ''' + ISNULL(CAST(@user_id AS varchar),'') +''', @flow_pattern_id = '''+ ISNULL(CAST(@flow_pattern_id AS varchar),'') + ''', @is_special_flow = ''' 
		--	+ ISNULL(CAST(@is_special_flow AS varchar),'') + ''', @machine_id = ''' + ISNULL(CAST(@machine_id AS varchar),'') +''''
		, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = @lot_id)
	-->> log exec

	
	--declare @lot_id int = 644970
	--declare @flow_pattern_id INT = 1817
	--declare @user_id INT = 1339
	--declare @machine_id int = -1
	--declare @step_no INT = 100
	--declare @is_special_flow INT = 1

	DECLARE @tran int = 0;
	-- row number
	DECLARE @r INT = 0;
	-- check step no
	declare @q1_step_no INT = 0
	declare @q1_back_step_no INT = 0
	declare @q1_back_step_no_master INT = 0
	-- insert or update special flow
	DECLARE @special_flow_id_up INT = NULL;
	DECLARE @step_id_up INT = NULL;
	-- check now
	DECLARE @step_no_now INT = NULL;
	declare @is_special_flow_now INT = NULL;
	DECLARE @flow_num INT = NULL;
	declare @table_recipe table
			(
				recipe varchar(30),
				step_no int,
				job_id int
			)
	---recipe 13.45
	insert @table_recipe (recipe ,step_no ,job_id)
	select [device_flows].[recipe]
		, [device_flows].[step_no]
		, [job].[job_id_old] as [job_id]
	from [APCSProDB].[trans].[lots]
	inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id]
	left join 
	(
		SELECT [flow_patterns].[id] as [flow_patterns_id]
			, [comments]
			--, [flow_details].[job_id] as  
			--, [processes].[name] as [process]
			, [jobs].[id] as [job_id_old]
			, case 
				when [jobs].[name] = 'OS1' then 50
				when [jobs].[name] = 'OS2' then 50
				when [jobs].[name] = 'FLFTTP' then 92
				when [jobs].[name] = 'OS+AUTO(1)' then 106
				when [jobs].[name] = 'AUTO(1) RE' then 106
				when [jobs].[name] = 'AUTO(1) BIN27' then 106
				when [jobs].[name] = 'AUTO(3) BIN27' then 110
				when [jobs].[name] = 'AUTO(3) Bin27-CF' then 110
				when [jobs].[name] = 'AUTO(1) SBLSYL' then 106
				when [jobs].[name] = 'AUTO(2) SBLSYL' then 108
				when [jobs].[name] = 'AUTO(3) SBLSYL' then 110
				when [jobs].[name] = 'AUTO(4) SBLSYL' then 119
				when [jobs].[name] = 'AUTO(5) SBLSYL' then 263
				when [jobs].[name] = 'OS+FT-TP' then 106
				when [jobs].[name] = 'FT-TP' then 106
				when [jobs].[name] = 'AUTO(1) BIN27-CF' then 106
			else [jobs].[id] end as [job_id]
			, case 
				when [jobs].[name] = 'OS1' then 'OS'
				when [jobs].[name] = 'OS2' then 'OS'
				when [jobs].[name] = 'FLFTTP' then 'FLFT'
				when [jobs].[name] = 'OS+AUTO(1)' then 'AUTO(1)'
				when [jobs].[name] = 'AUTO(1) RE' then 'AUTO(1)'
				when [jobs].[name] = 'AUTO(1) BIN27' then 'AUTO(1)'
				when [jobs].[name] = 'AUTO(3) BIN27' then 'AUTO(3)'
				when [jobs].[name] = 'AUTO(3) Bin27-CF' then 'AUTO(3)'
				when [jobs].[name] = 'AUTO(1) SBLSYL' then 'AUTO(1)'
				when [jobs].[name] = 'AUTO(2) SBLSYL' then 'AUTO(2)'
				when [jobs].[name] = 'AUTO(3) SBLSYL' then 'AUTO(3)'
				when [jobs].[name] = 'AUTO(4) SBLSYL' then 'AUTO(4)'
				when [jobs].[name] = 'AUTO(5) SBLSYL' then 'AUTO(5)'
				when [jobs].[name] = 'OS+FT-TP' then 'AUTO(1)'
				when [jobs].[name] = 'FT-TP' then 'AUTO(1)'
				when [jobs].[name] = 'AUTO(1) BIN27-CF' then 'AUTO(1)'
			else [jobs].[name] end as [job]
		FROM [APCSProDB].[method].[flow_patterns]
		inner join [APCSProDB].[method].[flow_details]  on [flow_patterns].[id] = [flow_details].[flow_pattern_id]
		inner join [APCSProDB].[method].[jobs] on [flow_details].[job_id] = [jobs].[id]
		inner join [APCSProDB].[method].[processes] on [jobs].[process_id] = [processes].[id]
		where [assy_ft_class] = 'S'
			and [is_released] = 1
			and [flow_patterns].[id] = @flow_pattern_id
	) as [job] on [device_flows].[job_id] = [job].[job_id]
	where [lots].[id] = @lot_id 
	---recipe

	SET @step_no = ISNULL(@step_no,
		(
			SELECT CASE WHEN [lots].[is_special_flow] = 1 THEN [lot_special_flows].[step_no] ELSE [lots].[step_no] END AS [step_no]
			FROM [APCSProDB].[trans].[lots]
			left join [APCSProDB].[trans].[special_flows] on [lots].[id] = [special_flows].[lot_id]
				and [lots].[special_flow_id] = [special_flows].[id] 
			left join [APCSProDB].[trans].[lot_special_flows] on [special_flows].[id]  = [lot_special_flows].[special_flow_id]
				AND [special_flows].[step_no]	= [lot_special_flows].[step_no]
			WHERE [lots].[id] = @lot_id
		)
	)

	--SET @recipe = ISNULL(@recipe,
	--	(
	--		isnull((select f.recipe 
	--				from [APCSProDB].[trans].[lots] as l 
	--				inner join [APCSProDB].[method].[device_flows] as f 
	--					on f.device_slip_id = l.device_slip_id 
	--				inner join [APCSProDB].[method].[jobs] as j 
	--					on j.id = f.job_id
	--				where l.id = @lot_id and f.step_no = @step_no),NULL)
	--	)
	--)


	IF (@is_special_flow = 1)
		BEGIN
			--<< @is_special_flow = 1
			SELECT TOP 1 @q1_step_no = [step_no]
				, @q1_back_step_no = [back_step_no]
				, @q1_back_step_no_master = ISNULL([next_step_no],
					(
						SELECT Min([step_no]) 
						FROM [APCSProDB].[method].[device_flows] 
						WHERE [device_flows].[device_slip_id] = 
							(
								SELECT device_slip_id 
								FROM [APCSProDB].[trans].[lots] 
								WHERE [lots].[id] = @lot_id
							)
						)
					) --as [back_step_no_master]
				--, @q1_is_special_flows = [is_special_flows]
			FROM (
				SELECT t3.step_no
					, t3.back_step_no
					, ISNULL([device_flows].next_step_no,max([device_flows].next_step_no) over (order by t3.back_step_no)) as [next_step_no]
					--, CASE WHEN [device_flows].next_step_no IS NOT NULL THEN 0 ELSE 1 END AS [is_special_flows]
				FROM (
					SELECT [step_no]
						, [back_step_no]
						, [lot_id]
					FROM (
							SELECT lag([step_no]) over (order by [step_no]) as [step_no]
								, [step_no] as [back_step_no]
								, @lot_id as [lot_id]
							FROM (
								SELECT [device_flows].[step_no]
								FROM [APCSProDB].[method].[device_flows]
								INNER JOIN [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
								WHERE [device_flows].[device_slip_id] = (SELECT device_slip_id FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)	
									AND [device_flows].[is_skipped] = 0
								UNION ALL
								SELECT [lot_special_flows].[step_no]
								FROM [APCSProDB].[trans].[special_flows]
								LEFT JOIN [APCSProDB].[trans].[lot_special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
								WHERE [special_flows].[lot_id] = @lot_id
							) as t1
							UNION ALL
							SELECT max([step_no]) as [step_no]
								, max([step_no]) as [back_step_no]
								, @lot_id as [lot_id]
							FROM (
								SELECT [device_flows].[step_no]
								FROM [APCSProDB].[method].[device_flows]
								INNER JOIN [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
								WHERE [device_flows].[device_slip_id] = (SELECT device_slip_id FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)	
									AND [device_flows].[is_skipped] = 0
								UNION ALL
								SELECT [lot_special_flows].[step_no]
								FROM [APCSProDB].[trans].[special_flows]
								LEFT JOIN [APCSProDB].[trans].[lot_special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
								WHERE [special_flows].[lot_id] = @lot_id
							) as t2
					) as [tsum]
					WHERE [tsum].[step_no] is not null
				) as t3
				left join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = (SELECT device_slip_id FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)
					AND [device_flows].step_no = t3.step_no
			) as [table]
			WHERE [table].[back_step_no] = @step_no
			order by [table].[step_no]

			--<< flow master start 100
			IF (@q1_step_no = 0 AND @q1_back_step_no = 0 AND @q1_back_step_no_master = 0)
				BEGIN
					SET @q1_back_step_no_master = 
					(
						SELECT Min([step_no]) 
						FROM [APCSProDB].[method].[device_flows] 
						WHERE [device_flows].[device_slip_id] = 
						(
							SELECT device_slip_id 
							FROM [APCSProDB].[trans].[lots] 
							WHERE [lots].[id] = @lot_id
						)
						and is_skipped = 0
					)

					SET @q1_step_no = 0
				END
			-->> flow master start 100
			-->> @is_special_flow = 1
		END
	ELSE
		BEGIN
			--<< @is_special_flow = 0
			SELECT TOP 1 @q1_step_no = [step_no]
				, @q1_back_step_no = [step_no]
				, @q1_back_step_no_master = ISNULL([next_step_no],
					(
						SELECT Min([step_no]) 
						FROM [APCSProDB].[method].[device_flows] 
						WHERE [device_flows].[device_slip_id] = 
							(
								SELECT device_slip_id 
								FROM [APCSProDB].[trans].[lots] 
								WHERE [lots].[id] = @lot_id
							)
						)
					) --as [back_step_no_master]
				--, @q1_is_special_flows = [is_special_flows]
			FROM (
				SELECT t3.step_no
					, t3.back_step_no
					, ISNULL([device_flows].next_step_no,max([device_flows].next_step_no) over (order by t3.back_step_no)) as [next_step_no]
					--, CASE WHEN [device_flows].next_step_no IS NOT NULL THEN 0 ELSE 1 END AS [is_special_flows]
				FROM (
					SELECT [step_no]
						, [back_step_no]
						, [lot_id]
					FROM (
							SELECT lag([step_no]) over (order by [step_no]) as [step_no]
								, [step_no] as [back_step_no]
								, @lot_id as [lot_id]
							FROM (
								SELECT [device_flows].[step_no]
								FROM [APCSProDB].[method].[device_flows]
								INNER JOIN [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
								WHERE [device_flows].[device_slip_id] = (SELECT device_slip_id FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)	
									AND [device_flows].[is_skipped] = 0
								UNION ALL
								SELECT [lot_special_flows].[step_no]
								FROM [APCSProDB].[trans].[special_flows]
								LEFT JOIN [APCSProDB].[trans].[lot_special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
								WHERE [special_flows].[lot_id] = @lot_id
							) as t1
							UNION ALL
							SELECT max([step_no]) as [step_no]
								, max([step_no]) as [back_step_no]
								, @lot_id as [lot_id]
							FROM (
								SELECT [device_flows].[step_no]
								FROM [APCSProDB].[method].[device_flows]
								INNER JOIN [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
								WHERE [device_flows].[device_slip_id] = (SELECT device_slip_id FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)	
									AND [device_flows].[is_skipped] = 0
								UNION ALL
								SELECT [lot_special_flows].[step_no]
								FROM [APCSProDB].[trans].[special_flows]
								LEFT JOIN [APCSProDB].[trans].[lot_special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
								WHERE [special_flows].[lot_id] = @lot_id
							) as t2
					) as [tsum]
					WHERE [tsum].[step_no] is not null
				) as t3
				left join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = (SELECT device_slip_id FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)
					AND [device_flows].step_no = t3.step_no
			) as [table]
			WHERE [table].[step_no] = @step_no
			order by [table].[step_no]
			-->> @is_special_flow = 0
		END

	--SELECT @q1_step_no,@q1_back_step_no, @q1_back_step_no_master

	
	BEGIN TRANSACTION;
	BEGIN TRY
		IF (NOT EXISTS(
			SELECT [special_flows].[id]
				, [lot_special_flows].[id]
			FROM [APCSProDB].[trans].[special_flows]
			INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
			WHERE [lot_id] = @lot_id 
				AND [lot_special_flows].[step_no] = (IIF(@is_special_flow = 1, @q1_step_no + 1 , @q1_back_step_no + 1 ))
			) AND NOT EXISTS (
			SELECT [step_no]
			FROM [APCSProDB].[method].[device_flows] 
			WHERE [device_flows].[device_slip_id] = 
				(
					SELECT device_slip_id 
					FROM [APCSProDB].[trans].[lots] 
					WHERE [lots].[id] = @lot_id
				)
				AND [step_no] = (IIF(@is_special_flow = 1, @q1_step_no + 1 , @q1_back_step_no + 1 ))
			)
		)
			---<< IF NOT EXISTS 1
			BEGIN
				IF (NOT EXISTS(
					SELECT [special_flows].[id]
						, [lot_special_flows].[id]
					FROM [APCSProDB].[trans].[special_flows]
					INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
					WHERE [lot_id] = @lot_id 
						AND [lot_special_flows].[step_no] = (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no ))
				)  OR @is_special_flow = 1)
					--<< INSERT
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
							, (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no )) + 1
							, @q1_back_step_no_master
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
						FROM [APCSProDB].[trans].[lots] 
						INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'special_flows.id'
						WHERE [lots].[id] = @lot_id

						SET @r = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r
						, @special_flow_id_up = [id] + @r
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
							, @special_flow_id_up
							, (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no )) + row_number() over (order by [flow_details].[flow_pattern_id])
							, (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no )) + row_number() over (order by [flow_details].[flow_pattern_id]) + 1
							, [jobs].[process_id]
							, [jobs].[id]
							, [lots].[act_package_id] AS [act_package_flow_id]
							, 0 AS [permitted_machine_id]
							, 0 AS [process_minutes]
							, 0 AS [sum_process_minutes]
							, IIF(@recipe is null,(select recipe from @table_recipe where job_id = [jobs].[id]),@recipe) AS [recipe]
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
						SET [next_step_no] = (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no )) + @r
						WHERE [special_flow_id] = @special_flow_id_up AND [next_step_no] = (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no )) + @r + 1


						IF (@is_special_flow = 1)
							BEGIN
								UPDATE [APCSProDB].[trans].[lots]
								SET [quality_state] = 4
									, [is_special_flow] = 1
									, [special_flow_id] = @special_flow_id_up
									, [updated_at] = GETDATE()
									, [updated_by] = @user_id
								WHERE [lots].[id] = @lot_id;
							END
						ELSE
							BEGIN
								SET @flow_num = ISNULL((select count(id) from [APCSProDB].[trans].[special_flows] WHERE [lot_id] = @lot_id),0)
								(SELECT 
									@step_no_now = CASE WHEN [lots].[is_special_flow] = 1 THEN [lot_special_flows].[step_no] ELSE [lots].[step_no] END
									, @is_special_flow_now = [lots].[is_special_flow]
									FROM [APCSProDB].[trans].[lots]
									left join [APCSProDB].[trans].[special_flows] on [lots].[id] = [special_flows].[lot_id]
										and [lots].[special_flow_id] = [special_flows].[id] 
									left join [APCSProDB].[trans].[lot_special_flows] on [special_flows].[id]  = [lot_special_flows].[special_flow_id]
										AND [special_flows].[step_no]	= [lot_special_flows].[step_no]
									WHERE [lots].[id] = @lot_id
								)

								IF (@step_no = @step_no_now and @is_special_flow_now = 0)
									BEGIN
										UPDATE [APCSProDB].[trans].[lots]
										SET [is_special_flow] = 0
											, [special_flow_id] = @special_flow_id_up
											, [updated_at] = GETDATE()
											, [updated_by] = @user_id
										WHERE [lots].[id] = @lot_id;
									END
								ELSE
									BEGIN
										IF (@flow_num = 1)
											BEGIN
												UPDATE [APCSProDB].[trans].[lots]
												SET [is_special_flow] = 0
													, [special_flow_id] = @special_flow_id_up
													, [updated_at] = GETDATE()
													, [updated_by] = @user_id
												WHERE [lots].[id] = @lot_id;
											END	
										ELSE
											BEGIN
												DECLARE @special_flow_id_update int = NULL
												select top (1) 
													  @special_flow_id_update = lot_special_flows.special_flow_id
													--, @step_no = lot_special_flows.step_no
												from APCSProDB.trans.lots
												inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
												inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
												where lots.id = @lot_id
													and lot_special_flows.step_no >= lots.step_no
													and special_flows.wip_state = 20
													and (lots.is_special_flow = 0 or lots.is_special_flow is null )
												order by lot_special_flows.step_no asc

												IF (ISNULL(@special_flow_id_update,0) != 0)
													BEGIN
														UPDATE [APCSProDB].[trans].[lots]
														SET [is_special_flow] = 0
															, [special_flow_id] = @special_flow_id_update
															, [updated_at] = GETDATE()
															, [updated_by] = @user_id
														WHERE [lots].[id] = @lot_id;
													END
											END	
									END
							--	ELSE
							--		BEGIN
							--			IF (@is_special_flow_now = 0 and (@special_flow_id_is_null = 0 or @special_flow_id_is_null is null))
							--				BEGIN
							--					UPDATE [APCSProDB].[trans].[lots]
							--					SET [special_flow_id] = @special_flow_id
							--						, [updated_at] = GETDATE()
							--						, [updated_by] = @user_id
							--					WHERE [lots].[id] = @lot_id;
							--				END
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
							, 20 as [wip_state]
							, 0 as [process_state]
							, [quality_state]
							, 0 as [first_ins_state]
							, 0 as [final_ins_state]
							, [is_special_flow]
							, @special_flow_id_up as [special_flow_id]
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
						INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = @special_flow_id_up
						WHERE [lots].[id] = @lot_id

						SET @r = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r
						WHERE [name] = 'lot_process_records.id';

						SELECT 1 as status_id --add flow สำเร็จ
					END
					-->> INSERT
				ELSE
					--<< UPDATE
					BEGIN
					
						SELECT @special_flow_id_up =[special_flows].[id]
							, @step_id_up = [lot_special_flows].[id]
						FROM [APCSProDB].[trans].[special_flows]
						INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [lot_id] = @lot_id 
							AND [lot_special_flows].[step_no] = (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no ))

						UPDATE [APCSProDB].[trans].[special_flows]
						SET [back_step_no] = @q1_back_step_no_master
						WHERE [id] = @special_flow_id_up AND [lot_id] = @lot_id;

						UPDATE [APCSProDB].[trans].[lot_special_flows]
						SET [next_step_no] = (IIF(@is_special_flow = 1, @q1_step_no + 1 , @q1_back_step_no + 1 ))
						WHERE [id] = @step_id_up 
							AND [special_flow_id] = @special_flow_id_up;
	
						INSERT INTO [APCSProDB].[trans].[lot_special_flows]([id]
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
							, @special_flow_id_up
							, (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no )) + row_number() over (order by [flow_details].[flow_pattern_id])
							, (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no )) + row_number() over (order by [flow_details].[flow_pattern_id]) + 1
							, [jobs].[process_id]
							, [jobs].[id]
							, [lots].[act_package_id] AS [act_package_flow_id]
							, 0 AS [permitted_machine_id]
							, 0 AS [process_minutes]
							, 0 AS [sum_process_minutes]
							, IIF(@recipe is null,(select recipe from @table_recipe where job_id = [jobs].[id]),@recipe) AS [recipe]
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
						SET [next_step_no] = (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no )) + @r
						WHERE [special_flow_id] = @special_flow_id_up AND [next_step_no] = (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no )) + @r + 1

						IF (@is_special_flow = 1)
							BEGIN
								UPDATE [APCSProDB].[trans].[lots]
								SET [quality_state] = 4
									, [is_special_flow] = 1
									, [special_flow_id] = @special_flow_id_up
									, [updated_at] = GETDATE()
									, [updated_by] = @user_id
								WHERE [lots].[id] = @lot_id;
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
							, 20 as [wip_state]
							, 0 as [process_state]
							, [quality_state]
							, 0 as [first_ins_state]
							, 0 as [final_ins_state]
							, [is_special_flow]
							, @special_flow_id_up as [special_flow_id]
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
						INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = @special_flow_id_up
							AND [lot_special_flows].[step_no] > (IIF(@is_special_flow = 1, @q1_step_no , @q1_back_step_no ))
						WHERE [lots].[id] = @lot_id

						SET @r = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r
						WHERE [name] = 'lot_process_records.id';

						SELECT 1 as status_id --add flow สำเร็จ
					END
					-->> UPDATE
			END
			--->> IF NOT EXISTS 1
		ELSE
			BEGIN
				SELECT 2 as status_id,@step_no --ไม่สามารถ add flow ได้
			END	
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		set @tran = 1 ;
		SELECT 2 as status_id
		ROLLBACK TRANSACTION;
	END CATCH;


	if (@tran = 1)
	begin
	--<< log exec
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no])
		SELECT GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'ROLLBACK TRANSACTION EXEC [atom].[sp_set_trans_special_flow_v4_new] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') + ''', @step_no = ''' + ISNULL(CAST(@step_no AS varchar),'') + ''', @back_step_no = ''' 
				+ ISNULL(CAST(@back_step_no AS varchar),'') +''', @user_id = ''' + ISNULL(CAST(@user_id AS varchar),'') +''', @flow_pattern_id = '''+ ISNULL(CAST(@flow_pattern_id AS varchar),'') + ''', @is_special_flow = ''' 
				+ ISNULL(CAST(@is_special_flow AS varchar),'') +''', @machine_id = ''' + ISNULL(CAST(@machine_id AS varchar),'') + ''', @recipe = '''
				+ ISNULL(CAST(@recipe AS varchar),'') +''''
			--, 'EXEC [atom].[sp_set_trans_special_flow_v5] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') + ''', @step_no = ''' + ISNULL(CAST(@step_no AS varchar),'') + ''', @back_step_no = ''' 
			--	+ ISNULL(CAST(@back_step_no AS varchar),'') +''', @user_id = ''' + ISNULL(CAST(@user_id AS varchar),'') +''', @flow_pattern_id = '''+ ISNULL(CAST(@flow_pattern_id AS varchar),'') + ''', @is_special_flow = ''' 
			--	+ ISNULL(CAST(@is_special_flow AS varchar),'') + ''', @machine_id = ''' + ISNULL(CAST(@machine_id AS varchar),'') +''''
			, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = @lot_id)
		-->> log exec
	end

END

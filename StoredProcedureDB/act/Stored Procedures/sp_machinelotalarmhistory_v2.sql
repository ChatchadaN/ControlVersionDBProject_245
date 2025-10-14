
CREATE PROCEDURE [act].[sp_machinelotalarmhistory_v2] (
	@lot_no CHAR(20) = NULL
	,@alarm_level INT = 0
	,@alarm_level_alarm INT = 1
	,@alarm_level_warning INT = 1
	,@alarm_level_caution INT = 1
	)
AS
BEGIN
	--DECLARE @lot_no CHAR(20) = '2028A2325V'
	--DECLARE @alarm_level_alarm INT = 1
	--DECLARE @alarm_level_warning INT = 1
	--DECLARE @alarm_level_caution INT = 1
	--DECLARE @alarm_level INT = 0
	DECLARE @device_slip_id INT = (
			SELECT device_slip_id
			FROM APCSProDB.trans.lots WITH (NOLOCK)
			WHERE lot_no = @lot_no
			);
	DECLARE @lot_id INT = (
			SELECT id AS package_id
			FROM APCSProDB.trans.lots WITH (NOLOCK)
			WHERE lot_no = @lot_no
			);
	DECLARE @lot_list NVARCHAR(max) = (
			SELECT STRING_AGG(child_lot_id, ',')
			FROM (
				SELECT cl.id AS child_lot_id
				FROM APCSProDB.trans.lots AS l WITH (NOLOCK)
				LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS m WITH (NOLOCK) ON m.lot_id = l.id
				LEFT OUTER JOIN APCSProDB.trans.lots AS cl WITH (NOLOCK) ON cl.id = m.child_lot_id
				WHERE l.id = @lot_id
				
				UNION ALL
				
				SELECT @lot_id
				) AS t
			);

	SET @alarm_level = @alarm_level_alarm + @alarm_level_warning + @alarm_level_caution;

	--IF OBJECT_ID(N'tempdb..#t_act_flow', N'U') IS NOT NULL
	--	DROP TABLE #t_act_flow;
	--IF OBJECT_ID(N'tempdb..#t_flow', N'U') IS NOT NULL
	--	DROP TABLE #t_flow;
	----temporary table
	SELECT t2.flow_order AS flow_order
		,t2.lot_id AS lot_id
		,t2.process_id AS process_id
		,t2.job_id AS job_id
		,t2.machine_id AS machine_id
		,t2.step_no AS step_no
		,t2.id_from AS id_from
		,t2.id_to AS id_to
		,t2.first_recorded_at AS first_recorded_at
		,t2.lot_start_at AS lot_start_at
		,t2.lot_end_at AS lot_end_at
		,t2.qty_in AS qty_in
		,t2.qty_pass AS qty_pass
		,t2.qty_fail AS qty_fail
		,t2.qty_pass_step_sum AS qty_pass_step_sum
		,t2.qty_fail_step_sum AS qty_fail_step_sum
		,t2.recipe AS recipe
		,t2.delay2 AS delay2
	INTO #t_act_flow
	FROM (
		SELECT t1.id AS id
			,t1.recorded_at AS recorded_at
			,t1.operated_by AS operated_by
			,t1.record_class AS record_class
			,t1.lot_id AS lot_id
			,t1.process_id AS process_id
			,t1.job_id AS job_id
			,t1.machine_id AS machine_id
			,t1.step_no AS step_no
			,t1.flow_order AS flow_order
			,t1.flow_order_rank AS flow_order_rank
			,min(t1.id) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				) AS id_from
			,max(t1.id) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				) AS id_to
			,t1.first_recorded_at AS first_recorded_at
			,isnull(max(t1.started_at) OVER (
					PARTITION BY t1.lot_id
					,t1.flow_order
					), min(t1.recorded_at) OVER (
					PARTITION BY t1.lot_id
					,t1.flow_order
					)) AS lot_start_at
			,isnull(max(t1.finished_at) OVER (
					PARTITION BY t1.lot_id
					,t1.flow_order
					), max(t1.recorded_at) OVER (
					PARTITION BY t1.lot_id
					,t1.flow_order
					)) AS lot_end_at
			,t1.qty_in AS qty_in
			,t1.qty_pass AS qty_pass
			,max(t1.qty_fail) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				) AS qty_fail
			,max(t1.qty_pass_step_sum) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				) AS qty_pass_step_sum
			,max(t1.qty_fail_step_sum) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				) AS qty_fail_step_sum
			,t1.recipe AS recipe
			,t1.delay2 AS delay2
		FROM (
			SELECT t0.id AS id
				,t0.recorded_at AS recorded_at
				,t0.operated_by AS operated_by
				,t0.record_class AS record_class
				,t0.lot_id AS lot_id
				,t0.process_id AS process_id
				,t0.job_id AS job_id
				,t0.machine_id AS machine_id
				,t0.step_no AS step_no
				,t0.flow_order AS flow_order
				,t0.flow_order_rank AS flow_order_rank
				,t0.qty_in AS qty_in
				,t0.qty_pass AS qty_pass
				,t0.qty_fail AS qty_fail
				,t0.qty_pass_step_sum AS qty_pass_step_sum
				,t0.qty_fail_step_sum AS qty_fail_step_sum
				,t0.recipe AS recipe
				,t0.delay2 AS delay2
				,min(t0.recorded_at) OVER (
					PARTITION BY t0.lot_id
					,t0.flow_order ORDER BY t0.recorded_at
					) AS first_recorded_at
				,CASE 
					WHEN t0.record_class = 1
						THEN t0.recorded_at
					ELSE NULL
					END AS started_at
				,CASE 
					WHEN t0.record_class = 2
						THEN t0.recorded_at
					ELSE NULL
					END AS finished_at
			FROM (
				SELECT s1.*
					,ROW_NUMBER() OVER (
						PARTITION BY flow_order ORDER BY record_class
							,id
						) AS flow_order_rank
				FROM (
					SELECT s0.*
						,sum(next_flag) OVER (
							ORDER BY id
							) AS flow_order
					FROM (
						SELECT lpr.id AS id
							,lpr.recorded_at AS recorded_at
							,lpr.operated_by AS operated_by
							,lpr.record_class AS record_class
							,lpr.lot_id AS lot_id
							,lpr.process_job_id AS process_job_id
							,lpr.process_id AS process_id
							,lpr.job_id AS job_id
							,lpr.machine_id AS machine_id
							,lpr.step_no AS step_no
							,lpr.qty_in AS qty_in
							,lpr.qty_pass AS qty_pass
							,lpr.qty_fail AS qty_fail
							,lpr.qty_pass_step_sum AS qty_pass_step_sum
							,lpr.qty_fail_step_sum AS qty_fail_step_sum
							,lpr.recipe AS recipe
							,CASE 
								WHEN datediff(day, lpr.pass_plan_time_up, getdate()) > 0
									THEN datediff(day, lpr.pass_plan_time_up, getdate())
								ELSE 0
								END AS delay2
							,lag(step_no) OVER (
								ORDER BY id
								) AS pre_step_no
							,CASE 
								WHEN lpr.step_no <> lag(step_no) OVER (
										ORDER BY id
										)
									THEN 1
								ELSE 0
								END AS next_flag
						FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
						WHERE lot_id = @lot_id
						) AS s0
					) AS s1
				) AS t0
			) AS t1
		) AS t2
	WHERE t2.flow_order_rank = 1
	ORDER BY id

	DECLARE @current_job INT = (
			SELECT TOP 1 t0.step_no
			FROM (
				SELECT flow_order AS flow_order
					,step_no AS step_no
					,step_no % 100 AS step_no_sp
				FROM #t_act_flow
				) AS t0
			WHERE t0.step_no_sp = 0
			ORDER BY flow_order DESC
			)
	DECLARE @current_job_sp INT = (
			SELECT TOP 1 t0.step_no
			FROM (
				SELECT flow_order AS flow_order
					,step_no AS step_no
				FROM #t_act_flow
				) AS t0
			ORDER BY flow_order DESC
			)

	----
	--実績フローと将来フロー
	----
	SELECT row_number() OVER (
			ORDER BY act.lot_start_at
			) AS act_flow_order
		,act.lot_id AS lot_id
		,act.process_id AS process_id
		,act.job_id AS job_id
		,act.step_no AS step_no
		,act.machine_id AS machine_id
		,act.id_from AS id_from
		,act.id_to AS id_to
		,act.first_recorded_at AS first_recorded_at
		,act.lot_start_at AS lot_start_at
		,act.lot_end_at AS lot_end_at
		,act.qty_in AS qty_in
		,act.qty_pass AS qty_pass
		,act.qty_fail AS qty_fail
		,act.qty_pass_step_sum AS qty_pass_step_sum
		,act.qty_fail_step_sum AS qty_fail_step_sum
		,act.recipe AS recipe
		,act.delay2 AS delay2
		,act.child_flg AS child_flg
		,act.act_flow_flg AS act_flow_flg
		,act.current_job_flg AS current_job_flg
	INTO #t_flow
	FROM (
		----
		--実績フロー
		----
		SELECT t0.lot_id AS lot_id
			,t0.process_id AS process_id
			,t0.job_id AS job_id
			,t0.step_no AS step_no
			,t0.machine_id AS machine_id
			,t0.id_from AS id_from
			,t0.id_to AS id_to
			,t0.first_recorded_at AS first_recorded_at
			,t0.lot_start_at AS lot_start_at
			,t0.lot_end_at AS lot_end_at
			,t0.qty_in AS qty_in
			,t0.qty_pass AS qty_pass
			,t0.qty_fail AS qty_fail
			,t0.qty_pass_step_sum AS qty_pass_step_sum
			,t0.qty_fail_step_sum AS qty_fail_step_sum
			,t0.recipe AS recipe
			,t0.delay2 AS delay2
			,0 AS child_flg
			,1 AS act_flow_flg
			,CASE 
				WHEN t0.step_no = @current_job_sp
					THEN 1
				ELSE 0
				END AS current_job_flg
		--INTO #t_flow
		FROM #t_act_flow AS t0
		
		UNION ALL
		
		----
		--子チップ履歴
		----
		SELECT t2.lot_id AS lot_id
			,t2.process_id AS process_id
			,t2.job_id AS job_id
			,t2.step_no AS step_no
			,t2.machine_id AS machine_id
			,t2.id_from AS id_from
			,t2.id_to AS id_to
			,t2.first_recorded_at AS first_recorded_at
			,t2.lot_start_at AS lot_start_at
			,t2.lot_end_at AS lot_end_at
			,t2.qty_in AS qty_in
			,t2.qty_pass AS qty_pass
			,t2.qty_fail AS qty_fail
			,t2.qty_pass_step_sum AS qty_pass_step_sum
			,t2.qty_fail_step_sum AS qty_fail_step_sum
			,t2.recipe AS recipe
			,t2.delay2 AS delay2
			,1 AS child_flag
			,1 AS act_flow_flg
			,0 AS current_job_flg
		FROM (
			SELECT t1.id AS id
				,t1.recorded_at AS recorded_at
				,t1.operated_by AS operated_by
				,t1.record_class AS record_class
				,t1.lot_id AS lot_id
				,t1.process_id AS process_id
				,t1.job_id AS job_id
				,t1.machine_id AS machine_id
				,t1.step_no AS step_no
				,min(t1.id) OVER (PARTITION BY t1.lot_id) AS id_from
				,max(t1.id) OVER (PARTITION BY t1.lot_id) AS id_to
				,min(t1.recorded_at) OVER (
					PARTITION BY t1.lot_id ORDER BY t1.recorded_at
					) AS first_recorded_at
				,isnull(max(t1.started_at) OVER (PARTITION BY t1.lot_id), min(t1.recorded_at) OVER (PARTITION BY t1.lot_id)) AS lot_start_at
				,max(t1.finished_at) OVER (PARTITION BY t1.lot_id) AS lot_end_at
				,t1.qty_in AS qty_in
				,t1.qty_pass AS qty_pass
				,max(t1.qty_fail) OVER (PARTITION BY t1.lot_id) AS qty_fail
				,max(t1.qty_pass_step_sum) OVER (PARTITION BY t1.lot_id) AS qty_pass_step_sum
				,max(t1.qty_fail_step_sum) OVER (PARTITION BY t1.lot_id) AS qty_fail_step_sum
				,t1.recipe AS recipe
				,t1.delay2 AS delay2
				,t1.flow_order_rank AS flow_order_rank
			FROM (
				SELECT c_lp.id AS id
					,c_lp.recorded_at AS recorded_at
					,c_lp.operated_by AS operated_by
					,c_lp.record_class AS record_class
					,c_lp.lot_id AS lot_id
					,c_lp.process_id AS process_id
					,c_lp.job_id AS job_id
					,c_lp.machine_id AS machine_id
					,c_lp.step_no AS step_no
					,c_lp.qty_in AS qty_in
					,c_lp.qty_pass AS qty_pass
					,c_lp.qty_fail AS qty_fail
					,c_lp.qty_pass_step_sum AS qty_pass_step_sum
					,c_lp.qty_fail_step_sum AS qty_fail_step_sum
					,c_lp.recipe AS recipe
					,CASE 
						WHEN datediff(day, c_lp.pass_plan_time_up, getdate()) > 0
							THEN datediff(day, c_lp.pass_plan_time_up, getdate())
						ELSE 0
						END AS delay2
					,CASE 
						WHEN c_lp.record_class = 1
							THEN c_lp.recorded_at
						ELSE NULL
						END AS started_at
					,CASE 
						WHEN c_lp.record_class = 2
							THEN c_lp.recorded_at
						ELSE NULL
						END AS finished_at
					,ROW_NUMBER() OVER (
						PARTITION BY c_lp.lot_id
						,c_lp.step_no ORDER BY id
						) AS flow_order_rank
				FROM APCSProDB.trans.lot_process_records AS c_lp WITH (NOLOCK)
				INNER JOIN (
					SELECT step_no AS parent_step_no
						,*
					FROM (
						SELECT df.step_no AS step_no
							,df.next_step_no AS next_step_no
							,df.act_process_id AS act_process_id
							,RANK() OVER (
								PARTITION BY df.act_process_id ORDER BY df.step_no
								) AS num
						FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
						WHERE df.device_slip_id = @device_slip_id
							AND df.is_skipped = 0
							AND act_process_id IN (
								SELECT cl.act_process_id AS child_process_id
								FROM [APCSProDB].[trans].[lots] AS l WITH (NOLOCK)
								LEFT OUTER JOIN [APCSProDB].[trans].[lot_multi_chips] AS m WITH (NOLOCK) ON m.lot_id = l.id
								LEFT OUTER JOIN [APCSProDB].[trans].[lots] AS cl WITH (NOLOCK) ON cl.id = m.child_lot_id
								WHERE l.id = @lot_id
								)
						) AS x
					WHERE x.num = 1
					) AS p_step ON p_step.act_process_id = c_lp.process_id
				WHERE lot_id IN (
						SELECT cl.id AS child_lot_id
						FROM [APCSProDB].[trans].[lots] AS l WITH (NOLOCK)
						LEFT OUTER JOIN [APCSProDB].[trans].[lot_multi_chips] AS m WITH (NOLOCK) ON m.lot_id = l.id
						LEFT OUTER JOIN [APCSProDB].[trans].[lots] AS cl WITH (NOLOCK) ON cl.id = m.child_lot_id
						WHERE l.id = @lot_id
						)
				) AS t1
			) AS t2
		WHERE t2.flow_order_rank = 1
		) AS act

	SELECT
		--convert(NVARCHAR, ROW_NUMBER() OVER (
		--			ORDER BY tt2.act_flow_order
		--				,tt2.step_no
		--				,tt2.child_flg
		--			)) + '_' + convert(NVARCHAR, tt2.lot_id) + '_' + convert(NVARCHAR, tt2.step_no) + '_' + convert(NVARCHAR, isnull(tt2.id_from, 0)) + '_' + convert(NVARCHAR, isnull(tt2.id_to, 0)) AS pid
		ROW_NUMBER() OVER (
			ORDER BY tt2.act_flow_order
				,tt2.step_no
				,tt2.child_flg
			) AS pid
		,isnull(tt2.id_from, 0) AS id_from
		,isnull(tt2.id_to, 0) AS id_to
		,tt2.act_flow_order AS process_order
		,tt2.lot_id AS lot_id
		,tt2.lot_no AS lot_no
		,tt2.child_flg AS child_lot_flag
		,ROW_NUMBER() OVER (
			PARTITION BY tt2.act_flow_order
			,tt2.child_flg ORDER BY tt2.lot_start_at
			) AS rank_child_lot_flag
		,tt2.process_id AS process_id
		,ROW_NUMBER() OVER (
			PARTITION BY tt2.act_flow_order ORDER BY tt2.lot_start_at
			) AS rank_xy
		,tt2.process_name AS process_name
		,tt2.step_no AS step_no
		,tt2.sp_flg AS sp_flg
		,tt2.job_id AS job_id
		,tt2.job_name AS job_name
		,tt2.machine_id AS machine_id
		,tt2.machine_name AS machine_name
		,tt2.machine_model_name AS machine_model_name
		,tt2.first_recorded_at AS first_recorded_at
		,tt2.lot_start_at AS start_at
		,tt2.lot_end_at AS end_at
		,tt2.x_point AS x_point
		,tt2.x_diff AS x_diff
		,tt2.qty_in AS qty_input
		,tt2.qty_pass AS qty_pass
		,tt2.qty_fail AS qty_fail
		,convert(DECIMAL(9, 1), tt2.qty_pass_step_sum) / nullif(tt2.qty_pass_step_sum + tt2.qty_fail_step_sum, 0) * 100 AS yield_process
		,tt2.yield_sum AS yield_sum
		,tt2.qty_pass_step_sum AS qty_pass_step_sum
		,tt2.qty_fail_step_sum AS qty_fail_step_sum
		,tt2.machine_alarm_record_id AS machine_alarm_record_id
		,tt2.alarm_id AS alarm_id
		,tt2.alarm_code AS alarm_code
		,tt2.alarm_text_id AS alarm_text_id
		,tt2.alarm_text AS alarm_text
		,sum(CASE 
				WHEN tt2.alarm_id > 0
					THEN 1
				ELSE 0
				END) OVER (PARTITION BY tt2.act_flow_order) AS sum_alarm_counts
		,tt2.alarm_level AS alarm_level
		,tt2.alarm_on_at AS alarm_on_at
		,tt2.alarm_off_at AS alarm_off_at
		,tt2.started_at AS alarm_restarted_at
		,tt2.updated_at AS alarm_updated_at
		,tt2.alarm_x_point AS alarm_x_point
		,tt2.alarm_diff AS alarm_diff
		,AVG(tt2.alarm_x_point) OVER (
			PARTITION BY tt2.act_flow_order
			,tt2.lot_id
			) AS alarm_x_point_avg
	FROM (
		SELECT tt1.*
			--Lot Box Point Data
			,DATEDIFF(SECOND, format(min(tt1.lot_start_at) OVER (
						ORDER BY tt1.lot_start_at
						), 'yyyy-MM-dd 00:00:00'), tt1.lot_start_at) AS x_point
			--,ROW_NUMBER() OVER (
			--	ORDER BY t1.id DESC
			--	) AS y_point
			,isnull(DATEDIFF(SECOND, tt1.lot_start_at, tt1.lot_end_at), 0) AS x_diff
			--Alarm Point Data
			,min(tt1.machine_alarm_record_id) OVER (PARTITION BY tt1.act_flow_order) AS id_from
			,max(tt1.machine_alarm_record_id) OVER (PARTITION BY tt1.act_flow_order) AS id_to
			,DATEDIFF(SECOND, format(min(tt1.lot_start_at) OVER (
						ORDER BY tt1.lot_start_at
						), 'yyyy-MM-dd 00:00:00'), tt1.alarm_on_at) AS alarm_x_point
			,DATEDIFF(SECOND, tt1.alarm_on_at, tt1.alarm_off_at) AS alarm_diff
		FROM (
			SELECT
				--t1.pid AS pid
				t1.act_flow_order AS act_flow_order
				,t1.lot_id AS lot_id
				,t1.lot_no AS lot_no
				,t1.child_flg AS child_flg
				,t1.act_flow_flg AS act_flow_flg
				,CASE 
					WHEN t1.current_job_flg = 1
						THEN CASE 
								WHEN t1.rank_current_job_flg = 1
									THEN t1.current_job_flg
								ELSE 0
								END
					ELSE t1.current_job_flg
					END AS current_job_flg
				,t1.process_id AS process_id
				,t1.process_name AS process_name
				,t1.job_id AS job_id
				,t1.job_name AS job_name
				,t1.machine_id AS machine_id
				,t1.machine_name AS machine_name
				,t1.machine_model_name AS machine_model_name
				,t1.step_no AS step_no
				,t1.sp_flg AS sp_flg
				--,t1.id_from AS id_from
				--,t1.id_to AS id_to
				,t1.first_recorded_at AS first_recorded_at
				,t1.lot_start_at AS lot_start_at
				,t1.lot_end_at AS lot_end_at
				,t1.qty_in AS qty_in
				,
				--投入数量
				t1.qty_pass AS qty_pass
				,
				--工程良品数
				t1.qty_pass_step_sum AS qty_pass_step_sum
				,
				--工程NG数
				t1.qty_fail AS qty_fail
				,
				--累積NG数
				t1.qty_fail_step_sum AS qty_fail_step_sum
				,
				--工程歩留まり[%]
				t1.yield AS yield
				,
				--全体歩留まり[%]
				t1.yield_sum AS yield_sum
				,t1.recipe AS recipe
				,t1.delay2 AS delay2
				-------
				,t2.machine_alarm_record_id
				,t2.alarm_id
				,t2.alarm_code
				,t2.alarm_text_id
				,t2.alarm_text
				,t2.alarm_level
				,t2.alarm_on_at
				,t2.alarm_off_at
				,t2.started_at
				,t2.updated_at
			FROM (
				SELECT t0.act_flow_order AS act_flow_order
					,t0.lot_id AS lot_id
					,dl.lot_no AS lot_no
					,t0.child_flg AS child_flg
					,t0.act_flow_flg AS act_flow_flg
					,t0.current_job_flg AS current_job_flg
					,ROW_NUMBER() OVER (
						PARTITION BY t0.current_job_flg ORDER BY t0.lot_start_at DESC
						) AS rank_current_job_flg
					,t0.process_id AS process_id
					,dp.name AS process_name
					,t0.job_id AS job_id
					,dj.name AS job_name
					,t0.machine_id AS machine_id
					,dm.name AS machine_name
					,mm.name AS machine_model_name
					,t0.step_no AS step_no
					,CASE 
						WHEN t0.step_no >= 100
							THEN CASE 
									WHEN t0.step_no % 100 = 0
										THEN 0
									ELSE 1
									END
						ELSE 0
						END AS sp_flg
					--,t0.id_from AS id_from
					--,t0.id_to AS id_to
					,t0.first_recorded_at AS first_recorded_at
					,t0.lot_start_at AS lot_start_at
					,t0.lot_end_at AS lot_end_at
					,t0.qty_in AS qty_in
					,t0.qty_pass AS qty_pass
					,t0.qty_pass_step_sum AS qty_pass_step_sum
					,t0.qty_fail AS qty_fail
					,t0.qty_fail_step_sum AS qty_fail_step_sum
					,convert(DECIMAL(9, 1), t0.qty_pass_step_sum) / nullif((t0.qty_pass_step_sum + t0.qty_fail_step_sum), 0) * 100 AS yield
					,convert(DECIMAL(9, 1), t0.qty_pass) / nullif((t0.qty_pass + t0.qty_fail), 0) * 100 AS yield_sum
					,t0.recipe AS recipe
					,t0.delay2 AS delay2
				FROM #t_flow AS t0
				LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = t0.process_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = t0.job_id
				INNER JOIN APCSProDWH.dwh.dim_lots AS dl WITH (NOLOCK) ON dl.id = t0.lot_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t0.machine_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_machine_models AS mm WITH (NOLOCK) ON mm.id = dm.machine_model_id
				) AS t1
			LEFT OUTER JOIN (
				SELECT ar.id AS machine_alarm_record_id
					,ar.machine_id AS machine_id
					,ar.model_alarm_id AS alarm_id
					,ma.alarm_code AS alarm_code
					,ma.alarm_text_id AS alarm_text_id
					,txt.alarm_text AS alarm_text
					,ma.alarm_level AS alarm_level
					,ar.alarm_on_at AS alarm_on_at
					,ar.alarm_off_at AS alarm_off_at
					,ar.started_at AS started_at
					,ar.updated_at AS updated_at
					,lr.lot_id AS lot_id
				FROM APCSProDB.trans.machine_alarm_records AS ar WITH (NOLOCK)
				INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = ar.model_alarm_id
				INNER JOIN APCSProDB.mc.alarm_texts AS txt WITH (NOLOCK) ON txt.alarm_text_id = ma.alarm_text_id
				LEFT OUTER JOIN APCSProDB.trans.alarm_lot_records AS lr WITH (NOLOCK) ON lr.id = ar.id
				INNER JOIN (
					SELECT value
					FROM STRING_SPLIT(@lot_list, ',')
					) AS li ON li.value = lr.lot_id
				WHERE (
						(
							@alarm_level > 0
							AND (
								(
									@alarm_level_alarm > 0
									AND ma.alarm_level = 0
									)
								OR (
									@alarm_level_warning > 0
									AND ma.alarm_level = 1
									)
								OR (
									@alarm_level_caution > 0
									AND ma.alarm_level = 2
									)
								OR ma.alarm_level IS NULL
								)
							)
						OR (
							@alarm_level = 0
							AND (
								ma.alarm_level >= 0
								OR ma.alarm_level IS NULL
								)
							)
						)
				) AS t2 ON t2.machine_id = t1.machine_id
				AND t2.lot_id = t1.lot_id
				AND (t1.first_recorded_at <= t2.alarm_on_at)
				AND (t2.alarm_on_at <= t1.lot_end_at)
			) AS tt1
		) AS tt2
	ORDER BY lot_start_at
		,alarm_on_at
END

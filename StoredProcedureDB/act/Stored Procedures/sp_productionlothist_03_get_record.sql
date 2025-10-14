
CREATE PROCEDURE [act].[sp_productionlothist_03_get_record] @lot_no NVARCHAR(32) = NULL
AS
BEGIN
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

	--IF OBJECT_ID(N'tempdb..#t_act_flow', N'U') IS NOT NULL
	--	DROP TABLE #t_act_flow;
	--IF OBJECT_ID(N'tempdb..#t_flow', N'U') IS NOT NULL
	--	DROP TABLE #t_flow;
	----temporary table
	--フローの履歴（special flowも考慮した実際のフロー）
	----
	SELECT t2.lot_id AS lot_id
		,t2.process_id AS process_id
		,t2.job_id AS job_id
		,t2.machine_id AS machine_id
		,t2.step_no AS step_no
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
			,max(t1.started_at) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				) AS lot_start_at
			,max(t1.finished_at) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				) AS lot_end_at
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
						PARTITION BY flow_order ORDER BY id
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
							AND record_class <> 25
							AND record_class <> 26
						) AS s0
					) AS s1
				) AS t0
			) AS t1
		) AS t2
	WHERE t2.flow_order_rank = 1
	ORDER BY id

	DECLARE @current_job INT = (
			SELECT max(t0.step_no)
			FROM (
				SELECT step_no AS step_no
					,step_no % 100 AS step_no_sp
				FROM #t_act_flow
				) AS t0
			WHERE t0.step_no_sp = 0
			)
	DECLARE @current_job_sp INT = (
			SELECT max(t0.step_no)
			FROM (
				SELECT step_no AS step_no
				FROM #t_act_flow
				) AS t0
			)

	----
	--実績フロー
	----
	SELECT t0.lot_id AS lot_id
		,t0.process_id AS process_id
		,t0.job_id AS job_id
		,t0.step_no AS step_no
		,t0.machine_id AS machine_id
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
	INTO #t_flow
	FROM #t_act_flow AS t0
	
	UNION ALL
	
	----
	--未来のフロー
	----
	SELECT @lot_id AS lot_id
		,df.act_process_id AS process_id
		,df.job_id AS job_id
		,df.step_no AS step_no
		,NULL AS machine_id
		,NULL AS lot_start_at
		,NULL AS lot_end_at
		,NULL AS qty_in
		,NULL AS qty_pass
		,NULL AS qty_fail
		,NULL AS qty_pass_step_sum
		,NULL AS qty_fail_step_sum
		,NULL AS recipe
		,NULL AS delay2
		,0 AS child_flag
		,0 AS act_flow_flg
		,2 AS current_job_flg
	FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
	LEFT OUTER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.id = df.job_id
	LEFT OUTER JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = mj.process_id
	WHERE df.device_slip_id = @device_slip_id
		AND df.is_skipped = 0
		AND (
			(
				@current_job IS NOT NULL
				AND df.step_no > @current_job
				)
			OR (
				@current_job IS NULL
				AND df.step_no > 0
				)
			)
	
	UNION ALL
	
	----
	--子チップ履歴
	----
	SELECT t2.lot_id AS lot_id
		,t2.process_id AS process_id
		,t2.job_id AS job_id
		,t2.step_no AS step_no
		,t2.machine_id AS machine_id
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
			,max(t1.started_at) OVER (PARTITION BY t1.lot_id) AS lot_start_at
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
							FROM APCSProDB.trans.lots AS l WITH (NOLOCK)
							LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS m ON m.lot_id = l.id
							LEFT OUTER JOIN APCSProDB.trans.lots AS cl ON cl.id = m.child_lot_id
							WHERE l.id = @lot_id
							)
					) AS x
				WHERE x.num = 1
				) AS p_step ON p_step.act_process_id = c_lp.process_id
			WHERE lot_id IN (
					SELECT cl.id AS child_lot_id
					FROM [APCSProDB].[trans].[lots] AS l WITH (NOLOCK)
					LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS m ON m.lot_id = l.id
					LEFT OUTER JOIN APCSProDB.trans.lots AS cl ON cl.id = m.child_lot_id
					WHERE l.id = @lot_id
					)
			) AS t1
		) AS t2
	WHERE t2.flow_order_rank = 1;

	SELECT convert(NVARCHAR, ROW_NUMBER() OVER (
				ORDER BY t0.step_no
					,t0.job_id
					,t0.child_flg
				)) + '_' + convert(NVARCHAR, t0.lot_id) + '_' + convert(NVARCHAR, t0.step_no) AS pid
		,t0.lot_id AS lot_id
		,dl.lot_no AS lot_no
		,t0.child_flg AS child_flg
		,t0.act_flow_flg AS act_flow_flg
		,t0.current_job_flg AS current_job_flg
		,t0.process_id AS process_id
		,dp.name AS process_name
		,t0.job_id AS job_id
		,dj.name AS job_name
		,t0.machine_id AS machine_id
		,dm.name AS machine_name
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
		,t0.lot_start_at AS lot_start_at
		,t0.lot_end_at AS lot_end_at
		,t0.qty_in AS qty_in
		,
		--投入数量
		t0.qty_pass AS qty_pass
		,
		--工程良品数
		t0.qty_pass_step_sum AS qty_pass_step_sum
		,
		--工程NG数
		t0.qty_fail AS qty_fail
		,
		--累積NG数
		t0.qty_fail_step_sum AS qty_fail_step_sum
		,
		--工程歩留まり[%]
		convert(DECIMAL(9, 1), t0.qty_pass_step_sum) / nullif((t0.qty_pass_step_sum + t0.qty_fail_step_sum), 0) * 100 AS yield
		,
		--全体歩留まり[%]
		convert(DECIMAL(9, 1), t0.qty_pass) / nullif((t0.qty_pass + t0.qty_fail), 0) * 100 AS yield_sum
		,t0.recipe AS recipe
		,t0.delay2 AS delay2
	FROM #t_flow AS t0
	LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = t0.process_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = t0.job_id
	INNER JOIN APCSProDWH.dwh.dim_lots AS dl WITH (NOLOCK) ON dl.id = t0.lot_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t0.machine_id
	ORDER BY t0.step_no
		,t0.job_id
		,t0.child_flg;
END

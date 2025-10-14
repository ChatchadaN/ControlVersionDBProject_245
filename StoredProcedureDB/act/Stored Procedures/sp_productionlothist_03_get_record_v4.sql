
CREATE PROCEDURE [act].[sp_productionlothist_03_get_record_v4] @lot_no NVARCHAR(32) = NULL
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
	SELECT t2.flow_order AS flow_order
		,t2.lot_id AS lot_id
		,t2.process_id AS process_id
		,t2.job_id AS job_id
		,t2.machine_id AS machine_id
		,t2.step_no AS step_no
		,t2.id_from AS id_from
		,t2.id_to AS id_to
		,t2.lot_start_at AS lot_start_at
		,t2.lot_end_at AS lot_end_at
		,t2.qty_in AS qty_in
		,t2.qty_pass AS qty_pass
		,t2.qty_fail AS qty_fail
		,t2.qty_last_pass
		,t2.qty_last_fail
		,t2.qty_pass_step_sum AS qty_pass_step_sum
		,t2.qty_fail_step_sum AS qty_fail_step_sum
		,t2.qty_p_nashi
		,t2.qty_front_ng
		,t2.qty_marker
		,t2.qty_combined
		,t2.qty_hasuu
		,t2.qty_cut_frame
		,t2.qty_frame_in
		,t2.qty_frame_pass
		,t2.qty_frame_fail
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
			,isnull(max(t1.started_at) OVER (
					PARTITION BY t1.lot_id
					,t1.flow_order
					), min(t1.recorded_at) OVER (
					PARTITION BY t1.lot_id
					,t1.flow_order
					)) AS lot_start_at
			,max(t1.finished_at) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				) AS lot_end_at
			,t1.qty_in AS qty_in
			,t1.qty_pass AS qty_pass
			,max(t1.qty_fail) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_fail
			,max(t1.qty_last_pass) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_last_pass
			,max(t1.qty_last_fail) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_last_fail
			,max(CASE 
					WHEN t1.record_class = 2
						THEN t1.qty_pass_step_sum
					ELSE NULL
					END) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				) AS qty_pass_step_sum
			,max(CASE 
					WHEN t1.record_class = 2
						THEN t1.qty_fail_step_sum
					ELSE NULL
					END) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				) AS qty_fail_step_sum
			,max(t1.qty_p_nashi) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_p_nashi
			,max(t1.qty_front_ng) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_front_ng
			,max(t1.qty_marker) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_marker
			,max(t1.qty_combined) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_combined
			,max(t1.qty_hasuu) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_hasuu
			,max(t1.qty_cut_frame) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_cut_frame
			,max(t1.qty_frame_in) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_frame_in
			,max(t1.qty_frame_pass) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_frame_pass
			,max(t1.qty_frame_fail) OVER (
				PARTITION BY t1.lot_id
				,t1.flow_order
				,t1.record_class_flag
				) AS qty_frame_fail
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
				,CASE 
					WHEN t0.record_class < 10
						THEN 1
					ELSE 0
					END AS record_class_flag --2020-09-25 record_class=40,41対応
				,t0.qty_in AS qty_in
				,t0.qty_pass AS qty_pass
				,t0.qty_fail AS qty_fail
				,t0.qty_last_pass
				,t0.qty_last_fail
				,t0.qty_pass_step_sum AS qty_pass_step_sum
				,t0.qty_fail_step_sum AS qty_fail_step_sum
				,t0.qty_p_nashi
				,t0.qty_front_ng
				,t0.qty_marker
				,t0.qty_combined
				,t0.qty_hasuu
				,t0.qty_cut_frame
				,t0.qty_frame_in
				,t0.qty_frame_pass
				,t0.qty_frame_fail
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
							,lpr.qty_last_pass
							,lpr.qty_last_fail
							,lpr.qty_pass_step_sum AS qty_pass_step_sum
							,lpr.qty_fail_step_sum AS qty_fail_step_sum
							,lpr.qty_p_nashi
							,lpr.qty_front_ng
							,lpr.qty_marker
							,lpr.qty_combined
							,lpr.qty_hasuu
							,lpr.qty_cut_frame
							,lpr.qty_frame_in
							,lpr.qty_frame_pass
							,lpr.qty_frame_fail
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
		,act.lot_start_at AS lot_start_at
		,act.lot_end_at AS lot_end_at
		,act.qty_in AS qty_in
		,act.qty_pass AS qty_pass
		,act.qty_fail AS qty_fail
		,act.qty_last_pass
		,act.qty_last_fail
		,act.qty_pass_step_sum AS qty_pass_step_sum
		,act.qty_fail_step_sum AS qty_fail_step_sum
		,act.qty_p_nashi
		,act.qty_front_ng
		,act.qty_marker
		,act.qty_combined
		,act.qty_hasuu
		,act.qty_cut_frame
		,act.qty_frame_in
		,act.qty_frame_pass
		,act.qty_frame_fail
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
			,t0.lot_start_at AS lot_start_at
			,t0.lot_end_at AS lot_end_at
			,t0.qty_in AS qty_in
			,t0.qty_pass AS qty_pass
			,t0.qty_fail AS qty_fail
			,t0.qty_last_pass
			,t0.qty_last_fail
			,t0.qty_pass_step_sum AS qty_pass_step_sum
			,t0.qty_fail_step_sum AS qty_fail_step_sum
			,t0.qty_p_nashi
			,t0.qty_front_ng
			,t0.qty_marker
			,t0.qty_combined
			,t0.qty_hasuu
			,t0.qty_cut_frame
			,t0.qty_frame_in
			,t0.qty_frame_pass
			,t0.qty_frame_fail
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
			,t2.lot_start_at AS lot_start_at
			,t2.lot_end_at AS lot_end_at
			,t2.qty_in AS qty_in
			,t2.qty_pass AS qty_pass
			,t2.qty_fail AS qty_fail
			,t2.qty_last_pass
			,t2.qty_last_fail
			,t2.qty_pass_step_sum AS qty_pass_step_sum
			,t2.qty_fail_step_sum AS qty_fail_step_sum
			,t2.qty_p_nashi
			,t2.qty_front_ng
			,t2.qty_marker
			,t2.qty_combined
			,t2.qty_hasuu
			,t2.qty_cut_frame
			,t2.qty_frame_in
			,t2.qty_frame_pass
			,t2.qty_frame_fail
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
				,isnull(max(t1.started_at) OVER (PARTITION BY t1.lot_id), min(t1.recorded_at) OVER (PARTITION BY t1.lot_id)) AS lot_start_at
				,max(t1.finished_at) OVER (PARTITION BY t1.lot_id) AS lot_end_at
				,t1.qty_in AS qty_in
				,t1.qty_pass AS qty_pass
				,max(t1.qty_fail) OVER (PARTITION BY t1.lot_id) AS qty_fail
				,max(t1.qty_last_pass) OVER (PARTITION BY t1.lot_id) AS qty_last_pass
				,max(t1.qty_last_fail) OVER (PARTITION BY t1.lot_id) AS qty_last_fail
				--,max(t1.qty_pass_step_sum) OVER (PARTITION BY t1.lot_id) AS qty_pass_step_sum
				--,max(t1.qty_fail_step_sum) OVER (PARTITION BY t1.lot_id) AS qty_fail_step_sum
				,max(CASE 
						WHEN t1.record_class = 2
							THEN t1.qty_pass_step_sum
						ELSE NULL
						END) OVER (PARTITION BY t1.lot_id) AS qty_pass_step_sum
				,max(CASE 
						WHEN t1.record_class = 2
							THEN t1.qty_fail_step_sum
						ELSE NULL
						END) OVER (PARTITION BY t1.lot_id) AS qty_fail_step_sum
				,max(t1.qty_p_nashi) OVER (PARTITION BY t1.lot_id) AS qty_p_nashi
				,max(t1.qty_front_ng) OVER (PARTITION BY t1.lot_id) AS qty_front_ng
				,max(t1.qty_marker) OVER (PARTITION BY t1.lot_id) AS qty_marker
				,max(t1.qty_combined) OVER (PARTITION BY t1.lot_id) AS qty_combined
				,max(t1.qty_hasuu) OVER (PARTITION BY t1.lot_id) AS qty_hasuu
				,max(t1.qty_cut_frame) OVER (PARTITION BY t1.lot_id) AS qty_cut_frame
				,max(t1.qty_frame_in) OVER (PARTITION BY t1.lot_id) AS qty_frame_in
				,max(t1.qty_frame_pass) OVER (PARTITION BY t1.lot_id) AS qty_frame_pass
				,max(t1.qty_frame_fail) OVER (PARTITION BY t1.lot_id) AS qty_frame_fail
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
					,c_lp.qty_last_pass
					,c_lp.qty_last_fail
					,c_lp.qty_pass_step_sum AS qty_pass_step_sum
					,c_lp.qty_fail_step_sum AS qty_fail_step_sum
					,c_lp.qty_p_nashi
					,c_lp.qty_front_ng
					,c_lp.qty_marker
					,c_lp.qty_combined
					,c_lp.qty_hasuu
					,c_lp.qty_cut_frame
					,c_lp.qty_frame_in
					,c_lp.qty_frame_pass
					,c_lp.qty_frame_fail
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
								LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS m WITH (NOLOCK) ON m.lot_id = l.id
								LEFT OUTER JOIN APCSProDB.trans.lots AS cl WITH (NOLOCK) ON cl.id = m.child_lot_id
								WHERE l.id = @lot_id
								)
						) AS x
					WHERE x.num = 1
					) AS p_step ON p_step.act_process_id = c_lp.process_id
				WHERE lot_id IN (
						SELECT cl.id AS child_lot_id
						FROM APCSProDB.trans.lots AS l WITH (NOLOCK)
						LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS m WITH (NOLOCK) ON m.lot_id = l.id
						LEFT OUTER JOIN APCSProDB.trans.lots AS cl WITH (NOLOCK) ON cl.id = m.child_lot_id
						WHERE l.id = @lot_id
						)
				) AS t1
			) AS t2
		WHERE t2.flow_order_rank = 1
		) AS act
	
	UNION ALL
	
	----
	--未来のフロー
	----
	SELECT 9999 AS act_flow_order
		,@lot_id AS lot_id
		,df.act_process_id AS process_id
		,df.job_id AS job_id
		--,NULL AS flow_order
		,df.step_no AS step_no
		,NULL AS machine_id
		,NULL AS id_from
		,NULL AS id_to
		,NULL AS lot_start_at
		,NULL AS lot_end_at
		,NULL AS qty_in
		,NULL AS qty_pass
		,NULL AS qty_fail
		,NULL AS qty_last_pass
		,NULL AS qty_last_fail
		,NULL AS qty_pass_step_sum
		,NULL AS qty_fail_step_sum
		,NULL AS qty_p_nashi
		,NULL AS qty_front_ng
		,NULL AS qty_marker
		,NULL AS qty_combined
		,NULL AS qty_hasuu
		,NULL AS qty_cut_frame
		,NULL AS qty_frame_in
		,NULL AS qty_frame_pass
		,NULL AS qty_frame_fail
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

	SELECT t1.pid AS pid
		,t1.act_flow_order AS act_flow_order
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
		,t1.step_no AS step_no
		,t1.sp_flg AS sp_flg
		,t1.id_from AS id_from
		,t1.id_to AS id_to
		,t1.lot_start_at AS lot_start_at
		,t1.lot_end_at AS lot_end_at
		,t1.qty_in AS qty_in
		,t1.qty_pass
		,t1.qty_last_pass
		,t1.qty_last_fail
		,t1.qty_pass_step_sum
		,t1.qty_fail_step_sum
		,t1.qty_fail
		,t1.qty_p_nashi
		,t1.qty_front_ng
		,t1.qty_marker
		,t1.qty_combined
		,t1.qty_hasuu
		,t1.qty_cut_frame
		,t1.qty_frame_in
		,t1.qty_frame_pass
		,t1.yield AS yield
		,t1.yield_sum AS yield_sum
		,t1.recipe AS recipe
		,t1.delay2 AS delay2
	FROM (
		SELECT convert(NVARCHAR, ROW_NUMBER() OVER (
					ORDER BY t0.act_flow_order
						,t0.step_no
						,t0.child_flg
					)) + '_' + convert(NVARCHAR, t0.lot_id) + '_' + convert(NVARCHAR, t0.step_no) + '_' + convert(NVARCHAR, isnull(t0.id_from, 0)) + '_' + convert(NVARCHAR, isnull(t0.id_to, 0)) AS pid
			,t0.act_flow_order AS act_flow_order
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
			,t0.id_from AS id_from
			,t0.id_to AS id_to
			,t0.lot_start_at AS lot_start_at
			,t0.lot_end_at AS lot_end_at
			,t0.qty_in AS qty_in
			----投入数量
			,t0.qty_pass
			----工程良品数(直前)
			,t0.qty_last_pass
			----工程NG数(直前)
			,t0.qty_last_fail
			----工程良品数
			,t0.qty_pass_step_sum
			----工程NG数
			,t0.qty_fail_step_sum
			----累積NG数
			,t0.qty_fail
			----製品無し
			,t0.qty_p_nashi
			----DB/WBでのNG
			,t0.qty_front_ng
			----Mold以降の検査工程で不良と判定されたものに印を打った数
			,t0.qty_marker
			----継ぎ足し数
			,t0.qty_combined
			----端数
			,t0.qty_hasuu
			----FLで金型を壊してしまう可能性のあるものを検査工程で切り取った数
			,t0.qty_cut_frame
			----投入フレーム数量
			,t0.qty_frame_in
			----Passフレーム数量
			,t0.qty_frame_pass
			----Failフレーム数量
			,t0.qty_frame_fail
			----工程歩留まり[%]
			,convert(DECIMAL(9, 1), t0.qty_pass_step_sum) / nullif((t0.qty_pass_step_sum + t0.qty_fail_step_sum), 0) * 100 AS yield
			----全体歩留まり[%]
			,convert(DECIMAL(9, 1), t0.qty_pass) / nullif((t0.qty_pass + t0.qty_fail), 0) * 100 AS yield_sum
			,t0.recipe AS recipe
			,t0.delay2 AS delay2
		FROM #t_flow AS t0
		LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = t0.process_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = t0.job_id
		INNER JOIN APCSProDWH.dwh.dim_lots AS dl WITH (NOLOCK) ON dl.id = t0.lot_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t0.machine_id
		) AS t1
	ORDER BY t1.act_flow_order
		,t1.step_no
END

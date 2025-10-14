
CREATE PROCEDURE [act].[sp_machinelotalarmhistory] (
	@lot_no CHAR(20) = NULL
	,@alarm_level INT = NULL
	,@alarm_level_alarm INT = 1
	,@alarm_level_warning INT = 1
	,@alarm_level_caution INT = 1
	)
AS
BEGIN
	--DECLARE @lot_no CHAR(20) = '1939A1088V'
	--DECLARE @alarm_level_alarm INT = 1
	--DECLARE @alarm_level_warning INT = 1
	--DECLARE @alarm_level_caution INT = 1
	--DECLARE @alarm_level INT = 0
	DECLARE @lot_id INT = (
			SELECT id AS package_id
			FROM APCSProDB.trans.lots
			WHERE lot_no = @lot_no
			);
	DECLARE @lot_list NVARCHAR(max) = (
			SELECT STRING_AGG(child_lot_id, ',')
			FROM (
				SELECT cl.id AS child_lot_id
				FROM APCSProDB.trans.lots AS l
				LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS m ON m.lot_id = l.id
				LEFT OUTER JOIN APCSProDB.trans.lots AS cl ON cl.id = m.child_lot_id
				WHERE l.id = @lot_id
				
				UNION ALL
				
				SELECT @lot_id
				) AS t
			);

	SET @alarm_level = @alarm_level_alarm + @alarm_level_warning + @alarm_level_caution;

	SELECT t3.id AS id
		,dense_rank() OVER (
			ORDER BY t3.id
			) AS process_order
		,t3.lot_id AS lot_id
		,t3.lot_no AS lot_no
		,t3.child_lot_flag AS child_lot_flag
		,CASE 
			WHEN t3.child_lot_flag = 0
				THEN 0
			ELSE dense_rank() OVER (
					PARTITION BY t3.child_lot_flag
					,t3.process_id ORDER BY t3.process_job_id
					)
			END AS rank_child_lot_flag
		,t3.process_id AS process_id
		,t3.process_name AS process_name
		,t3.job_id AS job_id
		,t3.job_name AS job_name
		,row_number() OVER (
			PARTITION BY t3.process_id
			,t3.process_job_id ORDER BY t3.alarm_on_at
			) AS rank_pj_id
		,t3.step_no AS step_no
		,t3.machine_id AS machine_id
		,t3.machine_name AS machine_name
		,t3.machine_model_name AS machine_model_name
		,isnull(t3.process_job_id, 0) AS process_job_id
		,t3.lot_start_at AS start_at
		,t3.end_updated_at AS end_at
		,t3.x_point AS x_point
		,t3.diff AS x_diff
		,t3.record_class AS record_class
		,t3.qty_input AS qty_input
		,t3.qty_pass AS qty_pass
		,t3.qty_fail AS qty_fail
		,convert(DECIMAL(9, 1), t3.qty_pass) / nullif(t3.qty_pass + t3.qty_fail, 0) * 100 AS yield_sum
		,t3.qty_pass_step_sum AS qty_pass_step_sum
		,t3.qty_fail_step_sum AS qty_fail_step_sum
		,convert(DECIMAL(9, 1), t3.qty_pass_step_sum) / nullif(t3.qty_pass_step_sum + t3.qty_fail_step_sum, 0) * 100 AS yield_process
		,t3.record_label AS record_label
		,t3.machine_alarm_record_id AS machine_alarm_record_id
		,t3.alarm_id AS alarm_id
		,t3.alarm_code AS alarm_code
		,t3.alarm_text_id AS alarm_text_id
		,sum(CASE 
				WHEN t3.alarm_id > 0
					THEN 1
				ELSE 0
				END) OVER (
			PARTITION BY t3.process_job_id
			,t3.job_id
			) AS sum_alarm_counts
		,t3.alarm_text AS alarm_text
		,t3.alarm_level AS alarm_level
		,t3.alarm_on_at AS alarm_on_at
		,t3.alarm_off_at AS alarm_off_at
		,t3.started_at AS alarm_restarted_at
		,t3.updated_at AS alarm_updated_at
		,t3.alarm_x_point AS alarm_x_point
		,AVG(t3.alarm_x_point) OVER (
			PARTITION BY t3.process_job_id
			,t3.lot_id
			) AS alarm_x_point_avg
		,t3.alarm_diff AS alarm_diff
		,t3.rank_xy AS rank_xy
	FROM (
		SELECT t2.id AS id
			,t2.lot_id AS lot_id
			,dl.lot_no AS lot_no
			,CASE 
				WHEN t2.lot_id = @lot_id
					THEN 0
				ELSE 1
				END AS child_lot_flag
			,t2.process_id AS process_id
			,dp.name AS process_name
			,t2.job_id AS job_id
			,dj.name AS job_name
			,t2.step_no AS step_no
			,t2.machine_id AS machine_id
			,dm.name AS machine_name
			,mm.name AS machine_model_name
			,t2.process_job_id AS process_job_id
			,t2.lot_start_at AS lot_start_at
			,t2.lot_end_at AS end_updated_at
			,row_number() OVER (
				PARTITION BY t2.x_point
				,t2.y_point ORDER BY rec.machine_alarm_record_id
				) AS rank_xy
			,t2.x_point AS x_point
			,t2.diff AS diff
			,t2.record_class AS record_class
			,t2.qty_pass_step_sum + t2.qty_fail_step_sum AS qty_input
			,t2.qty_pass AS qty_pass
			,t2.qty_fail AS qty_fail
			,t2.qty_pass_step_sum AS qty_pass_step_sum
			,t2.qty_fail_step_sum AS qty_fail_step_sum
			,il.label_eng AS record_label
			,rec.machine_alarm_record_id AS machine_alarm_record_id
			,rec.alarm_id AS alarm_id
			,rec.alarm_code AS alarm_code
			,rec.alarm_text_id AS alarm_text_id
			,rec.alarm_text AS alarm_text
			,rec.alarm_level AS alarm_level
			,rec.alarm_on_at AS alarm_on_at
			,rec.alarm_off_at AS alarm_off_at
			,rec.started_at AS started_at
			,rec.updated_at AS updated_at
			,DATEDIFF(SECOND, format(min(t2.lot_start_at) OVER (
						ORDER BY t2.id
						), 'yyyy-MM-dd 00:00:00'), rec.alarm_on_at) AS alarm_x_point
			,DATEDIFF(SECOND, rec.alarm_on_at, rec.alarm_off_at) AS alarm_diff
		FROM (
			SELECT t1.*
				,DATEDIFF(SECOND, format(min(t1.lot_start_at) OVER (
							ORDER BY t1.id
							), 'yyyy-MM-dd 00:00:00'), t1.lot_start_at) AS x_point
				,ROW_NUMBER() OVER (
					ORDER BY t1.id DESC
					) AS y_point
				,isnull(DATEDIFF(SECOND, t1.lot_start_at, t1.lot_end_at), 0) AS diff
			FROM (
				SELECT rank() OVER (
						PARTITION BY t0.process_job_id
						,t0.lot_id
						,t0.step_no
						,t0.machine_id ORDER BY t0.id DESC
						) AS rec_rank
					,t0.id AS id
					,t0.lot_id AS lot_id
					,t0.process_id AS process_id
					,t0.job_id AS job_id
					,t0.step_no AS step_no
					,t0.machine_id AS machine_id
					,t0.process_job_id AS process_job_id
					,t0.start_updated_at AS start_updated_at
					,t0.end_updated_at AS end_updated_at
					,CASE 
						WHEN s1.started_at IS NULL
							AND s1.finished_at IS NULL
							THEN t0.start_updated_at
						ELSE s1.started_at
						END AS lot_start_at
					,CASE 
						WHEN s1.started_at IS NULL
							AND s1.finished_at IS NULL
							THEN t0.end_updated_at
								--現在進行中のアラームを取得する。
						WHEN s1.started_at IS NOT NULL
							AND s1.finished_at IS NULL
							THEN CASE 
									WHEN s1.rec_rank = 1
										THEN GETDATE()
									ELSE t0.end_updated_at
									END
						ELSE s1.finished_at
						END AS lot_end_at
					,t0.record_class
					,t0.qty_in AS qty_in
					,t0.qty_pass AS qty_pass
					,t0.qty_fail AS qty_fail
					,t0.qty_pass_step_sum AS qty_pass_step_sum
					,t0.qty_fail_step_sum AS qty_fail_step_sum
				FROM (
					SELECT l_rec.id AS id
						,l_rec.lot_id AS lot_id
						,l_rec.process_id AS process_id
						,l_rec.job_id AS job_id
						,l_rec.new_step_no AS step_no
						,l_rec.machine_id AS machine_id
						,l_rec.process_job_id AS process_job_id
						,min(l_rec.updated_at) OVER (
							PARTITION BY l_rec.process_job_id
							,l_rec.new_step_no
							,l_rec.machine_id
							,l_rec.lot_id
							) AS start_updated_at
						,max(l_rec.updated_at) OVER (
							PARTITION BY l_rec.process_job_id
							,l_rec.new_step_no
							,l_rec.machine_id
							,l_rec.lot_id
							) AS end_updated_at
						,l_rec.record_class
						,l_rec.qty_in AS qty_in
						,l_rec.qty_pass AS qty_pass
						,l_rec.qty_fail AS qty_fail
						,l_rec.qty_pass_step_sum AS qty_pass_step_sum
						,l_rec.qty_fail_step_sum AS qty_fail_step_sum
					FROM (
						SELECT lp.id AS id
							,lp.lot_id AS lot_id
							,lp.process_id AS process_id
							,lp.job_id AS job_id
							,CASE 
								WHEN lp.step_no >= 100
									THEN round(lp.step_no, - 1)
								ELSE lp.step_no
								END AS new_step_no
							,lp.machine_id AS machine_id
							,lp.process_job_id AS process_job_id
							,lp.updated_at AS updated_at
							,lp.record_class
							,lp.qty_in AS qty_in
							,lp.qty_pass AS qty_pass
							,lp.qty_fail AS qty_fail
							,lp.qty_pass_step_sum AS qty_pass_step_sum
							,lp.qty_fail_step_sum AS qty_fail_step_sum
						FROM APCSProDB.trans.lot_process_records AS lp WITH (NOLOCK)
						) AS l_rec
					WHERE lot_id = @lot_id
						OR lot_id IN (
							SELECT cl.id AS child_lot_id
							FROM APCSProDB.trans.lots AS l WITH (NOLOCK)
							LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS m WITH (NOLOCK) ON m.lot_id = l.id
							LEFT OUTER JOIN APCSProDB.trans.lots AS cl WITH (NOLOCK) ON cl.id = m.child_lot_id
							WHERE l.id = @lot_id
							)
					) AS t0
				LEFT OUTER JOIN (
					SELECT ROW_NUMBER() OVER (
							ORDER BY pj.started_at DESC
							) AS rec_rank
						,pl.pj_id AS process_job_id
						,pj.machine_id AS machine_id
						,pj.started_at AS started_at
						,pj.finished_at AS finished_at
						,pl.lot_id AS lot_id
					FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
					INNER JOIN APCSProDWH.dwh.view_fact_pj_lots AS pl WITH (NOLOCK) ON pl.pj_id = pj.id
					WHERE pl.lot_id = @lot_id
					) AS s1 ON s1.process_job_id = t0.process_job_id
					AND s1.machine_id = t0.machine_id
				) AS t1
			WHERE rec_rank = 1
			) AS t2
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
			) AS rec ON rec.machine_id = t2.machine_id
			AND rec.lot_id = t2.lot_id
			AND (t2.lot_start_at <= rec.alarm_on_at)
			AND (rec.alarm_on_at <= t2.lot_end_at)
		LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = t2.process_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = t2.job_id
		LEFT OUTER JOIN APCSProDB.trans.item_labels AS il WITH (NOLOCK) ON il.val = t2.record_class
			AND il.name = 'lot_process_records.record_class'
		LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t2.machine_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_machine_models AS mm WITH (NOLOCK) ON mm.id = dm.machine_model_id
		INNER JOIN APCSProDWH.dwh.dim_lots AS dl WITH (NOLOCK) ON dl.id = t2.lot_id
		) AS t3
	--where rank_xy = 1
	ORDER BY step_no
		,start_at
END

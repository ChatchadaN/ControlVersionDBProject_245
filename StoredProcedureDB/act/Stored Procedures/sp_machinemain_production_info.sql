
CREATE PROCEDURE [act].[sp_machinemain_production_info] (
	@date_from DATETIME,
	@date_to DATETIME,
	@machine_id INT,
	@time_offset INT = 0
	)
AS
BEGIN
	--DECLARE @machine_id INT = 18
	--DECLARE @date_from DATETIME = '2019-11-01 00:00:00'
	--DECLARE @date_to DATETIME = '2019-11-30 23:59:00'
	SELECT v3.pid,
		v3.lot_rank AS lot_rank,
		v3.cancel_flag AS cancel_flag,
		v3.process_job_id AS process_job_id,
		v3.machine_id AS machine_id,
		v3.lot_id AS lot_id,
		v3.lot_no AS lot_no,
		v3.started_at AS started_at,
		v3.finished_at AS finished_at,
		mus.english_name AS started_by_name,
		muf.english_name AS finished_by_name,
		v3.qty_in AS qty_in,
		v3.qty_pass AS qty_pass,
		v3.qty_fail AS qty_fail,
		v3.process_time AS process_time,
		v3.uph_act AS uph_act,
		v3.yield AS yield,
		v3.state_rank AS state_rank,
		v3.state_started_at AS state_started_at,
		v3.state_ended_at AS state_ended_at,
		v3.run_state AS code,
		il.label_eng AS code_name,
		v3.sum_diff_h AS sum_diff_h,
		v3.sum_diff_h * 100 / v3.process_time AS percent_sum_diff_h,
		v3.other_sum_diff_h AS other_diff_h,
		v3.other_sum_diff_h * 100 / v3.process_time AS percent_other_diff_h
	FROM (
		SELECT row_number() OVER (
				ORDER BY v2.started_at,
					v2.state_started_at
				) AS pid,
			v2.*,
			sum(v2.diff_h) OVER (
				PARTITION BY v2.lot_id,
				v2.process_job_id,
				v2.run_state
				) AS sum_diff_h,
			v2.process_time - sum(v2.diff_h) OVER (
				PARTITION BY v2.lot_id,
				v2.process_job_id
				) AS other_sum_diff_h
		FROM (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY v1.lot_id,
					v1.process_job_id ORDER BY v1.started_at,
						v1.state_started_at
					) AS lot_rank,
				v1.cancel_flag AS cancel_flag,
				v1.process_job_id AS process_job_id,
				v1.machine_id AS machine_id,
				v1.lot_id AS lot_id,
				v1.lot_no AS lot_no,
				v1.started_at AS started_at,
				v1.finished_at AS finished_at,
				v1.started_by AS started_by,
				v1.finished_by AS finished_by,
				v1.qty_in AS qty_in,
				v1.qty_pass AS qty_pass,
				v1.qty_fail AS qty_fail,
				v1.process_time AS process_time,
				v1.uph_act AS uph_act,
				v1.yield AS yield,
				--
				ROW_NUMBER() OVER (
					PARTITION BY v1.lot_id,
					v1.process_job_id,
					v1.run_state ORDER BY v1.started_at,
						v1.state_started_at
					) AS state_rank,
				v1.state_started_at AS state_started_at,
				v1.state_ended_at AS state_ended_at,
				--diff_h:1sec以下は0.0
				convert(DECIMAL(9, 1), DATEDIFF(second, v1.state_started_at, v1.state_ended_at)) / 60 / 60 AS diff_h,
				v1.run_state AS run_state
			FROM (
				SELECT u3.process_job_id AS process_job_id,
					u3.machine_id AS machine_id,
					u3.lot_id AS lot_id,
					u3.lot_no AS lot_no,
					u3.started_at AS started_at,
					u3.finished_at AS finished_at,
					u3.started_by AS started_by,
					u3.finished_by AS finished_by,
					u3.qty_in AS qty_in,
					u3.qty_pass AS qty_pass,
					u3.qty_fail AS qty_fail,
					u3.process_time AS process_time,
					u3.qty_pass / nullif(process_time, 0) AS uph_act,
					convert(DECIMAL(9, 1), u3.qty_pass) / nullif((u3.qty_in), 0) * 100 AS yield,
					u3.cancel_flag AS cancel_flag,
					CASE 
						WHEN u3.started_at > t3.started_at
							THEN u3.started_at
						ELSE t3.started_at
						END AS state_started_at,
					CASE 
						WHEN u3.finished_at < t3.ended_at
							THEN u3.finished_at
						ELSE t3.ended_at
						END AS state_ended_at,
					t3.run_state AS run_state
				FROM (
					SELECT u2.*,
						convert(DECIMAL(9, 1), DATEDIFF(SECOND, u2.started_at, u2.finished_at)) / 60 / 60 AS process_time
					FROM (
						SELECT u1.process_job_id AS process_job_id,
							u1.record_class AS record_class,
							u1.lotend_flag AS lotend_flag,
							u1.machine_id AS machine_id,
							u1.lot_id AS lot_id,
							u1.lot_no AS lot_no,
							u1.started_at AS started_at,
							u1.finished_at AS finished_at,
							u1.operated_by AS started_by,
							u1.operated_by AS finished_by,
							CASE 
								WHEN u1.lotend_flag = 1
									THEN u1.qty_pass_step_sum + u1.qty_fail_step_sum
								ELSE u1.qty_pass
								END AS qty_in,
							u1.qty_pass_step_sum AS qty_pass,
							u1.qty_fail_step_sum AS qty_fail,
							cancel_flag AS cancel_flag
						FROM (
							SELECT lpr.process_job_id AS process_job_id,
								lpr.operated_by AS operated_by,
								lpr.started_at AS started_at,
								lpr.finished_at AS finished_at,
								CASE 
									WHEN lpr.record_class = 6
										THEN 1
									ELSE 0
									END AS cancel_flag,
								lpr.lotend_flag AS lotend_flag,
								lpr.machine_id AS machine_id,
								lpr.lot_id AS lot_id,
								tl.lot_no AS lot_no,
								lpr.record_class AS record_class,
								lpr.qty_in AS qty_in,
								lpr.qty_pass AS qty_pass,
								lpr.qty_fail AS qty_fail,
								lpr.qty_pass_step_sum AS qty_pass_step_sum,
								lpr.qty_fail_step_sum AS qty_fail_step_sum
							FROM (
								SELECT t3.finished_record_class_rank AS finished_record_class_rank,
									t3.record_class AS record_class,
									t3.lotend_flag AS lotend_flag,
									t3.process_job_id AS process_job_id,
									t3.machine_id AS machine_id,
									t3.started_at AS started_at,
									t3.finished_at AS finished_at,
									t3.operated_by AS operated_by,
									t3.lot_id AS lot_id,
									t3.qty_in AS qty_in,
									t3.qty_pass AS qty_pass,
									t3.qty_fail AS qty_fail,
									t3.qty_pass_step_sum AS qty_pass_step_sum,
									t3.qty_fail_step_sum AS qty_fail_step_sum
								FROM (
									SELECT ROW_NUMBER() OVER (
											PARTITION BY t2.process_job_id,
											t2.lot_id ORDER BY t2.lotend_flag DESC,
												t2.recorded_at DESC
											) AS finished_record_class_rank,
										t2.record_class AS record_class,
										t2.lotend_flag AS lotend_flag,
										t2.process_job_id AS process_job_id,
										t2.machine_id AS machine_id,
										t2.started_at AS started_at,
										CASE 
											WHEN t2.finished_at IS NULL
												THEN CASE 
														WHEN @date_to < GETDATE()
															THEN @date_to
														ELSE GETDATE()
														END
											ELSE t2.finished_at
											END AS finished_at,
										t2.operated_by AS operated_by,
										t2.lot_id AS lot_id,
										t2.qty_in AS qty_in,
										t2.qty_pass AS qty_pass,
										t2.qty_fail AS qty_fail,
										t2.qty_pass_step_sum AS qty_pass_step_sum,
										t2.qty_fail_step_sum AS qty_fail_step_sum
									FROM (
										SELECT t1.*,
											rec.recorded_at AS recorded_at,
											rec.operated_by AS operated_by,
											rec.record_class AS record_class,
											CASE 
												WHEN rec.record_class = 2
													THEN 1
												ELSE 0
												END AS lotend_flag,
											rec.qty_in AS qty_in,
											rec.qty_pass AS qty_pass,
											rec.qty_fail AS qty_fail,
											rec.qty_pass_step_sum AS qty_pass_step_sum,
											rec.qty_fail_step_sum AS qty_fail_step_sum
										FROM (
											SELECT pl.pj_id AS process_job_id,
												pj.machine_id AS machine_id,
												pj.started_at AS started_at,
												pj.finished_at AS finished_at,
												pl.lot_id AS lot_id
											FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
											INNER JOIN APCSProDWH.dwh.view_fact_pj_lots AS pl WITH (NOLOCK) ON pl.pj_id = pj.id
											WHERE pj.machine_id = @machine_id
												AND (
													(
														NOT (pj.finished_at < @date_from)
														AND NOT (@date_to < pj.started_at)
														)
													OR (
														pj.started_at BETWEEN @date_from
															AND @date_to
														AND pj.finished_at IS NULL
														)
													)
											) AS t1
										LEFT OUTER JOIN apcsprodb.trans.lot_process_records AS rec WITH (NOLOCK) ON rec.lot_id = t1.lot_id
											AND rec.process_job_id = t1.process_job_id
										) AS t2
									) AS t3
								WHERE t3.finished_record_class_rank = 1
								) AS lpr
							INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = lpr.lot_id
							) AS u1
						) AS u2
					) AS u3
				LEFT OUTER JOIN (
					SELECT t2.*
					FROM (
						SELECT t1.id AS id,
							t1.day_id AS day_id,
							t1.started_at AS started_at,
							CASE 
								WHEN t1.ended_at IS NULL
									THEN GETDATE()
								ELSE t1.ended_at
								END AS ended_at,
							t1.machine_id AS machine_id,
							t1.online_state AS online_state,
							t1.run_state AS run_state,
							t1.qc_state AS qc_state,
							t1.check_state AS chekc_state
						FROM (
							SELECT ms.id AS id,
								ms.day_id AS day_id,
								ms.updated_at AS started_at,
								ms.machine_id AS machine_id,
								ms.online_state AS online_state,
								ms.run_state AS run_state,
								ms.qc_state AS qc_state,
								ms.check_state AS check_state,
								lag(ms.updated_at) OVER (
									PARTITION BY ms.machine_id ORDER BY ms.updated_at DESC
									) AS ended_at
							FROM APCSProDB.trans.machine_state_records AS ms WITH (NOLOCK)
							WHERE machine_id = @machine_id
							) AS t1
						) AS t2
					) AS t3 ON NOT (t3.ended_at < u3.started_at)
					AND NOT (u3.finished_at < t3.started_at)
				) AS v1
			) AS v2
		) AS v3
	INNER JOIN APCSProDB.trans.item_labels AS il WITH (NOLOCK) ON il.name = 'machine_states.run_state'
		AND il.val = v3.run_state
	LEFT OUTER JOIN APCSProDB.man.users AS mus WITH (NOLOCK) ON mus.id = v3.started_by
	LEFT OUTER JOIN APCSProDB.man.users AS muf WITH (NOLOCK) ON muf.id = v3.finished_by
	WHERE v3.state_rank = 1
	--AND lot_rank = 1
	ORDER BY v3.started_at,
		v3.state_started_at
END

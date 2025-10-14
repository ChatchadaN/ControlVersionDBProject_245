
CREATE PROCEDURE [act].[sp_productionlothist_04_get_leadtime_v2] @lot_no NVARCHAR(32) = NULL
AS
BEGIN
	DECLARE @lot_id INT = (
			SELECT id
			FROM APCSProDB.trans.lots WITH (NOLOCK)
			WHERE lot_no = @lot_no
			);
	DECLARE @normal_leadtime_minutes INT = (
			SELECT normal_leadtime_minutes
			FROM APCSProDB.method.device_slips WITH (NOLOCK)
			WHERE device_slip_id = (
					SELECT device_slip_id
					FROM APCSProDB.trans.lots WITH (NOLOCK)
					WHERE lot_no = @lot_no
					)
			);

	--IF OBJECT_ID(N'tempdb..#t_act_flow', N'U') IS NOT NULL
	--	DROP TABLE #t_act_flow;
	SELECT *
	INTO #t_act_flow
	FROM (
		SELECT t2.lot_id AS lot_id
			,t2.process_id AS process_id
			,t2.job_id AS job_id
			,t2.machine_id AS machine_id
			,t2.step_no AS step_no
			,t2.lot_start_at AS lot_start_at
			,t2.lot_end_at AS lot_end_at
			,t2.step_no_inc_sp AS step_no_inc_sp
			,row_number() OVER (
				PARTITION BY t2.step_no_inc_sp
				,t2.process_id
				,t2.job_id ORDER BY t2.lot_start_at DESC
				) AS rank_step_no
			,t2.wait_time AS wait_time
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
				,CASE 
					WHEN t1.step_no >= 100
						THEN (t1.step_no / 100) * 100
					ELSE t1.step_no
					END AS step_no_inc_sp
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
				,t1.wait_time AS wait_time
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
						WHEN t0.record_class = 1
							THEN t0.recorded_at
						ELSE NULL
						END AS started_at
					,CASE 
						WHEN t0.record_class = 2
							THEN t0.recorded_at
						ELSE NULL
						END AS finished_at
					,max(t0.wait_time) OVER (PARTITION BY t0.flow_order) AS wait_time
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
								,lpr.wait_time AS wait_time
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
		) AS t3
	WHERE t3.rank_step_no = 1

	SELECT *
		,sum(t3.lead_time_logic) OVER (
			ORDER BY t3.step_no rows UNBOUNDED PRECEDING
			) AS sum_lead_time_logic
		,CASE 
			WHEN t3.wait_time_from_record IS NULL
				THEN NULL
			WHEN t3.process_time_actual IS NULL
				THEN NULL
			ELSE sum(t3.wait_time_from_record + t3.process_time_actual) OVER (
					ORDER BY t3.step_no rows UNBOUNDED PRECEDING
					)
			END AS sum_lead_time_actual
	FROM (
		SELECT *
			,isnull(max(t2.pass_plan_time) OVER (
					ORDER BY t2.step_no rows BETWEEN unbounded preceding
							AND 1 preceding
					), t2.in_date) AS pre_step_plan_time
			,datediff(minute, isnull(max(t2.pass_plan_time) OVER (
						ORDER BY t2.step_no rows BETWEEN unbounded preceding
								AND 1 preceding
						), t2.in_date), t2.pass_plan_time) AS lead_time_logic
			,isnull(max(t2.finished_at) OVER (
					ORDER BY t2.step_no rows BETWEEN unbounded preceding
							AND 1 preceding
					), t2.in_date) AS pre_finished_time
			,datediff(minute, isnull(max(t2.finished_at) OVER (
						ORDER BY t2.step_no rows BETWEEN unbounded preceding
								AND 1 preceding
						), t2.in_date), t2.started_at) AS wait_time_from_record
			,datediff(minute, t2.started_at, t2.finished_at) AS process_time_actual
		FROM (
			SELECT *
				,dateadd(minute, t1.lead_time_rate * t1.sum_process_minutes, convert(DATETIME, t1.in_date)) AS pass_plan_time
			FROM (
				SELECT f.step_no
					,f.next_step_no
					,f.act_process_id
					,f.job_id
					,mj.name AS job_name
					,f.process_minutes
					--2020.04.14
					--,f.sum_process_minutes as sum_process_minutes
					,sum(f.process_minutes) OVER (
						ORDER BY f.step_no
						) AS sum_process_minutes
					,f.is_skipped
					------new
					,lpr.lot_start_at AS started_at
					,lpr.lot_end_at AS finished_at
					--,lpr.wait_time as wait_time
					,lpr.wait_time AS wait_time
					----
					--,r_start.id AS started_record_id
					--,CASE 
					--	WHEN r_start.id IS NULL
					--		THEN 1
					--	ELSE 0
					--	END AS flag
					--,r_start.recorded_at AS started_at
					--,r_start.wait_time
					--,r.id AS record_id
					--,isnull(r.recorded_at, r_start.recorded_at) AS finished_at
					--,rank() OVER (
					--	PARTITION BY f.job_id
					--	,r.record_class_rank
					--	,r_start.record_class_rank ORDER BY r.recorded_at DESC
					--	) AS last_record_in_process
					,d1.date_value AS in_date
					,d2.date_value AS out_date
					,(l.out_plan_date_id - l.in_plan_date_id) * 24 * 60 AS lead_time_min
					,isnull(convert(DECIMAL, (l.out_plan_date_id - l.in_plan_date_id) * 24 * 60) / nullif(@normal_leadtime_minutes, 0), 0) AS lead_time_rate
				FROM APCSProDB.trans.lots AS l WITH (NOLOCK)
				INNER JOIN (
					SELECT df.*
					FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
					WHERE isnull(df.is_skipped, 0) = 0
					) AS f ON f.device_slip_id = l.device_slip_id
					AND l.id = @lot_id
				LEFT OUTER JOIN #t_act_flow AS lpr ON lpr.step_no_inc_sp = f.step_no
					AND lpr.process_id = f.act_process_id
					AND lpr.job_id = f.job_id
				INNER JOIN APCSProDB.trans.days AS d1 WITH (NOLOCK) ON d1.id = l.in_plan_date_id
				INNER JOIN APCSProDB.trans.days AS d2 WITH (NOLOCK) ON d2.id = l.out_plan_date_id
				LEFT OUTER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.id = f.job_id
				) AS t1
			) AS t2
		) AS t3
	ORDER BY step_no
		,started_at
END

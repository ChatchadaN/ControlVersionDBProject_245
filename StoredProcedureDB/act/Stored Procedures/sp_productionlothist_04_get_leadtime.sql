
CREATE PROCEDURE [act].[sp_productionlothist_04_get_leadtime] @lot_no NVARCHAR(32) = NULL
AS
BEGIN
	DECLARE @lot_id INT = (
			SELECT id
			FROM APCSProDB.trans.lots
			WHERE lot_no = @lot_no
			);
	DECLARE @normal_leadtime_minutes INT = (
			SELECT normal_leadtime_minutes
			FROM APCSProDB.method.device_slips
			WHERE device_slip_id = (
					SELECT device_slip_id
					FROM APCSProDB.trans.lots
					WHERE lot_no = @lot_no
					)
			);

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
					ORDER BY t2.started_record_id
						,t2.step_no rows BETWEEN unbounded preceding
							AND 1 preceding
					), t2.in_date) AS pre_finished_time
			,datediff(minute, isnull(max(t2.finished_at) OVER (
						ORDER BY t2.started_record_id
							,t2.step_no rows BETWEEN unbounded preceding
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
					,r_start.id AS started_record_id
					,CASE 
						WHEN r_start.id IS NULL
							THEN 1
						ELSE 0
						END AS flag
					,r_start.recorded_at AS started_at
					,r_start.wait_time
					,r.id AS record_id
					,isnull(r.recorded_at, r_start.recorded_at) AS finished_at
					,rank() OVER (
						PARTITION BY f.job_id
						,r.record_class_rank
						,r_start.record_class_rank ORDER BY r.recorded_at DESC
						) AS last_record_in_process
					,d1.date_value AS in_date
					,d2.date_value AS out_date
					,(l.out_plan_date_id - l.in_plan_date_id) * 24 * 60 AS lead_time_min
					,isnull(convert(DECIMAL, (l.out_plan_date_id - l.in_plan_date_id) * 24 * 60) / nullif(@normal_leadtime_minutes, 0), 0) AS lead_time_rate
				FROM APCSProDB.trans.lots AS l WITH (NOLOCK)
				INNER JOIN (
					SELECT df.*
					FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
					WHERE df.is_skipped = 0
					) AS f ON f.device_slip_id = l.device_slip_id
				LEFT OUTER JOIN (
					SELECT rank() OVER (
							PARTITION BY job_id
							,record_class ORDER BY recorded_at
							) AS record_class_rank
						,*
					FROM APCSProDB.trans.lot_process_records WITH (NOLOCK)
					WHERE lot_id = @lot_id
					) AS r_start ON r_start.lot_id = l.id
					AND r_start.record_class IN (1)
					AND r_start.job_id = f.job_id
				LEFT OUTER JOIN (
					SELECT rank() OVER (
							PARTITION BY job_id
							,record_class ORDER BY recorded_at
							) AS record_class_rank
						,*
					FROM APCSProDB.trans.lot_process_records WITH (NOLOCK)
					WHERE lot_id = @lot_id
					) AS r ON r.lot_id = l.id
					AND r.record_class IN (2)
					AND r.job_id = f.job_id
					AND r.record_class_rank = r_start.record_class_rank
				INNER JOIN APCSProDB.trans.days AS d1 WITH (NOLOCK) ON d1.id = l.in_plan_date_id
				INNER JOIN APCSProDB.trans.days AS d2 WITH (NOLOCK) ON d2.id = l.out_plan_date_id
				LEFT OUTER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.id = f.job_id
				WHERE l.id = @lot_id
					--2020.04.14
					--AND f.is_skipped = 0
				) AS t1
			WHERE t1.last_record_in_process = 1
				OR t1.last_record_in_process IS NULL
			) AS t2
		) AS t3
	ORDER BY step_no
		,started_record_id
END

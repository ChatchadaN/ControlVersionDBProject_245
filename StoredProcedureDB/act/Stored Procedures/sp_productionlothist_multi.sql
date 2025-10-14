
CREATE PROCEDURE [act].[sp_productionlothist_multi] (@lot_id_list NVARCHAR(max) = NULL)
AS
BEGIN
	SELECT t2.lot_rank AS lot_rank
		,t2.lot_id AS lot_id
		,tl.lot_no AS lot_no
		,dd.name AS device_name
		,t2.process_id AS process_id
		,t2.job_id AS job_id
		,t2.machine_id AS machine_id
		,dp.name AS process_name
		,dj.name AS job_name
		,dm.name AS machine_name
		,t2.started_at AS started_at
		,convert(DATE, t2.started_at) AS started_date
		,format(t2.started_at, 'HH:mm:ss') AS started_time
		,t2.finished_at AS finished_at
		,convert(DATE, t2.finished_at) AS finished_date
		,format(t2.finished_at, 'HH:mm:ss') AS finished_time
		,t2.qty_pass AS qty_pass
		,t2.qty_fail_step_sum AS qty_fail_step_sum
		,t2.qty_fail AS qty_fail
		,t2.operated_by AS operated_by
		,mu.english_name AS english_name
	FROM (
		SELECT t1.lot_rank AS lot_rank
			,t1.lot_id AS lot_id
			,t1.process_id AS process_id
			,t1.job_id AS job_id
			,t1.machine_id AS machine_id
			,t1.process_job_id AS process_job_id
			,t1.started_at AS started_at
			,t1.finished_at AS finished_at
			,t1.qty_pass AS qty_pass
			,t1.qty_fail_step_sum AS qty_fail_step_sum
			,t1.qty_fail AS qty_fail
			,t1.operated_by AS operated_by
		FROM (
			SELECT t0.lot_rank AS lot_rank
				,t0.lot_id AS lot_id
				,t0.process_id AS process_id
				,t0.job_id AS job_id
				,t0.machine_id AS machine_id
				,t0.process_job_id AS process_job_id
				,t0.updated_at AS updated_at
				,t0.record_class AS record_class
				,CASE 
					WHEN t0.record_class = 1
						THEN t0.updated_at
					ELSE NULL
					END AS started_at
				,CASE 
					WHEN LEAD(t0.updated_at) OVER (
							PARTITION BY t0.lot_id ORDER BY t0.updated_at
							) IS NOT NULL
						THEN LEAD(t0.updated_at) OVER (
								PARTITION BY t0.lot_id ORDER BY t0.updated_at
								)
					ELSE NULL
					END AS finished_at
				,t0.qty_pass AS qty_pass
				,max(t0.qty_fail_step_sum) OVER (
					PARTITION BY t0.lot_id
					,t0.process_job_id
					) AS qty_fail_step_sum
				,max(t0.qty_fail) OVER (
					PARTITION BY t0.lot_id
					,t0.process_job_id
					) AS qty_fail
				,t0.operated_by AS operated_by
			FROM (
				SELECT dense_rank() OVER (
						ORDER BY lp.lot_id
						) AS lot_rank
					,lp.id AS id
					,lp.lot_id AS lot_id
					,lp.process_id AS process_id
					,lp.job_id AS job_id
					,lp.machine_id AS machine_id
					,lp.process_job_id AS process_job_id
					,lp.updated_at AS updated_at
					,lp.record_class
					,lp.qty_in AS qty_in
					,lp.qty_pass AS qty_pass
					,lp.qty_fail AS qty_fail
					,lp.qty_pass_step_sum AS qty_pass_step_sum
					,lp.qty_fail_step_sum AS qty_fail_step_sum
					,lp.operated_by AS operated_by
				FROM APCSProDB.trans.lot_process_records AS lp WITH (NOLOCK)
				INNER JOIN (
					SELECT convert(INT, value) AS value
					FROM STRING_SPLIT(@lot_id_list, ',')
					) AS v ON v.value = lp.lot_id
				) AS t0
			WHERE t0.record_class IN (
					1
					,2
					)
			) AS t1
		WHERE t1.record_class = 1
		) AS t2
	LEFT JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = t2.process_id
	LEFT JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = t2.job_id
	LEFT JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t2.machine_id
	INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = t2.lot_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = tl.act_device_name_id
	LEFT OUTER JOIN APCSProDB.man.users AS mu WITH (NOLOCK) ON mu.id = t2.operated_by
	ORDER BY t2.lot_rank
		,t2.started_at
END

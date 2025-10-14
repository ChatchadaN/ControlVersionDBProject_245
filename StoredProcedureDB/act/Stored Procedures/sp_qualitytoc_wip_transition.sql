
CREATE PROCEDURE [act].[sp_qualitytoc_wip_transition] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_id INT = NULL
	,@date_from DATE
	,@date_to DATE
	)
AS
BEGIN
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_from
			)
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_to
			)

	SELECT s1.day_id AS day_id
		,s1.date_value AS date_value
		,s2.package_id AS package_id
		,dg.name AS package_name
		,s2.process_id AS process_id
		,dp.name AS process_name
		,s2.job_id AS job_id
		,dj.name AS job_name
		,
		--wip
		s2.lot_val_open AS lot_val_open
		,s2.lot_val_close AS lot_val_close
		,s2.lot_val_high AS lot_val_high
		,s2.lot_val_low AS lot_val_low
		,s2.kpcs_val_open AS kpcs_val_open
		,s2.kpcs_val_close AS kpcs_val_close
		,s2.kpcs_val_high AS kpcs_val_high
		,s2.kpcs_val_low AS kpcs_val_low
		,
		--fact_end
		s3.sum_lot_count AS fact_end_lot_count
		,s3.sum_pass_kpcs AS fact_end_pass_kpcs
		,s3.sum_wait_time_h AS fact_end_wait_time_h
		,s3.sum_process_time_h AS fact_end_process_time_h
		,s3.machine_count AS fact_end_machine_count
		,
		--input
		s4.sum_input_lot_count AS sum_input_lot_count
		,s4.sum_input_pass_kpcs AS sum_input_pass_kpcs
	FROM (
		SELECT dd.id AS day_id
			,dd.date_value AS date_value
		FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
		WHERE @from <= dd.id
			AND dd.id <= @to
		) AS s1
	LEFT OUTER JOIN (
		SELECT t4.day_id AS day_id
			,t4.package_id AS package_id
			,t4.process_id AS process_id
			,t4.job_id AS job_id
			,max(t4.lot_val_open) AS lot_val_open
			,max(t4.lot_val_close) AS lot_val_close
			,max(t4.lot_val_high) AS lot_val_high
			,max(t4.lot_val_low) AS lot_val_low
			,
			--
			convert(DECIMAL(9, 1), nullif(max(t4.pcs_val_open), 0)) / 1000 AS kpcs_val_open
			,convert(DECIMAL(9, 1), nullif(max(t4.pcs_val_close), 0)) / 1000 AS kpcs_val_close
			,convert(DECIMAL(9, 1), nullif(max(t4.pcs_val_high), 0)) / 1000 AS kpcs_val_high
			,convert(DECIMAL(9, 1), nullif(max(t4.pcs_val_low), 0)) / 1000 AS kpcs_val_low
		FROM (
			SELECT t3.day_id AS day_id
				,t3.hour_code AS hour_code
				,t3.package_id AS package_id
				,t3.process_id AS process_id
				,t3.job_id AS job_id
				,t3.lot_count AS lot_count
				,t3.pcs AS pcs
				,t3.start_end_flag AS start_end_flag
				,
				--lot_count
				CASE 
					WHEN t3.start_end_flag = 0
						THEN t3.lot_count
					END AS lot_val_open
				,CASE 
					WHEN t3.start_end_flag = 2
						THEN t3.lot_count
					END AS lot_val_close
				,CASE 
					WHEN t3.start_end_flag = 1
						THEN max(t3.lot_count) OVER (PARTITION BY t3.day_id)
					END AS lot_val_high
				,CASE 
					WHEN t3.start_end_flag = 1
						THEN min(t3.lot_count) OVER (PARTITION BY t3.day_id)
					END AS lot_val_low
				,
				--pcs
				CASE 
					WHEN t3.start_end_flag = 0
						THEN t3.pcs
					END AS pcs_val_open
				,CASE 
					WHEN t3.start_end_flag = 2
						THEN t3.pcs
					END AS pcs_val_close
				,CASE 
					WHEN t3.start_end_flag = 1
						THEN max(t3.pcs) OVER (PARTITION BY t3.day_id)
					END AS pcs_val_high
				,CASE 
					WHEN t3.start_end_flag = 1
						THEN min(t3.pcs) OVER (PARTITION BY t3.day_id)
					END AS pcs_val_low
			FROM (
				SELECT t2.day_id AS day_id
					,t2.hour_code AS hour_code
					,t2.package_id AS packaage_id
					,t2.package_id AS package_id
					,t2.process_id AS process_id
					,t2.job_id AS job_id
					,t2.lot_count AS lot_count
					,t2.pcs AS pcs
					,CASE 
						WHEN t2.first_hour = 1
							THEN 0
						WHEN t2.last_hour = 1
							THEN 2
						ELSE 1
						END AS start_end_flag
				FROM (
					SELECT t1.day_id AS day_id
						,t1.hour_code AS hour_code
						,t1.package_id AS packaage_id
						,t1.package_id AS package_id
						,t1.process_id AS process_id
						,t1.job_id AS job_id
						,t1.lot_count AS lot_count
						,t1.pcs AS pcs
						,dense_rank() OVER (
							PARTITION BY t1.day_id ORDER BY t1.hour_code
							) AS first_hour
						,dense_rank() OVER (
							PARTITION BY t1.day_id ORDER BY t1.hour_code DESC
							) AS last_hour
					FROM (
						SELECT fw.day_id AS day_id
							,fw.hour_code AS hour_code
							,fw.package_id AS packaage_id
							,fw.package_id AS package_id
							,fw.process_id AS process_id
							,fw.job_id AS job_id
							,sum(fw.lot_count) AS lot_count
							,sum(fw.pcs) AS pcs
						FROM APCSProDWH.dwh.fact_wip AS fw WITH (NOLOCK)
						WHERE fw.package_id = @package_id
							AND fw.job_id = @job_id
							AND @from <= fw.day_id
							AND fw.day_id <= @to
						GROUP BY fw.day_id
							,fw.hour_code
							,fw.package_id
							,fw.process_id
							,fw.job_id
						) AS t1
					) AS t2
				) AS t3
			) AS t4
		GROUP BY t4.day_id
			,t4.package_id
			,t4.process_id
			,t4.job_id
		) AS s2 ON s2.day_id = s1.day_id
	LEFT OUTER JOIN (
		SELECT fe.day_id AS day_id
			,count(fe.lot_id) AS sum_lot_count
			,convert(DECIMAL(9, 1), nullif(sum(fe.pass_pcs), 0)) / 1000 AS sum_pass_kpcs
			,convert(DECIMAL(9, 1), nullif(sum(fe.wait_time), 0)) / 60 AS sum_wait_time_h
			,convert(DECIMAL(9, 1), nullif(sum(fe.process_time), 0)) / 60 AS sum_process_time_h
			,max(fe.machine_count) AS machine_count
		FROM (
			SELECT day_id AS day_id
				,lot_id AS lot_id
				,pass_pcs AS pass_pcs
				,wait_time AS wait_time
				,process_time AS process_time
				,dense_rank() OVER (
					PARTITION BY day_id ORDER BY machine_id
					) AS machine_count
			FROM APCSProDWH.dwh.fact_end WITH (NOLOCK)
			WHERE package_id = @package_id
				AND job_id = @job_id
				AND @from <= day_id
				AND day_id <= @to
			) AS fe
		GROUP BY fe.day_id
		) AS s3 ON s3.day_id = s1.day_id
	LEFT OUTER JOIN (
		SELECT fe.day_id AS day_id
			,count(fe.lot_id) AS sum_input_lot_count
			,convert(DECIMAL(9, 1), nullif(sum(fe.pass_pcs), 0)) / 1000 AS sum_input_pass_kpcs
		FROM (
			SELECT day_id AS day_id
				,lot_id AS lot_id
				,pass_pcs AS pass_pcs
			--dense_rank() OVER (
			--	PARTITION BY day_id ORDER BY machine_id
			--	) AS machine_count
			FROM APCSProDWH.dwh.fact_end WITH (NOLOCK)
			WHERE package_id = @package_id
				--and next_process_id = @process_id
				AND (
					(
						@process_id IS NOT NULL
						AND next_process_id = @process_id
						)
					OR (
						@process_id IS NULL
						AND next_process_id > 0
						)
					)
				AND next_job_id = @job_id
				AND @from <= day_id
				AND day_id <= @to
			) AS fe
		GROUP BY fe.day_id
		) AS s4 ON s4.day_id = s1.day_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS dg WITH (NOLOCK) ON dg.id = s2.package_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = s2.process_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = s2.job_id
	ORDER BY day_id
END

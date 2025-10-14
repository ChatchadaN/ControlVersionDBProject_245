
CREATE PROCEDURE [act].[sp_operator_lot_processed] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@shift_code INT = NULL
	--,@job_id INT = NULL
	--,@device_name VARCHAR(20) = NULL
	--,@machine_id INT = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2021-06-01'
	--DECLARE @date_to DATETIME = '2021-06-07'
	--DECLARE @package_id INT = NULL
	--DECLARE @process_id INT = 3
	--DECLARE @time_offset INT = 8
	--DECLARE @shift_code INT = NULL
	DECLARE @fr_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = convert(DATE, @date_from)
			);
	DECLARE @to_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = convert(DATE, @date_to)
			);

	SELECT d.id AS day_id
		,d.date_value AS date_value
		,t6.shift_code
		,t6.operated_by
		,t6.operated_name
		,t6.process_id
		,t6.process_name
		,t6.lot_count
		,t6.incharge_mc_count
		,t6.use_mc_count
		,t6.rk_ope
		,t6.max_rk_ope
		,t6.ope_per_process
		,t6.ope_sum
	FROM (
		SELECT dd.id
			,dd.date_value
		FROM apcsprodwh.dwh.dim_days AS dd
		WHERE dd.id BETWEEN @fr_date
				AND @to_date
		) AS d
	LEFT JOIN (
		SELECT t5.new_day_id AS day_id
			,t5.new_date_value AS date_value
			,t5.shift_code AS shift_code
			,t5.operated_by
			,mu.name AS operated_name
			,t5.process_id
			,t5.process_name
			,t5.lot_count
			,t5.incharge_mc_count
			,t5.use_mc_count
			,t5.rk_ope
			,max(t5.rk_ope) OVER () AS max_rk_ope
			,t5.ope_per_process
			,t5.ope_sum
		FROM (
			SELECT t4.new_day_id
				,t4.new_date_value
				,t4.shift_code
				,t4.operated_by
				,t4.process_id
				,t4.process_name
				,count(t4.lot_id) AS lot_count
				,t4.incharge_mc_count
				,t4.use_mc_count
				,dense_rank() OVER (
					PARTITION BY t4.process_id ORDER BY t4.operated_by
					) AS rk_ope
				,ope_per_process AS ope_per_process
				,ope_all AS ope_sum
			FROM (
				SELECT t3.*
					,max(rk_ope_count) OVER (
						PARTITION BY new_day_id
						,t3.shift_code
						,t3.process_id
						) AS ope_per_process
					,max(rk_all_ope_count) OVER (
						PARTITION BY new_day_id
						,t3.shift_code
						) AS ope_all
					,max(rk_mc_count) OVER (
						PARTITION BY new_day_id
						,t3.shift_code
						,t3.process_id
						,t3.operated_by
						) AS incharge_mc_count
					,max(rk_all_count) OVER (
						PARTITION BY new_day_id
						,t3.shift_code
						,t3.process_id
						) AS use_mc_count
				FROM (
					SELECT t2.id
						,t2.day_id
						,t2.recorded_at
						,dd.id AS new_day_id
						,t2.shifted_recorded_at
						,t2.new_date_value
						,t2.shift_code
						,t2.operated_by
						,t2.lot_id
						,t2.process_id
						,dp.name AS process_name
						,t2.job_id
						,t2.machine_id
						,dm.name AS machine_name
						,dense_rank() OVER (
							PARTITION BY dd.id
							,t2.shift_code
							,t2.process_id ORDER BY t2.operated_by
							) AS rk_ope_count
						,dense_rank() OVER (
							PARTITION BY dd.id
							,t2.shift_code ORDER BY t2.operated_by
							) AS rk_all_ope_count
						,dense_rank() OVER (
							PARTITION BY dd.id
							,t2.shift_code
							,t2.process_id
							,t2.operated_by ORDER BY t2.machine_id
							) AS rk_mc_count
						,dense_rank() OVER (
							PARTITION BY dd.id
							,t2.shift_code
							,t2.process_id ORDER BY t2.machine_id
							) AS rk_all_count
					FROM (
						SELECT t1.id
							,t1.day_id
							,t1.recorded_at
							,t1.shifted_recorded_at
							,t1.shifted_recorded_hour
							,convert(DATE, t1.shifted_recorded_at) AS new_date_value
							,CASE 
								WHEN shifted_recorded_hour >= 12
									THEN 1
								ELSE 0
								END AS shift_code
							,t1.operated_by
							,t1.lot_id
							,t1.process_id
							,t1.job_id
							,t1.machine_id
						FROM (
							SELECT lpr.id
								,lpr.day_id
								,lpr.recorded_at
								,DATEADD(HOUR, - 1 * @time_offset, lpr.recorded_at) AS shifted_recorded_at
								,datepart(hour, DATEADD(HOUR, - 1 * @time_offset, lpr.recorded_at)) AS shifted_recorded_hour
								,lpr.operated_by
								,lpr.record_class
								,lpr.lot_id
								,lpr.process_id
								,lpr.job_id
								,lpr.machine_id
							FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
							INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = lpr.lot_id
							WHERE lpr.day_id BETWEEN @fr_date
									AND @to_date + 1
								AND record_class = 2
								AND (
									(
										@package_id IS NOT NULL
										AND tl.act_package_id = @package_id
										)
									OR (
										@package_id IS NULL
										AND tl.act_package_id > 0
										)
									)
							) AS t1
						) AS t2
					INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.date_value = t2.new_date_value
					INNER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = t2.process_id
					INNER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t2.machine_id
					WHERE (
							(
								@shift_code IS NOT NULL
								AND t2.shift_code = @shift_code
								)
							OR (@shift_code IS NULL)
							)
					) AS t3
				WHERE t3.new_day_id BETWEEN @fr_date
						AND @to_date
				) AS t4
			GROUP BY t4.new_day_id
				,t4.new_date_value
				,t4.shift_code
				,t4.operated_by
				,t4.process_id
				,t4.process_name
				,ope_per_process
				,ope_all
				,t4.incharge_mc_count
				,t4.use_mc_count
			) AS t5
		LEFT JOIN APCSProDB.man.users AS mu WITH (NOLOCK) ON mu.id = t5.operated_by
		WHERE (
				(
					@process_id IS NOT NULL
					AND t5.process_id = @process_id
					)
				OR (
					@process_id IS NULL
					AND t5.process_id > 0
					)
				)
		) AS t6 ON t6.day_id = d.id
	ORDER BY day_id
		,shift_code
		,process_id
		,lot_count DESC
		,operated_by
END

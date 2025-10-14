
CREATE PROCEDURE [act].[sp_operator_lot_list_old] (
	@date_from DATETIME
	,@date_to DATETIME
	,@machine_group_id INT = NULL
	,@machine_model_id INT = NULL
	,@machine_id INT = NULL
	,@time_offset INT = 0
	,@operated_by INT
	,@shift_code INT = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2021-07-01'
	--DECLARE @date_to DATETIME = '2021-07-30'
	--DECLARE @machine_group_id INT = 2
	--DECLARE @machine_model_id INT = NULL
	--DECLARE @machine_id INT = NULL
	--DECLARE @time_offset INT = 8
	--DECLARE @operated_by INT = 727
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

	IF OBJECT_ID(N'tempdb..#ope_lot_list', N'U') IS NOT NULL
		DROP TABLE #ope_lot_list;

	SELECT t1.machine_id
		,t1.machine_name
		,t1.machine_group_id
		,t1.machine_group_name
		,t1.machine_model_id
		,t1.machine_model_name
		,dd.id AS day_id
		,t1.shifted_date_value AS date_value
		,t1.shift_code
		,t1.lot_id
		,t1.lot_no
		,isnull(t1.operated_by, - 1) AS operated_by
		,lp.started_at AS started_at
		,lp.finished_at AS finished_at
		,lp.started_by AS started_by
		,lp.finished_by AS finished_by
	INTO #ope_lot_list
	FROM (
		SELECT ml.*
			,op.operated_by
		FROM (
			SELECT t2.machine_id
				,t2.machine_name
				,t2.machine_model_id
				,t2.machine_model_name
				,t2.machine_group_name
				,t2.machine_group_id
				,t2.process_job_id
				,t2.shifted_started_at
				,t2.shifted_finished_at
				,t2.shifted_date_value
				,t2.shift_code
				,t2.lot_id
				,t2.lot_no
			FROM (
				SELECT t1.machine_id
					,t1.machine_name
					,t1.machine_model_id
					,t1.machine_model_name
					,t1.machine_group_name
					,t1.machine_group_id
					,t1.process_job_id
					,t1.started_at
					,t1.finished_at
					,DATEADD(HOUR, - 1 * @time_offset, t1.started_at) AS shifted_started_at
					,DATEADD(HOUR, - 1 * @time_offset, t1.finished_at) AS shifted_finished_at
					,CONVERT(DATE, DATEADD(HOUR, - 1 * @time_offset, t1.finished_at)) AS shifted_date_value
					,CASE 
						WHEN datepart(hour, DATEADD(HOUR, - 1 * @time_offset, t1.finished_at)) >= 12
							THEN 1
						ELSE 0
						END AS shift_code
					,t1.lot_id
					,t1.lot_no
				FROM (
					SELECT m.id AS machine_id
						,m.name AS machine_name
						,md.id AS machine_model_id
						,md.name AS machine_model_name
						,g.id AS machine_group_id
						,g.name AS machine_group_name
						,pj.process_job_id
						,pj.started_at
						,pj.finished_at
						,lp.idx
						,lp.lot_id
						,rtrim(l.lot_no) AS lot_no
					FROM APCSProDB.mc.groups AS g WITH (NOLOCK)
					INNER JOIN APCSProDB.mc.group_models AS gm WITH (NOLOCK) ON gm.machine_group_id = g.id
					INNER JOIN APCSProDB.mc.models AS md WITH (NOLOCK) ON md.id = gm.machine_model_id
					INNER JOIN APCSProDB.mc.machines AS m WITH (NOLOCK) ON m.machine_model_id = md.id
					LEFT OUTER JOIN APCSProDB.trans.lot_pjs AS pj WITH (NOLOCK) ON pj.machine_id = m.id
						AND pj.finished_at IS NOT NULL
						AND (
							pj.started_at BETWEEN @date_from
								AND DATEADD(day, 1, @date_to)
							OR pj.finished_at BETWEEN @date_from
								AND DATEADD(day, 1, @date_to)
							)
						AND pj.started_at > DATEADD(day, - 1, finished_at)
					LEFT OUTER JOIN APCSProDB.trans.pj_lots AS lp WITH (NOLOCK) ON lp.process_job_id = pj.process_job_id
					LEFT OUTER JOIN APCSProDB.trans.lots AS l WITH (NOLOCK) ON l.id = lp.lot_id
					LEFT OUTER JOIN APCSProDB.method.device_names AS d WITH (NOLOCK) ON d.id = l.act_device_name_id
						AND d.is_assy_only IN (
							0
							,1
							)
					--WHERE g.name = 'WB'
					WHERE (
							(
								@machine_group_id IS NOT NULL
								AND g.id = @machine_group_id
								)
							OR (
								@machine_group_id IS NULL
								AND g.id > 0
								)
							)
						AND (
							(
								@machine_model_id IS NOT NULL
								AND md.id = @machine_model_id
								)
							OR (
								@machine_model_id IS NULL
								AND md.id > 0
								)
							)
						AND (
							(
								@machine_id IS NOT NULL
								AND m.id = @machine_id
								)
							OR (
								@machine_id IS NULL
								AND m.id > 0
								)
							)
					) AS t1
				) AS t2
			WHERE shifted_date_value BETWEEN @date_from
					AND @date_to
			) AS ml
		--operator
		LEFT JOIN (
			SELECT lpr.id
				,lpr.day_id
				,lpr.recorded_at
				,lpr.operated_by
				,lpr.record_class
				,lpr.lot_id
				,lpr.process_job_id
				,lpr.process_id
				,lpr.job_id
				,lpr.machine_id
			FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
			WHERE record_class = 2
			) AS op ON op.lot_id = ml.lot_id
			AND op.process_job_id = ml.process_job_id
		) AS t1
	INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.date_value = t1.shifted_date_value
	INNER JOIN APCSProDB.trans.lot_pjs AS lp WITH (NOLOCK) ON lp.process_job_id = t1.process_job_id
	WHERE dd.id BETWEEN @fr_date
			AND @to_date
		AND (
			(
				@machine_group_id IS NOT NULL
				AND t1.machine_group_id = @machine_group_id
				)
			OR (
				@machine_group_id IS NULL
				AND t1.machine_group_id > 0
				)
			)
		AND (
			(
				@machine_model_id IS NOT NULL
				AND t1.machine_model_id = @machine_model_id
				)
			OR (
				@machine_model_id IS NULL
				AND t1.machine_model_id > 0
				)
			)
		AND (
			(
				@machine_id IS NOT NULL
				AND t1.machine_id = @machine_id
				)
			OR (
				@machine_id IS NULL
				AND t1.machine_id > 0
				)
			)
		AND t1.operated_by = @operated_by
		AND (
			(
				@shift_code IS NULL
				AND t1.shift_code >= 0
				)
			OR (
				@shift_code IS NOT NULL
				AND t1.shift_code = @shift_code
				)
			)

	----Lot List
	SELECT *
	FROM #ope_lot_list
	ORDER BY finished_at
		,shift_code
		,machine_name

	----
	SELECT machine_id
		,machine_name
		,max(num_of_lots_on_day) AS num_of_lots_on_day
		,max(num_of_lots_on_night) AS num_of_lots_on_night
		,isnull(max(num_of_lots_on_day), 0) + isnull(max(num_of_lots_on_night), 0) AS all_count
	FROM (
		SELECT machine_id
			,machine_name
			,CASE 
				WHEN shift_code = 0
					THEN COUNT(lot_id)
				ELSE NULL
				END AS num_of_lots_on_day
			,CASE 
				WHEN shift_code = 1
					THEN COUNT(lot_id)
				ELSE NULL
				END AS num_of_lots_on_night
			,shift_code
		FROM #ope_lot_list
		GROUP BY machine_id
			,machine_name
			,shift_code
		) AS t1
	GROUP BY machine_id
		,machine_name
	ORDER BY all_count DESC
		,machine_name

	----Lot gantt
	SELECT *
		,max(mc_rank) OVER () + 1 AS max_mc_rank
		,CASE 
			WHEN DATEDIFF(MINUTE, start_time, started_at) > 0
				THEN DATEDIFF(MINUTE, start_time, started_at)
			ELSE 0
			END AS start_point
		,CASE 
			WHEN (DATEDIFF(MINUTE, start_time, started_at) + process_time) < span
				THEN DATEDIFF(MINUTE, start_time, started_at) + process_time
			ELSE span
			END AS end_point
	FROM (
		SELECT machine_id
			,machine_name
			,shift_code
			,started_at
			,finished_at
			,lot_id
			,lot_no
			,DENSE_RANK() OVER (
				ORDER BY machine_name DESC
				) AS mc_rank
			,datediff(MINUTE, @date_from, @date_to + 1) AS span
			,DATEDIFF(MINUTE, started_at, finished_at) AS process_time
			--
			--,CASE 
			--	WHEN @shift_code = 0
			--		THEN DATEADD(HOUR, @time_offset, @date_from)
			--	ELSE DATEADD(HOUR, @time_offset + 12, @date_from)
			--	END AS start_time
			,DATEADD(HOUR, @time_offset, @date_from) AS start_time
			,started_by
			,finished_by
		FROM #ope_lot_list AS t1
		) AS t1
	ORDER BY mc_rank
		,started_at
END

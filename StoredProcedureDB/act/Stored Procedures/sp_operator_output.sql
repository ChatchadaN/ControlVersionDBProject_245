
CREATE PROCEDURE [act].[sp_operator_output] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@package_group_id INT = NULL
	,@package_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@machine_group_id INT = NULL
	,@machine_model_id INT = NULL
	,@machine_id INT = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2021-07-01'
	--DECLARE @date_to DATETIME = '2021-08-05'
	--DECLARE @machine_group_id INT = 2
	--DECLARE @machine_model_id INT = NULL
	--DECLARE @machine_id INT = NULL
	--DECLARE @time_offset INT = 8
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = 246
	--DECLARE @device_name VARCHAR(20) = NULL
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
		,t1.package_id
		,isnull(lp.finished_by, - 1) AS operated_by
		,lp.started_at AS started_at
		,lp.finished_at AS finished_at
		,lp.started_by AS started_by
		,lp.finished_by AS finished_by
	INTO #ope_lot_list
	FROM (
		SELECT ml.*
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
				,t2.package_id
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
					,t1.package_id
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
						,l.act_package_id AS package_id
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
					LEFT JOIN APCSProDB.method.packages AS mp WITH (NOLOCK) ON mp.id = l.act_package_id
					LEFT JOIN APCSProDB.method.package_groups AS pg WITH (NOLOCK) ON pg.id = mp.package_group_id
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
						AND (
							(
								@package_group_id IS NOT NULL
								AND pg.id = @package_group_id
								)
							OR (
								@package_group_id IS NULL
								AND pg.id > 0
								)
							)
						AND (
							(
								@package_id IS NOT NULL
								AND mp.id = @package_id
								)
							OR (
								@package_id IS NULL
								AND mp.id > 0
								)
							)
						AND (
							(
								@device_name IS NOT NULL
								AND d.name = @device_name
								)
							OR (@device_name IS NULL)
							)
					) AS t1
				) AS t2
			WHERE shifted_date_value BETWEEN @date_from
					AND @date_to
			) AS ml
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

	----day list
	SELECT td.id AS day_id
		,td.date_value AS date_value
	FROM APCSProDB.trans.days AS td WITH (NOLOCK)
	WHERE td.id BETWEEN @fr_date
			AND @to_date

	----ope output
	SELECT *
		,max(rk_ope) OVER () AS max_rk_ope
	FROM (
		SELECT *
			,DENSE_RANK() OVER (
				ORDER BY operated_by
				) AS rk_ope
		FROM (
			SELECT day_id
				,date_value
				,operated_by
				,num_of_lot
				,rk_mc2 AS num_of_mc
				,lots_per_mc
			FROM (
				SELECT *
					,MAX(rk_mc) OVER (
						PARTITION BY day_id
						,operated_by
						) AS rk_mc2
					,convert(DECIMAL(6, 3), convert(DECIMAL, num_of_lot) / (
							MAX(rk_mc) OVER (
								PARTITION BY day_id
								,operated_by
								)
							)) AS lots_per_mc
				FROM (
					SELECT day_id
						,date_value
						,machine_id
						,machine_name
						,count(lot_id) OVER (
							PARTITION BY day_id
							,operated_by
							) AS num_of_lot
						,operated_by
						,DENSE_RANK() OVER (
							PARTITION BY day_id
							,operated_by ORDER BY machine_id
							) AS rk_mc
					FROM #ope_lot_list
					) AS t1
				) AS t2
			GROUP BY day_id
				,date_value
				,operated_by
				,num_of_lot
				,rk_mc2
				,lots_per_mc
			) AS t3
		) AS t4
	ORDER BY day_id
END

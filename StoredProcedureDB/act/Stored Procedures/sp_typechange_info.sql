
CREATE PROCEDURE [act].[sp_typechange_info] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@package_id INT = NULL
	,@process_id INT = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2020-01-03 00:00:00'
	--DECLARE @date_to DATETIME = '2020-02-28 00:00:00'
	--DECLARE @time_offset INT = 0
	--DECLARE @package_id INT = 103
	--DECLARE @process_id INT = 2
	DECLARE @local_date_from DATETIME = dateadd(hour, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = dateadd(hour, @time_offset, @date_to)
	DECLARE @fr_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
			WHERE date_value = convert(DATE, @local_date_from)
			)
	DECLARE @to_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
			WHERE date_value = convert(DATE, @local_date_to)
			)

	IF OBJECT_ID(N'tempdb..#mc', N'U') IS NOT NULL
		DROP TABLE #mc;

	IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
		DROP TABLE #table;

	--指定期間、パッケージ、工程で使用された装置抽出
	SELECT machine_id
	INTO #mc
	FROM (
		SELECT lpr.machine_id
		FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
		INNER JOIN (
			SELECT job_id
				,process_id
			FROM APCSProDWH.dwh.dim_package_jobs WITH (NOLOCK)
			WHERE package_id = @package_id
				AND is_skipped = 0
				AND process_id = @process_id
			) AS j ON j.job_id = lpr.job_id
			AND j.process_id = lpr.process_id
		INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = lpr.lot_id
		WHERE lpr.day_id BETWEEN @fr_date
				AND @to_date
			AND lpr.process_id = @process_id
			AND tl.act_package_id = @package_id
			AND lpr.machine_id > 0
			AND lpr.record_class < 20
		) AS l
	GROUP BY l.machine_id

	--装置で処理されたロット抽出
	SELECT lpr5.id
		,lpr5.day_id
		,lpr5.recorded_at AS started_at
		,lpr5.finished_at AS finished_at
		,lpr5.lot_id
		,lpr5.process_id
		,lpr5.job_id
		,lpr5.machine_id
		,lpr5.is_special_flow
	INTO #table
	FROM (
		SELECT lpr4.*
			,LEAD(lpr4.recorded_at, 1) OVER (
				PARTITION BY lpr4.lot_id
				,lpr4.machine_id
				,lpr4.step_no ORDER BY lpr4.id
				) AS finished_at
		FROM (
			SELECT lpr3.*
			FROM (
				SELECT lpr2.*
					,ROW_NUMBER() OVER (
						PARTITION BY lpr2.process_id
						,lpr2.machine_id
						,lpr2.step_no
						,lpr2.lot_id
						,lpr2.is_special_flow ORDER BY lpr2.recorded_at
						) AS started_at_rn
					,ROW_NUMBER() OVER (
						PARTITION BY lpr2.process_id
						,lpr2.machine_id
						,lpr2.step_no
						,lpr2.lot_id
						,lpr2.is_special_flow ORDER BY lpr2.recorded_at DESC
						) AS finished_at_rn
				FROM (
					SELECT lpr.id
						,lpr.day_id
						,lpr.recorded_at
						,lpr.record_class
						,lpr.lot_id
						,lpr.process_id
						,lpr.job_id
						,lpr.step_no
						,lpr.process_job_id
						,lpr.machine_id
						,lpr.is_special_flow
					FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
					INNER JOIN (
						SELECT job_id
							,process_id
						FROM APCSProDWH.dwh.dim_package_jobs WITH (NOLOCK)
						WHERE package_id = @package_id
							AND is_skipped = 0
							AND process_id = @process_id
						) AS j ON j.job_id = lpr.job_id
						AND j.process_id = lpr.process_id
					INNER JOIN #mc AS mc ON mc.machine_id = lpr.machine_id
					WHERE lpr.day_id BETWEEN @fr_date
							AND @to_date
						AND lpr.process_id = @process_id
						AND lpr.record_class NOT IN (
							25
							,26
							)
					) AS lpr2
				) AS lpr3
			WHERE lpr3.started_at_rn = 1
				OR lpr3.finished_at_rn = 1
			) AS lpr4
		) AS lpr5
	WHERE lpr5.finished_at IS NOT NULL

	--ORDER BY machine_id
	--	,lot_id
	--	,id
	-------------------------------------
	SELECT u1.y
		,u1.m
		,u1.machine_id
		,mm.name AS machine_name
		,u1.total_diff_min
		,u1.monthly_change_package
		,u1.monthly_change_package_min
		,u1.monthly_change_package_per
		,u1.monthly_change_device
		,u1.monthly_change_device_min
		,u1.monthly_change_device_per
		,dense_rank() OVER (
			ORDER BY y
				,m
			) AS rn_month
		,ROW_NUMBER() OVER (
			PARTITION BY y
			,m ORDER BY all_change_package DESC
				,mm.name
			) AS rn_change_package
		,ROW_NUMBER() OVER (
			PARTITION BY y
			,m ORDER BY all_change_package_per DESC
				,mm.name
			) AS rn_change_package_min
		,ROW_NUMBER() OVER (
			PARTITION BY y
			,m ORDER BY all_change_device DESC
				,mm.name
			) AS rn_change_device
		,ROW_NUMBER() OVER (
			PARTITION BY y
			,m ORDER BY all_change_device_per DESC
				,mm.name
			) AS rn_change_device_min
	FROM (
		SELECT s1.y
			,s1.m
			,s1.machine_id
			,s2.total_diff_min
			,s2.monthly_change_package
			,s2.all_change_package
			,s2.monthly_change_package_min
			,s2.monthly_change_package_per
			,s2.all_change_package_per
			,s2.monthly_change_device
			,s2.all_change_device
			,s2.monthly_change_device_min
			,s2.monthly_change_device_per
			,s2.all_change_device_per
		FROM (
			SELECT *
			FROM (
				SELECT d1.*
				FROM (
					SELECT dd.y
						,dd.m
					FROM apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK)
					WHERE dd.id BETWEEN @fr_date
							AND @to_date
					) AS d1
				GROUP BY d1.y
					,d1.m
				) AS d2
			CROSS JOIN #mc AS m
			) AS s1
		LEFT JOIN (
			SELECT t7.y
				,t7.m
				,t7.machine_id
				,t7.monthly_change_package
				,t7.total_diff_min AS total_diff_min
				,sum(t7.monthly_change_package) OVER (PARTITION BY t7.machine_id) AS all_change_package
				,t7.monthly_change_package_min
				,CONVERT(DECIMAL(8, 2), t7.monthly_change_package_min) / nullif(t7.monthly_change_package, 0) AS monthly_change_package_per
				,sum(CONVERT(DECIMAL(8, 2), t7.monthly_change_package_min) / nullif(t7.monthly_change_package, 0)) OVER (PARTITION BY t7.machine_id) AS all_change_package_per
				,t7.monthly_change_device
				,sum(monthly_change_device) OVER (PARTITION BY t7.machine_id) AS all_change_device
				,t7.monthly_change_device_min
				,CONVERT(DECIMAL(8, 2), t7.monthly_change_device_min) / nullif(t7.monthly_change_device, 0) AS monthly_change_device_per
				,sum(CONVERT(DECIMAL(8, 2), t7.monthly_change_device_min) / nullif(t7.monthly_change_device, 0)) OVER (PARTITION BY t7.machine_id) AS all_change_device_per
			FROM (
				SELECT t6.y
					,t6.m
					,t6.machine_id
					,sum(t6.change_package) AS monthly_change_package
					,sum(t6.diff_package) AS monthly_change_package_min
					,sum(t6.change_device) AS monthly_change_device
					,sum(t6.diff_device) AS monthly_change_device_min
					,sum(t6.diff_min) AS total_diff_min
				FROM (
					SELECT t5.id
						,t5.day_id
						,dd.y AS y
						,dd.m AS m
						,dd.week_no AS week_no
						,t5.started_at
						,t5.finished_at
						,t5.lot_id
						,t5.process_id
						,t5.job_id
						,t5.machine_id
						--マイナス対策(不具合履歴対策)
						,CASE 
							WHEN t5.diff_min >= 0
								THEN t5.diff_min
							ELSE 0
							END AS diff_min
						,t5.act_package_id
						--マイナス対策(不具合履歴対策)
						,CASE 
							WHEN diff_package >= 0
								THEN t5.change_package
							ELSE 0
							END AS change_package
						,CASE 
							WHEN diff_package >= 0
								THEN t5.diff_package
							ELSE 0
							END AS diff_package
						,t5.act_device_name_id
						,CASE 
							WHEN diff_device >= 0
								THEN t5.change_device
							ELSE 0
							END AS change_device
						,CASE 
							WHEN diff_device >= 0
								THEN t5.diff_device
							ELSE 0
							END AS diff_device
					FROM (
						SELECT t4.*
							,CASE 
								WHEN t4.change_package = 0
									THEN 0
								ELSE t4.diff_min
								END AS diff_package
							,CASE 
								WHEN t4.change_device = 0
									THEN 0
								ELSE t4.diff_min
								END AS diff_device
						FROM (
							SELECT t3.id
								,t3.day_id
								,t3.started_at
								,t3.finished_at
								,t3.lot_id
								,t3.process_id
								,t3.job_id
								,t3.machine_id
								,t3.is_special_flow
								,t3.act_device_name_id
								,t3.next_device_name_id
								,t3.act_package_id
								,t3.next_package_id
								,t3.change_package
								,CASE 
									WHEN t3.change_device = 1
										THEN CASE 
												WHEN t3.change_package = 0
													THEN 1
												ELSE 0
												END
									ELSE 0
									END AS change_device
								,isnull(DATEDIFF(MINUTE, t3.finished_at, LEAD(t3.started_at, 1) OVER (
											PARTITION BY t3.machine_id ORDER BY t3.id
											)), 0) AS diff_min
							FROM (
								SELECT t2.*
									,CASE 
										WHEN t2.next_device_name_id IS NULL
											THEN 0
										ELSE CASE 
												WHEN t2.act_device_name_id = t2.next_device_name_id
													THEN 0
												ELSE 1
												END
										END AS change_device
									,CASE 
										WHEN t2.next_package_id IS NULL
											THEN 0
										ELSE CASE 
												WHEN t2.act_package_id = t2.next_package_id
													THEN 0
												ELSE 1
												END
										END AS change_package
								FROM (
									SELECT t1.id
										,t1.day_id
										,t1.started_at
										,t1.finished_at
										,t1.lot_id
										,t1.process_id
										,t1.job_id
										,t1.machine_id
										,t1.is_special_flow
										,tl.act_device_name_id
										,LEAD(tl.act_device_name_id, 1) OVER (
											PARTITION BY t1.machine_id ORDER BY t1.id
											) AS next_device_name_id
										,tl.act_package_id
										,LEAD(tl.act_package_id, 1) OVER (
											PARTITION BY t1.machine_id ORDER BY t1.id
											) AS next_package_id
									FROM #table AS t1
									INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = t1.lot_id
									) AS t2
								) AS t3
							) AS t4
						) AS t5
					INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = t5.day_id
					) AS t6
				GROUP BY machine_id
					,y
					,m
				) AS t7
			) AS s2 ON s2.m = s1.m
			AND s2.y = s1.y
			AND s2.machine_id = s1.machine_id
		) AS u1
	INNER JOIN apcsprodb.mc.machines AS mm WITH (NOLOCK) ON mm.id = u1.machine_id
	ORDER BY y
		,m
		,mm.name
		--,rn_change_device_min
END

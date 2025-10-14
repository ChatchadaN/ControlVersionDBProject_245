
CREATE PROCEDURE [act].[sp_user_specific_data_01] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@machine_id INT = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2021-03-01 00:00:00'
	--DECLARE @date_to DATETIME = '2021-04-01 00:00:00'
	--DECLARE @time_offset INT = 0
	--DECLARE @package_group_id INT = 33
	--DECLARE @package_id INT = 242
	--DECLARE @process_id INT = NULL
	--DECLARE @job_id INT = NULL
	--DECLARE @machine_id INT = NULL
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

	IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
		DROP TABLE #table;

	IF OBJECT_ID(N'tempdb..#table2', N'U') IS NOT NULL
		DROP TABLE #table2;

	SELECT *
	INTO #table
	FROM (
		SELECT lpr4.day_id
			,dd.date_value AS date_value
			,lpr4.first_recorded_at AS started_at
			,lpr4.last_recorded_at AS finished_at
			,lpr4.new_lotstart_at AS lotstart_at
			,lpr4.new_onlinestart_at AS onlinestart_at
			,lpr4.new_onlineend_at AS onlineend_at
			,lpr4.new_lotend_at AS lotend_at
			,DATEDIFF(minute, lpr4.first_recorded_at, lpr4.last_recorded_at) AS process_minutes
			,lpr4.qty_pass
			,trim(lpr4.lot_no) AS lot_no
			,TRIM(dn.name) AS device_name
			,trim(pg.name) AS package_group_name
			,trim(mp.name) AS package_name
			,trim(pr.name) AS process_name
			,trim(mj.name) AS job_name
			,trim(mm.name) AS machine_name
			,CASE 
				WHEN lpr4.is_special_flow = 0
					THEN 'normal'
				ELSE 'special'
				END AS flow
			,lpr4.lot_id
			,lpr4.package_id
			,lpr4.process_id
			,lpr4.job_id
			,lpr4.machine_id
			,lpr4.process_job_id
		FROM (
			SELECT lpr3.*
			FROM (
				SELECT lpr2.id
					,lpr2.day_id
					,lpr2.recorded_at
					,lpr2.record_class
					,ROW_NUMBER() OVER (
						PARTITION BY lpr2.package_id
						,lpr2.process_id
						,lpr2.process_job_id
						,lpr2.machine_id
						,lpr2.step_no
						,lpr2.lot_id
						,lpr2.lot_no
						,lpr2.is_special_flow ORDER BY lpr2.recorded_at
						) AS rn
					,min(lpr2.lotstart_at) OVER (
						PARTITION BY lpr2.package_id
						,lpr2.process_id
						,lpr2.process_job_id
						,lpr2.machine_id
						,lpr2.step_no
						,lpr2.lot_id
						,lpr2.lot_no
						,lpr2.is_special_flow
						) AS new_lotstart_at
					,min(lpr2.onlinestart_at) OVER (
						PARTITION BY lpr2.package_id
						,lpr2.process_id
						,lpr2.process_job_id
						,lpr2.machine_id
						,lpr2.step_no
						,lpr2.lot_id
						,lpr2.lot_no
						,lpr2.is_special_flow
						) AS new_onlinestart_at
					,max(lpr2.onlineend_at) OVER (
						PARTITION BY lpr2.package_id
						,lpr2.process_id
						,lpr2.process_job_id
						,lpr2.machine_id
						,lpr2.step_no
						,lpr2.lot_id
						,lpr2.lot_no
						,lpr2.is_special_flow
						) AS new_onlineend_at
					,max(lpr2.lotend_at) OVER (
						PARTITION BY lpr2.package_id
						,lpr2.process_id
						,lpr2.process_job_id
						,lpr2.machine_id
						,lpr2.step_no
						,lpr2.lot_id
						,lpr2.lot_no
						,lpr2.is_special_flow
						) AS new_lotend_at
					-----------------------------------------------------------------
					,min(lpr2.recorded_at) OVER (
						PARTITION BY lpr2.package_id
						,lpr2.process_id
						,lpr2.process_job_id
						,lpr2.machine_id
						,lpr2.step_no
						,lpr2.lot_id
						,lpr2.lot_no
						,lpr2.is_special_flow
						) AS first_recorded_at
					,max(lpr2.recorded_at) OVER (
						PARTITION BY lpr2.package_id
						,lpr2.process_id
						,lpr2.process_job_id
						,lpr2.machine_id
						,lpr2.step_no
						,lpr2.lot_id
						,lpr2.lot_no
						,lpr2.is_special_flow
						) AS last_recorded_at
					----------------------------------------------------------------
					,lpr2.lot_id
					,lpr2.lot_no
					,lpr2.act_device_name_id
					,lpr2.package_id
					,lpr2.process_id
					,lpr2.job_id
					,lpr2.step_no
					,lpr2.process_job_id
					,lpr2.machine_id
					,lpr2.qty_pass
					,lpr2.is_special_flow
				FROM (
					SELECT lpr.id
						,lpr.day_id
						,lpr.recorded_at
						,lpr.record_class
						------
						,CASE 
							WHEN record_class = 1
								THEN recorded_at
							ELSE NULL
							END AS lotstart_at
						,CASE 
							WHEN record_class = 11
								THEN recorded_at
							ELSE NULL
							END AS onlinestart_at
						,CASE 
							WHEN record_class = 2
								THEN recorded_at
							ELSE NULL
							END AS lotend_at
						,CASE 
							WHEN record_class = 12
								THEN recorded_at
							ELSE NULL
							END AS onlineend_at
						------
						,lpr.lot_id
						,tl.lot_no
						,tl.act_device_name_id
						,mp.id AS package_id
						,lpr.process_id
						,lpr.job_id
						,lpr.step_no
						,lpr.process_job_id
						,lpr.machine_id
						,lpr.qty_pass
						,lpr.is_special_flow
					FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
					INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = lpr.lot_id
					LEFT JOIN APCSProDB.method.packages AS mp WITH (NOLOCK) ON mp.id = tl.act_package_id
					LEFT JOIN APCSProDB.method.package_groups AS pg WITH (NOLOCK) ON pg.id = mp.package_group_id
					WHERE lpr.day_id BETWEEN @fr_date
							AND @to_date
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
						AND lpr.process_id IN (
							2
							,3
							,4
							,8
							,9
							,10
							)
						AND lpr.record_class NOT IN (
							20
							,25
							,26
							,5
							,6
							)
						AND lpr.machine_id > 0
					) AS lpr2
				) AS lpr3
			WHERE rn = 1
			) AS lpr4
		INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = lpr4.day_id
		INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = lpr4.act_device_name_id
		INNER JOIN APCSProDB.method.packages AS mp WITH (NOLOCK) ON mp.id = lpr4.package_id
		LEFT JOIN APCSProDB.method.package_groups AS pg WITH (NOLOCK) ON pg.id = mp.package_group_id
		INNER JOIN APCSProDB.method.processes AS pr WITH (NOLOCK) ON pr.id = lpr4.process_id
		INNER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.id = lpr4.job_id
		INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = lpr4.machine_id
		) AS lpr5
	WHERE started_at <> finished_at
	ORDER BY package_id
		,process_id
		,job_id
		,machine_id
		,started_at
		,lot_id

	SELECT t2.day_id
		,t2.date_value
		,t2.started_at
		,t2.finished_at
		,t2.lotstart_at AS lotstart_at
		,t2.onlinestart_at AS onlinestart_at
		,t2.onlineend_at AS onlineend_at
		,t2.lotend_at AS lotend_at
		,t2.process_minutes
		,t2.qty_pass
		,t2.lot_no
		,t2.device_name
		,t2.package_group_name
		,t2.package_name
		,t2.process_name
		,t2.job_name
		,t2.machine_name
		,t2.flow
		,t2.lot_id
		,t2.package_id
		,t2.process_id
		,t2.job_id
		,t2.machine_id
		,t2.process_job_id
		,t2.flag
	FROM (
		SELECT CASE 
				WHEN t1.next_started_at IS NULL
					THEN 0
				ELSE CASE 
						WHEN t1.finished_at > t1.next_started_at
							THEN 1
						ELSE 0
						END
				END AS flag
			,t1.*
		FROM (
			SELECT lead(t.started_at) OVER (
					PARTITION BY t.machine_id ORDER BY t.started_at
					) AS next_started_at
				,t.*
			FROM #table AS t
			) AS t1
		) AS t2
	ORDER BY package_id
		,process_id
		,job_id
		,machine_id
		,started_at
		,lot_id
END

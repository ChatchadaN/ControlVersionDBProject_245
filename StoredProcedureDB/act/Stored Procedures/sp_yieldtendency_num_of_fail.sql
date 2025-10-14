
CREATE PROCEDURE [act].[sp_yieldtendency_num_of_fail] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@machine_id INT = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2021-01-01 00:00:00'
	--DECLARE @date_to DATETIME = '2021-01-05 00:00:00'
	--DECLARE @time_offset INT = 0
	--DECLARE @package_id INT = 242
	--DECLARE @process_id INT = 9
	--DECLARE @job_id INT = NULL
	--DECLARE @machine_id INT = NULL
	DECLARE @local_date_from DATETIME = dateadd(hour, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = dateadd(hour, @time_offset, dateadd(day, 1, @date_to))
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

	SELECT lpr.id
		,lpr.day_id
		,dd.date_value
		,lpr.recorded_at
		,DATEDIFF(s, @date_from, lpr.recorded_at) AS time_val
		,lpr.operated_by
		,lpr.record_class
		,lpr.lot_id
		,tl.lot_no
		,tl.act_package_id AS package_id
		,tl.act_device_name_id AS device_name_id
		,lpr.process_id
		,lpr.job_id
		,lpr.step_no
		,lpr.qty_in
		--工程投入数量
		,lpr.qty_pass_step_sum + lpr.qty_fail_step_sum AS step_qty_in
		--工程良品数
		,lpr.qty_pass_step_sum
		--工程NG数
		,lpr.qty_fail_step_sum
		--累積NG数
		,lpr.qty_fail
		,lpr.is_special_flow
		--工程歩留まり[%]
		,convert(DECIMAL(9, 1), lpr.qty_pass_step_sum) / nullif((lpr.qty_pass_step_sum + lpr.qty_fail_step_sum), 0) * 100 AS yield
		--全体歩留まり[%]
		,convert(DECIMAL(9, 1), lpr.qty_pass) / nullif((lpr.qty_pass + lpr.qty_fail), 0) * 100 AS yield_sum
		,lpr.machine_id
	INTO #table
	FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
	INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = lpr.lot_id
	INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
	INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = lpr.day_id
	WHERE lpr.recorded_at BETWEEN @local_date_from
			AND @local_date_to
		AND (
			(
				@package_id IS NULL
				AND tl.act_package_id > 0
				)
			OR (
				@package_id IS NOT NULL
				AND tl.act_package_id = @package_id
				)
			)
		AND (
			(
				@process_id IS NULL
				AND lpr.process_id > 0
				)
			OR (
				@process_id IS NOT NULL
				AND lpr.process_id = @process_id
				)
			)
		AND (
			(
				@device_name IS NOT NULL
				AND dn.name = @device_name
				)
			OR (@device_name IS NULL)
			)
		AND (
			(
				@machine_id IS NULL
				AND lpr.machine_id > 0
				)
			OR (
				@machine_id IS NOT NULL
				AND lpr.machine_id = @machine_id
				)
			)
		AND (
			(
				lpr.record_class = 2
				AND lpr.is_special_flow = 0
				)
			OR (
				--lpr.record_class = 26
				lpr.record_class = 2
				AND lpr.is_special_flow = 1
				)
			)

	------group by process
	IF @process_id IS NULL
	BEGIN
		SELECT t2.day_id
			,t2.date_value
			,t2.process_id
			,NULL AS job_id
			,t2.machine_id
			,mp.name AS process_name
			,NULL AS job_name
			,mm.name AS machine_name
			,dense_rank() OVER (
				ORDER BY t2.process_id
				) AS prc_rank
			,NULL AS job_rank
			,dense_rank() OVER (
				PARTITION BY t2.process_id ORDER BY t2.machine_id
				) AS mc_rank_prc
			,NULL AS mc_rank_job
			,sum_of_fail AS sum_of_fail
			,sum(sum_of_fail) OVER (
				PARTITION BY t2.process_id
				,t2.machine_id ORDER BY t2.day_id
				) AS accum_of_fail
		FROM (
			SELECT t1.day_id
				,t1.date_value
				,t1.process_id
				,t1.machine_id
				,sum(t1.qty_fail_step_sum) AS sum_of_fail
			FROM #table AS t1
			GROUP BY t1.day_id
				,t1.date_value
				,t1.process_id
				,t1.machine_id
			) AS t2
		INNER JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = t2.process_id
		INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = t2.machine_id
		ORDER BY day_id
			,process_id
			,machine_id
	END

	------group by job
	IF @process_id IS NOT NULL
	BEGIN
		SELECT t2.day_id
			,t2.date_value
			,t2.process_id AS process_id
			,t2.job_id
			,t2.machine_id
			,mp.name AS process_name
			,mj.name AS job_name
			,mm.name AS machine_name
			,NULL AS prc_rank
			,dense_rank() OVER (
				ORDER BY t2.job_id
				) AS job_rank
			,NULL AS mc_rank_prc
			,dense_rank() OVER (
				PARTITION BY t2.job_id ORDER BY t2.machine_id
				) AS mc_rank_job
			,sum_of_fail AS sum_of_fail
			,sum(sum_of_fail) OVER (
				PARTITION BY t2.job_id
				,t2.machine_id ORDER BY t2.day_id
				) AS accum_of_fail
		FROM (
			SELECT t1.day_id
				,t1.date_value
				,t1.process_id
				,t1.job_id
				,t1.machine_id
				,sum(t1.qty_fail_step_sum) AS sum_of_fail
			FROM #table AS t1
			GROUP BY t1.day_id
				,t1.date_value
				,t1.process_id
				,t1.job_id
				,t1.machine_id
			) AS t2
		INNER JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = t2.process_id
		INNER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.id = t2.job_id
		INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = t2.machine_id
		ORDER BY day_id
			,process_id
			,job_id
			,machine_id
	END
END

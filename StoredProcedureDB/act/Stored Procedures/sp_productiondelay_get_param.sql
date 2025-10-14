
CREATE PROCEDURE [act].[sp_productiondelay_get_param] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_name VARCHAR(32) = NULL
	,@lot_type VARCHAR(32) = NULL
	)
AS
BEGIN
	SELECT convert(INT, isnull(floor(t4.minX), 0)) AS minVal
		,convert(INT, isnull(ceiling(t4.maxX), 0)) AS maxVal
		,convert(INT, isnull(ceiling((t4.maxX - t4.minX) / (SQRT(n))), - 1)) AS widVal
	FROM (
		SELECT nullif(sum(t3.lot), 0) AS n
			,max(t3.diff_bucket) AS maxX
			,min(t3.diff_bucket) AS minX
		FROM (
			SELECT t2.*
				,1 AS lot
			FROM (
				SELECT t1.*
					,(convert(FLOAT, DATEDIFF(hh, t1.pass_plan_time_up, GETDATE())) / 24.0) AS diff_bucket
				FROM (
					SELECT tl.id AS id
						,tl.lot_no AS lot_no
						,pg.id AS package_group_id
						,pg.name AS package_group_name
						,tl.act_package_id AS package_id
						,pk.name AS package_name
						,tl.act_process_id AS process_id
						,pr.name AS process_name
						,tl.act_job_id AS job_id
						,jb.name AS job_name
						,tl.act_device_name_id AS device_name_id
						,tl.device_slip_id AS device_slip_id
						,tl.wip_state AS wip_state
						,tl.pass_plan_time AS pass_plan_time
						,tl.pass_plan_time_up AS pass_plan_time_up
					FROM APCSProDB.trans.lots AS tl WITH (NOLOCK)
					LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS pk WITH (NOLOCK) ON pk.id = tl.act_package_id
					LEFT OUTER JOIN APCSProDWH.dwh.dim_package_groups AS pg WITH (NOLOCK) ON pg.id = pk.package_group_id
					LEFT OUTER JOIN apcsprodwh.dwh.dim_processes AS pr WITH (NOLOCK) ON pr.id = tl.act_process_id
					LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS jb WITH (NOLOCK) ON jb.id = tl.act_job_id
					) AS t1
				WHERE t1.wip_state = 20
					AND (
						(
							@lot_type IS NOT NULL
							AND substring(t1.lot_no, 5, 1) = @lot_type
							)
						OR (@lot_type IS NULL)
						)
					AND (
						(
							@package_id IS NOT NULL
							AND t1.package_id = @package_id
							)
						OR (
							@package_id IS NULL
							AND @package_group_id IS NOT NULL
							AND t1.package_group_id = @package_group_id
							)
						OR (
							@package_id IS NULL
							AND @package_group_id IS NULL
							AND t1.package_id > 0
							)
						)
					AND (
						(
							(@device_name IS NOT NULL)
							AND t1.device_name_id IN (
								SELECT id
								FROM APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK)
								WHERE dd.name = @device_name
								)
							)
						OR (
							@device_name IS NULL
							AND t1.device_name_id > 0
							)
						)
					AND (
						(
							@process_id IS NOT NULL
							AND t1.process_id = @process_id
							)
						OR (@process_id IS NULL)
						)
				) AS t2
			WHERE t2.diff_bucket >= 0
			) AS t3
		) AS t4
END

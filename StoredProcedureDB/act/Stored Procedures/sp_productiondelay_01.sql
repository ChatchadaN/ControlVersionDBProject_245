
CREATE PROCEDURE [act].[sp_productiondelay_01] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_name VARCHAR(32) = NULL
	,@max_rank INT = 10
	,@min_rank INT = 0
	,@span INT = NULL
	,@lot_type VARCHAR(32) = NULL
	,@bin_type VARCHAR(32) = NULL
	)
AS
BEGIN
	DECLARE @width INT = (
			CASE 
				WHEN @bin_type = 'width'
					THEN @span * 1000
				WHEN @bin_type = 'number'
					THEN ((@max_rank - @min_rank) * 1000 / @span)
				END
			)

	SELECT t3.*
		,
		--dense_rank() OVER (
		--	ORDER BY t3.bucket
		--	) AS rank_bucket,
		t3.bucket AS rank_bucket
		,ROW_NUMBER() OVER (
			PARTITION BY t3.process_id
			,t3.bucket ORDER BY t3.id
			) AS rank_process
		,sum(t3.lot) OVER (
			PARTITION BY t3.process_id
			,t3.bucket
			) AS lots_per_process
		,sum(isnull(convert(DECIMAL, t3.qty_in) / 1000, 0)) OVER (
			PARTITION BY t3.process_id
			,t3.bucket
			) AS kpcs_per_process
		,ROW_NUMBER() OVER (
			PARTITION BY t3.job_id
			,t3.bucket ORDER BY t3.id
			) AS rank_job
		,sum(t3.lot) OVER (
			PARTITION BY t3.job_id
			,t3.bucket
			) AS lots_per_job
		,sum(isnull(convert(DECIMAL, t3.qty_in) / 1000, 0)) OVER (
			PARTITION BY t3.job_id
			,t3.bucket
			) AS kpcs_per_job
	INTO #table
	FROM (
		SELECT t2.*
			,1 AS lot
		FROM (
			SELECT t1.*
				,convert(INT, floor(convert(FLOAT, DATEDIFF(hh, t1.pass_plan_time_up, GETDATE())) / 24.0 * 1000)) AS diff_bucket
				,(convert(INT, floor(convert(FLOAT, DATEDIFF(hh, t1.pass_plan_time_up, GETDATE())) / 24.0 * 1000)) - @min_rank * 1000) / @width AS bucket
			FROM (
				SELECT tl.id AS id
					,tl.lot_no AS lot_no
					,tl.order_id AS order_id
					,tl.product_family_id AS product_family_id
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
					,tl.qty_in AS qty_in
					,tl.wip_state AS wip_state
					,tl.process_state AS process_state
					,tl.quality_state AS quality_state
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
	WHERE (@min_rank * 1000 < t3.diff_bucket)
		AND (t3.diff_bucket < @max_rank * 1000)

	--for histogram chart
	-- all data
	SELECT *
		,isnull(convert(DECIMAL, diff_bucket) / 1000, 0) AS delay_day
		,dd.name AS device_name
		,ao.order_no AS order_no
	FROM #table AS t
	LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = t.device_name_id
	LEFT OUTER JOIN APCSProDB.robin.assy_orders AS ao WITH (NOLOCK) ON ao.id = t.order_id
	ORDER BY delay_day DESC;

	--Process data
	IF @process_id IS NULL
	BEGIN
		SELECT *
		FROM #table
		WHERE rank_process = 1
		ORDER BY rank_bucket
			,process_id;
	END
			--Job data
	ELSE
	BEGIN
		SELECT *
		FROM #table
		WHERE rank_job = 1
		ORDER BY rank_bucket
			,job_id;
	END

	--for x-axis
	--case package selected
	IF @package_group_id IS NOT NULL
		OR @package_id IS NOT NULL
	BEGIN
		-- x axis process
		SELECT p.process_id AS process_id
			,p.process_name AS process_name
		FROM (
			SELECT pg.id AS package_group_id
				,pp.package_id AS package_id
				,pp.process_id AS process_id
				,pp.process_name AS process_name
				,pp.process_no AS process_no
			FROM APCSProDWH.dwh.dim_package_processes AS pp WITH (NOLOCK)
			LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS pk WITH (NOLOCK) ON pk.id = pp.package_id
			LEFT OUTER JOIN apcsprodwh.dwh.dim_package_groups AS pg WITH (NOLOCK) ON pg.id = pk.package_group_id
			) AS p
		WHERE (
				(
					@package_id IS NOT NULL
					AND p.package_id = @package_id
					)
				OR (
					@package_id IS NULL
					AND @package_group_id IS NOT NULL
					AND p.package_group_id = @package_group_id
					)
				OR (
					@package_id IS NULL
					AND @package_group_id IS NULL
					AND p.package_id > 0
					)
				)
		GROUP BY p.process_id
			,p.process_name
			,p.process_no
		ORDER BY p.process_no;

		-- x axis job
		SELECT j.job_id AS job_id
			,j.job_name AS job_name
		FROM (
			SELECT pg.id AS package_group_id
				,pj.*
			FROM APCSProDWH.dwh.dim_package_jobs AS pj WITH (NOLOCK)
			LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS pk WITH (NOLOCK) ON pk.id = pj.package_id
			LEFT OUTER JOIN APCSProDWH.dwh.dim_package_groups AS pg WITH (NOLOCK) ON pg.id = pk.package_group_id
			) AS j
		WHERE (
				(
					@package_id IS NOT NULL
					AND j.package_id = @package_id
					)
				OR (
					@package_id IS NULL
					AND @package_group_id IS NOT NULL
					AND j.package_group_id = @package_group_id
					)
				OR (
					@package_id IS NULL
					AND @package_group_id IS NULL
					AND j.package_id > 0
					)
				)
			AND (
				(
					@process_id IS NOT NULL
					AND j.process_id = @process_id
					)
				OR (@process_id IS NULL)
				)
		GROUP BY j.job_id
			,j.job_name
			,j.process_no
			,j.job_no
		ORDER BY j.process_no
			,j.job_no
	END
			-- package not selected
	ELSE
	BEGIN
		-- x axis process
		SELECT process_id AS process_id
			,process_name AS process_name
		FROM #table
		GROUP BY process_id
			,process_name;

		-- x axis job
		SELECT job_id AS job_id
			,job_name AS job_name
		FROM #table
		GROUP BY job_id
			,job_name;
	END
END


CREATE PROCEDURE [act].[sp_machine_commonfilter_mc] @package_group_id INT = NULL,
	@package_id INT = NULL,
	@process_id INT = NULL,
	@job_id INT = NULL,
	@machine_group_id INT = NULL,
	@machine_model_id INT = NULL
AS
BEGIN
	SELECT dp.package_group_id AS package_group_id,
		dpg.name AS package_group_name,
		pp.package_id AS package_id,
		dp.name AS package_name,
		pp.process_id AS process_id,
		pp.process_no AS process_no,
		dpr.name AS process_name,
		isnull(pj.job_id, 0) AS job_id,
		isnull(pj.job_no, 0) AS job_no,
		isnull(dj.name, 'Unknown') AS job_name,
		mj.machine_group_id AS machine_group_id,
		gm.model_id AS machine_model_id,
		mgr.name AS machine_group_name,
		mml.name AS machine_model_name,
		mj.is_skipped AS is_skipped
	INTO #table
	FROM APCSProDWH.dwh.dim_package_processes AS pp WITH (NOLOCK)
	LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = pp.package_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_package_groups AS dpg WITH (NOLOCK) ON dpg.id = dp.package_group_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dpr WITH (NOLOCK) ON dpr.id = pp.process_id
	INNER JOIN APCSProDWH.dwh.dim_package_jobs AS pj WITH (NOLOCK) ON pj.process_id = pp.process_id
		AND pj.package_id = pp.package_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = pj.job_id
	LEFT OUTER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.id = pj.job_id
		AND mj.process_id = pj.process_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_mc_group_models AS gm WITH (NOLOCK) ON gm.group_id = mj.machine_group_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_machine_groups AS mgr WITH (NOLOCK) ON mgr.id = gm.group_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_machine_models AS mml WITH (NOLOCK) ON mml.id = gm.model_id

	--Package Group
	SELECT t2.package_group_id AS id,
		t2.package_group_name AS name
	FROM #table AS t2
	GROUP BY t2.package_group_id,
		t2.package_group_name
	ORDER BY name;

	--Package
	SELECT t2.package_id AS id,
		t2.package_name AS name
	FROM #table AS t2
	WHERE (
			(
				@package_group_id IS NOT NULL
				AND t2.package_group_id = @package_group_id
				)
			OR (
				@package_group_id IS NULL
				AND t2.package_group_id >= 0
				)
			)
		AND (
			(
				@process_id IS NOT NULL
				AND t2.process_id = @process_id
				)
			OR (
				@process_id IS NULL
				AND t2.process_id >= 0
				)
			)
		AND (
			(
				@job_id IS NOT NULL
				AND t2.job_id = @job_id
				)
			OR (
				@job_id IS NULL
				AND t2.job_id >= 0
				)
			)
		AND (
			(
				@machine_model_id IS NOT NULL
				AND t2.machine_model_id = @machine_model_id
				)
			OR (
				@machine_model_id IS NULL
				AND (
					t2.machine_model_id >= 0
					OR t2.machine_model_id IS NULL
					)
				)
			)
		AND (
			(
				@machine_group_id IS NOT NULL
				AND t2.machine_group_id = @machine_group_id
				)
			OR (
				@machine_group_id IS NULL
				AND (
					t2.machine_group_id >= 0
					OR t2.machine_group_id IS NULL
					)
				)
			)
	GROUP BY t2.package_id,
		t2.package_name
	ORDER BY name;

	--Process
	SELECT t2.process_id AS id,
		t2.process_name AS name,
		t2.process_no AS process_no
	FROM #table AS t2
	WHERE (
			(
				@package_group_id IS NOT NULL
				AND t2.package_group_id = @package_group_id
				)
			OR (
				@package_group_id IS NULL
				AND t2.package_group_id >= 0
				)
			)
		AND (
			(
				@package_id IS NOT NULL
				AND t2.package_id = @package_id
				)
			OR (
				@package_id IS NULL
				AND t2.package_id >= 0
				)
			)
		AND (
			(
				@job_id IS NOT NULL
				AND t2.job_id = @job_id
				)
			OR (
				@job_id IS NULL
				AND t2.job_id >= 0
				)
			)
		AND (
			(
				@machine_model_id IS NOT NULL
				AND t2.machine_model_id = @machine_model_id
				)
			OR (
				@machine_model_id IS NULL
				AND (
					t2.machine_model_id >= 0
					OR t2.machine_model_id IS NULL
					)
				)
			)
		AND (
			(
				@machine_group_id IS NOT NULL
				AND t2.machine_group_id = @machine_group_id
				)
			OR (
				@machine_group_id IS NULL
				AND (
					t2.machine_group_id >= 0
					OR t2.machine_group_id IS NULL
					)
				)
			)
	GROUP BY t2.process_id,
		t2.process_name,
		t2.process_no
	ORDER BY t2.process_no;

	--job
	SELECT t2.job_id AS id,
		t2.job_name AS name,
		t2.process_no AS process_no,
		t2.job_no AS job_no
	FROM #table AS t2
	WHERE (
			(
				@package_group_id IS NOT NULL
				AND t2.package_group_id = @package_group_id
				)
			OR (
				@package_group_id IS NULL
				AND t2.package_group_id >= 0
				)
			)
		AND (
			(
				@package_id IS NOT NULL
				AND t2.package_id = @package_id
				)
			OR (
				@package_id IS NULL
				AND t2.package_id >= 0
				)
			)
		AND (
			(
				@process_id IS NOT NULL
				AND t2.process_id = @process_id
				)
			OR (
				@process_id IS NULL
				AND t2.process_id >= 0
				)
			)
		AND t2.is_skipped = 0
		AND (
			(
				@machine_model_id IS NOT NULL
				AND t2.machine_model_id = @machine_model_id
				)
			OR (
				@machine_model_id IS NULL
				AND (
					t2.machine_model_id >= 0
					OR t2.machine_model_id IS NULL
					)
				)
			)
		AND (
			(
				@machine_group_id IS NOT NULL
				AND t2.machine_group_id = @machine_group_id
				)
			OR (
				@machine_group_id IS NULL
				AND (
					t2.machine_group_id >= 0
					OR t2.machine_group_id IS NULL
					)
				)
			)
	GROUP BY t2.job_id,
		t2.job_name,
		t2.process_no,
		t2.job_no
	ORDER BY t2.process_no,
		t2.job_no;

	--Location
	SELECT dl.id AS id,
		dl.name AS location_name
	FROM APCSProDWH.dwh.dim_locations AS dl
	ORDER BY dl.name;

	--Machine Group
	SELECT t2.machine_group_id AS id,
		t2.machine_group_name AS name
	FROM #table AS t2
	WHERE (
			(
				@package_group_id IS NOT NULL
				AND t2.package_group_id = @package_group_id
				)
			OR (
				@package_group_id IS NULL
				AND t2.package_group_id >= 0
				)
			)
		AND (
			(
				@package_id IS NOT NULL
				AND t2.package_id = @package_id
				)
			OR (
				@package_id IS NULL
				AND t2.package_id >= 0
				)
			)
		AND (
			(
				@job_id IS NOT NULL
				AND t2.job_id = @job_id
				)
			OR (
				@job_id IS NULL
				AND t2.job_id >= 0
				)
			)
		AND (
			(
				@machine_model_id IS NOT NULL
				AND t2.machine_model_id = @machine_model_id
				)
			OR (
				@machine_model_id IS NULL
				AND t2.machine_model_id >= 0
				)
			)
		AND (
			(
				@machine_group_id IS NOT NULL
				AND t2.machine_group_id = @machine_group_id
				)
			OR (
				@machine_group_id IS NULL
				AND t2.machine_group_id >= 0
				)
			)
	GROUP BY t2.machine_group_id,
		t2.machine_group_name
	ORDER BY t2.machine_group_name;

	--Machine Model
	SELECT t2.machine_model_id AS id,
		t2.machine_model_name AS name
	FROM #table AS t2
	WHERE (
			(
				@package_group_id IS NOT NULL
				AND t2.package_group_id = @package_group_id
				)
			OR (
				@package_group_id IS NULL
				AND t2.package_group_id >= 0
				)
			)
		AND (
			(
				@package_id IS NOT NULL
				AND t2.package_id = @package_id
				)
			OR (
				@package_id IS NULL
				AND t2.package_id >= 0
				)
			)
		AND (
			(
				@job_id IS NOT NULL
				AND t2.job_id = @job_id
				)
			OR (
				@job_id IS NULL
				AND t2.job_id >= 0
				)
			)
		AND (
			(
				@machine_model_id IS NOT NULL
				AND t2.machine_model_id = @machine_model_id
				)
			OR (
				@machine_model_id IS NULL
				AND t2.machine_model_id >= 0
				)
			)
		AND (
			(
				@machine_group_id IS NOT NULL
				AND t2.machine_group_id = @machine_group_id
				)
			OR (
				@machine_group_id IS NULL
				AND t2.machine_group_id >= 0
				)
			)
	GROUP BY t2.machine_model_id,
		t2.machine_model_name
	ORDER BY t2.machine_model_name;
END

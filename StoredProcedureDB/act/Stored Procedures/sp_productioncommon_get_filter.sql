
CREATE PROCEDURE [act].[sp_productioncommon_get_filter] (
	@package_group_id INT = NULL,
	@package_id INT = NULL,
	@process_id INT = NULL,
	@job_id INT = NULL
	)
AS
BEGIN
	SELECT t1.package_group_id AS package_group_id,
		t1.package_group_name AS package_group_name,
		t1.package_id AS package_id,
		t1.package_name AS package_name,
		t1.process_id AS process_id,
		t1.process_no AS process_no,
		t1.process_name AS process_name,
		t1.job_id AS job_id,
		t1.job_no AS job_no,
		t1.job_name AS job_name,
		t1.is_skipped AS is_skipped
	INTO #table
	FROM (
		SELECT dp.package_group_id AS package_group_id,
			dpg.name AS package_group_name,
			dj.package_id AS package_id,
			dp.name AS package_name,
			dj.process_id AS process_id,
			dj.process_no AS process_no,
			dj.process_name AS process_name,
			dj.job_id AS job_id,
			dj.job_no AS job_no,
			isnull(dj.job_name, 'Unknown') AS job_name,
			isnull(dj.is_skipped, 0) AS is_skipped
		FROM APCSProDWH.dwh.dim_package_jobs AS dj WITH (NOLOCK)
		inner JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = dj.package_id
		inner JOIN APCSProDWH.dwh.dim_package_groups AS dpg WITH (NOLOCK) ON dpg.id = dp.package_group_id
		--LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dpr WITH (NOLOCK) ON dpr.id = dj.process_id
		--LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS mj WITH (NOLOCK) ON mj.id = dj.job_id
		) AS t1
	WHERE t1.process_id IS NOT NULL
		AND t1.job_id IS NOT NULL
		AND t1.process_no IS NOT NULL
		AND t1.process_no <> ''
		;

	SELECT t2.package_group_id AS id,
		t2.package_group_name AS name
	FROM #table AS t2
	GROUP BY t2.package_group_id,
		t2.package_group_name
	ORDER BY name;

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
	GROUP BY t2.package_id,
		t2.package_name
	ORDER BY name;

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
		and t2.is_skipped = 0
	GROUP BY t2.process_id,
		t2.process_name,
		t2.process_no
	ORDER BY t2.process_no;

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
	GROUP BY t2.job_id,
		t2.job_name,
		t2.process_no,
		t2.job_no
	ORDER BY t2.process_no,
		t2.job_no;

	SELECT process_id AS process_id,
		process_no AS process_no,
		job_id AS job_id,
		job_no AS job_no
	FROM (
		SELECT t1.*
		FROM #table AS t1
		WHERE (
				(
					@package_id IS NOT NULL
					AND package_id = @package_id
					)
				OR (
					@package_id IS NULL
					AND @package_group_id IS NOT NULL
					AND package_group_id = @package_group_id
					)
				OR (
					@package_id IS NULL
					AND @package_group_id IS NULL
					AND package_id > 0
					)
				)
			AND (
				(
					@process_id IS NOT NULL
					AND process_id = @process_id
					)
				OR (
					@process_id IS NULL
					AND process_id >= 0
					)
				)
			AND t1.is_skipped = 0
		) AS t2
	GROUP BY process_id,
		process_no,
		job_id,
		job_no
	ORDER BY t2.process_no,
		t2.job_no;
END


CREATE PROCEDURE [act].[sp_productionmrp_latest_fact_end] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	)
AS
BEGIN
	SELECT t1.job_id AS job_id
		,t1.job_name AS job_name
		,sum(isnull(convert(FLOAT, t1.pass_pcs) / 1000, - 3)) AS sum_end_kpcs
		,SUM(t1.lot) AS sum_end_lot
	FROM (
		SELECT fe.job_id AS job_id
			,dj.name AS job_name
			,fe.pass_pcs AS pass_pcs
			,1 AS lot
		FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
		LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fe.device_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = fe.job_id
		WHERE (
				(
					(
						@package_id IS NULL
						AND @package_group_id IS NOT NULL
						AND fe.package_group_id = @package_group_id
						)
					OR (
						@package_id IS NULL
						AND @package_group_id IS NULL
						AND fe.package_id > 0
						)
					)
				OR (
					(@package_id IS NOT NULL)
					AND (fe.package_id = @package_id)
					)
				)
			AND (
				(
					day_id = (
						SELECT finished_day_id - 1
						FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
						WHERE to_fact_table = 'dwh.fact_end'
						)
					AND hour_code > (
						SELECT finished_hour_code
						FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
						WHERE to_fact_table = 'dwh.fact_end'
						)
					)
				OR day_id = (
					SELECT finished_day_id
					FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
					WHERE to_fact_table = 'dwh.fact_end'
					)
				)
			AND (
				(
					@device_name IS NOT NULL
					AND ddv.name = @device_name
					)
				OR (@device_name IS NULL)
				)
		) AS t1
	GROUP BY t1.job_id
		,t1.job_name
	ORDER BY t1.job_id
END

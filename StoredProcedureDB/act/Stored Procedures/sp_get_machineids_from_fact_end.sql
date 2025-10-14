
CREATE PROCEDURE [act].[sp_get_machineids_from_fact_end] (
	@from_at DATE,
	@to_at DATE,
	@package_id INT = NULL,
	@process_id INT = NULL,
	@job_id INT = NULL
	)
AS
BEGIN
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd
			WHERE date_value = @from_at
			)
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd
			WHERE date_value = @to_at
			)

	SELECT STRING_AGG(machine_id, ',') within
	GROUP (
			ORDER BY machine_id
			) AS machine_ids
	FROM (
		SELECT fe.machine_id AS machine_id,
			isnull(dm.name, 'machine name unkown') AS machine_name
		FROM APCSProDWH.dwh.fact_end AS fe
		LEFT OUTER JOIN APCSProDB.mc.machines AS dm WITH (NOLOCK) ON dm.id = fe.machine_id
		WHERE fe.machine_id > 0 and 
			(
				(
					@package_id IS NOT NULL
					AND fe.package_id = @package_id
					)
				OR (
					@package_id IS NULL
					AND fe.package_id > 0
					)
				)
			AND (
				(
					@process_id IS NOT NULL
					AND fe.process_id = @process_id
					)
				OR (
					@process_id IS NULL
					AND fe.process_id >= 0
					)
				)
			AND (
				(
					@job_id IS NOT NULL
					AND fe.job_id = @job_id
					)
				OR (
					@job_id IS NULL
					AND fe.job_id > 0
					)
				)
			AND @from <= fe.day_id
			AND fe.day_id <= @to
		GROUP BY fe.machine_id,
			dm.name
		) AS t1
END

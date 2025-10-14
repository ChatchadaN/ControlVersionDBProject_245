
CREATE PROCEDURE [act].[sp_machinealarminprocess_pareto] (
	@package_group_id INT = NULL,
	@package_id INT = NULL,
	@process_id INT = NULL,
	@job_id INT = NULL,
	@date_from DATE,
	@date_to DATE,
	@alarm_unit BIT
	)
AS
BEGIN

declare @datetime_to datetime = dateadd(day,1, convert(datetime, @date_to));

SELECT t3.*
FROM (
	SELECT t2.*,
		CONVERT(DECIMAL(4, 1), sum(convert(FLOAT, t2.alarm_times) * 100 / t2.all_alarm_times) OVER (
				ORDER BY t2.alarm_times DESC rows unbounded preceding
				)) AS percent_alarm_times,
		CONVERT(DECIMAL(4, 1), sum(t2.alarm_duration * 100 / t2.all_alarm_duration) OVER (
				ORDER BY t2.alarm_duration DESC rows unbounded preceding
				)) AS percent_alarm_duration
	FROM (
		SELECT t1.*,
			sum(t1.alarm_times) OVER (PARTITION BY t1.const) AS all_alarm_times,
			sum(t1.alarm_duration) OVER (PARTITION BY t1.const) AS all_alarm_duration,
			sum(t1.alarm_duration_after_off) OVER (PARTITION BY t1.const) AS all_alarm_duration_after_off
		FROM (
			SELECT ma.alarm_code,
				tx.alarm_text
				--,m.name as machine_name
				,
				count(a.id) AS alarm_times,
				isnull(convert(DECIMAL(9, 1), sum(convert(DECIMAL, datediff(SECOND, a.alarm_on_at, a.started_at)) / 60 / 60)),0.0) AS alarm_duration,
				isnull(convert(DECIMAL(9, 1), sum(convert(DECIMAL, datediff(SECOND, a.alarm_off_at, a.started_at)) / 60 / 60)),0.0) AS alarm_duration_after_off,
				1 AS const
			FROM apcsprodb.trans.machine_alarm_records AS a with (nolock)
			INNER JOIN apcsprodb.mc.model_alarms AS ma with (nolock) ON ma.id = a.model_alarm_id
			INNER JOIN apcsprodb.mc.alarm_texts AS tx with (nolock) ON tx.alarm_text_id = ma.alarm_text_id
			INNER JOIN apcsprodb.mc.machines AS m with (nolock) ON m.id = a.machine_id
			WHERE a.machine_id IN (
					SELECT
						--md.id as machine_model_id, 
						--md.name as machine_model,
						m.id AS machine_id
					--,m.name as machine_name
					FROM apcsprodb.trans.lots AS l with (nolock)
					INNER JOIN apcsprodb.trans.lot_process_records AS r with (nolock) ON r.lot_id = l.id
						AND r.record_class = 1
					INNER JOIN apcsprodb.mc.machines AS m with (nolock) ON m.id = r.machine_id
					INNER JOIN apcsprodb.mc.models AS md with (nolock) ON md.id = m.machine_model_id
					LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS dp with (nolock) ON dp.id = l.act_package_id
					WHERE
						--l.act_package_id = @package_id
						(
							(
								@package_id IS NOT NULL
								AND l.act_package_id = @package_id
								)
							OR (
								@package_id IS NULL
								AND @package_group_id IS NOT NULL
								AND dp.package_group_id = @package_group_id
								)
							OR (
								@package_id IS NULL
								AND @package_group_id IS NULL
								AND l.act_package_id > 0
								)
							)
						AND (
							(
								@process_id IS NOT NULL
								AND r.process_id = @process_id
								)
							OR (
								@process_id IS NULL
								AND r.process_id >= 0
								)
							)
						AND (
							(
								@job_id IS NOT NULL
								AND r.job_id = @job_id
								)
							OR (
								@job_id IS NULL
								AND r.job_id >= 0
								)
							)
						--AND r.job_id IN (@job_id)
						AND r.recorded_at >= @date_from
						AND r.recorded_at < @datetime_to
					GROUP BY
						--md.id,
						--md.name,
						m.id
						--,m.name
					)
				AND a.alarm_on_at >= @date_from
				AND a.alarm_on_at < @datetime_to
				AND ma.alarm_level = 0
			GROUP BY ma.alarm_code,
				tx.alarm_text
				--,m.name 
			) AS t1
		) AS t2
	) AS t3
ORDER BY CASE 
		WHEN @alarm_unit = 0
			THEN t3.percent_alarm_times
		END ASC,
	 CASE 
		WHEN @alarm_unit = 0
			THEN t3.alarm_times
		END desc,
	CASE 
		WHEN @alarm_unit = 1
			THEN t3.alarm_duration
		END desc,
		CASE 
		WHEN @alarm_unit = 1
			THEN t3.percent_alarm_duration
		END ASC,
	t3.alarm_code

END

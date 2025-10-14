
CREATE PROCEDURE [act].[sp_machinealarminprocess_pareto_detail] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@date_from DATE
	,@date_to DATE
	,@alarm_unit BIT
	,@alarm_code VARCHAR(20)
	)
AS
BEGIN
	DECLARE @datetime_to DATETIME = dateadd(day, 1, convert(DATETIME, @date_to));

	SELECT t4.*
	FROM (
		SELECT t3.*
			,convert(DECIMAL(4, 1), sum(convert(FLOAT, t3.alarm_times) * 100 / nullif(t3.all_alarm_times, 0)) OVER (
					ORDER BY t3.alarm_times DESC rows unbounded preceding
					)) AS percent_alarm_times
			,CONVERT(DECIMAL(9, 1), sum(convert(FLOAT, t3.alarm_duration) * 100 / nullif(t3.all_alarm_duration, 0)) OVER (
					ORDER BY t3.alarm_duration DESC rows unbounded preceding
					)) AS percent_alarm_duration
			,CONVERT(DECIMAL(9, 1), sum(convert(FLOAT, t3.alarm_duration_after_off) * 100 / nullif(t3.all_alarm_duration_after_off, 0)) OVER (
					ORDER BY t3.alarm_duration_after_off DESC rows unbounded preceding
					)) AS percent_alarm_duration_after_off
		FROM (
			SELECT t2.alarm_code AS alarm_code
				,t2.alarm_text
				,t2.machine_id AS machine_id
				,t2.machine_name AS machine_name
				,t2.times_total AS all_alarm_times
				,t2.times AS alarm_times
				,isnull(t2.duration_total, 0) AS all_alarm_duration
				,isnull(t2.duration, 0) AS alarm_duration
				,isnull(t2.duration_after_off_total, 0) AS all_alarm_duration_after_off
				,isnull(t2.duration_after_off, 0) AS alarm_duration_after_off
			FROM (
				SELECT t1.*
					,sum(t1.times) OVER (PARTITION BY t1.alarm_code) AS times_total
					,sum(t1.duration) OVER (PARTITION BY t1.alarm_code) AS duration_total
					,sum(t1.duration_after_off) OVER (PARTITION BY t1.alarm_code) AS duration_after_off_total
				FROM (
					SELECT ma.alarm_code
						,tx.alarm_text
						,ml.machine_id AS machine_id
						,ml.machine_name AS machine_name
						,count(a.id) AS times
						,convert(DECIMAL(9, 1), sum(convert(DECIMAL, datediff(SECOND, a.alarm_on_at, a.started_at)) / 60 / 60)) AS duration
						,convert(DECIMAL(9, 1), sum(convert(DECIMAL, datediff(SECOND, a.alarm_off_at, a.started_at)) / 60 / 60)) AS duration_after_off
					FROM (
						SELECT md.id AS machine_model_id
							,
							--md.name as machine_model,
							m.id AS machine_id
							,m.name AS machine_name
						FROM apcsprodb.trans.lots AS l WITH (NOLOCK)
						INNER JOIN apcsprodb.trans.lot_process_records AS r WITH (NOLOCK) ON r.lot_id = l.id
							AND r.record_class = 1
						INNER JOIN apcsprodb.mc.machines AS m WITH (NOLOCK) ON m.id = r.machine_id
						INNER JOIN apcsprodb.mc.models AS md WITH (NOLOCK) ON md.id = m.machine_model_id
						WHERE l.act_package_id = @package_id
							--AND r.job_id IN (@job_id)
							AND r.recorded_at >= @date_from
							AND r.recorded_at < @datetime_to
							AND (
								(
									(@job_id IS NOT NULL)
									AND (r.job_id IN (@job_id))
									)
								OR (
									(@job_id IS NULL)
									AND (r.process_id = @process_id)
									)
								)
						GROUP BY md.id
							,
							--md.name,
							m.id
							,m.name
						) AS ml
					LEFT OUTER JOIN apcsprodb.mc.model_alarms AS ma WITH (NOLOCK) ON ma.machine_model_id = ml.machine_model_id
						AND ma.alarm_code = @alarm_code
					LEFT OUTER JOIN apcsprodb.mc.alarm_texts AS tx WITH (NOLOCK) ON tx.alarm_text_id = ma.alarm_text_id
					LEFT OUTER JOIN apcsprodb.trans.machine_alarm_records AS a WITH (NOLOCK) ON a.machine_id = ml.machine_id
						AND a.model_alarm_id = ma.id
						AND a.alarm_on_at >= @date_from
						AND a.alarm_on_at < @datetime_to
					GROUP BY ma.alarm_code
						,tx.alarm_text
						,ml.machine_id
						,ml.machine_name
					) AS t1
				) AS t2
			) AS t3
		) AS t4
	WHERE t4.alarm_code = @alarm_code
	ORDER BY CASE 
			WHEN @alarm_unit = 0
				THEN percent_alarm_times
			END ASC
		,CASE 
			WHEN @alarm_unit = 0
				THEN t4.alarm_times
			END DESC
		,CASE 
			WHEN @alarm_unit = 1
				THEN t4.alarm_duration
			END DESC
		,CASE 
			WHEN @alarm_unit = 1
				THEN t4.percent_alarm_duration
			END ASC
END

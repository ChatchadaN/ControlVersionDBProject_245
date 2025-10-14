
CREATE PROCEDURE [act].[sp_machinealarminprocess_datetime_map] (
	@machine_id INT = NULL,
	@date_from DATE,
	@date_to DATE,
	@alarm_code VARCHAR(20),
	@alarm_unit BIT
	)
AS
BEGIN

	declare @datetime_to datetime = convert(datetime,dateadd(day,1,@date_to));

	SELECT row_number() over(order by t2.date_value,t2.alarm_on_at) as pid, 
		t2.lot_id AS lot_id,
		t2.lot_no AS lot_no,
		t2.date_value AS date_value,
		t2.alarm_on_at AS alarm_on_at,
		t2.alarm_off_at AS alarm_off_at,
		t2.started_at AS started_at,
		t2.day_rank AS day_rank,
		--t2.alarm_date AS alarm_date,
		t2.alarm_hour AS alarm_hour,
		t2.alarm_minute AS alarm_minute,
		t2.x_point AS x_point,
		t2.y_point AS y_point,
		t2.day_id AS day_id,
		t2.hour_code AS hour_code,
		isnull(t2.alarm_times, 0) AS alarm_times,
		isnull(t2.alarm_duration, 0) AS alarm_duration,
		isnull(t2.alarm_duration_after_off, 0) AS alarm_duration_after_off,
		isnull(t2.sum_alarm_duration, 0) AS sum_alarm_duration,
		isnull(t2.sum_alarm_duration_after_off, 0) AS sum_alarm_duration_after_off,
		--0.25,0.5,0.75のpercentileに分類
		--duration size
		CASE 
			WHEN (t2.alarm_duration <= t2.duration_P25)
				THEN 1
			WHEN (
					t2.duration_P25 < t2.alarm_duration
					AND t2.alarm_duration <= t2.duration_P50
					)
				THEN 2
			WHEN (
					t2.duration_P50 < t2.alarm_duration
					AND t2.alarm_duration <= t2.duration_P75
					)
				THEN 3
			WHEN (
					t2.duration_P75 < t2.alarm_duration
					AND t2.alarm_duration < t2.duration_MAX
					)
				THEN 4
			WHEN (t2.alarm_duration = t2.duration_MAX)
				THEN 5
			END AS duration_size,
		--duration off size
		CASE 
			WHEN (t2.alarm_duration_after_off <= t2.duration_off_P25)
				THEN 1
			WHEN (
					t2.duration_off_P25 < t2.alarm_duration_after_off
					AND t2.alarm_duration_after_off <= t2.duration_off_P50
					)
				THEN 2
			WHEN (
					t2.duration_off_P50 < t2.alarm_duration_after_off
					AND t2.alarm_duration_after_off <= t2.duration_off_P75
					)
				THEN 3
			WHEN (
					t2.duration_off_P75 < t2.alarm_duration_after_off
					AND t2.alarm_duration_after_off < t2.duration_off_MAX
					)
				THEN 4
			WHEN (t2.alarm_duration_after_off = t2.duration_off_MAX)
				THEN 5
			END AS duration_off_size
	FROM (
		SELECT t1.lot_id AS lot_id,
			t1.lot_no AS lot_no,
			t1.date_value AS date_value,
			t1.alarm_on_at AS alarm_on_at,
			t1.alarm_off_at AS alarm_off_at,
			t1.started_at AS started_at,
			t1.day_rank AS day_rank,
			--t1.alarm_date AS alarm_date,
			t1.on_h AS alarm_hour,
			t1.on_m AS alarm_minute,
			(t1.day_id - (min(t1.day_id) OVER ()) + 1) AS x_point,
			convert(DECIMAL(4, 1), (t1.on_h + t1.on_m)) AS y_point,
			t1.day_id AS day_id,
			dh.code AS hour_code,
			t1.alarm_times AS alarm_times,
			t1.alarm_duration AS alarm_duration,
			t1.alarm_duration_after_off AS alarm_duration_after_off,
			t1.sum_alarm_duration AS sum_alarm_duration,
			t1.sum_alarm_duration_after_off AS sum_alarm_duration_after_off,
			--duration percentile
			PERCENTILE_CONT(0.25) WITHIN
		GROUP (
				ORDER BY t1.alarm_duration
				) OVER () AS duration_P25,
			PERCENTILE_CONT(0.5) WITHIN
		GROUP (
				ORDER BY t1.alarm_duration
				) OVER () AS duration_P50,
			PERCENTILE_CONT(0.75) WITHIN
		GROUP (
				ORDER BY t1.alarm_duration
				) OVER () AS duration_P75,
			max(t1.alarm_duration) OVER () AS duration_MAX,
			--duration_off percentile
			PERCENTILE_CONT(0.25) WITHIN
		GROUP (
				ORDER BY t1.alarm_duration_after_off
				) OVER () AS duration_off_P25,
			PERCENTILE_CONT(0.5) WITHIN
		GROUP (
				ORDER BY t1.alarm_duration_after_off
				) OVER () AS duration_off_P50,
			PERCENTILE_CONT(0.75) WITHIN
		GROUP (
				ORDER BY t1.alarm_duration_after_off
				) OVER () AS duration_off_P75,
			max(t1.alarm_duration_after_off) OVER () AS duration_off_MAX
		FROM (
			SELECT dd.id AS day_id,
				dd.date_value AS date_value,
				t.*,
				row_number() OVER (
					PARTITION BY dd.date_value ORDER BY (convert(DATE, t.alarm_on_at))
					) AS day_rank
			FROM APCSProDWH.dwh.dim_days AS dd with(nolock)
			LEFT OUTER JOIN (
				SELECT a.id AS record_id,
					r.lot_id AS lot_id,
					tl.lot_no AS lot_no,
					ma.alarm_code AS alarmcode,
					tx.alarm_text,
					m.id AS machineid,
					m.name AS machine,
					convert(DATE, a.alarm_on_at) AS alarm_date,
					a.alarm_on_at,
					DATEPART(hour, a.alarm_on_at) AS on_h,
					convert(DECIMAL(3, 1), DATEPART(MINUTE, a.alarm_on_at)) / 60 AS on_m,
					a.alarm_off_at,
					a.started_at,
					isnull(convert(DECIMAL(9, 1), datediff(SECOND, a.alarm_on_at, a.started_at)) / 60 / 60, 0.0) AS alarm_duration,
					isnull(convert(DECIMAL(9, 1), datediff(SECOND, a.alarm_off_at, a.started_at)) / 60 / 60, 0.0) AS alarm_duration_after_off,
					isnull(sum(convert(DECIMAL(9, 1), datediff(SECOND, a.alarm_on_at, a.started_at)) / 60 / 60) OVER (PARTITION BY convert(DATE, a.alarm_on_at)), 0.0) AS sum_alarm_duration,
					isnull(sum(convert(DECIMAL(9, 1), datediff(SECOND, a.alarm_off_at, a.started_at)) / 60 / 60) OVER (PARTITION BY convert(DATE, a.alarm_on_at)), 0.0) AS sum_alarm_duration_after_off,
					count(ma.alarm_code) OVER (PARTITION BY convert(DATE, a.alarm_on_at)) AS alarm_times
				FROM apcsprodb.trans.machine_alarm_records AS a with(nolock)
				INNER JOIN apcsprodb.mc.model_alarms AS ma with(nolock) ON ma.id = a.model_alarm_id
				INNER JOIN apcsprodb.mc.alarm_texts AS tx with(nolock) ON tx.alarm_text_id = ma.alarm_text_id
				INNER JOIN apcsprodb.mc.machines AS m  with(nolock) ON m.id = a.machine_id
				LEFT OUTER JOIN APCSProDB.trans.alarm_lot_records AS r with(nolock) ON r.id = a.id
				LEFT OUTER JOIN APCSProDB.trans.lots AS tl with(nolock) ON tl.id = r.lot_id
				WHERE a.machine_id = @machine_id
					AND a.alarm_on_at >= @date_from
					AND a.alarm_on_at < @datetime_to
					AND ma.alarm_code = @alarm_code
				) AS t ON t.alarm_date = dd.date_value
			WHERE dd.date_value >= @date_from
				AND dd.date_value < @datetime_to
			) AS t1
		LEFT OUTER JOIN APCSProDWH.dwh.dim_hours AS dh with(nolock) ON dh.h = t1.on_h
		) AS t2
	ORDER BY t2.date_value,
		t2.alarm_on_at
END

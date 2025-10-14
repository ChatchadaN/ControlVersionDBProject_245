
CREATE PROCEDURE [act].[sp_productionipi_input_limit_records] @list NVARCHAR(max) = NULL
AS
BEGIN
	SELECT m.id AS monitoring_id,
		dateadd(hour, hr.h, convert(DATETIME, dy.date_value)) AS dyFrom,
		dateadd(hour, hr.h + 6, convert(DATETIME, dy.date_value)) AS dyTo,
		r.alarm_value,
		r.is_alarmed,
		r.current_value
	FROM APCSProDWH.dwh.dim_days AS dy WITH (NOLOCK)
	CROSS JOIN APCSProDWH.dwh.dim_hours AS hr WITH (NOLOCK)
	CROSS JOIN APCSProDWH.wip_control.monitoring_items AS m WITH (NOLOCK)
	LEFT OUTER JOIN APCSProDWH.wip_control.monitoring_item_records AS r WITH (NOLOCK) ON r.monitoring_item_id = m.id
		AND r.recorded_at < dateadd(hour, hr.h + 6, convert(DATETIME, dy.date_value))
		AND r.recorded_at >= convert(DATETIME, dy.date_value)
	WHERE dy.date_value BETWEEN CONVERT(DATE, getdate() - 7)
			AND CONVERT(DATE, getdate())
		AND dateadd(hour, hr.h, convert(DATETIME, dy.date_value)) < GETDATE()
		AND hr.h % 6 = 0
		AND NOT EXISTS (
			SELECT *
			FROM APCSProDWH.wip_control.monitoring_item_records AS r2 WITH (NOLOCK)
			WHERE r2.monitoring_item_id = m.id
				AND r2.recorded_at > r.recorded_at
				AND r2.recorded_at < dateadd(hour, hr.h + 6, convert(DATETIME, dy.date_value))
			)
		AND (
			(
				(
					(@list IS NOT NULL)
					OR (@list <> '')
					)
				AND m.id IN (
					SELECT value
					FROM STRING_SPLIT(@list, ',')
					)
				)
			OR (
				(@list IS NULL)
				OR (@list = '')
				)
			)
	ORDER BY monitoring_id,
		dyFrom
END


CREATE PROCEDURE [act].[sp_productionipi_wip_transition_v2] @device_id INT = NULL
	,@date_from DATE = NULL
	,@date_to DATE = NULL
	,@time_offset INT = 0
AS
BEGIN
	--DECLARE @device_id INT = 5316
	--DECLARE @date_from DATE = '2019-04-01'
	--DECLARE @date_to DATE = '2019-04-22'
	DECLARE @from INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_from
			);
	DECLARE @to INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_to
			);
	DECLARE @finish_hour_code INT = CASE 
			WHEN @to = (
					SELECT finished_day_id
					FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
					WHERE to_fact_table = 'dwh.fact_wip'
					)
				THEN (
						SELECT finished_hour_code
						FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
						WHERE to_fact_table = 'dwh.fact_wip'
						)
			ELSE 24
			END;

	SELECT t2.new_day_id AS day_id
		,dd.date_value
		,t2.process_id
		,t2.process_name
		,t2.sum_lot_count
		,t2.sum_kpcs
		,t2.process_class_flag
	FROM (
		SELECT t1.*
			,dense_RANK() OVER (
				PARTITION BY t1.new_day_id ORDER BY t1.tmp_hour_code DESC
				) AS latest_hour_code
		FROM (
			SELECT d.day_id
				,CASE 
					WHEN d.hour_code < @time_offset + 1
						THEN d.day_id - 1
					ELSE d.day_id
					END AS new_day_id
				,d.hour_code
				,CASE 
					WHEN d.hour_code - @time_offset <= 0
						THEN d.hour_code - @time_offset + 24
					ELSE d.hour_code - @time_offset
					END AS tmp_hour_code
				,fw.process_id
				,fw.process_name
				,fw.sum_lot_count
				,isnull(convert(DECIMAL, fw.sum_pcs) / 1000, 0) AS sum_kpcs
				,CASE 
					WHEN fw.process_id = 9
						THEN 1
					WHEN fw.process_id = 10
						THEN 2
					ELSE 0
					END AS process_class_flag
			FROM (
				SELECT dd.id AS day_id
					,dh.code AS hour_code
				FROM apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK)
				CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
				WHERE (
						dd.id BETWEEN @from - 1
							AND @to
						)
					AND (
						(
							dd.id = @to
							AND dh.code <= @finish_hour_code
							)
						OR dd.id <> @to
						)
				) AS d
			LEFT JOIN (
				SELECT w.day_id
					,w.hour_code
					,w.process_id
					,w.process_name
					,sum(w.lot_count) AS sum_lot_count
					,sum(cast(w.pcs AS BIGINT)) AS sum_pcs
				FROM (
					SELECT wi.day_id AS day_id
						,wi.hour_code AS hour_code
						,wi.process_id AS process_id
						,dp.name AS process_name
						,wi.lot_count AS lot_count
						,wi.pcs AS pcs
					FROM apcsprodwh.dwh.fact_wip AS wi WITH (NOLOCK)
					LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = wi.process_id
					WHERE (wi.hour_code > 0)
						AND (
							wi.day_id BETWEEN @from - 1
								AND @to
							)
						AND wi.device_id = @device_id
					) AS w
				GROUP BY w.day_id
					,w.hour_code
					,w.process_id
					,w.process_name
				) AS fw ON fw.day_id = d.day_id
				AND fw.hour_code = d.hour_code
			) AS t1
		) AS t2
	LEFT JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = t2.new_day_id
	WHERE t2.latest_hour_code = 1
		AND t2.new_day_id BETWEEN @from
			AND @to
	ORDER BY day_id
		,process_id
END

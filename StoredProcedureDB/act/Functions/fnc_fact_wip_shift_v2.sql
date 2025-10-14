
CREATE FUNCTION [act].[fnc_fact_wip_shift_v2] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@from INT
	,@to INT
	,@hour_flag BIT
	,@time_offset INT = 0
	)
RETURNS @retTbl TABLE (
	day_id INT NOT NULL
	,shift_code TINYINT
	,sum_lot_count INT NOT NULL
	,sum_pcs BIGINT NOT NULL
	)

BEGIN
	--DECLARE @today INT = (
	--		SELECT id
	--		FROM dwh.dim_days
	--		WHERE date_value = CONVERT(DATE, getdate())
	--		)
	--DECLARE @update_h INT = (
	--		SELECT finished_hour_code
	--		FROM dwh.function_finish_control
	--		WHERE to_fact_table = 'dwh.fact_wip'
	--		)
	INSERT INTO @retTbl
	SELECT t3.day_id AS day_id
		,t3.shift_code AS shift_code
		--,t3.hour_code
		,t3.sum_lot_count AS sum_lot_count
		,t3.sum_pcs AS sum_pcs
	FROM (
		SELECT t2.new_day_id AS day_id
			,t2.hour_code
			,t2.tmp_hour_code
			,t2.shift_code AS shift_code
			,dense_RANK() OVER (
				PARTITION BY t2.new_day_id
				,t2.shift_code ORDER BY t2.tmp_hour_code DESC
				) AS latest_hour_code
			,t2.sum_lot_count
			,t2.sum_pcs
		FROM (
			SELECT t1.day_id
				,CASE 
					WHEN t1.hour_code < @time_offset + 1
						THEN t1.day_id - 1
					ELSE t1.day_id
					END AS new_day_id
				,t1.hour_code
				,CASE 
					WHEN t1.hour_code - @time_offset <= 0
						THEN t1.hour_code - @time_offset + 24
					ELSE t1.hour_code - @time_offset
					END AS tmp_hour_code
				,CASE 
					WHEN @time_offset <= 12
						THEN CASE 
								WHEN t1.hour_code BETWEEN (@time_offset + 1)
										AND (@time_offset + 12)
									THEN 0
								ELSE 1
								END
					ELSE CASE 
							WHEN t1.hour_code BETWEEN (@time_offset - 12 + 1)
									AND (@time_offset)
								THEN 1
							ELSE 0
							END
					END AS shift_code
				,t1.sum_lot_count
				,t1.sum_pcs
			FROM (
				SELECT wi.day_id AS day_id
					,wi.hour_code AS hour_code
					,sum(wi.lot_count) AS sum_lot_count
					,sum(cast(wi.pcs AS BIGINT)) AS sum_pcs
				FROM apcsprodwh.dwh.fact_wip AS wi WITH (NOLOCK)
				LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = wi.device_id
				WHERE (wi.hour_code > 0)
					AND (
						wi.day_id BETWEEN @from - 1
							AND @to + 1
						)
					AND (
						(
							@package_id IS NOT NULL
							AND wi.package_id = @package_id
							)
						OR (
							@package_id IS NULL
							AND @package_group_id IS NOT NULL
							AND wi.package_group_id = @package_group_id
							)
						OR (
							@package_id IS NULL
							AND @package_group_id IS NULL
							AND wi.package_id > 0
							)
						)
					AND (
						(
							@process_id IS NOT NULL
							AND wi.process_id = @process_id
							)
						OR (
							@process_id IS NULL
							AND wi.process_id >= 0
							)
						)
					AND (
						(
							@device_name IS NOT NULL
							AND dd.name = @device_name
							)
						OR (@device_name IS NULL)
						)
				GROUP BY wi.day_id
					,wi.hour_code
				) AS t1
			) AS t2
		) AS t3
	WHERE t3.day_id BETWEEN @from
			AND @to
		AND t3.latest_hour_code = 1

	--ORDER BY day_id,
	--	hour_code
	RETURN
END

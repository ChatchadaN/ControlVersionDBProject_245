
------高速化の為、参照元にソースを直書きしている。v2
CREATE FUNCTION [act].[fnc_fact_wip_delay_v2] (
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
	,hour_code TINYINT
	,delay_state_code INT NOT NULL
	,sum_lot_count INT NOT NULL
	,sum_pcs BIGINT NOT NULL
	)

BEGIN
	

	INSERT INTO @retTbl
	SELECT t3.day_id AS day_id
		,t3.hour_code AS hour_code
		,t3.delay_state_code
		,t3.sum_lot_count AS sum_lot_count
		,t3.sum_pcs AS sum_pcs
	FROM (
		SELECT CASE 
				WHEN @hour_flag = 0
					THEN t2.new_day_id
				ELSE t2.day_id
				END AS day_id
			,t2.hour_code
			,t2.delay_state_code
			,t2.sum_lot_count AS sum_lot_count
			,t2.sum_pcs AS sum_pcs
			,dense_RANK() OVER (
				PARTITION BY t2.new_day_id ORDER BY t2.tmp_hour_code DESC
				) AS latest_hour_code
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
				,t1.delay_state_code
				,t1.sum_lot_count AS sum_lot_count
				,t1.sum_pcs AS sum_pcs
			FROM (
				SELECT wi.day_id AS day_id
					,wi.hour_code AS hour_code
					,wi.delay_state_code AS delay_state_code
					,sum(wi.lot_count) AS sum_lot_count
					,sum(cast(wi.pcs AS BIGINT)) AS sum_pcs
				FROM apcsprodwh.dwh.fact_wip AS wi WITH (NOLOCK)
				LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = wi.device_id
				WHERE (wi.hour_code > 0)
					AND (
						wi.day_id BETWEEN @from - 1
							AND @to
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
							AND ddv.name = @device_name
							)
						OR (@device_name IS NULL)
						)
				GROUP BY wi.day_id
					,wi.hour_code
					,wi.delay_state_code
				) AS t1
			) AS t2
		) AS t3
	WHERE (
			(
				@hour_flag = 0
				AND t3.latest_hour_code = 1
				)
			OR (@hour_flag = 1)
			)
		AND t3.day_id BETWEEN @from
			AND @to

	RETURN
END

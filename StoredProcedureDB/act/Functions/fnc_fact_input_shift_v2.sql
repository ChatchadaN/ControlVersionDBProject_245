
CREATE FUNCTION [act].[fnc_fact_input_shift_v2] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@from INT
	,@to INT
	,@time_offset INT = 0
	)
RETURNS @retTbl TABLE (
	day_id INT NOT NULL
	,shift_code TINYINT
	,lot_count INT
	,pcs INT
	,LotAve7days FLOAT
	,PcsAve7days FLOAT
	)

BEGIN
	INSERT INTO @retTbl
	SELECT t5.day_id AS day_id
		,t5.shift_code AS shift_code
		,isnull(t5.lot_count, 0) AS lot_count
		,isnull(t5.pcs, 0) AS pcs
		,CASE 
			WHEN count(t5.day_id) OVER (
					ORDER BY t5.day_id rows BETWEEN 6 preceding
							AND CURRENT row
					) > 0
				THEN isnull(round(convert(FLOAT, sum(t5.lot_count) OVER (
									PARTITION BY t5.shift_code ORDER BY t5.day_id rows BETWEEN 6 preceding
											AND CURRENT row
									)) / count(t5.day_id) OVER (
								PARTITION BY t5.shift_code ORDER BY t5.day_id rows BETWEEN 6 preceding
										AND CURRENT row
								), 0), 1)
			ELSE 0
			END AS LotAve7days
		,CASE 
			WHEN count(t5.day_id) OVER (
					ORDER BY t5.day_id rows BETWEEN 6 preceding
							AND CURRENT row
					) > 0
				THEN isnull(sum(t5.pcs) OVER (
							PARTITION BY t5.shift_code ORDER BY t5.day_id rows BETWEEN 6 preceding
									AND CURRENT row
							) / count(t5.day_id) OVER (
							PARTITION BY t5.shift_code ORDER BY t5.day_id rows BETWEEN 6 preceding
									AND CURRENT row
							), 0)
			ELSE 0
			END AS PcsAve7days
	FROM (
		SELECT
			--t4.day_id AS day_id
			t4.new_day_id AS day_id
			,t4.shift_code AS shift_code
			,sum(t4.lot_count) AS lot_count
			,sum(t4.pcs) AS pcs
		FROM (
			SELECT t3.day_id AS day_id
				,CASE 
					WHEN t3.hour_code < @time_offset + 1
						THEN t3.day_id - 1
					ELSE t3.day_id
					END AS new_day_id
				,t3.hour_code AS hour_code
				,CASE 
					WHEN @time_offset <= 12
						THEN CASE 
								WHEN t3.hour_code BETWEEN (@time_offset + 1)
										AND (@time_offset + 12)
									THEN 0
								ELSE 1
								END
					ELSE CASE 
							WHEN t3.hour_code BETWEEN (@time_offset - 12 + 1)
									AND (@time_offset)
								THEN 1
							ELSE 0
							END
					END AS shift_code
				,isnull(sum(t3.lot_count), 0) AS lot_count
				,isnull(sum(t3.pcs), 0) AS pcs
			FROM (
				SELECT t2.day_id AS day_id
					,t2.hour_code AS hour_code
					,t2.lot_count AS lot_count
					,t2.pcs AS pcs
				FROM (
					SELECT dd.day_id AS day_id
						,dd.hour_code AS hour_code
						,t1.package_id AS package_id
						,t1.lot_count AS lot_count
						,t1.pcs AS pcs
					FROM (
						SELECT ddy.id AS day_id
							,dh.code AS hour_code
						FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
						CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
						) AS dd
					LEFT OUTER JOIN (
						SELECT fi.day_id AS day_id
							,fi.hour_code AS hour_code
							,fi.package_id
							,fi.lot_count
							,fi.pcs
						FROM apcsprodwh.dwh.fact_input AS fi WITH (NOLOCK)
						LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fi.device_id
						WHERE (
								(
									@package_id IS NOT NULL
									AND fi.package_id = @package_id
									)
								OR (
									@package_id IS NULL
									AND @package_group_id IS NOT NULL
									AND fi.package_group_id = @package_group_id
									)
								OR (
									@package_id IS NULL
									AND @package_group_id IS NULL
									AND fi.package_id > 0
									)
								)
							AND (
								(
									@device_name IS NOT NULL
									AND ddv.name = @device_name
									)
								OR (@device_name IS NULL)
								)
						) AS t1 ON t1.day_id = dd.day_id
						AND t1.hour_code = dd.hour_code
					WHERE dd.day_id BETWEEN @from - 7
							AND @to + 1
					) AS t2
				) AS t3
			GROUP BY t3.day_id
				,hour_code
			) AS t4
		GROUP BY
			--t4.day_id
			t4.new_day_id
			,t4.shift_code
		) AS t5
	WHERE t5.day_id BETWEEN @from - 7
			AND @to + 1

	-- order by t2.day_id 
	--ORDER BY t2.shift_code
	RETURN
END

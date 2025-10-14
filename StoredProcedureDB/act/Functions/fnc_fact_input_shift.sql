
CREATE FUNCTION [act].[fnc_fact_input_shift] (
	@package_group_id INT = NULL,
	@package_id INT = NULL,
	@device_id INT = NULL,
	@device_name VARCHAR(20) = NULL,
	@from INT,
	@to INT
	)
RETURNS @retTbl TABLE (
	day_id INT NOT NULL,
	hour_code TINYINT,
	lot_count INT,
	pcs INT,
	LotAve7days FLOAT,
	PcsAve7days FLOAT
	)

BEGIN
	INSERT INTO @retTbl
	SELECT t2.day_id AS day_id,
		--isnull(t2.shift_code, - 1) AS shift_code,
		CASE 
			WHEN t2.shift_code = 0
				THEN 8
			WHEN t2.shift_code = 1
				THEN 20
			END AS hour_code,
		isnull(t2.lot_count, 0) AS lot_count,
		isnull(t2.pcs, 0) AS pcs,
		CASE 
			WHEN count(t2.day_id) OVER (
					ORDER BY t2.day_id rows BETWEEN 6 preceding
							AND CURRENT row
					) > 0
				THEN isnull(round(convert(FLOAT, sum(t2.lot_count) OVER (
									PARTITION BY t2.shift_code ORDER BY t2.day_id rows BETWEEN 6 preceding
											AND CURRENT row
									)) / count(t2.day_id) OVER (
								PARTITION BY t2.shift_code ORDER BY t2.day_id rows BETWEEN 6 preceding
										AND CURRENT row
								), 0), 1)
			ELSE 0
			END AS LotAve7days,
		CASE 
			WHEN count(t2.day_id) OVER (
					ORDER BY t2.day_id rows BETWEEN 6 preceding
							AND CURRENT row
					) > 0
				THEN isnull(sum(t2.pcs) OVER (
							PARTITION BY t2.shift_code ORDER BY t2.day_id rows BETWEEN 6 preceding
									AND CURRENT row
							) / count(t2.day_id) OVER (
							PARTITION BY t2.shift_code ORDER BY t2.day_id rows BETWEEN 6 preceding
									AND CURRENT row
							), 0)
			ELSE 0
			END AS PcsAve7days
	FROM (
		SELECT t2.day_id AS day_id,
			--t2.new_day_id AS day_id,
			t2.shift_code AS shift_code,
			sum(t2.lot_count) AS lot_count,
			sum(t2.pcs) AS pcs
		FROM (
			SELECT t1.day_id AS day_id,
				--CASE 
				--	WHEN (t1.hour_code < 8 + 1)
				--		THEN t1.day_id - 1
				--	ELSE t1.day_id
				--	END AS new_day_id,
				t1.hour_code AS hour_code,
				CASE 
					WHEN (t1.hour_code < 8 + 1)
						OR (t1.hour_code > 20 + 1)
						THEN 1
					ELSE 0
					END AS shift_code,
				isnull(sum(t1.lot_count), 0) AS lot_count,
				isnull(sum(t1.pcs), 0) AS pcs
			FROM (
				SELECT dd.day_id AS day_id,
					dd.hour_code AS hour_code,
					-- dd.shift_code as shift_code,
					-- t3.shift_code as shift_code,
					t3.package_id AS package_id,
					t3.lot_count AS lot_count,
					t3.pcs AS pcs
				FROM (
					SELECT ddy.id AS day_id,
						dh.code AS hour_code
					FROM apcsprodwh.dwh.dim_days AS ddy
					CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
					) AS dd
				LEFT OUTER JOIN (
					SELECT fi.day_id AS day_id,
						fi.hour_code AS hour_code,
						fi.package_id,
						fi.lot_count,
						fi.pcs
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
					) AS t3 ON t3.day_id = dd.day_id
					AND t3.hour_code = dd.hour_code
				WHERE dd.day_id BETWEEN @from - 7
						AND @to + 1
				) AS t1
			GROUP BY t1.day_id,
				-- shift_code,
				hour_code
			) AS t2
		GROUP BY t2.day_id,
			--t2.new_day_id,
			t2.shift_code
		) AS t2
	WHERE t2.day_id BETWEEN @from - 7
			AND @to + 1

	-- order by t2.day_id 
	--ORDER BY t2.shift_code
	RETURN
END

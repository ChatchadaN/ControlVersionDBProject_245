
CREATE FUNCTION [act].[fnc_fact_capa_v2] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@from INT
	,@to INT
	,@time_offset INT = 0
	)
RETURNS @retTbl TABLE (
	day_id INT NOT NULL
	-- ,hour_code tinyint
	-- ,sum_lot_count int not null
	,sum_pcs INT NULL
	)

BEGIN
	INSERT INTO @retTbl
	SELECT fc.day_id - 1 AS day_id
		/*8時締めなので実際の日付から集計日は-1 */
		,
		--   case when @hour_flag =1 then wi.hour_code end as hour_code,
		-- sum(fc.lot_count) as sum_lot_count,
		sum(fc.pcs) AS sum_pcs
	FROM apcsprodwh.dwh.fact_capa AS fc WITH (NOLOCK)
	WHERE fc.day_id BETWEEN @from - 1
			AND @to + 1
		AND (
			(
				@package_id IS NOT NULL
				AND fc.package_id = @package_id
				)
			OR (
				@package_id IS NULL
				AND @package_group_id IS NOT NULL
				AND fc.package_group_id = @package_group_id
				)
			OR (
				@package_id IS NULL
				AND @package_group_id IS NULL
				AND fc.package_id > 0
				)
			)
		AND (
			(
				@process_id IS NOT NULL
				AND fc.process_id = @process_id
				)
			OR (
				@process_id IS NULL
				AND fc.process_id > 0
				)
			)
		AND fc.device_id IN (
			SELECT t.id
			FROM APCSProDWH.dwh.dim_devices AS t WITH (NOLOCK)
			WHERE (t.id = fc.device_id)
				AND (
					@device_name IS NOT NULL
					AND t.name = @device_name
					)
				OR (
					@device_name IS NULL
					AND fc.device_id > 0
					)
			)
	--AND (
	--	(
	--		@device_id IS NOT NULL
	--		AND fc.device_id = @device_id
	--		)
	--	OR (
	--		@device_id IS NULL
	--		AND fc.device_id > 0
	--		)
	--	)
	GROUP BY fc.day_id

	RETURN
END

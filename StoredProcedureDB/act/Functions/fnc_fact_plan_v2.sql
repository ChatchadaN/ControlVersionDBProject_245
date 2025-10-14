
CREATE FUNCTION [act].[fnc_fact_plan_v2] (
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
	,sum_pcs INT
	)

BEGIN
	INSERT INTO @retTbl
	SELECT pl.day_id AS day_id
		,sum(pl.pcs) AS sum_pcs
	FROM apcsprodwh.dwh.fact_plan AS pl WITH (NOLOCK)
	LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = pl.device_id
	WHERE pl.day_id BETWEEN @from
			AND @to
		AND (
			(
				@package_id IS NOT NULL
				AND pl.package_id = @package_id
				)
			OR (
				@package_id IS NULL
				AND @package_group_id IS NOT NULL
				AND pl.package_group_id = @package_group_id
				)
			OR (
				@package_id IS NULL
				AND @package_group_id IS NULL
				AND pl.package_id > 0
				)
			)
		AND (
			(
				@device_name IS NOT NULL
				AND dd.name = @device_name
				)
			OR (@device_name IS NULL)
			)
	GROUP BY pl.day_id

	RETURN
END

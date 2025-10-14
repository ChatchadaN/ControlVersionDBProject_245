
CREATE PROCEDURE [act].[sp_home_plan_v2] @date DATE = ''
	,@time_offset INT = 0
AS
BEGIN
	-- date
	DECLARE @day_id INT
	DECLARE @is_back INT

	------------------------------------------------------------------------
	-- Setup date
	------------------------------------------------------------------------
	SET @day_id = (
			SELECT da.id
			FROM APCSProDWH.dwh.dim_days AS da WITH (NOLOCK)
			WHERE da.date_value = @date
			);
	SET @is_back = (
			SELECT CASE 
					WHEN datepart(hour, GETDATE()) >= @time_offset
						THEN 0
					ELSE 1
					END AS is_back
			FROM APCSProDWH.dwh.dim_days AS da WITH (NOLOCK)
			WHERE da.date_value = @date
			);

	------------------------------------------------------------------------
	-- Select
	------------------------------------------------------------------------
	SELECT fp.day_id
		,ROUND(SUM(fp.pcs), - 3) / 1000 AS Kpcs
	FROM apcsprodwh.dwh.fact_plan AS fp WITH (NOLOCK)
	WHERE (
			(@is_back = 0)
			AND (
				day_id BETWEEN @day_id - 2
					AND @day_id - 1
				)
			)
		OR (
			(@is_back = 1)
			AND (
				day_id BETWEEN @day_id - 3
					AND @day_id - 2
				)
			)
	GROUP BY fp.day_id
	ORDER BY day_id
END

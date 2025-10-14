
CREATE PROCEDURE [act].[sp_machinestate_input_plan] (@package_id INT = NULL)
AS
BEGIN
	DECLARE @date_from DATETIME = convert(DATE, getdate())

	SELECT t2.*
	FROM (
		SELECT t1.*
			,sum(t1.kpcs) OVER (
				PARTITION BY t1.y
				,t1.m
				,t1.package_id
				) AS sum_kpcs
		FROM (
			SELECT dd.id AS day_id
				,dd.date_value AS date_value
				,dd.y AS y
				,dd.m AS m
				,fp.package_id
				,rtrim(dp.name) AS package_name
				,convert(DECIMAL, fp.pcs) / 1000 AS kpcs
			FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
			LEFT JOIN APCSProDWH.dwh.fact_plan AS fp WITH (NOLOCK) ON fp.day_id = dd.id
			INNER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = fp.package_id
			WHERE dd.y = YEAR(@date_from)
				AND dd.m = month(@date_from)
				AND (
					(
						@package_id IS NULL
						AND fp.package_id > 0
						)
					OR (
						@package_id IS NOT NULL
						AND fp.package_id = @package_id
						)
					)
			) AS t1
		) AS t2
	WHERE t2.date_value = @date_from
	ORDER BY t2.day_id;
END

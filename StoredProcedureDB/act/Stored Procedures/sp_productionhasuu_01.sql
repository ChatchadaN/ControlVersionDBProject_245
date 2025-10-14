
CREATE PROCEDURE [act].[sp_productionhasuu_01]
AS
BEGIN
	SELECT ROW_NUMBER() OVER (
			PARTITION BY 1 ORDER BY day_id
			) AS No
		,t1.*
	FROM (
		SELECT min(day_id) AS day_id
			,dp.name AS package_name
			,dd.name AS device_name
			,isnull(round(convert(FLOAT, sum(fh.pcs_per_pack), - 3) / 1000, 2), 0) AS Kpcs_per_pack
			,isnull(round(convert(FLOAT, sum(fh.pcs), - 3) / 1000, 2), 0) AS Kpcs
			,round(convert(FLOAT, sum(fh.pcs), - 3) / nullif(convert(FLOAT, sum(fh.pcs_per_pack), - 3), 0), 2) AS unit_num
		FROM apcsprodwh.dwh.fact_hasuu AS fh WITH (NOLOCK)
		LEFT OUTER JOIN apcsprodwh.dwh.dim_packages AS dp WITH (NOLOCK) ON fh.package_id = dp.id
		LEFT OUTER JOIN apcsprodwh.dwh.dim_devices AS dd WITH (NOLOCK) ON fh.device_id = dd.id
		GROUP BY dp.name
			,dd.name
		) AS t1
END

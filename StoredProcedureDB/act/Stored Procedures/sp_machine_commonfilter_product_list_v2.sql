
CREATE PROCEDURE [act].[sp_machine_commonfilter_product_list_v2] @package_group_id INT = NULL
	,@package_id INT = NULL
AS
BEGIN
	SELECT ROW_NUMBER() OVER (
			ORDER BY dn.name
			) AS rownum
		,dn.name
		,mp.id AS package_id
		,mp.name AS package_name
	FROM APCSProDB.method.device_names AS dn WITH (NOLOCK)
	INNER JOIN APCSProDB.method.packages AS mp WITH (NOLOCK) ON mp.id = dn.package_id
	LEFT JOIN APCSProDB.method.package_groups AS pg WITH (NOLOCK) ON pg.id = mp.package_group_id
	WHERE (
			(
				@package_id IS NOT NULL
				AND mp.id = @package_id
				)
			OR (
				@package_id IS NULL
				AND @package_group_id IS NOT NULL
				AND mp.package_group_id = @package_group_id
				)
			OR (
				@package_id IS NULL
				AND @package_group_id IS NULL
				AND mp.id > 0
				)
			)
		AND isnull(is_assy_only, 0) IN (
			0
			,1
			)
	GROUP BY dn.name
		,mp.id
		,mp.name
	ORDER BY dn.name
END

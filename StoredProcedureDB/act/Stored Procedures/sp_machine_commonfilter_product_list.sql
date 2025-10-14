
CREATE PROCEDURE [act].[sp_machine_commonfilter_product_list] @package_group_id INT = NULL,
	@package_id INT = NULL
AS
BEGIN
	SELECT dv.id AS device_id,
		gr.name AS package_group_name,
		pk.name AS package_name,
		dv.assy_name AS assy_name,
		dv.[name] AS device_name,
		dv.[ft_name] AS ft_name,
		dv.[package_id]
	FROM APCSProDB.method.device_names AS dv WITH (NOLOCK)
	LEFT OUTER JOIN APCSProDB.method.packages AS pk WITH (NOLOCK) ON dv.package_id = pk.id
	LEFT OUTER JOIN APCSProDB.method.package_groups AS gr WITH (NOLOCK) ON pk.package_group_id = gr.id
	WHERE is_assy_only = 0
	AND (
				(
					@package_id IS NOT NULL
					AND pk.id = @package_id
					)
				OR (
					@package_id IS NULL
					AND @package_group_id IS NOT NULL
					AND gr.id = @package_group_id
					)
				OR (
					@package_id IS NULL
					AND @package_group_id IS NULL
					AND pk.id > 0
					)
				)
END

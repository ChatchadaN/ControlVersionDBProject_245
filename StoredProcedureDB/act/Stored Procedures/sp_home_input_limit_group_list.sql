
CREATE PROCEDURE [act].[sp_home_input_limit_group_list] (
	@is_input_control INT = NULL
	,@is_restricted_only INT = 0
	)
AS
BEGIN
	SELECT pk.id AS package_id
		,pk.name AS package_name
		,pk.package_group_id AS package_group_id
		,t2.product_group_id AS product_group_id
		,t2.product_group AS product_group
		,t2.device_id AS device_id
		,t2.device AS device_name
		,t2.is_input_control AS is_input_control
	FROM (
		SELECT isnull(t1.package_id1, isnull(t1.package_id2, isnull(t1.package_id3, isnull(t1.package_id4, NULL)))) AS package_id
			,CASE 
				WHEN t1.package_id1 IS NOT NULL
					THEN NULL
				ELSE CASE 
						WHEN t1.package_id3 IS NOT NULL
							THEN NULL
						ELSE t1.product_group_id
						END
				END AS product_group_id
			,CASE 
				WHEN t1.package_id1 IS NOT NULL
					THEN NULL
				ELSE CASE 
						WHEN t1.package_id3 IS NOT NULL
							THEN NULL
						ELSE t1.product_group
						END
				END AS product_group
			,isnull(t1.device_id, NULL) AS device_id
			,isnull(t1.target_device, NULL) AS device
			,t1.is_input_control AS is_input_control
		FROM (
			SELECT i.package_id AS package_id1
				,i.is_alarmed
				,i.is_input_control AS is_input_control
				,wt.package_id AS package_id2
				,pg.id AS product_group_id
				,pg.name AS product_group
				,pg.package_id AS package_id3
				,pgd.package_id AS package_id4
				,pgd.id AS device_id
				,pgd.target_device
			FROM APCSProDWH.wip_control.monitoring_items AS i WITH (NOLOCK)
			LEFT OUTER JOIN APCSProDWH.wip_control.wip_count_target AS wt WITH (NOLOCK) ON wt.id = i.target_id
			LEFT OUTER JOIN apcsprodwh.wip_control.wip_count_jobs AS wj WITH (NOLOCK) ON wj.wip_count_target_id = wt.id
			LEFT OUTER JOIN APCSProDWH.wip_control.wip_count_product_groups AS wp WITH (NOLOCK) ON wp.wip_count_job_id = wj.id
			LEFT OUTER JOIN APCSProDWH.wip_control.product_groups AS pg WITH (NOLOCK) ON pg.id = wp.product_group_id
			LEFT OUTER JOIN APCSProDWH.wip_control.product_group_details AS pgd WITH (NOLOCK) ON pgd.product_group_id = pg.id
			WHERE (
					(
						(@is_restricted_only = 1)
						AND (
							i.is_alarmed BETWEEN 1
								AND 9
							)
						)
					OR @is_restricted_only <> 1
					)
				AND (
					(
						(@is_input_control >= 0)
						AND (isnull(i.is_input_control, 0) = @is_input_control)
						)
					OR (
						(@is_input_control < 0)
						AND (isnull(i.is_input_control, 0) >= 0)
						)
					)
				--GROUP BY i.package_id,
				--	i.is_alarmed,
				--	wt.package_id,
				--	pg.id,
				--	pg.name,
				--	pg.package_id,
				--	pgd.package_id,
				--	pgd.id,
				--	pgd.target_device
			) AS t1
		) AS t2
	INNER JOIN APCSProDWH.dwh.dim_packages AS pk WITH (NOLOCK) ON pk.id = t2.package_id
	GROUP BY pk.id
		,pk.name
		,pk.package_group_id
		,t2.product_group_id
		,t2.product_group
		,t2.device_id
		,t2.device
		,t2.is_input_control
	ORDER BY pk.package_group_id
		,pk.name
END

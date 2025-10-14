
CREATE FUNCTION [act].[fnc_productionipi_monitoring_items] (
	@package_id INT = NULL
	,@product_group_id INT = NULL
	,@device_id INT = NULL
	)
RETURNS @retTbl TABLE (
	item_id INT NOT NULL
	,package_id INT NULL
	,package_name NVARCHAR(32)
	,package_group_id INT NULL
	,product_group_id INT NULL
	,product_group NVARCHAR(32)
	,device_id INT NULL
	,device_name NVARCHAR(32)
	,name NVARCHAR(32)
	,is_input_control TINYINT NULL
	,control_unit_type TINYINT NULL
	,target_value INT NULL
	,warn_value INT NULL
	,alarm_value INT NULL
	,lcl_value INT NULL
	,is_alarmed TINYINT NULL
	,current_value INT NULL
	,occurred_at DATETIME NULL
	,cleared_at DATETIME NULL
	)

BEGIN
	INSERT INTO @retTbl
	SELECT t3.*
	FROM (
		SELECT t1.*
			,i.name
			,i.is_input_control AS is_input_control
			,i.control_unit_type AS control_unit_type
			,i.target_value AS target_value
			,i.warn_value AS warn_value
			,i.alarm_value AS alarm_value
			,i.lcl_value AS lcl
			,i.is_alarmed AS is_alarmed
			,i.current_value AS current_value
			,i.occurred_at AS occurred_at
			,i.cleared_at AS cleared_at
		FROM (
			SELECT t2.item_id AS item_id
				,pk.id AS package_id
				,pk.name AS package_name
				,pk.package_group_id AS package_group_id
				,t2.product_group_id AS product_group_id
				,t2.product_group AS product_group
				,t2.device_id AS device_id
				,t2.device AS device_name
			FROM (
				SELECT t1.item_id AS item_id
					,isnull(t1.package_id1, isnull(t1.package_id2, isnull(t1.package_id3, isnull(t1.package_id4, NULL)))) AS package_id
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
					,isnull(t1.target_device_id, NULL) AS device_id
					,isnull(t1.target_device, NULL) AS device
				FROM (
					SELECT i.id AS item_id
						,i.package_id AS package_id1
						,i.is_alarmed
						,wt.package_id AS package_id2
						,pg.id AS product_group_id
						,pg.name AS product_group
						,pg.package_id AS package_id3
						,pgd.id AS product_group_details_is
						,pgd.package_id AS package_id4
						,pgd.id AS target_device_id
						,pgd.target_device
					FROM APCSProDWH.wip_control.monitoring_items AS i WITH (NOLOCK)
					LEFT OUTER JOIN APCSProDWH.wip_control.wip_count_target AS wt WITH (NOLOCK) ON wt.id = i.target_id
					LEFT OUTER JOIN apcsprodwh.wip_control.wip_count_jobs AS wj WITH (NOLOCK) ON wj.wip_count_target_id = wt.id
					LEFT OUTER JOIN APCSProDWH.wip_control.wip_count_product_groups AS wp WITH (NOLOCK) ON wp.wip_count_job_id = wj.id
					LEFT OUTER JOIN APCSProDWH.wip_control.product_groups AS pg WITH (NOLOCK) ON pg.id = wp.product_group_id
					LEFT OUTER JOIN APCSProDWH.wip_control.product_group_details AS pgd WITH (NOLOCK) ON pgd.product_group_id = pg.id
					WHERE i.is_alarmed BETWEEN 0
							AND 10
					GROUP BY i.id
						,i.package_id
						,i.is_alarmed
						,wt.package_id
						,pg.id
						,pg.name
						,pg.package_id
						,pgd.id
						,pgd.package_id
						,pgd.id
						,pgd.target_device
					) AS t1
				) AS t2
			INNER JOIN APCSProDWH.dwh.dim_packages AS pk WITH (NOLOCK) ON pk.id = t2.package_id
			GROUP BY t2.item_id
				,pk.id
				,pk.name
				,pk.package_group_id
				,t2.product_group_id
				,t2.product_group
				,t2.device_id
				,t2.device
			) AS t1
		LEFT OUTER JOIN APCSProDWH.wip_control.monitoring_items AS i WITH (NOLOCK) ON i.id = t1.item_id
		) AS t3
	WHERE (
			(
				(@package_id IS NULL)
				AND t3.package_id > 0
				)
			OR (
				(@package_id IS NOT NULL)
				AND t3.package_id = @package_id
				)
			)
		AND (
			(
				(@product_group_id IS NULL)
				AND (
					t3.product_group_id > 0
					OR t3.product_group_id IS NULL
					)
				)
			OR (
				(@product_group_id IS NOT NULL)
				AND t3.product_group_id = @product_group_id
				)
			)
		AND (
			(
				(@device_id IS NULL)
				AND (
					t3.device_id > 0
					OR t3.device_id IS NULL
					)
				)
			OR (
				(@device_id IS NOT NULL)
				AND t3.device_id = @device_id
				)
			)

	RETURN
END

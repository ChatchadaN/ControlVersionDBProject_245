
CREATE PROCEDURE [act].[sp_productionipi_input_limit_items] @isInputControl INT = NULL,
	@item_def INT = NULL,
	@package_id INT = NULL,
	@product_group_id INT = NULL,
	@device_id INT = NULL,
	@control_unit_type int = 0
AS
BEGIN
	SELECT ROW_NUMBER() OVER (
			ORDER BY mi.occurred_at,
				mi.item_id
			) AS no,
		mi.item_id AS id,
		mi.is_input_control AS is_input_control,
		@item_def AS item_def,
		mi.name AS name,
		mi.package_group_id AS package_group_id,
		mi.package_id AS package_id,
		mi.package_name AS package_name,
		mi.product_group_id AS product_group_id,
		mi.product_group AS product_group,
		mi.device_id AS device_id,
		mi.device_name AS device_name,
		mi.is_alarmed AS is_alarmed,
		mi.control_unit_type AS control_unit_type,
		mi.current_value AS current_value,
		mi.alarm_value AS UCL,
		mi.lcl_value AS LCL,
		format(mi.occurred_at, 'yyyy-MM-dd HH:mm:ss') AS occurred_at,
		CASE 
			WHEN mi.cleared_at IS NULL
				THEN ''
			ELSE format(mi.cleared_at, 'yyyy-MM-dd HH:mm:ss')
			END AS cleared_at
	FROM [act].fnc_productionipi_monitoring_items(@package_id, @product_group_id, @device_id) AS mi
	WHERE (
			--(
			--	(@isInputControl = 1)
			--	AND isnull(mi.is_input_control, 0) = 1
			--	)
			--OR (
			--	(@isInputControl <> 1)
			--	--AND (isnull(mi.is_input_control, 0) <> 1)
			--	AND (isnull(mi.is_input_control, 0) >= 0)
			--	)
			--)
		(
				(@isInputControl = -1)
				AND isnull(mi.is_input_control, 0) >= 0
				)
			or (
				(@isInputControl <> -1)
				AND mi.is_input_control = @isInputControl
				)
			)
		AND (
			(
				(@item_def IN (1, 2))
				AND (
					mi.is_alarmed = CASE 
						WHEN @item_def = 1
							THEN 1
						WHEN @item_def = 2
							THEN 10
						END
					)
				)
			OR (
				(@item_def IN (3, 4))
				AND (
					(
						(@item_def = 3)
						AND (dateadd(day, 1, mi.occurred_at) >= getdate())
						)
					OR (
						(@item_def = 4)
						AND ((dateadd(day, 1, mi.cleared_at) >= getdate()))
						)
					)
				)
			OR ((@item_def = 5))
			AND (mi.item_id IS NOT NULL)
			--and (mi.control_unit_type = @control_unit_type)
			and (mi.control_unit_type >= 0)
			)
	ORDER BY
		mi.item_id,
		--is_alarmed
		CASE 
			WHEN @item_def = 5
				THEN mi.is_alarmed
			END DESC,
		--occurred_at
		CASE 
			WHEN @item_def = 1
				THEN mi.occurred_at
			END DESC,
		CASE 
			WHEN @item_def = 3
				THEN mi.occurred_at
			END DESC,
		CASE 
			WHEN @item_def = 5
				THEN mi.occurred_at
			END DESC,
		--cleared_at
		CASE 
			WHEN @item_def = 4
				THEN mi.cleared_at
			END DESC,
		--package_id,name
		mi.package_id,
		mi.name
END

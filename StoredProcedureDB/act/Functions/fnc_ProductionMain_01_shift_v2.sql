
CREATE FUNCTION [act].[fnc_ProductionMain_01_shift_v2] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@from INT
	,@to INT
	,@span NVARCHAR(32)
	,@time_offset INT = 0
	)
RETURNS @retTbl TABLE (
	id INT
	,date_value DATE NOT NULL
	--,hour_code TINYINT NOT NULL
	,shift_code INT NULL
	,span TINYINT NOT NULL
	,plan_Kpcs FLOAT NULL
	,input_lot_cnt INT NULL
	,input_Kpcs FLOAT NULL
	,input_lot_cnt_7ave FLOAT NULL
	,input_Kpcs_7ave FLOAT NULL
	,ship_lot_cnt INT NULL
	,ship_Kpcs FLOAT NULL
	,ship_lot_cnt_7ave FLOAT NULL
	,ship_Kpcs_7ave FLOAT NULL
	,wip_days FLOAT NULL
	)

BEGIN
	---------------------------------------------------------------------------------------------------------
	-- process指定無し
	---------------------------------------------------------------------------------------------------------
	IF @process_id IS NULL
	BEGIN
		INSERT INTO @retTbl
		SELECT dd.day_id AS id
			,dd.date_value AS date_value
			,dd.shift_code
			,dd.week_no AS span
			,isnull(convert(FLOAT, pln.sum_pcs) / 1000, 0) AS plan_Kpcs
			,isnull(ipt.lot_count, 0) AS input_lot_cnt
			,isnull(convert(FLOAT, ipt.pcs) / 1000, 0) AS input_Kpcs
			,isnull(ipt.LotAve7days, 0) AS input_lot_cnt_7ave
			,isnull(convert(FLOAT, ipt.PcsAve7days) / 1000, 0) AS input_Kpcs_7ave
			,isnull(shp.lot_count, 0) AS ship_lot_cnt
			,isnull(convert(FLOAT, shp.pcs) / 1000, 0) AS ship_Kpcs
			,isnull(shp.LotAve7days, 0) AS ship_lot_cnt_7ave
			,isnull(convert(FLOAT, shp.PcsAve7days) / 1000, 0) AS ship_Kpcs_7ave
			,isnull(convert(FLOAT, wip_all.sum_pcs) / nullif(convert(FLOAT, pln.sum_pcs), 0), 0) AS wip_days
		FROM (
			SELECT day_id AS day_id
				,date_value
				,week_no
				,shift_code AS shift_code
			FROM (
				SELECT ddy.id AS day_id
					,ddy.date_value
					,ddy.week_no
					,s.shift_code AS shift_code
				FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
				CROSS JOIN (
					SELECT 0 AS shift_code
					
					UNION ALL
					
					SELECT 1 AS shift_code
					) AS s
				) AS d
			) AS dd
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_plan_v2(@package_group_id, @package_id, @device_id, @device_name, @from, @to, @time_offset)
			) AS pln ON pln.day_id = dd.day_id
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_input_shift_v2(@package_group_id, @package_id, @device_id, @device_name, @from, @to, @time_offset)
			) AS ipt ON ipt.day_id = dd.day_id
			AND ipt.shift_code = dd.shift_code
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_shipment_shift_v2(@package_group_id, @package_id, @device_id, @device_name, @from, @to, @time_offset)
			) AS shp ON shp.day_id = dd.day_id
			AND shp.shift_code = dd.shift_code
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_wip_shift_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, 1, @time_offset)
			) AS wip_all ON wip_all.day_id = dd.day_id
			AND wip_all.shift_code = dd.shift_code
		WHERE dd.day_id BETWEEN @from
				AND @to
	END
			---------------------------------------------------------------------------------------------------------
			-- process指定有
			---------------------------------------------------------------------------------------------------------
	ELSE
	BEGIN
		INSERT INTO @retTbl
		SELECT dd.day_id AS id
			,dd.date_value AS date_value
			,dd.shift_code
			,dd.week_no AS span
			,isnull(convert(FLOAT, pln.sum_pcs) / 1000, 0) AS plan_Kpcs
			,isnull(ipt.lot_count, 0) AS input_lot_cnt
			,isnull(convert(FLOAT, ipt.input_pcs) / 1000, 0) AS input_Kpcs
			,isnull(ipt.LotAve7days, 0) AS input_lot_cnt_7ave
			,isnull(convert(FLOAT, ipt.PcsAve7days) / 1000, 0) AS input_Kpcs_7ave
			,isnull(shp.lot_count, 0) AS ship_lot_cnt
			,isnull(convert(FLOAT, shp.pcs) / 1000, 0) AS ship_Kpcs
			,isnull(shp.LotAve7days, 0) AS ship_lot_cnt_7ave
			,isnull(convert(FLOAT, shp.PcsAve7days) / 1000, 0) AS ship_Kpcs_7ave
			,isnull(convert(FLOAT, wip_all.sum_pcs) / nullif(convert(FLOAT, pln.sum_pcs), 0), 0) AS wip_days
		FROM (
			SELECT day_id AS day_id
				,date_value
				,week_no
				,shift_code AS shift_code
			FROM (
				SELECT ddy.id AS day_id
					,ddy.date_value
					,ddy.week_no
					,s.shift_code AS shift_code
				FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
				CROSS JOIN (
					SELECT 0 AS shift_code
					
					UNION ALL
					
					SELECT 1 AS shift_code
					) AS s
				) AS d
			) AS dd
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_plan_v2(@package_group_id, @package_id, @device_id, @device_name, @from, @to, @time_offset)
			) AS pln ON pln.day_id = dd.day_id
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_start_shift_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @time_offset)
			) AS ipt ON ipt.day_id = dd.day_id
			AND ipt.shift_code = dd.shift_code
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_end_shift_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @time_offset)
			) AS shp ON shp.day_id = dd.day_id
			AND shp.shift_code = dd.shift_code
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_wip_shift_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, 1, @time_offset)
			) AS wip_all ON wip_all.day_id = dd.day_id
			AND wip_all.shift_code = dd.shift_code
		WHERE dd.day_id BETWEEN @from
				AND @to
	END

	RETURN
END

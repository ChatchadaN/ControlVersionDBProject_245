
CREATE FUNCTION [act].[fnc_ProductionMain_01_shift] (
	@package_group_id INT = NULL,
	@package_id INT = NULL,
	@process_id INT = NULL,
	@device_id INT = NULL,
	@device_name VARCHAR(20) = NULL,
	@from INT,
	@to INT,
	@span NVARCHAR(32)
	)
RETURNS @retTbl TABLE (
	id INT,
	date_value DATE NOT NULL,
	hour_code TINYINT NOT NULL,
	shift_code INT NULL,
	span TINYINT NOT NULL,
	plan_Kpcs FLOAT NULL,
	input_lot_cnt INT NULL,
	input_Kpcs FLOAT NULL,
	input_lot_cnt_7ave FLOAT NULL,
	input_Kpcs_7ave FLOAT NULL,
	ship_lot_cnt INT NULL,
	ship_Kpcs FLOAT NULL,
	ship_lot_cnt_7ave FLOAT NULL,
	ship_Kpcs_7ave FLOAT NULL,
	wip_days FLOAT NULL
	)

BEGIN
	---------------------------------------------------------------------------------------------------------
	-- process指定無し
	---------------------------------------------------------------------------------------------------------
	IF @process_id IS NULL
	BEGIN
		INSERT INTO @retTbl
		SELECT dd.id AS id,
			dd.date_value AS date_value,
			-- 0:day 1:night 2:not use
			dh.code AS hour_code,
			CASE 
				WHEN
					-- １つ前のshift値を集計する(例えば、2018-10-16の昼は、2018-10-15 19時の値を参照する)
					dh.code >= 9
					AND dh.code <= 20
					THEN 1
				ELSE 0
				END AS shift_code,
			dd.week_no AS span,
			isnull(convert(FLOAT, pln.sum_pcs) / 1000, 0) AS plan_Kpcs,
			isnull(ipt.lot_count, 0) AS input_lot_cnt,
			isnull(convert(FLOAT, ipt.pcs) / 1000, 0) AS input_Kpcs,
			isnull(ipt.LotAve7days, 0) AS input_lot_cnt_7ave,
			isnull(convert(FLOAT, ipt.PcsAve7days) / 1000, 0) AS input_Kpcs_7ave,
			isnull(shp.lot_count, 0) AS ship_lot_cnt,
			isnull(convert(FLOAT, shp.pcs) / 1000, 0) AS ship_Kpcs,
			isnull(shp.LotAve7days, 0) AS ship_lot_cnt_7ave,
			isnull(convert(FLOAT, shp.PcsAve7days) / 1000, 0) AS ship_Kpcs_7ave,
			isnull(convert(FLOAT, wip_all.sum_pcs) / nullif(convert(FLOAT, pln.sum_pcs), 0), 0) AS wip_days
		FROM apcsprodwh.dwh.dim_days AS dd
		CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_plan(@package_group_id, @package_id, @device_id, @device_name, @from, @to)
			) AS pln ON pln.day_id = dd.id
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_input_shift(@package_group_id, @package_id, @device_id, @device_name, @from, @to)
			) AS ipt ON ipt.day_id = dd.id
			AND ipt.hour_code = dh.code
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_shipment_shift(@package_group_id, @package_id, @device_id, @device_name, @from, @to)
			) AS shp ON shp.day_id = dd.id
			AND shp.hour_code = dh.code
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_wip(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, 1)
			) AS wip_all ON wip_all.day_id = dd.id
			AND wip_all.hour_code = dh.code
		WHERE dd.id BETWEEN @from
				AND @to
					--hour_dode = 8  : 夜shiftの最後の時間( 7:59:59)
					--hour_dode = 20 : 昼shiftの最後の時間(19:59:59)
			AND dh.code IN (8, 20)
			-- RETURN
	END
			---------------------------------------------------------------------------------------------------------
			-- process指定有
			---------------------------------------------------------------------------------------------------------
	ELSE
	BEGIN
		INSERT INTO @retTbl
		SELECT dd.id AS id,
			dd.date_value AS date_value,
			-- 0:day 1:night 2:not use
			dh.code AS hour_code,
			CASE 
				WHEN dh.code >= 9
					AND dh.code <= 20
					THEN 1
				ELSE 0
				END AS shift_code,
			dd.week_no AS span,
			isnull(convert(FLOAT, pln.sum_pcs) / 1000, 0) AS plan_Kpcs,
			isnull(ipt.lot_count, 0) AS input_lot_cnt,
			isnull(convert(FLOAT, ipt.input_pcs) / 1000, 0) AS input_Kpcs,
			isnull(ipt.LotAve7days, 0) AS input_lot_cnt_7ave,
			isnull(convert(FLOAT, ipt.PcsAve7days) / 1000, 0) AS input_Kpcs_7ave,
			isnull(shp.lot_count, 0) AS ship_lot_cnt,
			isnull(convert(FLOAT, shp.pcs) / 1000, 0) AS ship_Kpcs,
			isnull(shp.LotAve7days, 0) AS ship_lot_cnt_7ave,
			isnull(convert(FLOAT, shp.PcsAve7days) / 1000, 0) AS ship_Kpcs_7ave,
			isnull(convert(FLOAT, wip_all.sum_pcs) / nullif(convert(FLOAT, pln.sum_pcs), 0), 0) AS wip_days
		FROM apcsprodwh.dwh.dim_days AS dd
		CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_plan(@package_group_id, @package_id, @device_id, @device_name, @from, @to)
			) AS pln ON pln.day_id = dd.id
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_start_shift(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to)
			) AS ipt ON ipt.day_id = dd.id
			AND ipt.hour_code = dh.code
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_end_shift(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to)
			) AS shp ON shp.day_id = dd.id
			AND shp.hour_code = dh.code
		LEFT OUTER JOIN (
			SELECT *
			FROM storedproceduredb.act.fnc_fact_wip(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, 1)
			) AS wip_all ON wip_all.day_id = dd.id
			AND wip_all.hour_code = dh.code
		WHERE (
				dd.id BETWEEN @from
					AND @to
				)
			--hour_dode = 8  : 夜shiftの最後の時間( 7:59:59)
			--hour_dode = 20 : 昼shiftの最後の時間(19:59:59)
			AND dh.code IN (8, 20)
	END

	RETURN
END


CREATE FUNCTION [act].[fnc_ProductionMain_01_weekly] (
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
	span TINYINT NOT NULL,
	date_value DATE NOT NULL,
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
	---- plan用に指定月初、月末日を取得
	DECLARE @from_s INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days
			WHERE date_value = (
					SELECT DATEADD(dd, 1, EOMONTH(date_value, - 1))
					FROM apcsprodwh.dwh.dim_days
					WHERE id = @from
					)
			)
	DECLARE @to_e INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days
			WHERE date_value = (
					SELECT EOMONTH(date_value)
					FROM apcsprodwh.dwh.dim_days
					WHERE id = @to
					)
			)

	---------------------------------------------------------------------------------------------------------
	-- process指定無し
	---------------------------------------------------------------------------------------------------------
	IF @process_id IS NULL
	BEGIN
		INSERT INTO @retTbl
		SELECT t1.id AS id,
			t1.span AS span,
			t1.date_value AS date_value,
			t1.plan_Kpcs AS plan_Kpcs,
			t1.input_lot_cnt AS input_lot_cnt,
			t1.input_Kpcs AS input_Kpcs,
			t1.input_lot_cnt_7ave AS input_lot_cnt_7ave,
			t1.input_Kpcs_7ave AS input_Kpcs_7ave,
			t1.ship_lot_cnt AS ship_lot_cnt,
			t1.ship_Kpcs AS ship_Kpcs,
			t1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave,
			t1.ship_Kpcs_7ave AS ship_Kpcs_7ave,
			t1.wip_days AS wip_days
		FROM (
			SELECT min(pm.id) AS id,
				(
					CASE @span
						WHEN 'wk'
							THEN min(pm.wk)
						WHEN 'm'
							THEN min(pm.m)
						END
					) AS span,
				pm.y AS y,
				min(pm.date_value) AS date_value,
				sum(pm.plan_Kpcs) AS plan_Kpcs,
				sum(pm.input_lot_cnt) AS input_lot_cnt,
				sum(pm.input_Kpcs) AS input_Kpcs,
				sum(pm.input_lot_cnt_7ave) AS input_lot_cnt_7ave,
				sum(pm.input_Kpcs_7ave) AS input_Kpcs_7ave,
				sum(pm.ship_lot_cnt) AS ship_lot_cnt,
				sum(pm.ship_Kpcs) AS ship_Kpcs,
				sum(pm.ship_lot_cnt_7ave) AS ship_lot_cnt_7ave,
				sum(pm.ship_Kpcs_7ave) AS ship_Kpcs_7ave,
				sum(pm.wip_days) AS wip_days
			FROM (
				SELECT dd.id AS id,
					dd.week_no AS wk,
					dd.date_value AS date_value,
					dd.m AS m,
					dd.y AS y,
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
				LEFT OUTER JOIN (
					SELECT *
					FROM storedproceduredb.act.fnc_fact_plan(@package_group_id, @package_id, @device_id, @device_name, @from_s, @to_e)
					) AS pln ON pln.day_id = dd.id
				LEFT OUTER JOIN (
					SELECT *
					FROM storedproceduredb.act.fnc_fact_input(@package_group_id, @package_id, @device_id, @device_name, @from_s, @to_e, 0)
					) AS ipt ON ipt.day_id = dd.id
				LEFT OUTER JOIN (
					SELECT *
					FROM storedproceduredb.act.fnc_fact_shipment(@package_group_id, @package_id, @device_id, @device_name, @from_s, @to_e, 0)
					) AS shp ON shp.day_id = dd.id
				LEFT OUTER JOIN (
					SELECT *
					FROM storedproceduredb.act.fnc_fact_wip(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from_s, @to_e, 0)
					) AS wip_all ON wip_all.day_id = dd.id
				WHERE dd.id BETWEEN @from
						AND @to
				) AS pm
			GROUP BY pm.y,
				(
					CASE @span
						WHEN 'wk'
							THEN pm.wk
						WHEN 'm'
							THEN pm.m
						END
					)
			) AS t1
	END
			---------------------------------------------------------------------------------------------------------
			-- process指定有
			---------------------------------------------------------------------------------------------------------
	ELSE
	BEGIN
		INSERT INTO @retTbl
		SELECT t1.id AS id,
			t1.span AS span,
			t1.date_value AS date_value,
			t1.plan_Kpcs AS plan_Kpcs,
			t1.input_lot_cnt AS input_lot_cnt,
			t1.input_Kpcs AS input_Kpcs,
			t1.input_lot_cnt_7ave AS input_lot_cnt_7ave,
			t1.input_Kpcs_7ave AS input_Kpcs_7ave,
			t1.ship_lot_cnt AS ship_lot_cnt,
			t1.ship_Kpcs AS ship_Kpcs,
			t1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave,
			t1.ship_Kpcs_7ave AS ship_Kpcs_7ave,
			t1.wip_days AS wip_days
		FROM (
			SELECT min(pm.id) AS id,
				(
					CASE @span
						WHEN 'wk'
							THEN min(pm.wk)
						WHEN 'm'
							THEN min(pm.m)
						END
					) AS span,
				pm.y AS y,
				min(pm.date_value) AS date_value,
				sum(pm.plan_Kpcs) AS plan_Kpcs,
				sum(pm.input_lot_cnt) AS input_lot_cnt,
				sum(pm.input_Kpcs) AS input_Kpcs,
				sum(pm.input_lot_cnt_7ave) AS input_lot_cnt_7ave,
				sum(pm.input_Kpcs_7ave) AS input_Kpcs_7ave,
				sum(pm.ship_lot_cnt) AS ship_lot_cnt,
				sum(pm.ship_Kpcs) AS ship_Kpcs,
				sum(pm.ship_lot_cnt_7ave) AS ship_lot_cnt_7ave,
				sum(pm.ship_Kpcs_7ave) AS ship_Kpcs_7ave,
				sum(pm.wip_days) AS wip_days
			FROM (
				SELECT dd.id AS id,
					dd.week_no AS wk,
					dd.date_value AS date_value,
					dd.m AS m,
					dd.y AS y,
					isnull(convert(FLOAT, pln.sum_pcs) / 1000, 0) AS plan_Kpcs,
					isnull(ipt.lot_count, 0) AS input_lot_cnt,
					isnull(convert(FLOAT, ipt.input_pcs) / 1000, 0) AS input_Kpcs,
					isnull(ipt.LotAve7days, 0) AS input_lot_cnt_7ave,
					isnull(convert(FLOAT, ipt.PcsAve7days) / 1000, 0) AS input_Kpcs_7ave,
					isnull(shp.lot_count, 0) AS ship_lot_cnt,
					isnull(convert(FLOAT, shp.pcs) / 1000, 0) AS ship_Kpcs,
					isnull(shp.LotAve7days, 0) AS ship_lot_cnt_7ave,
					isnull(convert(FLOAT, shp.PcsAve7days) / 1000, 0) AS ship_Kpcs_7ave,
					isnull(convert(FLOAT, capa.sum_pcs) / 1000, 0) AS capa_Kpcs,
					isnull(convert(FLOAT, wip_all.sum_pcs) / nullif(convert(FLOAT, pln.sum_pcs), 0), 0) AS wip_days
				FROM apcsprodwh.dwh.dim_days AS dd
				LEFT OUTER JOIN (
					SELECT *
					FROM storedproceduredb.act.fnc_fact_plan(@package_group_id, @package_id, @device_id, @device_name, @from_s, @to_e)
					) AS pln ON pln.day_id = dd.id
				LEFT OUTER JOIN (
					SELECT *
					FROM storedproceduredb.act.fnc_fact_start(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from_s, @to_e, 0)
					) AS ipt ON ipt.day_id = dd.id
				LEFT OUTER JOIN (
					SELECT *
					FROM storedproceduredb.act.fnc_fact_end(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from_s, @to_e, 0)
					) AS shp ON shp.day_id = dd.id
				LEFT OUTER JOIN (
					SELECT *
					FROM storedproceduredb.act.fnc_fact_capa(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from_s, @to_e)
					) AS capa ON capa.day_id = dd.id
				LEFT OUTER JOIN (
					SELECT *
					FROM storedproceduredb.act.fnc_fact_wip(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from_s, @to_e, 0)
					) AS wip_all ON wip_all.day_id = dd.id
				WHERE dd.id BETWEEN @from
						AND @to
				) AS pm
			GROUP BY pm.y,
				(
					CASE @span
						WHEN 'wk'
							THEN pm.wk
						WHEN 'm'
							THEN pm.m
						END
					)
			) AS t1
	END

	RETURN
END

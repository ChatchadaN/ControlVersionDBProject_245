
CREATE FUNCTION [act].[fnc_ProductionMain_01_hours] (
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
	shift_code INT NULL,
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
	---------------------------------------------------------------------------------------------------------
	-- process指定無し
	---------------------------------------------------------------------------------------------------------
	IF @process_id IS NULL
	BEGIN
		INSERT INTO @retTbl
		SELECT dd.id AS id,
			CASE 
				WHEN dh.code >= 9
					AND dh.code <= 20
					THEN 0
				WHEN dh.code > 20
					AND id = @to + 1
					THEN 2
				ELSE 1
				END AS shift_code,
			dh.h AS span,
			dd.date_value AS date_value,
			0 AS plan_Kpcs,
			isnull(ipt.lot_count, 0) AS input_lot_cnt,
			isnull(convert(FLOAT, ipt.pcs) / 1000, 0) AS input_Kpcs,
			0 AS input_lot_cnt_7ave,
			0 AS input_Kpcs_7ave,
			isnull(shp.lot_count, 0) AS ship_lot_cnt,
			isnull(convert(FLOAT, shp.pcs) / 1000, 0) AS ship_Kpcs,
			0 AS ship_lot_cnt_7ave,
			0 AS ship_Kpcs_7ave,
			0 AS wip_days
		FROM apcsprodwh.dwh.dim_days AS dd
		CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
		LEFT OUTER JOIN (
			SELECT t2.day_id AS day_id,
				t2.hour_code AS hour_code,
				t2.lot_count AS lot_count,
				t2.pcs AS pcs
			FROM (
				SELECT t1.day_id AS day_id,
					t1.hour_code AS hour_code,
					sum(t1.lot_count) AS lot_count,
					sum(t1.pcs) AS pcs
				FROM (
					SELECT fi.day_id AS day_id,
						fi.hour_code AS hour_code,
						package_id,
						fi.lot_count,
						fi.pcs
					FROM apcsprodwh.dwh.fact_input AS fi WITH (NOLOCK)
					WHERE fi.day_id BETWEEN @from
							AND @to
								/*前後の日もひとまず検索対象 */
						AND (
							(
								@package_id IS NOT NULL
								AND fi.package_id = @package_id
								)
							OR (
								@package_id IS NULL
								AND fi.package_id > 0
								)
							)
						AND fi.device_id IN (
							SELECT t.id
							FROM APCSProDWH.dwh.dim_devices AS t
							WHERE (t.id = fi.device_id)
								AND (
									@device_name IS NOT NULL
									AND t.name = @device_name
									)
								OR (
									@device_name IS NULL
									AND fi.device_id > 0
									)
							)
						--AND (
						--	(
						--		@device_id IS NOT NULL
						--		AND fi.device_id = @device_id
						--		)
						--	OR (
						--		@device_id IS NULL
						--		AND fi.device_id > 0
						--		)
						--	)
					) AS t1
				GROUP BY t1.day_id,
					t1.hour_code
				) AS t2
			) AS ipt ON (ipt.day_id = dd.id)
			AND (ipt.hour_code = dh.code)
		LEFT OUTER JOIN (
			SELECT t2.day_id as day_id,
				t2.hour_code as hour_code,
				--t2.lot_count,
				t2.lot_count-t2.d_lot_counter as lot_count,
				t2.pcs as pcs,
				t2.sum_lead_time as sum_lead_time,
				t2.sum_process_time as sum_process_time,
				t2.sum_wait_time as sum_wait_time
			FROM (
				SELECT t1.day_id AS day_id,
					t1.hour_code AS hour_code,
					count(t1.lot_id) AS lot_count,
					sum(t1.d_lot_counter) as d_lot_counter,
					sum(t1.pass_pcs) AS pcs,
					sum(t1.lead_time) AS sum_lead_time,
					sum(t1.wait_time) AS sum_wait_time,
					sum(t1.process_time) AS sum_process_time
				FROM (
					SELECT fs.day_id,
						fs.hour_code,
						fs.lot_id,
						fs.pass_pcs,
						fs.lead_time,
						fs.wait_time,
						fs.process_time,
						tl.lot_no AS lot_no,
						CASE 
						WHEN substring(tl.lot_no, 5, 1) = 'D'
							THEN 1
						ELSE 0
						END AS d_lot_counter,
						tl.wip_state AS wip_state
					FROM apcsprodwh.dwh.fact_shipment AS fs WITH (NOLOCK)
					INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fs.lot_id
					WHERE fs.day_id BETWEEN @from
							AND @to
						AND (
							(
								@package_id IS NOT NULL
								AND fs.package_id = @package_id
								)
							OR (
								@package_id IS NULL
								AND fs.package_id > 0
								)
							)
						AND fs.device_id IN (
							SELECT t.id
							FROM APCSProDWH.dwh.dim_devices AS t
							WHERE (t.id = fs.device_id)
								AND (
									@device_name IS NOT NULL
									AND t.name = @device_name
									)
								OR (
									@device_name IS NULL
									AND fs.device_id > 0
									)
							)
						--AND (
						--	(
						--		@device_id IS NOT NULL
						--		AND fs.device_id = @device_id
						--		)
						--	OR (
						--		@device_id IS NULL
						--		AND fs.device_id > 0
						--		)
						--	)
						AND tl.wip_state <> 101
					) AS t1
				GROUP BY t1.day_id,
					t1.hour_code
				) AS t2
			) AS shp ON shp.day_id = dd.id
			AND shp.hour_code = dh.code
		WHERE dd.id BETWEEN @from
				AND @to
		ORDER BY id,
			span
	END
			---------------------------------------------------------------------------------------------------------
			-- process指定有
			---------------------------------------------------------------------------------------------------------
	ELSE
	BEGIN
		INSERT INTO @retTbl
		SELECT dd.id AS id,
			CASE 
				WHEN dh.code >= 9
					AND dh.code <= 20
					THEN 0
				WHEN dh.code > 20
					AND id = @to + 1
					THEN 2
				ELSE 1
				END AS shift_code,
			(
				CASE @span
					WHEN 'mm'
						THEN dh.h
					END
				) AS span,
			dd.date_value AS date_value,
			0 AS plan_Kpcs,
			0 AS input_lot_cnt,
			isnull(convert(FLOAT, ipt.input_pcs) / 1000, 0) AS input_Kpcs,
			0 AS input_lot_cnt_7ave,
			0 AS input_Kpcs_7ave,
			isnull(shp.lot_count, 0) AS ship_lot_cnt,
			isnull(convert(FLOAT, shp.pcs) / 1000, 0) AS ship_Kpcs,
			0 AS ship_lot_cnt_7ave,
			0 AS ship_Kpcs_7ave,
			0 AS wip_days
		FROM apcsprodwh.dwh.dim_days AS dd
		CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
		LEFT OUTER JOIN (
			SELECT t2.day_id AS day_id,
				t2.hour_code AS hour_code,
				t2.input_pcs AS input_pcs
			FROM (
				SELECT t1.day_id AS day_id,
					t1.hour_code AS hour_code,
					sum(t1.input_pcs) AS input_pcs
				FROM (
					SELECT fs.day_id AS day_id,
						fs.hour_code AS hour_code,
						package_id,
						fs.input_pcs
					FROM apcsprodwh.dwh.fact_start AS fs WITH (NOLOCK)
					WHERE fs.day_id BETWEEN @from
							AND @to
								/*前後の日もひとまず検索対象 */
						AND (
							(
								@package_id IS NOT NULL
								AND fs.package_id = @package_id
								)
							OR (
								@package_id IS NULL
								AND fs.package_id > 0
								)
							)
						AND (
							(
								@process_id IS NOT NULL
								AND fs.process_id = @process_id
								)
							OR (
								@process_id IS NULL
								AND fs.process_id > 0
								)
							)
						AND fs.device_id IN (
							SELECT t.id
							FROM APCSProDWH.dwh.dim_devices AS t
							WHERE (t.id = fs.device_id)
								AND (
									@device_name IS NOT NULL
									AND t.name = @device_name
									)
								OR (
									@device_name IS NULL
									AND fs.device_id > 0
									)
							)
						--AND (
						--	(
						--		@device_id IS NOT NULL
						--		AND fs.device_id = @device_id
						--		)
						--	OR (
						--		@device_id IS NULL
						--		AND fs.device_id > 0
						--		)
						--	)
					) AS t1
				GROUP BY t1.day_id,
					t1.hour_code
				) AS t2
			) AS ipt ON (ipt.day_id = dd.id)
			AND (ipt.hour_code = dh.code)
		LEFT OUTER JOIN (
			SELECT t2.day_id as day_id,
				t2.hour_code as hour_code,
				--t2.lot_count,
				t2.lot_count - t2.d_lot_counter as lot_count,
				t2.pcs as pcs,
				t2.sum_process_time as sum_process_time,
				t2.sum_wait_time as sum_wait_time
			FROM (
				SELECT t1.day_id AS day_id,
					t1.hour_code AS hour_code,
					count(t1.lot_id) AS lot_count,
					sum(t1.d_lot_counter) as d_lot_counter,
					sum(t1.pass_pcs) AS pcs,
					sum(t1.wait_time) AS sum_wait_time,
					sum(t1.process_time) AS sum_process_time
				FROM (
					SELECT fe.day_id,
						fe.hour_code,
						fe.lot_id,
						fe.pass_pcs,
						fe.wait_time,
						fe.process_time,
						tl.lot_no AS lot_no,
						CASE 
						WHEN substring(tl.lot_no, 5, 1) = 'D'
							THEN 1
						ELSE 0
						END AS d_lot_counter,
						tl.wip_state AS wip_state
					FROM apcsprodwh.dwh.fact_end AS fe WITH (NOLOCK)
					INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fe.lot_id
					WHERE fe.day_id BETWEEN @from
							AND @to
						AND (
							(
								@package_id IS NOT NULL
								AND fe.package_id = @package_id
								)
							OR (
								@package_id IS NULL
								AND fe.package_id > 0
								)
							)
						AND (
							(
								@process_id IS NOT NULL
								AND fe.process_id = @process_id
								)
							OR (
								@process_id IS NULL
								AND fe.process_id > 0
								)
							)
						AND fe.device_id IN (
							SELECT t.id
							FROM APCSProDWH.dwh.dim_devices AS t
							WHERE (t.id = fe.device_id)
								AND (
									@device_name IS NOT NULL
									AND t.name = @device_name
									)
								OR (
									@device_name IS NULL
									AND fe.device_id > 0
									)
							)
						--AND (
						--	(
						--		@device_id IS NOT NULL
						--		AND fe.device_id = @device_id
						--		)
						--	OR (
						--		@device_id IS NULL
						--		AND fe.device_id > 0
						--		)
						--	)
						and fe.code = 2
						AND tl.wip_state <> 101
					) AS t1
				GROUP BY t1.day_id,
					t1.hour_code
				) AS t2
			) AS shp ON shp.day_id = dd.id
			AND shp.hour_code = dh.code
		WHERE dd.id BETWEEN @from
				AND @to
	END

	RETURN
END

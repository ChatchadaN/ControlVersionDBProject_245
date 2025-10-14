
CREATE FUNCTION [act].[fnc_ProductionMain_02_shift] (
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
	hour_code TINYINT NOT NULL,
	shift_code INT NULL,
	delay_state_code INT NOT NULL,
	wip_all_lot_cnt INT NULL,
	wip_all_Kpcs FLOAT NULL,
	on_time_lot_cnt INT NULL,
	on_time_Kpcs FLOAT NULL,
	delayed_lot_cnt INT NULL,
	delayed_Kpcs FLOAT NULL,
	delay_rank INT NOT NULL
	)

BEGIN
	INSERT INTO @retTbl
	SELECT *
	FROM (
		SELECT dd.id AS id,
			dd.week_no AS span,
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
			isnull(wip_all.delay_state_code, 0) AS delay_state_code,
			isnull(wip_all.sum_lot_count, 0) AS wip_all_lot_cnt,
			isnull(convert(FLOAT, wip_all.sum_pcs) / 1000, 0) AS wip_all_Kpcs,
			isnull(max(wip_all.sum_lot_count * (
						CASE 
							WHEN wip_all.delay_state_code = 1
								THEN 1
							ELSE 0
							END
						)) OVER (
					PARTITION BY dd.id,
					dd.week_no,
					dd.date_value,
					dh.code
					), 0) AS on_time_lot_cnt,
			isnull(convert(FLOAT, max(wip_all.sum_pcs * (
							CASE 
								WHEN wip_all.delay_state_code = 1
									THEN 1
								ELSE 0
								END
							)) OVER (
						PARTITION BY dd.id,
						dd.week_no,
						dd.date_value,
						dh.code
						)) / 1000, 0) AS on_time_Kpcs,
			isnull(max(wip_all.sum_lot_count * (
						CASE 
							WHEN wip_all.delay_state_code = 10
								THEN 1
							ELSE 0
							END
						)) OVER (
					PARTITION BY dd.id,
					dd.week_no,
					dd.date_value,
					dh.code
					), 0) AS delayed_lot_cnt,
			isnull(convert(DECIMAL, max(wip_all.sum_pcs * (
							CASE 
								WHEN wip_all.delay_state_code = 10
									THEN 1
								ELSE 0
								END
							)) OVER (
						PARTITION BY dd.id,
						dd.week_no,
						dd.date_value,
						dh.code
						)) / 1000, 0) AS delayed_Kpcs,
			rank() OVER (
				PARTITION BY dd.id,
				dd.week_no,
				dd.date_value,
				dh.code ORDER BY wip_all.delay_state_code
				) AS delay_rank
		FROM apcsprodwh.dwh.dim_days AS dd
		CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
		LEFT OUTER JOIN (
			SELECT *
			--FROM [act].fnc_fact_wip_delay(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, 1)
			FROM act.fnc_fact_wip_delay_united(@package_group_id, @package_id, @process_id, @device_id, @device_name,  @from, @to, 1)
			) AS wip_all ON wip_all.day_id = dd.id
			AND wip_all.hour_code = dh.code
		) AS t
	WHERE (
			t.id BETWEEN @from
				AND @to
			)
		--hour_dode = 8  : 夜shiftの最後の時間( 7:59:59)
		--hour_dode = 20 : 昼shiftの最後の時間(19:59:59)
		AND t.hour_code IN (8, 20)
		AND t.delay_rank = 1

	RETURN
END

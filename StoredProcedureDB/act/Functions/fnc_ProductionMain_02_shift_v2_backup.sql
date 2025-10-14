
create FUNCTION [act].[fnc_ProductionMain_02_shift_v2_backup] (
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
	,span TINYINT NOT NULL
	,date_value DATE NOT NULL
	,hour_code TINYINT NOT NULL
	,shift_code INT NULL
	,delay_state_code INT NOT NULL
	,wip_all_lot_cnt INT NULL
	,wip_all_Kpcs FLOAT NULL
	,on_time_lot_cnt INT NULL
	,on_time_Kpcs FLOAT NULL
	,delayed_lot_cnt INT NULL
	,delayed_Kpcs FLOAT NULL
	,delay_rank INT NOT NULL
	)

BEGIN
	INSERT INTO @retTbl
	SELECT t2.new_day_id AS id
		,dd.week_no AS span
		,dd.date_value
		,t2.hour_code
		,t2.shift_code
		,t2.delay_state_code
		,t2.wip_all_lot_cnt
		,t2.wip_all_Kpcs
		,t2.on_time_lot_cnt
		,t2.on_time_Kpcs
		,t2.delayed_lot_cnt
		,t2.delayed_Kpcs
		,t2.delay_rank
	FROM (
		SELECT t1.*
			,dense_RANK() OVER (
				PARTITION BY t1.new_day_id
				,t1.shift_code ORDER BY t1.tmp_hour_code DESC
				) AS latest_hour_code
		FROM (
			SELECT dd.id
				,CASE 
					WHEN dh.code < @time_offset + 1
						THEN dd.id - 1
					ELSE dd.id
					END AS new_day_id
				,dh.code AS hour_code
				,CASE 
					WHEN dh.code - @time_offset <= 0
						THEN dh.code - @time_offset + 24
					ELSE dh.code - @time_offset
					END AS tmp_hour_code
				,CASE 
					WHEN @time_offset <= 12
						THEN CASE 
								WHEN dh.code BETWEEN (@time_offset + 1)
										AND (@time_offset + 12)
									THEN 0
								ELSE 1
								END
					ELSE CASE 
							WHEN dh.code BETWEEN (@time_offset - 12 + 1)
									AND (@time_offset)
								THEN 1
							ELSE 0
							END
					END AS shift_code
				,isnull(wip_all.delay_state_code, 0) AS delay_state_code
				,isnull(wip_all.sum_lot_count, 0) AS wip_all_lot_cnt
				,isnull(convert(DECIMAL(10, 3), wip_all.sum_pcs) / 1000, 0) AS wip_all_Kpcs
				,isnull(max(wip_all.sum_lot_count * (
							CASE 
								WHEN wip_all.delay_state_code = 1
									THEN 1
								ELSE 0
								END
							)) OVER (
						PARTITION BY dd.id
						,dd.week_no
						,dh.code
						), 0) AS on_time_lot_cnt
				,isnull(convert(DECIMAL(10, 3), max(wip_all.sum_pcs * (
								CASE 
									WHEN wip_all.delay_state_code = 1
										THEN 1
									ELSE 0
									END
								)) OVER (
							PARTITION BY dd.id
							,dd.week_no
							,dh.code
							)) / 1000, 0) AS on_time_Kpcs
				,isnull(max(wip_all.sum_lot_count * (
							CASE 
								WHEN wip_all.delay_state_code = 10
									THEN 1
								ELSE 0
								END
							)) OVER (
						PARTITION BY dd.id
						,dd.week_no
						,dh.code
						), 0) AS delayed_lot_cnt
				,isnull(convert(DECIMAL(10, 3), max(wip_all.sum_pcs * (
								CASE 
									WHEN wip_all.delay_state_code = 10
										THEN 1
									ELSE 0
									END
								)) OVER (
							PARTITION BY dd.id
							,dd.week_no
							,dh.code
							)) / 1000, 0) AS delayed_Kpcs
				,rank() OVER (
					PARTITION BY dd.id
					,dd.week_no
					,dh.code ORDER BY wip_all.delay_state_code
					) AS delay_rank
			FROM apcsprodwh.dwh.dim_days AS dd
			CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
			LEFT OUTER JOIN (
				SELECT *
				FROM act.fnc_fact_wip_delay_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, 1, @time_offset)
				) AS wip_all ON wip_all.day_id = dd.id
				AND wip_all.hour_code = dh.code
			) AS t1
		WHERE (
				t1.id BETWEEN @from
					AND @to
				)
			AND t1.delay_rank = 1
		) AS t2
	INNER JOIN apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = t2.new_day_id
	WHERE latest_hour_code = 1
		AND t2.new_day_id BETWEEN @from
			AND @to

	RETURN
END

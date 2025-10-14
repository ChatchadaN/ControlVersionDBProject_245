
create FUNCTION [act].[fnc_ProductionMain_02_weekly_v2_backup] (
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

	INSERT INTO @retTbl
	SELECT t2.id AS id
		,t2.span AS span
		,t2.date_value AS date_value
		,t2.delay_state_code AS delay_state_code
		,isnull(t2.wip_all_lot_cnt, 0) AS wip_all_lot_cnt
		,isnull(t2.wip_all_Kpcs, 0) AS wip_all_Kpcs
		,isnull(t2.on_time_lot_cnt, 0) AS on_time_lot_cnt
		,isnull(t2.on_time_Kpcs, 0) AS on_time_Kpcs
		,isnull(t2.delayed_lot_cnt, 0) AS delayed_lot_cnt
		,isnull(t2.delayed_Kpcs, 0) AS delayed_Kpcs
		,t2.delay_rank AS delay_rank
	FROM (
		SELECT *
		FROM (
			SELECT dd.id AS id
				,dd.week_no AS wk
				,dd.date_value AS date_value
				,dd.m AS m
				,dd.y AS y
				,
				--明日以降のデータを省く為
				CASE 
					WHEN dd.date_value <= getdate()
						THEN 1
					ELSE 0
					END AS flag
				,CASE @span
					WHEN 'wk'
						THEN dd.week_no
					WHEN 'm'
						THEN dd.m
					END AS span
				,rank() OVER (
					PARTITION BY CASE @span
						WHEN 'wk'
							THEN dd.week_no
						WHEN 'm'
							THEN dd.m
						END
					,CASE 
						WHEN dd.date_value <= getdate()
							THEN 1
						ELSE 0
						END ORDER BY id DESC
					) AS row_num
				,isnull(wip_all.delay_state_code, 0) AS delay_state_code
				,isnull(wip_all.sum_lot_count, 0) AS wip_all_lot_cnt
				,isnull(convert(FLOAT, wip_all.sum_pcs) / 1000, 0) AS wip_all_Kpcs
				,isnull(max(wip_all.sum_lot_count * (
							CASE 
								WHEN wip_all.delay_state_code = 1
									THEN 1
								ELSE 0
								END
							)) OVER (
						PARTITION BY dd.id
						,dd.week_no
						,dd.date_value
						), 0) AS on_time_lot_cnt
				,isnull(convert(FLOAT, max(wip_all.sum_pcs * (
								CASE 
									WHEN wip_all.delay_state_code = 1
										THEN 1
									ELSE 0
									END
								)) OVER (
							PARTITION BY dd.id
							,dd.week_no
							,dd.date_value
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
						,dd.date_value
						), 0) AS delayed_lot_cnt
				,isnull(convert(DECIMAL, max(wip_all.sum_pcs * (
								CASE 
									WHEN wip_all.delay_state_code = 10
										THEN 1
									ELSE 0
									END
								)) OVER (
							PARTITION BY dd.id
							,dd.week_no
							,dd.date_value
							)) / 1000, 0) AS delayed_Kpcs
				,rank() OVER (
					PARTITION BY dd.id
					,dd.week_no
					,dd.date_value ORDER BY wip_all.delay_state_code
					) AS delay_rank
			FROM apcsprodwh.dwh.dim_days AS dd
			LEFT OUTER JOIN (
				SELECT *
				FROM act.fnc_fact_wip_delay_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from_s, @to_e, 0, @time_offset)
				) AS wip_all ON wip_all.day_id = dd.id
			WHERE (
					dd.id BETWEEN @from
						AND @to
					)
			) AS temp2
		WHERE temp2.flag = 1
			AND temp2.row_num = 1
			AND temp2.delay_rank = 1
		) AS t2

	RETURN
END

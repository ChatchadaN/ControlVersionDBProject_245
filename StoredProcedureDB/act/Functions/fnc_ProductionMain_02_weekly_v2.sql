
CREATE FUNCTION [act].[fnc_ProductionMain_02_weekly_v2] (
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
	DECLARE @hour_flag INT = CASE @span
			WHEN 'dd'
				THEN 0
			WHEN 'wk'
				THEN 0
			WHEN 'm'
				THEN 0
			WHEN 'shift'
				THEN 1
			WHEN 'mm'
				THEN 1
			END
	---- plan用に指定月初、月末日を取得
	DECLARE @from_s INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = (
					SELECT DATEADD(dd, 1, EOMONTH(date_value, - 1))
					FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
					WHERE id = @from
					)
			)
	DECLARE @to_e INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = (
					SELECT EOMONTH(date_value)
					FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
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
				--,isnull(wip_all.sum_lot_count, 0) AS wip_all_lot_cnt
				--,isnull(convert(FLOAT, wip_all.sum_pcs) / 1000, 0) AS wip_all_Kpcs
				--Normal wip 2021.12.17
				,isnull(max(wip_all.sum_lot_count * (
							CASE 
								WHEN wip_all.delay_state_code = 0
									THEN 1
								ELSE 0
								END
							)) OVER (
						PARTITION BY dd.id
						,dd.week_no
						,dd.date_value
						), 0) AS wip_all_lot_cnt
				,isnull(convert(FLOAT, max(wip_all.sum_pcs * (
								CASE 
									WHEN wip_all.delay_state_code = 0
										THEN 1
									ELSE 0
									END
								)) OVER (
							PARTITION BY dd.id
							,dd.week_no
							,dd.date_value
							)) / 1000, 0) AS wip_all_Kpcs
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
			FROM apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK)
			------高速化の為、非関数化(元ソース:fnc_fact_wip_delay_v2)
			LEFT OUTER JOIN (
				SELECT t3.day_id AS day_id
					,t3.hour_code AS hour_code
					,t3.delay_state_code
					,t3.sum_lot_count AS sum_lot_count
					,t3.sum_pcs AS sum_pcs
				FROM (
					SELECT CASE 
							WHEN @hour_flag = 0
								THEN t2.new_day_id
							ELSE t2.day_id
							END AS day_id
						,t2.hour_code
						,t2.delay_state_code
						,t2.sum_lot_count AS sum_lot_count
						,t2.sum_pcs AS sum_pcs
						,dense_RANK() OVER (
							PARTITION BY t2.new_day_id ORDER BY t2.tmp_hour_code DESC
							) AS latest_hour_code
					FROM (
						SELECT t1.day_id
							,CASE 
								WHEN t1.hour_code < @time_offset + 1
									THEN t1.day_id - 1
								ELSE t1.day_id
								END AS new_day_id
							,t1.hour_code
							,CASE 
								WHEN t1.hour_code - @time_offset <= 0
									THEN t1.hour_code - @time_offset + 24
								ELSE t1.hour_code - @time_offset
								END AS tmp_hour_code
							,t1.delay_state_code
							,t1.sum_lot_count AS sum_lot_count
							,t1.sum_pcs AS sum_pcs
						FROM (
							SELECT wi.day_id AS day_id
								,wi.hour_code AS hour_code
								,wi.delay_state_code AS delay_state_code
								,sum(wi.lot_count) AS sum_lot_count
								,sum(cast(wi.pcs AS BIGINT)) AS sum_pcs
							FROM apcsprodwh.dwh.fact_wip AS wi WITH (NOLOCK)
							LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = wi.device_id
							WHERE (wi.hour_code > 0)
								AND (
									wi.day_id BETWEEN @from - 1
										AND @to
									)
								AND (
									(
										@package_id IS NOT NULL
										AND wi.package_id = @package_id
										)
									OR (
										@package_id IS NULL
										AND @package_group_id IS NOT NULL
										AND wi.package_group_id = @package_group_id
										)
									OR (
										@package_id IS NULL
										AND @package_group_id IS NULL
										AND wi.package_id > 0
										)
									)
								AND (
									(
										@process_id IS NOT NULL
										AND wi.process_id = @process_id
										)
									OR (
										@process_id IS NULL
										AND wi.process_id >= 0
										)
									)
								AND (
									(
										@device_name IS NOT NULL
										AND ddv.name = @device_name
										)
									OR (@device_name IS NULL)
									)
							GROUP BY wi.day_id
								,wi.hour_code
								,wi.delay_state_code
							) AS t1
						) AS t2
					) AS t3
				WHERE (
						(
							@hour_flag = 0
							AND t3.latest_hour_code = 1
							)
						OR (@hour_flag = 1)
						)
					AND t3.day_id BETWEEN @from
						AND @to
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

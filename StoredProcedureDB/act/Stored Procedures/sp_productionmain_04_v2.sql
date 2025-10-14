
CREATE PROCEDURE [act].[sp_productionmain_04_v2] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@job_id INT = NULL
	,@date_from DATE
	,@date_to DATE
	,@span NVARCHAR(32)
	,@lot_type NVARCHAR(32)
	,@chart_type INT = 0
	,@N DECIMAL(2, 1) = 1.5 --目標leadtime計算用係数
	,@time_offset INT = 0
	)
AS
BEGIN
	DECLARE @from INT
	DECLARE @to INT

	SET @from = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_from
			);
	SET @to = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_to
			);

	--IF OBJECT_ID(N'tempdb..#t_shift', N'U') IS NOT NULL
	--	DROP TABLE #t_shift;
	--IF OBJECT_ID(N'tempdb..#t_span', N'U') IS NOT NULL
	--	DROP TABLE #t_span;
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	--WEEKLY/Monthly/Daily共通  create #t_span 平均リードタイム算出用
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'wk'
		OR @span = 'm'
		OR @span = 'dd'
	BEGIN
		SELECT t2.*
		INTO #t_span
		FROM (
			SELECT t1.day_id AS day_id
				,t1.new_day_id
				,t1.shift_code
				,t1.hour_code
				,t1.y AS y
				,t1.m AS m
				,t1.week_no AS week_no
				,t1.date_value AS date_value
				,t1.lot_type
				,t1.sum_lots
				,t1.sum_pcs
				,t1.sum_lead_time
				,t1.sum_wait_time
				,t1.sum_process_time
				,t1.sum_run_time
				,t1.sum_target_lead_time
				,row_number() OVER (
					PARTITION BY t1.day_id
					,t1.hour_code
					,t1.lot_type ORDER BY t1.day_id
						,t1.hour_code
					) AS day_hour_ranking
			FROM (
				SELECT dd.date_value AS date_value
					,dd.week_no AS week_no
					,dd.m AS m
					,dd.y AS y
					,lt.*
					,CASE 
						WHEN lot_type = @lot_type
							THEN count(lot_id) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE 0
						END AS sum_lots
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(pass_pcs) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE 0
						END AS sum_pcs
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(lead_time) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE NULL
						END AS sum_lead_time
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(wait_time) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE NULL
						END AS sum_wait_time
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(process_time) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE NULL
						END AS sum_process_time
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(run_time) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE NULL
						END AS sum_run_time
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(target_lead_time) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE NULL
						END AS sum_target_lead_time
				FROM act.fnc_LeadTime_united_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @from, @to, @N, @time_offset) AS lt
				LEFT OUTER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = lt.new_day_id
				) AS t1
			) AS t2
		WHERE t2.day_hour_ranking = 1
			AND t2.new_day_id BETWEEN @from
				AND @to

		--------------------------------------------------------------------
		IF @chart_type = 0
		BEGIN
			IF @span = 'wk'
			BEGIN
				SELECT min(date_value) AS date_value
					,min(week_no) AS span
					,y AS y
					,week_no AS week_no
					,sum(sum_lots) AS sum_lots
					,isnull(convert(FLOAT, sum(sum_pcs)) / 1000, 0) AS sum_kpcs
					,sum(sum_lead_time) / nullif(sum(sum_lots), 0) AS avg_lead_time
					,sum(sum_wait_time) / nullif(sum(sum_lots), 0) AS avg_wait_time
					,sum(sum_process_time) / nullif(sum(sum_lots), 0) AS avg_process_time
					,sum(sum_run_time) / nullif(sum(sum_lots), 0) AS avg_run_time
					,sum(sum_target_lead_time) / nullif(sum(sum_lots), 0) AS avg_target_lead_time
				FROM #t_span
				GROUP BY y
					,week_no
				ORDER BY y
					,week_no
			END

			IF @span = 'm'
			BEGIN
				SELECT min(date_value) AS date_value
					,min(m) AS span
					,y AS y
					,m AS m
					,sum(sum_lots) AS sum_lots
					,isnull(convert(FLOAT, sum(sum_pcs)) / 1000, 0) AS sum_kpcs
					,sum(sum_lead_time) / nullif(sum(sum_lots), 0) AS avg_lead_time
					,sum(sum_wait_time) / nullif(sum(sum_lots), 0) AS avg_wait_time
					,sum(sum_process_time) / nullif(sum(sum_lots), 0) AS avg_process_time
					,sum(sum_run_time) / nullif(sum(sum_lots), 0) AS avg_run_time
					,sum(sum_target_lead_time) / nullif(sum(sum_lots), 0) AS avg_target_lead_time
				FROM #t_span
				GROUP BY y
					,m
				ORDER BY y
					,m
			END

			IF @span = 'dd'
			BEGIN
				SELECT date_value AS date_value
					,min(new_day_id) AS span
					,sum(sum_lots) AS sum_lots
					,isnull(convert(FLOAT, sum(sum_pcs)) / 1000, 0) AS sum_kpcs
					,sum(sum_lead_time) / nullif(sum(sum_lots), 0) AS avg_lead_time
					,sum(sum_wait_time) / nullif(sum(sum_lots), 0) AS avg_wait_time
					,sum(sum_process_time) / nullif(sum(sum_lots), 0) AS avg_process_time
					,sum(sum_run_time) / nullif(sum(sum_lots), 0) AS avg_run_time
					,sum(sum_target_lead_time) / nullif(sum(sum_lots), 0) AS avg_target_lead_time
				FROM #t_span
				GROUP BY date_value
				ORDER BY date_value
			END
		END

		-------------------------------------------------------------------------------------------------------------------------------------------------------
		--WEEKLY/Monthly/Daily バラツキ 集計
		-------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @chart_type = 1
		BEGIN
			-------------------------------------------------------------------------------------------------------------------------------------------------------
			--WEEKLY  create #t_weekly_variation バラツキ
			-------------------------------------------------------------------------------------------------------------------------------------------------------
			IF @span = 'wk'
			BEGIN
				SELECT t3.*
					,CASE 
						WHEN t3.n = 1
							THEN (
									CASE 
										WHEN t3.avg_lead_time < t3.l_iqr
											THEN 0
										ELSE t3.n
										END
									)
						WHEN t3.n = 4
							THEN (
									CASE 
										WHEN t3.avg_lead_time > t3.u_iqr
											THEN 5
										ELSE t3.n
										END
									)
						ELSE t3.n
						END AS n2
				INTO #t_weekly_variation
				FROM (
					SELECT t2.*
						,CASE 
							WHEN (t2.hi <= t2.avg_lead_time)
								AND (t2.avg_lead_time <= t2.u_iqr)
								THEN max(t2.avg_lead_time) OVER (
										PARTITION BY t2.y
										,t2.week_no
										,CASE 
											WHEN (t2.hi <= t2.avg_lead_time)
												AND (t2.avg_lead_time <= t2.u_iqr)
												THEN 0
											ELSE 1
											END
										)
							ELSE NULL
							END AS max_val
						,CASE 
							WHEN (t2.l_iqr <= t2.avg_lead_time)
								AND (t2.avg_lead_time <= t2.lo)
								THEN min(t2.avg_lead_time) OVER (
										PARTITION BY t2.y
										,t2.week_no
										,CASE 
											WHEN (t2.l_iqr <= t2.avg_lead_time)
												AND (t2.avg_lead_time <= t2.lo)
												THEN 0
											ELSE 1
											END
										)
							ELSE NULL
							END AS min_val
						,CASE 
							WHEN t2.u_iqr < t2.avg_lead_time
								THEN t2.avg_lead_time
							ELSE NULL
							END AS out_of_max_val
						,CASE 
							WHEN t2.l_iqr > t2.avg_lead_time
								THEN t2.avg_lead_time
							ELSE NULL
							END AS out_of_min_val
					FROM (
						SELECT t1.*
							,t1.hi + t1.iqr * 1.5 AS u_iqr
							,CASE 
								WHEN t1.lo - t1.iqr * 1.5 > 0
									THEN t1.lo - t1.iqr * 1.5
								ELSE 0
								END AS l_iqr
						FROM (
							SELECT t.*
								,(
									PERCENTILE_CONT(0.75) WITHIN GROUP (
											ORDER BY avg_lead_time
											) OVER (
											PARTITION BY y
											,week_no
											) - PERCENTILE_CONT(0.25) WITHIN
									GROUP (
											ORDER BY avg_lead_time
											) OVER (
											PARTITION BY y
											,week_no
											)
									) AS iqr
							FROM (
								SELECT *
									,CASE 
										WHEN avg_lead_time IS NULL
											THEN NULL
										ELSE NTILE(4) OVER (
												PARTITION BY y
												,week_no
												,CASE 
													WHEN avg_lead_time IS NULL
														THEN 0
													ELSE 1
													END ORDER BY avg_lead_time
												)
										END AS n
									,PERCENTILE_CONT(0.75) WITHIN
								GROUP (
										ORDER BY avg_lead_time
										) OVER (
										PARTITION BY y
										,week_no
										) AS hi
									,PERCENTILE_CONT(0.5) WITHIN
								GROUP (
										ORDER BY avg_lead_time
										) OVER (
										PARTITION BY y
										,week_no
										) AS mid
									,PERCENTILE_CONT(0.25) WITHIN
								GROUP (
										ORDER BY avg_lead_time
										) OVER (
										PARTITION BY y
										,week_no
										) AS lo
								FROM (
									SELECT *
										,(sum_lead_time) / nullif((sum_lots), 0) AS avg_lead_time
									FROM #t_span
									) AS t0
								) AS t
							) AS t1
						) AS t2
					) AS t3

				---
				--box chart 箱ひげグラフ
				SELECT min(date_value) AS date_value
					,min(week_no) AS span
					,y AS y
					,week_no AS week_no
					,max(out_of_max_val) AS out_of_max_val
					,max(max_val) AS max_val
					,max(hi) AS hi
					,min(mid) AS mid
					,min(lo) AS lo
					,min(min_val) AS min_val
					,min(out_of_min_val) AS out_of_min_val
				FROM #t_weekly_variation
				GROUP BY y
					,week_no
				ORDER BY y
					,week_no;

				--outlier 外れ値
				SELECT min(date_value) OVER (
						PARTITION BY y
						,week_no ORDER BY date_value
						) AS date_value
					,min(week_no) OVER (
						PARTITION BY y
						,week_no ORDER BY date_value
						) AS span
					,out_of_max_val AS out_of_max_val
					,out_of_min_val AS out_of_min_val
				FROM #t_weekly_variation
				WHERE n2 IN (
						0
						,5
						)
				ORDER BY day_id
					,hour_code;
			END

			-------------------------------------------------------------------------------------------------------------------------------------------------------
			--Monthly  create #t_monthly_variation バラツキ
			-------------------------------------------------------------------------------------------------------------------------------------------------------
			IF @span = 'm'
			BEGIN
				SELECT t3.*
					,CASE 
						WHEN t3.n = 1
							THEN (
									CASE 
										WHEN t3.avg_lead_time < t3.l_iqr
											THEN 0
										ELSE t3.n
										END
									)
						WHEN t3.n = 4
							THEN (
									CASE 
										WHEN t3.avg_lead_time > t3.u_iqr
											THEN 5
										ELSE t3.n
										END
									)
						ELSE t3.n
						END AS n2
				INTO #t_monthly_variation
				FROM (
					SELECT t2.*
						,CASE 
							WHEN (t2.hi <= t2.avg_lead_time)
								AND (t2.avg_lead_time <= t2.u_iqr)
								THEN max(t2.avg_lead_time) OVER (
										PARTITION BY t2.y
										,t2.m
										,CASE 
											WHEN (t2.hi <= t2.avg_lead_time)
												AND (t2.avg_lead_time <= t2.u_iqr)
												THEN 0
											ELSE 1
											END
										)
							ELSE NULL
							END AS max_val
						,CASE 
							WHEN (t2.l_iqr <= t2.avg_lead_time)
								AND (t2.avg_lead_time <= t2.lo)
								THEN min(t2.avg_lead_time) OVER (
										PARTITION BY t2.y
										,t2.m
										,CASE 
											WHEN (t2.l_iqr <= t2.avg_lead_time)
												AND (t2.avg_lead_time <= t2.lo)
												THEN 0
											ELSE 1
											END
										)
							ELSE NULL
							END AS min_val
						,CASE 
							WHEN t2.u_iqr < t2.avg_lead_time
								THEN t2.avg_lead_time
							ELSE NULL
							END AS out_of_max_val
						,CASE 
							WHEN t2.l_iqr > t2.avg_lead_time
								THEN t2.avg_lead_time
							ELSE NULL
							END AS out_of_min_val
					FROM (
						SELECT t1.*
							,t1.hi + t1.iqr * 1.5 AS u_iqr
							,CASE 
								WHEN t1.lo - t1.iqr * 1.5 > 0
									THEN t1.lo - t1.iqr * 1.5
								ELSE 0
								END AS l_iqr
						FROM (
							SELECT t.*
								,(
									PERCENTILE_CONT(0.75) WITHIN GROUP (
											ORDER BY avg_lead_time
											) OVER (
											PARTITION BY y
											,m
											) - PERCENTILE_CONT(0.25) WITHIN
									GROUP (
											ORDER BY avg_lead_time
											) OVER (
											PARTITION BY y
											,m
											)
									) AS iqr
							FROM (
								SELECT *
									,CASE 
										WHEN avg_lead_time IS NULL
											THEN NULL
										ELSE NTILE(4) OVER (
												PARTITION BY y
												,m
												,CASE 
													WHEN avg_lead_time IS NULL
														THEN 0
													ELSE 1
													END ORDER BY avg_lead_time
												)
										END AS n
									,PERCENTILE_CONT(0.75) WITHIN
								GROUP (
										ORDER BY avg_lead_time
										) OVER (
										PARTITION BY y
										,m
										) AS hi
									,PERCENTILE_CONT(0.5) WITHIN
								GROUP (
										ORDER BY avg_lead_time
										) OVER (
										PARTITION BY y
										,m
										) AS mid
									,PERCENTILE_CONT(0.25) WITHIN
								GROUP (
										ORDER BY avg_lead_time
										) OVER (
										PARTITION BY y
										,m
										) AS lo
								FROM (
									SELECT *
										,(sum_lead_time) / nullif((sum_lots), 0) AS avg_lead_time
									FROM #t_span
									) AS t0
								) AS t
							) AS t1
						) AS t2
					) AS t3

				--box chart 箱ひげグラフ
				SELECT min(date_value) AS date_value
					,min(m) AS span
					,y AS y
					,m AS m
					,max(out_of_max_val) AS out_of_max_val
					,max(max_val) AS max_val
					,max(hi) AS hi
					,min(mid) AS mid
					,min(lo) AS lo
					,min(min_val) AS min_val
					,min(out_of_min_val) AS out_of_min_val
				FROM #t_monthly_variation
				GROUP BY y
					,m
				ORDER BY y
					,m;

				--outlier 外れ値
				SELECT min(date_value) OVER (
						PARTITION BY y
						,m ORDER BY date_value
						) AS date_value
					,min(week_no) OVER (
						PARTITION BY y
						,m ORDER BY date_value
						) AS span
					,out_of_max_val AS out_of_max_val
					,out_of_min_val AS out_of_min_val
				FROM #t_monthly_variation
				WHERE n2 IN (
						0
						,5
						)
				ORDER BY day_id
					,hour_code;
			END

			-------------------------------------------------------------------------------------------------------------------------------------------------------
			--Daily  create #t_daily_variation バラツキ
			-------------------------------------------------------------------------------------------------------------------------------------------------------
			IF @span = 'dd'
			BEGIN
				SELECT t3.*
					,CASE 
						WHEN t3.n = 1
							THEN (
									CASE 
										WHEN t3.avg_lead_time < t3.l_iqr
											THEN 0
										ELSE t3.n
										END
									)
						WHEN t3.n = 4
							THEN (
									CASE 
										WHEN t3.avg_lead_time > t3.u_iqr
											THEN 5
										ELSE t3.n
										END
									)
						ELSE t3.n
						END AS n2
				INTO #t_variation
				FROM (
					SELECT t2.*
						,CASE 
							WHEN (t2.hi <= t2.avg_lead_time)
								AND (t2.avg_lead_time <= t2.u_iqr)
								THEN max(t2.avg_lead_time) OVER (
										PARTITION BY t2.new_day_id
										,CASE 
											WHEN (t2.hi <= t2.avg_lead_time)
												AND (t2.avg_lead_time <= t2.u_iqr)
												THEN 0
											ELSE 1
											END
										)
							ELSE NULL
							END AS max_val
						,CASE 
							WHEN (t2.l_iqr <= t2.avg_lead_time)
								AND (t2.avg_lead_time <= t2.lo)
								THEN min(t2.avg_lead_time) OVER (
										PARTITION BY t2.new_day_id
										,CASE 
											WHEN (t2.l_iqr <= t2.avg_lead_time)
												AND (t2.avg_lead_time <= t2.lo)
												THEN 0
											ELSE 1
											END
										)
							ELSE NULL
							END AS min_val
						,CASE 
							WHEN t2.u_iqr < t2.avg_lead_time
								THEN t2.avg_lead_time
							ELSE NULL
							END AS out_of_max_val
						,CASE 
							WHEN t2.l_iqr > t2.avg_lead_time
								THEN t2.avg_lead_time
							ELSE NULL
							END AS out_of_min_val
					FROM (
						SELECT t1.*
							,t1.hi + t1.iqr * 1.5 AS u_iqr
							,CASE 
								WHEN t1.lo - t1.iqr * 1.5 > 0
									THEN t1.lo - t1.iqr * 1.5
								ELSE 0
								END AS l_iqr
						FROM (
							SELECT t.*
								,(
									PERCENTILE_CONT(0.75) WITHIN GROUP (
											ORDER BY avg_lead_time
											) OVER (PARTITION BY new_day_id) - PERCENTILE_CONT(0.25) WITHIN
									GROUP (
											ORDER BY avg_lead_time
											) OVER (PARTITION BY new_day_id)
									) AS iqr
							FROM (
								SELECT *
									,CASE 
										WHEN avg_lead_time IS NULL
											THEN NULL
										ELSE NTILE(4) OVER (
												PARTITION BY new_day_id
												,CASE 
													WHEN avg_lead_time IS NULL
														THEN 0
													ELSE 1
													END ORDER BY avg_lead_time
												)
										END AS n
									,PERCENTILE_CONT(0.75) WITHIN
								GROUP (
										ORDER BY avg_lead_time
										) OVER (PARTITION BY new_day_id) AS hi
									,PERCENTILE_CONT(0.5) WITHIN
								GROUP (
										ORDER BY avg_lead_time
										) OVER (PARTITION BY new_day_id) AS mid
									,PERCENTILE_CONT(0.25) WITHIN
								GROUP (
										ORDER BY avg_lead_time
										) OVER (PARTITION BY new_day_id) AS lo
								FROM (
									SELECT *
										,(sum_lead_time) / nullif((sum_lots), 0) AS avg_lead_time
									FROM #t_span
									) AS t0
								) AS t
							) AS t1
						) AS t2
					) AS t3

				---
				--box chart 箱ひげグラフ
				SELECT date_value AS date_value
					,min(new_day_id) AS span
					,max(out_of_max_val) AS out_of_max_val
					,max(max_val) AS max_val
					,max(hi) AS hi
					,min(mid) AS mid
					,min(lo) AS lo
					,min(min_val) AS min_val
					,min(out_of_min_val) AS out_of_min_val
				FROM #t_variation
				GROUP BY date_value
				ORDER BY date_value;

				--outlier 外れ値
				SELECT date_value AS date_value
					,new_day_id AS span
					,out_of_max_val AS out_of_max_val
					,out_of_min_val AS out_of_min_val
				FROM #t_variation
				WHERE n2 IN (
						0
						,5
						)
				ORDER BY day_id
					,hour_code
			END
		END
	END

	------------------------------------------------------------------------------------------------------------------------------------------------------
	--shift
	------------------------------------------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	--shift  create #t_shift
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'shift'
	BEGIN
		SELECT TEMP.*
			,dd.date_value AS date_value
		INTO #t_shift_forAve
		FROM (
			SELECT t2.new_day_id
				,min(t2.new_day_id) AS span
				,t2.shift_code
				,max(sum_lots) AS sum_lots
				,isnull(convert(FLOAT, max(sum_pcs)) / 1000, 0) AS sum_kpcs
				,max(avg_lead_time) AS avg_lead_time
				,max(avg_wait_time) AS avg_wait_time
				,max(avg_process_time) AS avg_process_time
				,max(avg_run_time) AS avg_run_time
				,max(avg_target_lead_time) AS avg_target_lead_time
			FROM (
				SELECT t1.day_id AS day_id
					,t1.new_day_id
					,t1.hour_code
					,t1.shift_code
					,t1.lot_type
					,t1.sum_lots
					,t1.sum_pcs
					,t1.avg_lead_time
					,t1.avg_wait_time
					,t1.avg_process_time
					,t1.avg_run_time
					,t1.avg_target_lead_time
				FROM (
					SELECT lt.*
						,CASE 
							WHEN lot_type = @lot_type
								THEN count(lot_id) OVER (
										PARTITION BY new_day_id
										,shift_code
										,lot_type
										)
							ELSE 0
							END AS sum_lots
						,CASE 
							WHEN lot_type = @lot_type
								THEN sum(pass_pcs) OVER (
										PARTITION BY new_day_id
										,shift_code
										,lot_type
										)
							ELSE 0
							END AS sum_pcs
						,CASE 
							WHEN lot_type = @lot_type
								THEN AVG(lead_time) OVER (
										PARTITION BY new_day_id
										,shift_code
										,lot_type
										)
							ELSE NULL
							END AS avg_lead_time
						,CASE 
							WHEN lot_type = @lot_type
								THEN AVG(wait_time) OVER (
										PARTITION BY new_day_id
										,shift_code
										,lot_type
										)
							ELSE NULL
							END AS avg_wait_time
						,CASE 
							WHEN lot_type = @lot_type
								THEN AVG(process_time) OVER (
										PARTITION BY new_day_id
										,shift_code
										,lot_type
										)
							ELSE NULL
							END AS avg_process_time
						,CASE 
							WHEN lot_type = @lot_type
								THEN AVG(run_time) OVER (
										PARTITION BY new_day_id
										,shift_code
										,lot_type
										)
							ELSE NULL
							END AS avg_run_time
						,CASE 
							WHEN lot_type = @lot_type
								THEN AVG(target_lead_time) OVER (
										PARTITION BY new_day_id
										,shift_code
										,lot_type
										)
							ELSE NULL
							END AS avg_target_lead_time
					FROM act.fnc_LeadTime_united_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @from, @to, @N, @time_offset) AS lt
					) AS t1
				) AS t2
			GROUP BY t2.new_day_id
				,shift_code
			) AS TEMP
		LEFT OUTER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = TEMP.new_day_id
		WHERE new_day_id BETWEEN @from
				AND @to

		----------------
		SELECT t2.*
		INTO #t_shift
		FROM (
			SELECT t1.day_id AS day_id
				,t1.new_day_id
				,t1.shift_code
				,t1.hour_code
				,t1.y AS y
				,t1.m AS m
				,t1.week_no AS week_no
				,t1.date_value AS date_value
				,t1.lot_type
				,t1.sum_lots
				,t1.sum_pcs
				,t1.sum_lead_time
				,t1.sum_wait_time
				,t1.sum_process_time
				,t1.sum_run_time
				,t1.sum_target_lead_time
				,row_number() OVER (
					PARTITION BY t1.day_id
					,t1.hour_code
					,t1.lot_type ORDER BY t1.day_id
						,t1.hour_code
					) AS day_hour_ranking
			FROM (
				SELECT dd.date_value AS date_value
					,dd.week_no AS week_no
					,dd.m AS m
					,dd.y AS y
					,lt.*
					,CASE 
						WHEN lot_type = @lot_type
							THEN count(lot_id) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE 0
						END AS sum_lots
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(pass_pcs) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE 0
						END AS sum_pcs
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(lead_time) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE NULL
						END AS sum_lead_time
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(wait_time) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE NULL
						END AS sum_wait_time
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(process_time) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE NULL
						END AS sum_process_time
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(run_time) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE NULL
						END AS sum_run_time
					,CASE 
						WHEN lot_type = @lot_type
							THEN sum(target_lead_time) OVER (
									PARTITION BY day_id
									,hour_code
									,lot_type
									)
						ELSE NULL
						END AS sum_target_lead_time
				FROM act.fnc_LeadTime_united_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @from, @to, @N, @time_offset) AS lt
				LEFT OUTER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = lt.new_day_id
				) AS t1
			) AS t2
		WHERE t2.day_hour_ranking = 1
			AND t2.new_day_id BETWEEN @from
				AND @to

		-------------------------------------------------------------------------------------------------------------------------------------------------------
		--shift  create #t_variation ばらつき用
		-------------------------------------------------------------------------------------------------------------------------------------------------------
		SELECT t3.*
			,CASE 
				WHEN t3.n = 1
					THEN (
							CASE 
								WHEN t3.avg_lead_time < t3.l_iqr
									THEN 0
								ELSE t3.n
								END
							)
				WHEN t3.n = 4
					THEN (
							CASE 
								WHEN t3.avg_lead_time > t3.u_iqr
									THEN 5
								ELSE t3.n
								END
							)
				ELSE t3.n
				END AS n2
		INTO #t_shift_variation
		FROM (
			SELECT t2.*
				,CASE 
					WHEN (t2.hi <= t2.avg_lead_time)
						AND (t2.avg_lead_time <= t2.u_iqr)
						THEN max(t2.avg_lead_time) OVER (
								PARTITION BY t2.new_day_id
								,shift_code
								,CASE 
									WHEN (t2.hi <= t2.avg_lead_time)
										AND (t2.avg_lead_time <= t2.u_iqr)
										THEN 0
									ELSE 1
									END
								)
					ELSE NULL
					END AS max_val
				,CASE 
					WHEN (t2.l_iqr <= t2.avg_lead_time)
						AND (t2.avg_lead_time <= t2.lo)
						THEN min(t2.avg_lead_time) OVER (
								PARTITION BY t2.new_day_id
								,shift_code
								,CASE 
									WHEN (t2.l_iqr <= t2.avg_lead_time)
										AND (t2.avg_lead_time <= t2.lo)
										THEN 0
									ELSE 1
									END
								)
					ELSE NULL
					END AS min_val
				,CASE 
					WHEN t2.u_iqr < t2.avg_lead_time
						THEN t2.avg_lead_time
					ELSE NULL
					END AS out_of_max_val
				,CASE 
					WHEN t2.l_iqr > t2.avg_lead_time
						THEN t2.avg_lead_time
					ELSE NULL
					END AS out_of_min_val
			FROM (
				SELECT t1.*
					,t1.hi + t1.iqr * 1.5 AS u_iqr
					,CASE 
						WHEN t1.lo - t1.iqr * 1.5 > 0
							THEN t1.lo - t1.iqr * 1.5
						ELSE 0
						END AS l_iqr
				FROM (
					SELECT t.*
						,(
							PERCENTILE_CONT(0.75) WITHIN GROUP (
									ORDER BY avg_lead_time
									) OVER (
									PARTITION BY new_day_id
									,shift_code
									) - PERCENTILE_CONT(0.25) WITHIN
							GROUP (
									ORDER BY avg_lead_time
									) OVER (
									PARTITION BY new_day_id
									,shift_code
									)
							) AS iqr
					FROM (
						SELECT *
							,CASE 
								WHEN avg_lead_time IS NULL
									THEN NULL
								ELSE NTILE(4) OVER (
										PARTITION BY new_day_id
										,shift_code
										,CASE 
											WHEN avg_lead_time IS NULL
												THEN 0
											ELSE 1
											END ORDER BY avg_lead_time
										)
								END AS n
							,PERCENTILE_CONT(0.75) WITHIN
						GROUP (
								ORDER BY avg_lead_time
								) OVER (
								PARTITION BY new_day_id
								,shift_code
								) AS hi
							,PERCENTILE_CONT(0.5) WITHIN
						GROUP (
								ORDER BY avg_lead_time
								) OVER (
								PARTITION BY new_day_id
								,shift_code
								) AS mid
							,PERCENTILE_CONT(0.25) WITHIN
						GROUP (
								ORDER BY avg_lead_time
								) OVER (
								PARTITION BY new_day_id
								,shift_code
								) AS lo
						FROM (
							SELECT *
								,(sum_lead_time) / nullif((sum_lots), 0) AS avg_lead_time
							FROM #t_shift
							) AS t0
						) AS t
					) AS t1
				) AS t2
			) AS t3

		IF @chart_type = 0
		BEGIN
			-- daytime data
			SELECT *
			FROM #t_shift_forAve
			WHERE shift_code = 0
			ORDER BY new_day_id
				,shift_code

			-- nighttime data
			SELECT *
			FROM #t_shift_forAve
			WHERE shift_code = 1
			ORDER BY new_day_id
				,shift_code
		END

		---------------------------ばらつきchart
		IF @chart_type = 1
		BEGIN
			-- daytime data
			--box chart 箱ひげグラフ
			SELECT date_value AS date_value
				,min(shift_code) AS shift_code
				,min(new_day_id) AS span
				,max(out_of_max_val) AS out_of_max_val
				,max(max_val) AS max_val
				,max(hi) AS hi
				,min(mid) AS mid
				,min(lo) AS lo
				,min(min_val) AS min_val
				,min(out_of_min_val) AS out_of_min_val
			FROM (
				SELECT *
				FROM #t_shift_variation
				WHERE shift_code = 0
				) AS t
			GROUP BY date_value
			ORDER BY date_value;

			--outlier 外れ値
			SELECT date_value AS date_value
				,shift_code AS shift_code
				,new_day_id AS span
				,out_of_max_val AS out_of_max_val
				,out_of_min_val AS out_of_min_val
			FROM #t_shift_variation
			WHERE shift_code = 0
				AND n2 IN (
					0
					,5
					)
			ORDER BY day_id
				,hour_code;

			-- nighttime data
			--box chart 箱ひげグラフ
			SELECT date_value AS date_value
				,min(shift_code) AS shift_code
				,min(new_day_id) AS span
				,max(out_of_max_val) AS out_of_max_val
				,max(max_val) AS max_val
				,max(hi) AS hi
				,min(mid) AS mid
				,min(lo) AS lo
				,min(min_val) AS min_val
				,min(out_of_min_val) AS out_of_min_val
			FROM (
				SELECT *
				FROM #t_shift_variation
				WHERE shift_code = 1
				) AS t
			GROUP BY date_value
			ORDER BY date_value;

			--outlier 外れ値
			SELECT date_value AS date_value
				,shift_code AS shift_code
				,new_day_id AS span
				,out_of_max_val AS out_of_max_val
				,out_of_min_val AS out_of_min_val
			FROM #t_shift_variation
			WHERE shift_code = 1
				AND n2 IN (
					0
					,5
					)
			ORDER BY day_id
				,hour_code;
		END
	END

	-------------------------------------------------------------------------------------------------------------------------------------------------------
	--HOURS
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'mm'
	BEGIN
		SELECT t3.*
			,dh.h AS span
			,dd.date_value AS date_value
		FROM (
			SELECT t2.day_id
				,t2.hour_code
				,max(sum_lots) AS sum_lots
				,isnull(convert(FLOAT, max(sum_pcs)) / 1000, 0) AS sum_kpcs
				,max(avg_lead_time) AS avg_lead_time
				,max(avg_wait_time) AS avg_wait_time
				,max(avg_process_time) AS avg_process_time
				,max(avg_run_time) AS avg_run_time
				,max(avg_target_lead_time) AS avg_target_lead_time
			FROM (
				SELECT t1.day_id AS day_id
					,t1.new_day_id
					,t1.hour_code
					,t1.lot_type
					,t1.sum_lots
					,t1.sum_pcs
					,t1.avg_lead_time
					,t1.avg_wait_time
					,t1.avg_process_time
					,t1.avg_run_time
					,t1.avg_target_lead_time
				FROM (
					SELECT lt.*
						,CASE 
							WHEN lot_type = @lot_type
								THEN count(lot_id) OVER (
										PARTITION BY day_id
										,hour_code
										,lot_type
										)
							ELSE 0
							END AS sum_lots
						,CASE 
							WHEN lot_type = @lot_type
								THEN sum(pass_pcs) OVER (
										PARTITION BY day_id
										,hour_code
										,lot_type
										)
							ELSE 0
							END AS sum_pcs
						,CASE 
							WHEN lot_type = @lot_type
								THEN AVG(lead_time) OVER (
										PARTITION BY day_id
										,hour_code
										,lot_type
										)
							ELSE NULL
							END AS avg_lead_time
						,CASE 
							WHEN lot_type = @lot_type
								THEN AVG(wait_time) OVER (
										PARTITION BY day_id
										,hour_code
										,lot_type
										)
							ELSE NULL
							END AS avg_wait_time
						,CASE 
							WHEN lot_type = @lot_type
								THEN AVG(process_time) OVER (
										PARTITION BY day_id
										,hour_code
										,lot_type
										)
							ELSE NULL
							END AS avg_process_time
						,CASE 
							WHEN lot_type = @lot_type
								THEN AVG(run_time) OVER (
										PARTITION BY day_id
										,hour_code
										,lot_type
										)
							ELSE NULL
							END AS avg_run_time
						,CASE 
							WHEN lot_type = @lot_type
								THEN AVG(target_lead_time) OVER (
										PARTITION BY day_id
										,hour_code
										,lot_type
										)
							ELSE NULL
							END AS avg_target_lead_time
					FROM act.fnc_LeadTime_united_V2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @from, @to, @N, @time_offset) AS lt
					) AS t1
				WHERE t1.new_day_id BETWEEN @from
						AND @to
				) AS t2
			GROUP BY t2.day_id
				,t2.hour_code
			) AS t3
		LEFT OUTER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = t3.day_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_hours AS dh WITH (NOLOCK) ON dh.code = t3.hour_code
		ORDER BY day_id
			,hour_code
	END
END

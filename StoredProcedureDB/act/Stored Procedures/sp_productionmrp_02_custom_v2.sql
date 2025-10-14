
CREATE PROCEDURE [act].[sp_productionmrp_02_custom_v2] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@date_from DATE
	,@date_to DATE
	,@d_lot INT = 1
	,@hour_flag INT = 0
	,@target_device NVARCHAR(32) = NULL
	,@time_offset INT = 0
	)
AS
BEGIN
	--IF OBJECT_ID(N'tempdb..#t_wip', N'U') IS NOT NULL
	--	DROP TABLE #t_wip;
	--IF OBJECT_ID(N'tempdb..#t_wip_init', N'U') IS NOT NULL
	--	DROP TABLE #t_wip_init;
	DECLARE @from INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_from
			);
	DECLARE @to INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_to
			);
	DECLARE @finish_hour_code INT = CASE 
			WHEN @to = (
					SELECT finished_day_id
					FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
					WHERE to_fact_table = 'dwh.fact_wip'
					)
				THEN (
						SELECT finished_hour_code
						FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
						WHERE to_fact_table = 'dwh.fact_wip'
						)
			ELSE 24
			END;

	-------------
	-- fact_wip
	-------------
	SELECT *
		,dense_RANK() OVER (
			PARTITION BY t3.new_day_id ORDER BY t3.tmp_hour_code DESC
			) AS latest_hour_code
	INTO #t_wip
	FROM (
		SELECT t2.day_id
			,CASE 
				WHEN hour_code < @time_offset + 1
					THEN day_id - 1
				ELSE day_id
				END AS new_day_id
			,t2.hour_code
			,CASE 
				WHEN hour_code - @time_offset <= 0
					THEN hour_code - @time_offset + 24
				ELSE hour_code - @time_offset
				END AS tmp_hour_code
			,t2.sum_lot_count_target
			,t2.sum_lot_count_non_target
			,t2.sum_pcs_target
			,t2.sum_pcs_non_target
		FROM (
			SELECT t1.day_id
				,t1.hour_code
				,sum(t1.sum_lot_count_target) AS sum_lot_count_target
				,sum(t1.sum_lot_count_non_target) AS sum_lot_count_non_target
				,sum(t1.sum_pcs_target) AS sum_pcs_target
				,sum(t1.sum_pcs_non_target) AS sum_pcs_non_target
			FROM (
				SELECT d.day_id
					,d.hour_code
					,fw.device_name
					,fw.sum_lot_count_target
					,fw.sum_lot_count_non_target
					,fw.sum_pcs_target
					,fw.sum_pcs_non_target
				FROM (
					SELECT dd.id AS day_id
						,dh.code AS hour_code
					FROM apcsprodwh.dwh.dim_days AS dd
					CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
					WHERE (
							dd.id BETWEEN @from - 1
								AND @to
							)
						AND (
							(
								dd.id = @to
								AND dh.code <= @finish_hour_code
								)
							OR dd.id <> @to
							)
					) AS d
				LEFT JOIN (
					SELECT wi.day_id
						,wi.hour_code
						,ddv.name AS device_name
						,sum((
								CASE 
									WHEN CHARINDEX(CASE 
												WHEN @target_device IS NULL
													THEN ddv.name
												ELSE @target_device
												END, ddv.name) = 1
										THEN 1
									ELSE 0
									END
								) * wi.lot_count) AS sum_lot_count_target
						,sum((
								CASE 
									WHEN CHARINDEX(CASE 
												WHEN @target_device IS NULL
													THEN ddv.name
												ELSE @target_device
												END, ddv.name) <> 1
										THEN 1
									ELSE 0
									END
								) * wi.lot_count) AS sum_lot_count_non_target
						,sum((
								CASE 
									WHEN CHARINDEX(CASE 
												WHEN @target_device IS NULL
													THEN ddv.name
												ELSE @target_device
												END, ddv.name) = 1
										THEN 1
									ELSE 0
									END
								) * cast(wi.pcs AS BIGINT)) AS sum_pcs_target
						,sum((
								CASE 
									WHEN CHARINDEX(CASE 
												WHEN @target_device IS NULL
													THEN ddv.name
												ELSE @target_device
												END, ddv.name) <> 1
										THEN 1
									ELSE 0
									END
								) * cast(wi.pcs AS BIGINT)) AS sum_pcs_non_target
					FROM (
						SELECT day_id
							,hour_code
							,package_group_id
							,package_id
							,process_id
							,job_id
							,device_id
							,pcs
							,lot_count
						FROM apcsprodwh.dwh.fact_wip WITH (NOLOCK)
						WHERE process_state_code NOT IN (
								2
								,102
								)
						) AS wi
					LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = wi.device_id
					WHERE (
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
								AND wi.process_id >= - 1
								)
							)
						AND (
							(
								@job_id IS NOT NULL
								AND job_id = @job_id
								)
							OR (
								@job_id IS NULL
								AND job_id >= - 1
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
						,ddv.name
					) AS fw ON fw.day_id = d.day_id
					AND fw.hour_code = d.hour_code
				) AS t1
			GROUP BY t1.day_id
				,t1.hour_code
			) AS t2
		) AS t3

	-------------
	--投入累積の初期値(前日最終時のWIP)
	---------------
	SELECT *
	INTO #t_wip_init
	FROM (
		SELECT t1.day_id
			,t1.new_day_id
			,t1.hour_code
			,t1.tmp_hour_code
			,isnull(t1.sum_lot_count_target, 0) AS init_lot
			,isnull(convert(FLOAT, t1.sum_pcs_target) / 1000, 0) AS init_pcs
			,isnull(t1.sum_lot_count_non_target, 0) AS init_lot_non_target
			,isnull(convert(FLOAT, t1.sum_pcs_non_target) / 1000, 0) AS init_pcs_non_target
		FROM #t_wip AS t1
		WHERE (new_day_id = @from - 1)
			AND (latest_hour_code = 1)
		) AS t2

	--------------------------------------------------------------------------------new
	-------------
	--chart data
	-------------
	SELECT
		--t3.day_id AS day_id
		t3.new_day_id AS day_id
		,t3.date_value AS date_value
		,t3.hour_code AS hour_code
		,t3.h AS h
		,@process_id AS process_id
		,@job_id AS job_id
		--start
		,t3.start_lots AS start_lots
		,t3.start_Kpcs AS start_Kpcs
		,t3.start_lots_non_target AS start_lots_non_target
		,t3.start_Kpcs_non_target AS start_Kpcs_non_target
		--end
		,t3.end_lots AS end_lots
		,t3.end_Kpcs AS end_Kpcs
		,t3.end_lots_target AS end_lots_target
		,t3.end_Kpcs_target AS end_Kpcs_target
		,t3.end_lots_non_target AS end_lots_non_target
		,t3.end_Kpcs_non_target AS end_Kpcs_non_target
		--WIP
		,t3.wip_lots AS wip_lots
		,t3.wip_Kpcs AS wip_Kpcs
		,t3.wip_lots_non_target AS wip_lots_non_target
		,t3.wip_Kpcs_non_target AS wip_Kpcs_non_target
		--累積
		,sum(t3.start_lots) OVER (
			ORDER BY t3.day_id
				,t3.hour_code rows unbounded preceding
			) + (
			SELECT init_lot
			FROM #t_wip_init
			) AS sum_start_lots
		,sum(t3.start_Kpcs) OVER (
			ORDER BY t3.day_id
				,t3.hour_code rows unbounded preceding
			) + (
			SELECT init_pcs
			FROM #t_wip_init
			) AS sum_start_Kpcs
		,sum(t3.end_lots) OVER (
			ORDER BY t3.day_id
				,t3.hour_code rows unbounded preceding
			) AS sum_end_lots
		,sum(t3.end_Kpcs) OVER (
			ORDER BY t3.day_id
				,t3.hour_code rows unbounded preceding
			) AS sum_end_Kpcs
		--累積 non target
		,sum(t3.start_lots_non_target) OVER (
			ORDER BY t3.day_id
				,t3.hour_code rows unbounded preceding
			) + (
			SELECT init_lot_non_target
			FROM #t_wip_init
			) AS sum_start_lots_non_target
		,sum(t3.start_Kpcs_non_target) OVER (
			ORDER BY t3.day_id
				,t3.hour_code rows unbounded preceding
			) + (
			SELECT init_pcs_non_target
			FROM #t_wip_init
			) AS sum_start_Kpcs_non_target
		,sum(t3.end_lots_non_target) OVER (
			ORDER BY t3.day_id
				,t3.hour_code rows unbounded preceding
			) AS sum_end_lots_non_target
		,sum(t3.end_Kpcs_non_target) OVER (
			ORDER BY t3.day_id
				,t3.hour_code rows unbounded preceding
			) AS sum_end_Kpcs_non_target
	FROM (
		SELECT t2.day_id AS day_id
			,t2.new_day_id
			,t2.date_value AS date_value
			,t2.hour_code AS hour_code
			,t2.h AS h
			,rank() OVER (
				PARTITION BY t2.day_id ORDER BY t2.day_id
					,t2.hour_code DESC
				) AS day_rank
			,
			--1 start lots/kpcs
			--1-1 target
			CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.START_sum_lot_count, 0)
				ELSE sum(isnull(t2.START_sum_lot_count, 0)) OVER (PARTITION BY t2.day_id)
				END AS start_lots
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.START_sum_pcs) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.START_sum_pcs) / 1000, 0)) OVER (PARTITION BY t2.day_id)
				END AS start_Kpcs
			,
			--start lots/kpcs
			--1-2 non target
			CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.START_sum_lot_count_non_target, 0)
				ELSE sum(isnull(t2.START_sum_lot_count_non_target, 0)) OVER (PARTITION BY t2.day_id)
				END AS start_lots_non_target
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.START_sum_pcs_non_target) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.START_sum_pcs_non_target) / 1000, 0)) OVER (PARTITION BY t2.day_id)
				END AS start_Kpcs_non_target
			,
			--2end lots/kpocs
			CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.end_lots - t2.end_dlots, 0)
				ELSE sum(isnull(t2.end_lots - t2.end_dlots, 0)) OVER (PARTITION BY t2.day_id)
				END AS end_lots
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.end_pcs) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.end_pcs) / 1000, 0)) OVER (PARTITION BY t2.day_id)
				END AS end_Kpcs
			,
			--2-1 target
			CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.END_sum_lot_count_target, 0)
				ELSE sum(isnull(t2.END_sum_lot_count_target, 0)) OVER (PARTITION BY t2.day_id)
				END AS end_lots_target
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.END_sum_pcs_target) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.END_sum_pcs_target) / 1000, 0)) OVER (PARTITION BY t2.day_id)
				END AS end_Kpcs_target
			,
			--2-2 non target
			CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.END_sum_lot_count_non_target, 0)
				ELSE sum(isnull(t2.END_sum_lot_count_non_target, 0)) OVER (PARTITION BY t2.day_id)
				END AS end_lots_non_target
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.END_sum_pcs_non_target) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.END_sum_pcs_non_target) / 1000, 0)) OVER (PARTITION BY t2.day_id)
				END AS end_Kpcs_non_target
			,
			--3 wip lots/kpcs
			--3-1 target
			CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.wip_lots, 0)
				ELSE min(t2.wip_lots) OVER (
						PARTITION BY t2.day_id ORDER BY t2.latest_hour_code range unbounded preceding
						)
				END AS wip_lots
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.wip_pcs) / 1000, 0)
				ELSE min(convert(FLOAT, t2.wip_pcs) / 1000) OVER (
						PARTITION BY t2.day_id ORDER BY t2.latest_hour_code range unbounded preceding
						)
				END AS wip_Kpcs
			,
			--3-2 non target
			CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.wip_lots_non_target, 0)
				ELSE min(t2.wip_lots_non_target) OVER (
						PARTITION BY t2.day_id ORDER BY t2.latest_hour_code range unbounded preceding
						)
				END AS wip_lots_non_target
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.wip_pcs_non_target) / 1000, 0)
				ELSE min(convert(FLOAT, t2.wip_pcs_non_target) / 1000) OVER (
						PARTITION BY t2.day_id ORDER BY t2.latest_hour_code range unbounded preceding
						)
				END AS wip_Kpcs_non_target
			,t2.latest_hour_code AS latest_hour_code
		FROM (
			SELECT t1.day_id AS day_id
				,CASE 
					WHEN t1.hour_code < @time_offset + 1
						THEN t1.day_id - 1
					ELSE t1.day_id
					END AS new_day_id
				,t1.hour_code AS hour_code
				,t1.date_value AS date_value
				,t1.h AS h
				,CASE 
					WHEN t1.hour_code - @time_offset <= 0
						THEN t1.hour_code - @time_offset + 24
					ELSE t1.hour_code - @time_offset
					END AS tmp_hour_code
				--input
				,fs3.sum_lot_count AS START_sum_lot_count
				,fs3.sum_lot_count_non_target AS START_sum_lot_count_non_target
				,fs3.sum_pcs AS START_sum_pcs
				,fs3.sum_pcs_non_target AS START_sum_pcs_non_target
				--output
				,fe4.lots AS end_lots
				,fe4.d_lots AS end_dlots
				,fe4.end_pcs AS end_pcs
				,
				--
				fe4.sum_lot_count_target AS END_sum_lot_count_target
				,fe4.sum_lot_count_non_target AS END_sum_lot_count_non_target
				,fe4.sum_pcs_target AS END_sum_pcs_target
				,fe4.sum_pcs_non_target AS END_sum_pcs_non_target
				--
				,wp.wip_lots AS wip_lots
				,wp.wip_lots_non_target AS wip_lots_non_target
				,wp.wip_pcs AS wip_pcs
				,wp.wip_pcs_non_target AS wip_pcs_non_target
				,isnull(wp.latest_hour_code, 99) AS latest_hour_code
			FROM (
				SELECT dd.id AS day_id
					,dh.code AS hour_code
					,dd.date_value AS date_value
					,dh.h AS h
				FROM apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK)
				CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
				WHERE dd.id BETWEEN @from - 1
						AND @to
				) AS t1
			--------------------------------------------start----------------------
			---前工程終了実績値を投入とする(fact_endのnext_job_id,next_process_id)
			LEFT OUTER JOIN (
				SELECT T1.day_id AS day_id
					,T1.hour_code AS hour_code
					,sum(T1.sum_lot_count_target) AS sum_lot_count
					,sum(T1.sum_lot_count_non_target) AS sum_lot_count_non_target
					,sum(T1.sum_pcs_target) AS sum_pcs
					,sum(T1.sum_pcs_non_target) AS sum_pcs_non_target
				FROM (
					SELECT day_id AS day_id
						,fw.hour_code AS hour_code
						,ddv.name AS device_name
						,sum((
								CASE 
									WHEN CHARINDEX(CASE 
												WHEN @target_device IS NULL
													THEN ddv.name
												ELSE @target_device
												END, ddv.name) = 1
										THEN 1
									ELSE 0
									END
								) * 1) AS sum_lot_count_target
						,sum((
								CASE 
									WHEN CHARINDEX(CASE 
												WHEN @target_device IS NULL
													THEN ddv.name
												ELSE @target_device
												END, ddv.name) <> 1
										THEN 1
									ELSE 0
									END
								) * 1) AS sum_lot_count_non_target
						,sum((
								CASE 
									WHEN CHARINDEX(CASE 
												WHEN @target_device IS NULL
													THEN ddv.name
												ELSE @target_device
												END, ddv.name) = 1
										THEN 1
									ELSE 0
									END
								) * cast(fw.pass_pcs AS BIGINT)) AS sum_pcs_target
						,sum((
								CASE 
									WHEN CHARINDEX(CASE 
												WHEN @target_device IS NULL
													THEN ddv.name
												ELSE @target_device
												END, ddv.name) <> 1
										THEN 1
									ELSE 0
									END
								) * cast(fw.pass_pcs AS BIGINT)) AS sum_pcs_non_target
					FROM apcsprodwh.dwh.fact_end AS fw WITH (NOLOCK)
					LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fw.device_id
					WHERE day_id BETWEEN @from - 1
							AND @to
						AND (
							(
								@package_id IS NOT NULL
								AND fw.package_id = @package_id
								)
							OR (
								@package_id IS NULL
								AND @package_group_id IS NOT NULL
								AND fw.package_group_id = @package_group_id
								)
							OR (
								@package_id IS NULL
								AND @package_group_id IS NULL
								AND fw.package_id > 0
								)
							)
						AND (
							(
								@process_id IS NOT NULL
								AND fw.next_process_id = @process_id
								)
							OR (
								@process_id IS NULL
								AND ((fw.next_process_id > 0))
								)
							)
						AND (
							(
								@job_id IS NOT NULL
								AND fw.next_job_id = @job_id
								)
							OR (
								@job_id IS NULL
								AND (
									(fw.next_job_id > 0)
									AND fw.code = 2
									)
								)
							)
						AND (
							(
								@device_name IS NOT NULL
								AND ddv.name = @device_name
								)
							OR @device_name IS NULL
							)
					GROUP BY fw.day_id
						,fw.hour_code
						,ddv.name
					) AS T1
				GROUP BY T1.day_id
					,T1.hour_code
				) AS fs3 ON fs3.day_id = t1.day_id
				AND fs3.hour_code = t1.hour_code
			--------------------------------------------end----------------------
			LEFT OUTER JOIN (
				SELECT fe3.day_id AS day_id
					,fe3.hour_code AS hour_code
					,count(fe3.lot_id) AS lots
					,sum(fe3.d_lot_counter) AS d_lots
					,sum(fe3.pass_pcs) AS end_pcs
					,
					--仕掛制限
					sum(fe3.lot_count_target) AS sum_lot_count_target
					,sum(fe3.lot_count_non_target) AS sum_lot_count_non_target
					,sum(fe3.pass_pcs * pcs_target) AS sum_pcs_target
					,sum(fe3.pass_pcs * pcs_non_target) AS sum_pcs_non_target
				FROM (
					SELECT fe2.*
					FROM (
						SELECT fe.day_id
							,fe.hour_code
							,fe.lot_id
							,fe.pass_pcs
							,fe.wait_time
							,fe.process_time
							,tl.lot_no AS lot_no
							,CASE 
								WHEN (substring(tl.lot_no, 5, 1) = 'D')
									AND @d_lot = 0
									THEN 1
								ELSE 0
								END AS d_lot_counter
							,ddv.name AS device_name
							,CASE 
								WHEN CHARINDEX(CASE 
											WHEN @target_device IS NULL
												THEN ddv.name
											ELSE @target_device
											END, ddv.name) = 1
									THEN 1
								ELSE 0
								END AS lot_count_target
							,CASE 
								WHEN CHARINDEX(CASE 
											WHEN @target_device IS NULL
												THEN ddv.name
											ELSE @target_device
											END, ddv.name) <> 1
									THEN 1
								ELSE 0
								END AS lot_count_non_target
							,CASE 
								WHEN CHARINDEX(CASE 
											WHEN @target_device IS NULL
												THEN ddv.name
											ELSE @target_device
											END, ddv.name) = 1
									THEN 1
								ELSE 0
								END AS pcs_target
							,CASE 
								WHEN CHARINDEX(CASE 
											WHEN @target_device IS NULL
												THEN ddv.name
											ELSE @target_device
											END, ddv.name) <> 1
									THEN 1
								ELSE 0
								END AS pcs_non_target
						FROM apcsprodwh.dwh.fact_end AS fe WITH (NOLOCK)
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fe.lot_id
						LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fe.device_id
						WHERE fe.day_id BETWEEN @from - 1
								AND @to
							AND (
								(
									@package_id IS NOT NULL
									AND fe.package_id = @package_id
									)
								OR (
									@package_id IS NULL
									AND @package_group_id IS NOT NULL
									AND fe.package_group_id = @package_group_id
									)
								OR (
									@package_id IS NULL
									AND @package_group_id IS NULL
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
							AND (
								(
									@job_id IS NOT NULL
									AND fe.job_id = @job_id
									)
								OR (
									@job_id IS NULL
									AND (
										fe.job_id > 0
										AND fe.code = 2
										)
									)
								)
							AND (
								(
									@device_name IS NOT NULL
									AND ddv.name = @device_name
									)
								OR (@device_name IS NULL)
								)
						) AS fe2
					) AS fe3
				GROUP BY fe3.day_id
					,fe3.hour_code
				) AS fe4 ON fe4.day_id = t1.day_id
				AND fe4.hour_code = t1.hour_code
			-----------------------------------WIP
			LEFT OUTER JOIN (
				SELECT w.day_id AS day_id
					,w.hour_code AS hour_code
					,w.sum_lot_count_target AS wip_lots
					,w.sum_lot_count_non_target AS wip_lots_non_target
					,w.sum_pcs_target AS wip_pcs
					,w.sum_pcs_non_target AS wip_pcs_non_target
					,w.latest_hour_code AS latest_hour_code
				FROM #t_wip AS w
				) AS wp ON wp.day_id = t1.day_id
				AND wp.hour_code = t1.hour_code
			) AS t2
		) AS t3
	LEFT JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = t3.new_day_id
	WHERE (
			@hour_flag = 1
			AND t3.hour_code > 0
			AND t3.new_day_id BETWEEN @from
				AND @to
			)
		OR (
			@hour_flag = 0
			AND t3.latest_hour_code = 1
			AND t3.new_day_id BETWEEN @from
				AND @to
			)
	ORDER BY day_id
		,hour_code
END

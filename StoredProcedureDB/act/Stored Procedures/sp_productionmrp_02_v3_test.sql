
CREATE PROCEDURE [act].[sp_productionmrp_02_v3_test] (
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
	,@time_offset INT = 0
	)
AS
BEGIN
	--IF OBJECT_ID(N'tempdb..#t_wip', N'U') IS NOT NULL
	--	DROP TABLE #t_wip;
	--IF OBJECT_ID(N'tempdb..#t_wip_init', N'U') IS NOT NULL
	--	DROP TABLE #t_wip_init;
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
			PARTITION BY t2.new_day_id ORDER BY t2.tmp_hour_code DESC
			) AS latest_hour_code
	INTO #t_wip
	FROM (
		SELECT day_id
			,CASE 
				WHEN hour_code < @time_offset + 1
					THEN day_id - 1
				ELSE day_id
				END AS new_day_id
			,hour_code
			,CASE 
				WHEN hour_code - @time_offset <= 0
					THEN hour_code - @time_offset + 24
				ELSE hour_code - @time_offset
				END AS tmp_hour_code
			,sum_lot_count
			,sum_pcs
		FROM (
			SELECT d.day_id
				,d.hour_code
				,fw.sum_lot_count
				,fw.sum_pcs
			FROM (
				SELECT dd.id AS day_id
					,dh.code AS hour_code
				FROM apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK)
				CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
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
					,sum(wi.lot_count) AS sum_lot_count
					,sum(cast(wi.pcs AS BIGINT)) AS sum_pcs
				FROM apcsprodwh.dwh.fact_wip AS wi WITH (NOLOCK)
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
				) AS fw ON fw.day_id = d.day_id
				AND fw.hour_code = d.hour_code
			) AS t1
		) AS t2

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
			,isnull(t1.sum_lot_count, 0) AS init_lot
			,isnull(convert(FLOAT, t1.sum_pcs) / 1000, 0) AS init_pcs
			,t1.latest_hour_code
		FROM #t_wip AS t1
		WHERE (new_day_id = @from - 1)
			AND (latest_hour_code = 1)
		) AS t2

	-------------
	--Main Query
	---------------
	SELECT
		--t3.day_id AS day_id
		--,
		t3.new_day_id AS day_id
		,dd.date_value AS date_value
		,t3.hour_code AS hour_code
		,t3.h AS h
		,@process_id AS process_id
		,@job_id AS job_id
		,t3.start_lots AS start_lots
		,t3.start_Kpcs AS start_Kpcs
		,t3.end_lots AS end_lots
		,t3.end_Kpcs AS end_Kpcs
		,t3.qty_combined AS qty_combined
		,t3.start_Kpcs_combined AS start_Kpcs_combined
		,t3.end_Kpcs_combined AS end_Kpcs_combined
		,t3.wip_lots AS wip_lots
		,t3.wip_Kpcs AS wip_Kpcs
		,sum(t3.start_lots) OVER (
			ORDER BY t3.new_day_id
				,t3.latest_hour_code DESC rows unbounded preceding
			) + (
			SELECT init_lot
			FROM #t_wip_init
			) AS sum_start_lots
		,sum(t3.start_Kpcs) OVER (
			ORDER BY t3.new_day_id
				,t3.latest_hour_code DESC rows unbounded preceding
			) + (
			SELECT init_pcs
			FROM #t_wip_init
			) AS sum_start_Kpcs
		,sum(t3.end_lots) OVER (
			ORDER BY t3.new_day_id
				,t3.latest_hour_code DESC rows unbounded preceding
			) AS sum_end_lots
		,sum(t3.end_Kpcs) OVER (
			ORDER BY t3.new_day_id
				,t3.latest_hour_code DESC rows unbounded preceding
			) AS sum_end_Kpcs
		,t3.latest_hour_code AS latest_hour_code
	FROM (
		SELECT t2.day_id AS day_id
			,t2.new_day_id
			,t2.hour_code AS hour_code
			,t2.h AS h
			--,isnull(dense_RANK() OVER (
			--		PARTITION BY t2.new_day_id ORDER BY t2.tmp_hour_code DESC
			--		), 99) AS latest_hour_code
			--start lots/kpcs
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.start_lots, 0)
				ELSE sum(isnull(t2.start_lots, 0)) OVER (PARTITION BY t2.new_day_id)
				END AS start_lots
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.start_pcs) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.start_pcs) / 1000, 0)) OVER (PARTITION BY t2.new_day_id)
				END AS start_Kpcs
			--end lots/kpocs
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.end_lots - t2.end_dlots, 0)
				ELSE sum(isnull(t2.end_lots - t2.end_dlots, 0)) OVER (PARTITION BY t2.new_day_id)
				END AS end_lots
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.end_pcs) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.end_pcs) / 1000, 0)) OVER (PARTITION BY t2.new_day_id)
				END AS end_Kpcs
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.qty_combined) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.qty_combined) / 1000, 0)) OVER (PARTITION BY t2.new_day_id)
				END AS qty_combined
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.end_pcs) / 1000, 0) + isnull(convert(FLOAT, t2.qty_combined) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.end_pcs) / 1000, 0) + isnull(convert(FLOAT, t2.qty_combined) / 1000, 0)) OVER (PARTITION BY t2.new_day_id)
				END AS end_Kpcs_combined
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.start_pcs) / 1000, 0) + isnull(convert(FLOAT, t2.qty_combined) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.start_pcs) / 1000, 0) + isnull(convert(FLOAT, t2.qty_combined) / 1000, 0)) OVER (PARTITION BY t2.new_day_id)
				END AS start_Kpcs_combined
			--wip lots/kpcs
			,isnull(t2.wip_lots, 0) AS wip_lots
			,isnull(convert(FLOAT, t2.wip_pcs) / 1000, 0) AS wip_Kpcs
			,isnull(t2.latest_hour_code, 99) AS latest_hour_code
		FROM (
			SELECT t1.day_id AS day_id
				,CASE 
					WHEN t1.hour_code < @time_offset + 1
						THEN t1.day_id - 1
					ELSE t1.day_id
					END AS new_day_id
				,t1.hour_code AS hour_code
				,t1.h AS h
				,CASE 
					WHEN t1.hour_code - @time_offset <= 0
						THEN t1.hour_code - @time_offset + 24
					ELSE t1.hour_code - @time_offset
					END AS tmp_hour_code
				--start
				,st.pcs AS start_pcs
				,st.lots AS start_lots
				--end
				,ed.end_pcs AS end_pcs
				,ed.lots AS end_lots
				,ed.d_lots AS end_dlots
				,ed.qty_combined AS qty_combined
				--wip
				,wp.wip_lots AS wip_lots
				,wp.wip_pcs AS wip_pcs
				,wp.latest_hour_code
			FROM (
				SELECT dd.id AS day_id
					,dh.code AS hour_code
					,dh.h AS h
				FROM apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK)
				CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
				WHERE dd.id BETWEEN @from - 1
						AND @to
				) AS t1
			--------------------------------------------start----------------------
			---前工程終了実績値を投入とする(fact_endのnext_job_id,next_process_id)
			LEFT OUTER JOIN (
				SELECT fs.day_id AS day_id
					,fs.hour_code AS hour_code
					,sum(fs.lot_count) AS lots
					,sum(fs.pcs) AS pcs
				FROM (
					SELECT day_id AS day_id
						,fs.hour_code AS hour_code
						,1 AS lot_count
						,fs.input_pcs AS pcs
					FROM apcsprodwh.dwh.fact_start AS fs WITH (NOLOCK)
					LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fs.device_id
					WHERE day_id BETWEEN @from - 1
							AND @to
						AND (
							(
								@package_id IS NOT NULL
								AND fs.package_id = @package_id
								)
							OR (
								@package_id IS NULL
								AND @package_group_id IS NOT NULL
								AND fs.package_group_id = @package_group_id
								)
							OR (
								@package_id IS NULL
								AND @package_group_id IS NULL
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
						AND (
							(
								@job_id IS NOT NULL
								AND fs.job_id = @job_id
								)
							OR (
								@job_id IS NULL
								AND (
									fs.job_id > 0
									AND fs.code = 1
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
					) AS fs
				GROUP BY fs.day_id
					,fs.hour_code
				) AS st ON st.day_id = t1.day_id
				AND st.hour_code = t1.hour_code
			--------------------------------------------end----------------------
			LEFT OUTER JOIN (
				SELECT fe3.day_id AS day_id
					,fe3.hour_code AS hour_code
					,count(fe3.lot_id) AS lots
					,sum(fe3.d_lot_counter) AS d_lots
					,sum(fe3.pass_pcs) AS end_pcs
					,sum(fe3.qty_combined) AS qty_combined
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
						    ,MAX(tlpr.qty_combined) AS qty_combined
						FROM apcsprodwh.dwh.fact_end AS fe WITH (NOLOCK)
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fe.lot_id
						LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fe.device_id
						LEFT OUTER JOIN APCSProDB.trans.lot_process_records AS tlpr WITH (NOLOCK) ON tlpr.lot_id = fe.lot_id AND tlpr.record_class = 2 AND tlpr.process_id = fe.process_id AND tlpr.job_id = fe.job_id AND tlpr.machine_id = fe.machine_id
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
						GROUP BY fe.day_id
							,fe.hour_code
							,fe.lot_id
							,fe.pass_pcs
							,fe.wait_time
							,fe.process_time
							,lot_no
						) AS fe2
					) AS fe3
				GROUP BY fe3.day_id
					,fe3.hour_code
				) AS ed ON ed.day_id = t1.day_id
				AND ed.hour_code = t1.hour_code
			-----------------------------------WIP
			LEFT OUTER JOIN (
				SELECT w.day_id AS day_id
					,w.hour_code AS hour_code
					,w.sum_lot_count AS wip_lots
					,w.sum_pcs AS wip_pcs
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

CREATE PROCEDURE [act].[sp_productionmrp_02_next] (
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

	-------------
	-- fact_wip
	-------------
	SELECT wi.day_id AS day_id
		,wi.hour_code AS hour_code
		,RANK() OVER (
			PARTITION BY wi.day_id ORDER BY wi.hour_code DESC
			) AS latest_hour_code
		,sum(wi.lot_count) AS sum_lot_count
		,sum(cast(wi.pcs AS BIGINT)) AS sum_pcs
	INTO #t_wip
	FROM apcsprodwh.dwh.fact_wip AS wi WITH (NOLOCK)
	LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = wi.device_id
	WHERE (
			wi.day_id BETWEEN @from
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

	-------------
	--投入累積の初期値(前日最終時のWIP)
	-------------
	SELECT isnull(tw.sum_lot_count, 0) AS init_lot
		,isnull(convert(FLOAT, tw.sum_pcs) / 1000, 0) AS init_pcs
	INTO #t_wip_init
	FROM #t_wip AS tw
	WHERE (day_id = @from - 1)
		AND (hour_code = 24);

	-------------
	--chart data
	-------------
	SELECT t3.day_id AS day_id
		,t3.date_value AS date_value
		,t3.hour_code AS hour_code
		,t3.h AS h
		,@process_id AS process_id
		,@job_id AS job_id
		,t3.start_lots AS start_lots
		,t3.start_Kpcs AS start_Kpcs
		,t3.end_lots AS end_lots
		,t3.end_Kpcs AS end_Kpcs
		,t3.wip_lots AS wip_lots
		,t3.wip_Kpcs AS wip_Kpcs
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
	FROM (
		SELECT t2.day_id AS day_id
			,t2.date_value AS date_value
			,t2.hour_code AS hour_code
			,t2.h AS h
			,rank() OVER (
				PARTITION BY t2.day_id ORDER BY t2.day_id
					,t2.hour_code
				) AS day_rank
			,
			--start lots/kpcs
			CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.start_lots, 0)
				ELSE sum(isnull(t2.start_lots, 0)) OVER (PARTITION BY t2.day_id)
				END AS start_lots
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.start_pcs) / 1000, 0)
				ELSE sum(isnull(convert(FLOAT, t2.start_pcs) / 1000, 0)) OVER (PARTITION BY t2.day_id)
				END AS start_Kpcs
			,
			--end lots/kpocs
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
			--wip lots/kpcs
			CASE 
				WHEN @hour_flag = 1
					THEN isnull(t2.wip_lots, 0)
						--ELSE min(isnull(t2.wip_lots, 0)) OVER (
						--		PARTITION BY t2.day_id ORDER BY t2.latest_hour_code range unbounded preceding
						--		)
				ELSE
					--isnull(t2.wip_lots, 0)
					min(t2.wip_lots) OVER (
						PARTITION BY t2.day_id ORDER BY t2.latest_hour_code range unbounded preceding
						)
				END AS wip_lots
			,CASE 
				WHEN @hour_flag = 1
					THEN isnull(convert(FLOAT, t2.wip_pcs) / 1000, 0)
						--ELSE min(isnull(convert(FLOAT, t2.wip_pcs) / 1000, 0)) OVER (
						--		PARTITION BY t2.day_id ORDER BY t2.latest_hour_code range unbounded preceding
						--		)
				ELSE min(convert(FLOAT, t2.wip_pcs) / 1000) OVER (
						PARTITION BY t2.day_id ORDER BY t2.latest_hour_code range unbounded preceding
						)
				END AS wip_Kpcs
			,t2.latest_hour_code AS latest_hour_code
		FROM (
			SELECT t1.day_id AS day_id
				,t1.hour_code AS hour_code
				,t1.date_value AS date_value
				,t1.h AS h
				,
				--
				fs3.pcs AS start_pcs
				,fs3.lots AS start_lots
				,
				--
				fe4.lots AS end_lots
				,fe4.d_lots AS end_dlots
				,fe4.end_pcs AS end_pcs
				,
				--
				wp3.wip_lots AS wip_lots
				,wp3.wip_pcs AS wip_pcs
				,isnull(wp3.latest_hour_code, 99) AS latest_hour_code
			FROM (
				SELECT dd.id AS day_id
					,dh.code AS hour_code
					,dd.date_value AS date_value
					,dh.h AS h
				FROM apcsprodwh.dwh.dim_days AS dd
				CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
				WHERE dd.id BETWEEN @from
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
						,fs.pass_pcs AS pcs
					FROM apcsprodwh.dwh.fact_end AS fs WITH (NOLOCK)
					LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fs.device_id
					WHERE day_id BETWEEN @from
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
								AND fs.next_process_id = @process_id
								)
							OR (
								@process_id IS NULL
								AND fs.next_process_id > 0
								)
							)
						AND (
							(
								@job_id IS NOT NULL
								AND fs.next_job_id = @job_id
								)
							OR (
								@job_id IS NULL
								AND (
									fs.next_job_id > 0
									AND fs.code = 2
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
				) AS fs3 ON fs3.day_id = t1.day_id
				AND fs3.hour_code = t1.hour_code
			--------------------------------------------end----------------------
			LEFT OUTER JOIN (
				SELECT fe3.day_id AS day_id
					,fe3.hour_code AS hour_code
					,count(fe3.lot_id) AS lots
					,sum(fe3.d_lot_counter) AS d_lots
					,sum(fe3.pass_pcs) AS end_pcs
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
						FROM apcsprodwh.dwh.fact_end AS fe WITH (NOLOCK)
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fe.lot_id
						LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fe.device_id
						WHERE fe.day_id BETWEEN @from
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
				SELECT wp.day_id AS day_id
					,wp.hour_code AS hour_code
					,wp.sum_lot_count AS wip_lots
					,wp.sum_pcs AS wip_pcs
					,wp.latest_hour_code AS latest_hour_code
				FROM #t_wip AS wp
				WHERE (
						(@hour_flag = 0)
						AND (
							(wp.day_id <> @to)
							AND wp.hour_code = 24
							)
						OR (
							(wp.day_id = @to)
							AND wp.latest_hour_code = 1
							)
						)
					OR (@hour_flag = 1)
				) AS wp3 ON wp3.day_id = t1.day_id
				AND wp3.hour_code = t1.hour_code
			WHERE t1.day_id BETWEEN @from
					AND @to
			) AS t2
		) AS t3
	WHERE (
			@hour_flag = 1
			AND t3.hour_code > 0
			)
		OR (
			@hour_flag = 0
			AND t3.day_rank = 1
			)
	ORDER BY t3.day_id
		,t3.hour_code
END

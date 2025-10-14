
CREATE PROCEDURE [act].[sp_productionmain_03] (
	@package_id INT = NULL
	,@process_id INT = NULL
	,@package_group_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	)
AS
BEGIN
	SELECT *
	INTO #table
	FROM (
		SELECT t4.wip_id AS wip_id
			,t4.package_group_id AS package_group_id
			,pkgG.name AS package_group_name
			,t4.package_id AS package_id
			,pkg.name AS package_name
			,t4.process_id AS process_id
			,t4.process_no AS process_no
			,prc.name AS process_name
			,t4.job_id AS job_id
			,t4.job_no AS job_no
			,job.name AS job_name
			,row_number() OVER (
				PARTITION BY t4.process_id
				,t4.job_id ORDER BY t4.wip_id
				) AS ranking
			,t4.sum_lot AS sum_lot
			,t4.sum_run_lot AS sum_run_lot
			,t4.sum_norm_lot AS sum_norm_lot
			,t4.sum_long_norm_lot AS sum_long_norm_lot
			,t4.sum_abnorm_lot AS sum_abnorm_lot
			,t4.sum_long_abnorm_lot AS sum_long_abnorm_lot
			,isnull(convert(FLOAT, t4.sum_pcs) / 1000, - 3) AS sum_kpcs
			,isnull(convert(FLOAT, t4.sum_run_pcs) / 1000, - 3) AS sum_run_kpcs
			,isnull(convert(FLOAT, t4.sum_norm_pcs) / 1000, - 3) AS sum_norm_kpcs
			,isnull(convert(FLOAT, t4.sum_long_norm_pcs) / 1000, - 3) AS sum_long_norm_kpcs
			,isnull(convert(FLOAT, t4.sum_abnorm_pcs) / 1000, - 3) AS sum_abnorm_kpcs
			,isnull(convert(FLOAT, t4.sum_long_abnorm_pcs) / 1000, - 3) AS sum_long_abnorm_kpcs
		FROM (
			SELECT t3.wip_id AS wip_id
				,t3.package_group_id AS package_group_id
				,t3.package_id AS package_id
				,t3.process_id AS process_id
				,t3.process_no AS process_no
				,t3.job_id AS job_id
				,t3.job_no AS job_no
				,t3.process_state_code AS process_state_code
				,t3.qc_state_code AS qc_state_code
				,t3.long_time_state_code AS long_time_state_code
				,t3.lot_cnt AS lot_cnt
				,t3.pcs AS pcs
				,sum(t3.lot_cnt) OVER (PARTITION BY t3.job_id) AS sum_lot
				,sum(t3.pcs) OVER (PARTITION BY t3.job_id) AS sum_pcs
				,sum(t3.run_lot) OVER (PARTITION BY t3.job_id) AS sum_run_lot
				,sum(t3.run_pcs) OVER (PARTITION BY t3.job_id) AS sum_run_pcs
				,sum(t3.norm_lot) OVER (PARTITION BY t3.job_id) AS sum_norm_lot
				,sum(t3.norm_pcs) OVER (PARTITION BY t3.job_id) AS sum_norm_pcs
				,sum(t3.long_norm_lot) OVER (PARTITION BY t3.job_id) AS sum_long_norm_lot
				,sum(t3.long_norm_pcs) OVER (PARTITION BY t3.job_id) AS sum_long_norm_pcs
				,sum(t3.abnorm_lot) OVER (PARTITION BY t3.job_id) AS sum_abnorm_lot
				,sum(t3.abnorm_pcs) OVER (PARTITION BY t3.job_id) AS sum_abnorm_pcs
				,sum(t3.long_abnorm_lot) OVER (PARTITION BY t3.job_id) AS sum_long_abnorm_lot
				,sum(t3.long_abnorm_pcs) OVER (PARTITION BY t3.job_id) AS sum_long_abnorm_pcs
			FROM (
				SELECT t2.wip_id AS wip_id
					,t2.package_group_id AS package_group_id
					,t2.package_id AS package_id
					,t2.process_id AS process_id
					,t2.process_no AS process_no
					,t2.job_id AS job_id
					,t2.job_no AS job_no
					,t2.process_state_code AS process_state_code
					,t2.qc_state_code AS qc_state_code
					,t2.long_time_state_code AS long_time_state_code
					,t2.lot_count AS lot_cnt
					,t2.pcs AS pcs
					,t2.lot_count * CASE 
						WHEN (t2.qc_state_code = 0)
							AND (
								t2.process_state_code % 10 IN (
									1
									,2
									)
								)
							THEN 1
						ELSE 0
						END AS run_lot
					,t2.pcs * CASE 
						WHEN (t2.qc_state_code = 0)
							AND (
								t2.process_state_code % 10 IN (
									1
									,2
									)
								)
							THEN 1
						ELSE 0
						END AS run_pcs
					,t2.lot_count * CASE 
						WHEN (
								t2.process_state_code % 10 NOT IN (
									1
									,2
									)
								AND t2.qc_state_code = 0
								AND t2.long_time_state_code = 0
								)
							OR (
								t2.qc_state_code = 4
								AND t2.long_time_state_code = 0
								)
							THEN 1
						ELSE 0
						END AS norm_lot
					,t2.pcs * CASE 
						WHEN (
								t2.process_state_code % 10 NOT IN (
									1
									,2
									)
								AND t2.qc_state_code = 0
								AND t2.long_time_state_code = 0
								)
							OR (
								t2.qc_state_code = 4
								AND t2.long_time_state_code = 0
								)
							THEN 1
						ELSE 0
						END AS norm_pcs
					,t2.lot_count * CASE 
						WHEN (
								t2.process_state_code % 10 NOT IN (
									1
									,2
									)
								AND t2.qc_state_code = 0
								AND t2.long_time_state_code = 1
								)
							OR (
								t2.qc_state_code = 4
								AND t2.long_time_state_code = 1
								)
							THEN 1
						ELSE 0
						END AS long_norm_lot
					,t2.pcs * CASE 
						WHEN (
								t2.process_state_code % 10 NOT IN (
									1
									,2
									)
								AND t2.qc_state_code = 0
								AND t2.long_time_state_code = 1
								)
							OR (
								t2.qc_state_code = 4
								AND t2.long_time_state_code = 1
								)
							THEN 1
						ELSE 0
						END AS long_norm_pcs
					,t2.lot_count * CASE 
						WHEN (
								t2.qc_state_code NOT IN (
									0
									,4
									)
								AND t2.long_time_state_code = 0
								)
							THEN 1
						ELSE 0
						END AS abnorm_lot
					,t2.pcs * CASE 
						WHEN (
								t2.qc_state_code NOT IN (
									0
									,4
									)
								AND t2.long_time_state_code = 0
								)
							THEN 1
						ELSE 0
						END AS abnorm_pcs
					,t2.lot_count * CASE 
						WHEN (
								t2.qc_state_code NOT IN (
									0
									,4
									)
								AND t2.long_time_state_code = 1
								)
							THEN 1
						ELSE 0
						END AS long_abnorm_lot
					,t2.pcs * CASE 
						WHEN (
								t2.qc_state_code NOT IN (
									0
									,4
									)
								AND t2.long_time_state_code = 1
								)
							THEN 1
						ELSE 0
						END AS long_abnorm_pcs
				FROM (
					SELECT wip.id AS wip_id
						,t1.package_group_id
						,t1.package_id
						,t1.process_id AS process_id
						,t1.process_no AS process_no
						,t1.job_id AS job_id
						,t1.job_no AS job_no
						,isnull(wip.delay_state_code, 0) AS delay_state_code
						,isnull(wip.process_state_code, 0) AS process_state_code
						,isnull(wip.qc_state_code, 0) AS qc_state_code
						,isnull(wip.long_time_state_code, 0) AS long_time_state_code
						,isnull(wip.lot_count, 0) AS lot_count
						,isnull(wip.pcs, 0) AS pcs
					FROM (
						SELECT dj.package_group_id AS package_group_id
							,dj.package_id AS package_id
							,dj.process_id AS process_id
							,dj.process_no AS process_no
							,dj.job_id AS job_id
							,dj.job_no AS job_no
							,dj.is_skipped AS is_skipped
						FROM (
							SELECT b.package_group_id AS package_group_id
								,a.package_id AS package_id
								,a.process_id AS process_id
								,a.process_no AS process_no
								,a.job_id AS job_id
								,a.job_no AS job_no
								,isnull(a.is_skipped, 0) AS is_skipped
							FROM APCSProDWH.dwh.dim_package_jobs AS a WITH (NOLOCK)
							LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS b WITH (NOLOCK) ON b.id = a.package_id
							) AS dj
						WHERE dj.is_skipped = 0
							AND (
								(
									@package_id IS NULL
									AND @package_group_id IS NOT NULL
									AND dj.package_group_id = @package_group_id
									)
								OR (
									@package_id IS NULL
									AND @package_group_id IS NULL
									AND dj.package_id > 0
									)
								)
							OR (
								(@package_id IS NOT NULL)
								AND (dj.package_id = @package_id)
								)
							AND dj.process_id IS NOT NULL
							AND dj.job_id IS NOT NULL
						) AS t1
					LEFT OUTER JOIN (
						SELECT fw.id AS id
							,fw.package_id AS package_id
							,fw.process_id AS process_id
							,fw.job_id AS job_id
							,fw.delay_state_code AS delay_state_code
							,fw.process_state_code AS process_state_code
							,fw.qc_state_code qc_state_code
							,fw.long_time_state_code long_time_state_code
							,fw.lot_count AS lot_count
							,fw.pcs AS pcs
						FROM APCSProDWH.dwh.fact_wip AS fw WITH (NOLOCK)
						LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fw.device_id
						WHERE day_id = (
								SELECT finished_day_id
								FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
								WHERE to_fact_table = 'dwh.fact_wip'
								)
							AND hour_code = (
								SELECT finished_hour_code
								FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
								WHERE to_fact_table = 'dwh.fact_wip'
								)
							AND (
								(
									@device_name IS NOT NULL
									AND ddv.name = @device_name
									)
								OR (@device_name IS NULL)
								)
							--AND fw.device_id IN (
							--	SELECT t.id
							--	FROM APCSProDWH.dwh.dim_devices AS t
							--	WHERE (t.id = fw.device_id)
							--		AND (
							--			@device_name IS NOT NULL
							--			AND t.name = @device_name
							--			)
							--		OR (
							--			@device_name IS NULL
							--			AND fw.device_id > 0
							--			)
							--	)
						) AS wip ON wip.package_id = t1.package_id
						AND wip.process_id = t1.process_id
						AND wip.job_id = t1.job_id
					) AS t2
				) AS t3
			) AS t4
		LEFT OUTER JOIN APCSProDWH.dwh.dim_package_groups AS pkgG WITH (NOLOCK) ON t4.package_group_id = pkgG.id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS pkg WITH (NOLOCK) ON pkg.id = t4.package_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS prc WITH (NOLOCK) ON prc.id = t4.process_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS job WITH (NOLOCK) ON job.id = t4.job_id
		WHERE (
				(
					(@process_id IS NOT NULL)
					AND (t4.process_id = @process_id)
					)
				OR (
					(@process_id IS NULL)
					AND (t4.process_id >= - 1)
					)
				)
		) AS t5
	WHERE t5.ranking = 1

	---------------------
	--Process指定有の場合
	---------------------
	IF @process_id IS NOT NULL
	BEGIN
		SELECT process_id AS process_id
			,process_no AS process_no
			,process_name AS process_name
			,job_id AS job_id
			,job_no AS job_no
			,job_name AS job_name
			,sum_lot AS sum_lots
			,sum_run_lot AS run_lots
			,sum_norm_lot AS wip_normal_lots
			,sum_long_norm_lot AS wip_long_normal_lots
			,sum_abnorm_lot AS wip_abnormal_lots
			,sum_long_abnorm_lot AS wip_long_abnormal_lots
			,sum_kpcs AS sum_kpcs
			,sum_run_kpcs AS run_kpcs
			,sum_norm_kpcs AS wip_normal_kpcs
			,sum_long_norm_kpcs AS wip_long_normal_kpcs
			,sum_abnorm_kpcs AS wip_abnormal_kpcs
			,sum_long_abnorm_kpcs AS wip_long_abnormal_kpcs
		FROM #table
		ORDER BY process_no
			,job_no
	END
	ELSE
	BEGIN
		SELECT *
		FROM (
			SELECT t6.process_id AS process_id
				,t6.process_no AS process_no
				,t6.process_name AS process_name
				,t6.job_id AS job_id
				,t6.job_no AS job_no
				,t6.job_name AS job_name
				,row_number() OVER (
					PARTITION BY t6.process_id ORDER BY t6.process_id
					) AS process_rank
				,sum(t6.sum_lot) OVER (PARTITION BY t6.process_id) AS sum_lots
				,sum(t6.sum_run_lot) OVER (PARTITION BY t6.process_id) AS run_lots
				,sum(t6.sum_norm_lot) OVER (PARTITION BY t6.process_id) AS wip_normal_lots
				,sum(t6.sum_long_norm_lot) OVER (PARTITION BY t6.process_id) AS wip_long_normal_lots
				,sum(t6.sum_abnorm_lot) OVER (PARTITION BY t6.process_id) AS wip_abnormal_lots
				,sum(t6.sum_long_abnorm_lot) OVER (PARTITION BY t6.process_id) AS wip_long_abnormal_lots
				,sum(t6.sum_kpcs) OVER (PARTITION BY t6.process_id) AS sum_kpcs
				,sum(t6.sum_run_kpcs) OVER (PARTITION BY t6.process_id) AS run_kpcs
				,sum(t6.sum_norm_kpcs) OVER (PARTITION BY t6.process_id) AS wip_normal_kpcs
				,sum(t6.sum_long_norm_kpcs) OVER (PARTITION BY t6.process_id) AS wip_long_normal_kpcs
				,sum(t6.sum_abnorm_kpcs) OVER (PARTITION BY t6.process_id) AS wip_abnormal_kpcs
				,sum(t6.sum_long_abnorm_kpcs) OVER (PARTITION BY t6.process_id) AS wip_long_abnormal_kpcs
			FROM #table AS t6
			) AS t7
		WHERE t7.process_rank = 1
		ORDER BY t7.process_no
			,t7.job_no
	END
END

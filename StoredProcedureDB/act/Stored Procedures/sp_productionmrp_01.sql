
CREATE PROCEDURE [act].[sp_productionmrp_01] @package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@all_jobs INT = NULL
AS
BEGIN
	--DECLARE @package_group_id INT = NULL;
	--DECLARE @package_id INT = NULL;
	--DECLARE @process_id INT = NULL;
	--DECLARE @all_job INT = 0;
	SELECT t5.package_group_id AS package_group_id
		,t5.package_group_name AS package_group_name
		,t5.package_id AS package_id
		,t5.package_name AS package_name
		,t5.process_id AS process_id
		,t5.process_no AS process_no
		,t5.process_name AS process_name
		,t5.job_id AS job_id
		,t5.job_no AS job_no
		,t5.job_name AS job_name
		,t5.sum_lot AS sum_lot
		,t5.sum_run_lot AS sum_run_lot
		,t5.sum_norm_lot AS sum_norm_lot
		,t5.sum_long_norm_lot AS sum_long_norm_lot
		,t5.sum_abnorm_lot AS sum_abnorm_lot
		,t5.sum_long_abnorm_lot AS sum_long_abnorm_lot
		,t5.sum_kpcs AS sum_kpcs
		,t5.sum_run_kpcs AS sum_run_kpcs
		,t5.sum_norm_kpcs AS sum_norm_kpcs
		,t5.sum_long_norm_kpcs AS sum_long_norm_kpcs
		,t5.sum_abnorm_kpcs AS sum_abnorm_kpcs
		,t5.sum_long_abnorm_kpcs AS sum_long_abnorm_kpcs
		,t5.process_rank AS process_rank
	FROM (
		SELECT t4.package_group_id AS package_group_id
			,pkgG.name AS package_group_name
			,t4.package_id AS package_id
			,pkg.name AS package_name
			,t4.process_id AS process_id
			,t4.process_no AS process_no
			,prc.name AS process_name
			,t4.job_id AS job_id
			,t4.job_no AS job_no
			,job.name AS job_name
			,CASE 
				WHEN @all_jobs = 1
					THEN t4.sum_lot
				ELSE sum(t4.sum_lot) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_lot
			,CASE 
				WHEN @all_jobs = 1
					THEN t4.sum_run_lot
				ELSE sum(t4.sum_run_lot) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_run_lot
			,CASE 
				WHEN @all_jobs = 1
					THEN t4.sum_norm_lot
				ELSE sum(t4.sum_norm_lot) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_norm_lot
			,CASE 
				WHEN @all_jobs = 1
					THEN t4.sum_long_norm_lot
				ELSE sum(t4.sum_long_norm_lot) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_long_norm_lot
			,CASE 
				WHEN @all_jobs = 1
					THEN t4.sum_abnorm_lot
				ELSE sum(t4.sum_abnorm_lot) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_abnorm_lot
			,CASE 
				WHEN @all_jobs = 1
					THEN t4.sum_long_abnorm_lot
				ELSE sum(t4.sum_long_abnorm_lot) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_long_abnorm_lot
			,CASE 
				WHEN @all_jobs = 1
					THEN isnull(convert(FLOAT, t4.sum_pcs) / 1000, - 3)
				ELSE sum(isnull(convert(FLOAT, t4.sum_pcs) / 1000, - 3)) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_kpcs
			,CASE 
				WHEN @all_jobs = 1
					THEN isnull(convert(FLOAT, t4.sum_run_pcs) / 1000, - 3)
				ELSE sum(isnull(convert(FLOAT, t4.sum_run_pcs) / 1000, - 3)) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_run_kpcs
			,CASE 
				WHEN @all_jobs = 1
					THEN isnull(convert(FLOAT, t4.sum_norm_pcs) / 1000, - 3)
				ELSE sum(isnull(convert(FLOAT, t4.sum_norm_pcs) / 1000, - 3)) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_norm_kpcs
			,CASE 
				WHEN @all_jobs = 1
					THEN isnull(convert(FLOAT, t4.sum_long_norm_pcs) / 1000, - 3)
				ELSE sum(isnull(convert(FLOAT, t4.sum_long_norm_pcs) / 1000, - 3)) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_long_norm_kpcs
			,CASE 
				WHEN @all_jobs = 1
					THEN isnull(convert(FLOAT, t4.sum_abnorm_pcs) / 1000, - 3)
				ELSE sum(isnull(convert(FLOAT, t4.sum_abnorm_pcs) / 1000, - 3)) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_abnorm_kpcs
			,CASE 
				WHEN @all_jobs = 1
					THEN isnull(convert(FLOAT, t4.sum_long_abnorm_pcs) / 1000, - 3)
				ELSE sum(isnull(convert(FLOAT, t4.sum_long_abnorm_pcs) / 1000, - 3)) OVER (
						PARTITION BY t4.process_id
						,t4.process_no
						)
				END AS sum_long_abnorm_kpcs
			,rank() OVER (
				PARTITION BY t4.process_id
				,t4.process_no ORDER BY t4.job_id
				) AS process_rank
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
				,row_number() OVER (
					PARTITION BY t3.process_id
					,t3.job_id ORDER BY t3.wip_id
					) AS ranking
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
							,isnull(dj.is_skipped, 0) AS is_skipped
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
		WHERE t4.ranking = 1
			AND (
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
	WHERE (
			(@all_jobs = 1)
			AND (t5.process_rank > 0)
			)
		OR (
			(@all_jobs != 1)
			AND (t5.process_rank = 1)
			)
	ORDER BY t5.process_no
		,t5.job_no
END

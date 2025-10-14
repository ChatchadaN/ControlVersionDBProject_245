
CREATE PROCEDURE [act].[sp_qualitytoc_bottleneck] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@date_from DATE
	,@date_to DATE
	)
AS
BEGIN
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_from
			)
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_to
			)
	DECLARE @plan INT = (
			SELECT sum(pcs) AS sum_plan_pcs
			FROM (
				SELECT [day_id]
					,[package_id]
					,[pcs]
				FROM APCSProDWH.dwh.fact_plan AS fp WITH (NOLOCK)
				WHERE package_id = @package_id
					AND @from <= fp.day_id
					AND fp.day_id <= @to
				) AS fp1
			)

	SELECT t3.package_id AS package_id
		,t3.job_id AS job_id
		,t3.job_no AS job_no
		,t3.job_name AS job_name
		,t3.is_skipped AS is_skipped
		,t3.process_id AS process_id
		,t3.process_no AS process_no
		,t3.process_name AS process_name
		,t3.sum_lot_cnt AS sum_lot_cnt
		,t3.all_lot_cnt AS all_lot_cnt
		,t3.sum_pass_kpcs AS sum_pass_kpcs
		,t3.all_pass_kpcs AS all_pass_kpcs
		,t3.wait_time AS wait_time
		,t3.process_time AS process_time
		,t3.sum_plan_kpcs AS sum_plan_kpcs
		,t3.all_wait_time AS all_wait_time
		,t3.all_process_time AS all_process_time
		,t3.sum_pass_kpcs / nullif((t3.sum_pass_kpcs + t3.all_pass_kpcs), 0) * 100 AS pkg_occupancy
		,t3.sum_pass_kpcs / nullif(t3.process_time, 0) * 60 AS pkg_per_h
		,convert(DECIMAL(16, 1), t3.process_time) / nullif(t3.process_time + t3.wait_time, 0) * 100 AS pkg_efficiency
		,t3.max_wip_lot_count AS max_wip_lot_count
		,t3.cur_wip_lot_count AS cur_wip_lot_count
		,t3.min_wip_lot_count AS min_wip_lot_count
		,t3.max_wip_kpcs AS max_wip_kpcs
		,t3.cur_wip_kpcs AS cur_wip_kpcs
		,t3.min_wip_kpcs AS min_wip_kpcs
	FROM (
		SELECT t2.package_id AS package_id
			,t2.job_id AS job_id
			,t2.job_no AS job_no
			,t2.job_name AS job_name
			,t2.is_skipped AS is_skipped
			,t2.process_id AS process_id
			,t2.process_no AS process_no
			,t2.process_name AS process_name
			,
			--							
			isnull(s1.lot_cnt, 0) AS sum_lot_cnt
			,isnull(s2.lot_cnt, 0) AS all_lot_cnt
			,convert(DECIMAL(16, 1), isnull(s1.sum_pass_pcs, 0)) / 1000 AS sum_pass_kpcs
			,convert(DECIMAL(16, 1), isnull(s2.sum_pass_pcs, 0)) / 1000 AS all_pass_kpcs
			,isnull(s1.wait_time, 0) AS wait_time
			,isnull(s1.process_time, 0) AS process_time
			,convert(DECIMAL(16, 1), isnull(@plan, 0)) / 1000 AS sum_plan_kpcs
			,
			--							
			isnull(s2.wait_time, 0) AS all_wait_time
			,isnull(s2.process_time, 0) AS all_process_time
			,
			--
			isnull(u1.max_lot_count, 0) AS max_wip_lot_count
			,isnull(u2.cur_lot_count, 0) AS cur_wip_lot_count
			,isnull(u1.min_lot_count, 0) AS min_wip_lot_count
			,
			--
			convert(DECIMAL(16, 1), isnull(u1.max_pcs, 0)) / 1000 AS max_wip_kpcs
			,convert(DECIMAL(16, 1), isnull(u2.cur_pcs, 0)) / 1000 AS cur_wip_kpcs
			,convert(DECIMAL(16, 1), isnull(u1.min_pcs, 0)) / 1000 AS min_wip_kpcs
		FROM (
			SELECT t1.package_id AS package_id
				,t1.job_id AS job_id
				,t1.job_no AS job_no
				,t1.job_name AS job_name
				,t1.is_skipped AS is_skipped
				,t1.process_id AS process_id
				,t1.process_no AS process_no
				,t1.process_name AS process_name
			FROM (
				SELECT pj.package_id AS package_id
					,pj.job_id AS job_id
					,pj.job_no AS job_no
					,pj.job_name AS job_name
					,isnull(pj.is_skipped, 0) AS is_skipped
					,pj.process_id AS process_id
					,pj.process_no AS process_no
					,pj.process_name AS process_name
				FROM APCSProDWH.dwh.dim_package_jobs AS pj WITH (NOLOCK)
				WHERE package_id = @package_id
				) AS t1
			WHERE is_skipped = 0
			) AS t2
		LEFT OUTER JOIN (
			SELECT fe1.process_id AS process_id
				,fe1.job_id AS job_id
				,sum(1) AS lot_cnt
				,sum(fe1.input_pcs) AS sum_input_pcs
				,sum(fe1.pass_pcs) AS sum_pass_pcs
				,avg(fe1.std_time) AS std_time
				,sum(fe1.wait_time) AS wait_time
				,sum(fe1.process_time) AS process_time
			FROM (
				SELECT fe.id AS id
					,fe.day_id AS day_id
					,fe.hour_code AS hour_code
					,fe.package_group_id AS package_group_id
					,fe.package_id AS package_id
					,fe.device_id AS device_id
					,fe.assy_name_id AS assy_name_id
					,fe.lot_id AS lot_id
					,fe.process_id AS process_id
					,fe.job_id AS job_id
					,fe.input_pcs AS input_pcs
					,fe.pass_pcs AS pass_pcs
					,fe.machine_id AS machine_id
					,fe.code AS code
					,fe.std_time AS std_time
					,fe.wait_time AS wait_time
					,fe.process_time AS process_time
				FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
				WHERE @from <= fe.day_id
					AND fe.day_id <= @to
					AND package_id = @package_id
				) AS fe1
			GROUP BY fe1.process_id
				,fe1.job_id
			) AS s1 ON s1.process_id = t2.process_id
			AND s1.job_id = t2.job_id
		LEFT OUTER JOIN (
			SELECT fe1.process_id AS process_id
				,fe1.job_id AS job_id
				,sum(1) AS lot_cnt
				,sum(fe1.input_pcs) AS sum_input_pcs
				,sum(fe1.pass_pcs) AS sum_pass_pcs
				,avg(fe1.std_time) AS std_time
				,sum(fe1.wait_time) AS wait_time
				,sum(fe1.process_time) AS process_time
			FROM (
				SELECT fe.id AS id
					,fe.day_id AS day_id
					,fe.hour_code AS hour_code
					,fe.package_group_id AS package_group_id
					,fe.package_id AS package_id
					,fe.device_id AS device_id
					,fe.assy_name_id AS assy_name_id
					,fe.lot_id AS lot_id
					,fe.process_id AS process_id
					,fe.job_id AS job_id
					,fe.input_pcs AS input_pcs
					,fe.pass_pcs AS pass_pcs
					,fe.machine_id AS machine_id
					,fe.code AS code
					,fe.std_time AS std_time
					,fe.wait_time AS wait_time
					,fe.process_time AS process_time
				FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
				WHERE @from <= fe.day_id
					AND fe.day_id <= @to
				) AS fe1
			GROUP BY fe1.process_id
				,fe1.job_id
			) AS s2 ON s2.process_id = t2.process_id
			AND s2.job_id = t2.job_id
		LEFT OUTER JOIN (
			SELECT t2.process_id AS process_id
				,t2.job_id AS job_id
				,max(t2.sum_lot_count) AS max_lot_count
				,max(t2.sum_pcs) AS max_pcs
				,min(t2.sum_lot_count) AS min_lot_count
				,min(t2.sum_pcs) AS min_pcs
			FROM (
				SELECT *
				FROM (
					SELECT fw.id AS id
						,fw.day_id AS day_id
						,fw.hour_code AS hour_code
						,fw.package_id AS package_id
						,fw.process_id AS process_id
						,fw.job_id AS job_id
						,fw.lot_count AS lot_count
						,fw.pcs AS pcs
						,rank() OVER (
							PARTITION BY fw.day_id
							,fw.hour_code
							,fw.process_id
							,fw.job_id ORDER BY fw.id
							) AS sum_rank
						,sum(fw.lot_count) OVER (
							PARTITION BY fw.day_id
							,fw.hour_code
							,fw.process_id
							,fw.job_id
							) AS sum_lot_count
						,sum(fw.pcs) OVER (
							PARTITION BY fw.day_id
							,fw.hour_code
							,fw.process_id
							,fw.job_id
							) AS sum_pcs
					FROM APCSProDWH.dwh.fact_wip AS fw WITH (NOLOCK)
					WHERE package_id = @package_id
						AND @from <= fw.day_id
						AND fw.day_id <= @to
					) AS t1
				WHERE sum_rank = 1
				) AS t2
			GROUP BY t2.process_id
				,t2.job_id
			) AS u1 ON u1.process_id = t2.process_id
			AND u1.job_id = t2.job_id
		LEFT OUTER JOIN (
			SELECT t3.process_id AS process_id
				,t3.job_id AS job_id
				,sum(t3.lot_count) AS cur_lot_count
				,sum(t3.pcs) AS cur_pcs
			FROM (
				SELECT t2.id AS id
					,t2.day_id AS day_id
					,t2.hour_code AS hour_code
					,t2.package_id AS package_id
					,t2.process_id AS process_id
					,t2.job_id AS job_id
					,t2.lot_count AS lot_count
					,t2.pcs AS pcs
					,t2.latest_hour_code AS latest_hour_code
				FROM (
					SELECT t1.id AS id
						,t1.day_id AS day_id
						,t1.hour_code AS hour_code
						,t1.package_id AS package_id
						,t1.process_id AS process_id
						,t1.job_id AS job_id
						,t1.lot_count AS lot_count
						,t1.pcs AS pcs
						,t1.latest_hour_code AS latest_hour_code
					FROM (
						SELECT fw.id AS id
							,fw.day_id AS day_id
							,fw.hour_code AS hour_code
							,fw.package_id AS package_id
							,fw.process_id AS process_id
							,fw.job_id AS job_id
							,fw.lot_count AS lot_count
							,fw.pcs AS pcs
							,dense_rank() OVER (
								ORDER BY fw.day_id DESC
									,fw.hour_code DESC
								) AS latest_hour_code
						FROM APCSProDWH.dwh.fact_wip AS fw WITH (NOLOCK)
						WHERE package_id = @package_id
							AND @from <= fw.day_id
							AND fw.day_id <= @to
						) AS t1
					WHERE t1.latest_hour_code = 1
					) AS t2
				) AS t3
			GROUP BY t3.process_id
				,t3.job_id
			) AS u2 ON u2.process_id = t2.process_id
			AND u2.job_id = t2.job_id
		) AS t3
	ORDER BY process_no
		,job_no
END

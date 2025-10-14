
CREATE PROCEDURE [act].[sp_productionipi_wip_current] @device_id INT = NULL
AS
BEGIN
	--DECLARE @device_id INT = 5316
	--@device_id(use as device_name_id)
	SELECT ROW_NUMBER() OVER (
			ORDER BY t1.act_process_id
				,t1.job_id
			) AS rownum
		,t1.act_process_id AS process_id
		,t1.process_name AS process_name
		,t1.job_id AS job_id
		,t1.job_name AS job_name
		,isnull(wip.sum_lot, 0) AS sum_lot_count
		,isnull(convert(DECIMAL, wip.sum_pcs) / 1000, 0) AS sum_kpcs
		,isnull(wip.run_lot, 0) AS run_lot
		,isnull(convert(DECIMAL, wip.run_pcs) / 1000, 0) AS run_kpcs
		,isnull(wip.norm_lot, 0) AS norm_lot
		,isnull(convert(DECIMAL, wip.norm_pcs) / 1000, 0) AS norm_kpcs
		,isnull(wip.long_norm_lot, 0) AS long_norm_lot
		,isnull(convert(DECIMAL, wip.long_norm_pcs) / 1000, 0) AS long_norm_kpcs
		,isnull(wip.abnorm_lot, 0) AS abnorm_lot
		,isnull(convert(DECIMAL, wip.abnorm_pcs) / 1000, 0) AS abnorm_kpcs
		,isnull(wip.long_abnorm_lot, 0) AS long_abnorm_lot
		,isnull(convert(DECIMAL, wip.long_abnorm_pcs) / 1000, 0) AS long_abnorm_kpcs
	FROM (
		SELECT dn.id AS device_name_id
			,rtrim(dn.name) AS device_name
			,dn.assy_name AS assy_name
			,df.act_process_id
			,mp.name AS process_name
			,df.job_id
			,mj.name AS job_name
		FROM APCSProDB.method.device_names AS dn WITH (NOLOCK)
		INNER JOIN (
			SELECT device_id
				,device_name_id
				,device_type
				,max(version_num) AS verion_num
			FROM APCSProDB.method.device_versions AS v WITH (NOLOCK)
			GROUP BY device_id
				,device_name_id
				,device_type
			) AS dv ON dv.device_name_id = dn.id
		INNER JOIN APCSProDB.method.device_slips AS ds WITH (NOLOCK) ON ds.device_id = dv.device_id
			AND ds.version_num = dv.verion_num
		INNER JOIN APCSProDB.method.device_flows AS df WITH (NOLOCK) ON df.device_slip_id = ds.device_slip_id
			AND df.is_skipped = 0
		INNER JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = df.act_process_id
		INNER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.id = df.job_id
		WHERE dn.id = @device_id
		GROUP BY dn.id
			,rtrim(dn.name)
			,dn.assy_name
			,df.act_process_id
			,mp.name
			,df.job_id
			,mj.name
		) AS t1
	LEFT OUTER JOIN (
		SELECT t2.package_id
			,t2.process_id
			,t2.job_id
			,SUM(t2.lot_cnt) AS sum_lot
			,sum(t2.pcs) AS sum_pcs
			,sum(t2.run_lot) AS run_lot
			,sum(t2.run_pcs) AS run_pcs
			,sum(t2.norm_lot) AS norm_lot
			,sum(t2.norm_pcs) AS norm_pcs
			,sum(t2.long_norm_lot) AS long_norm_lot
			,sum(t2.long_norm_pcs) AS long_norm_pcs
			,sum(t2.abnorm_lot) AS abnorm_lot
			,sum(t2.abnorm_pcs) AS abnorm_pcs
			,sum(t2.long_abnorm_lot) AS long_abnorm_lot
			,sum(t2.long_abnorm_pcs) AS long_abnorm_pcs
		FROM (
			SELECT fw.day_id AS day_id
				,fw.hour_code AS hour_code
				,fw.id AS wip_id
				,fw.package_group_id AS package_group_id
				,fw.package_id AS package_id
				,fw.process_id AS process_id
				,fw.job_id AS job_id
				,fw.process_state_code AS process_state_code
				,fw.qc_state_code AS qc_state_code
				,fw.long_time_state_code AS long_time_state_code
				,fw.lot_count AS lot_cnt
				,fw.pcs AS pcs
				,fw.lot_count * CASE 
					WHEN (fw.qc_state_code = 0)
						AND (
							fw.process_state_code % 10 IN (
								1
								,2
								)
							)
						THEN 1
					ELSE 0
					END AS run_lot
				,fw.pcs * CASE 
					WHEN (fw.qc_state_code = 0)
						AND (
							fw.process_state_code % 10 IN (
								1
								,2
								)
							)
						THEN 1
					ELSE 0
					END AS run_pcs
				,fw.lot_count * CASE 
					WHEN (
							fw.process_state_code % 10 NOT IN (
								1
								,2
								)
							AND fw.qc_state_code = 0
							AND fw.long_time_state_code = 0
							)
						OR (
							fw.qc_state_code = 4
							AND fw.long_time_state_code = 0
							)
						THEN 1
					ELSE 0
					END AS norm_lot
				,fw.pcs * CASE 
					WHEN (
							fw.process_state_code % 10 NOT IN (
								1
								,2
								)
							AND fw.qc_state_code = 0
							AND fw.long_time_state_code = 0
							)
						OR (
							fw.qc_state_code = 4
							AND fw.long_time_state_code = 0
							)
						THEN 1
					ELSE 0
					END AS norm_pcs
				,fw.lot_count * CASE 
					WHEN (
							fw.process_state_code % 10 NOT IN (
								1
								,2
								)
							AND fw.qc_state_code = 0
							AND fw.long_time_state_code = 1
							)
						OR (
							fw.qc_state_code = 4
							AND fw.long_time_state_code = 1
							)
						THEN 1
					ELSE 0
					END AS long_norm_lot
				,fw.pcs * CASE 
					WHEN (
							fw.process_state_code % 10 NOT IN (
								1
								,2
								)
							AND fw.qc_state_code = 0
							AND fw.long_time_state_code = 1
							)
						OR (
							fw.qc_state_code = 4
							AND fw.long_time_state_code = 1
							)
						THEN 1
					ELSE 0
					END AS long_norm_pcs
				,fw.lot_count * CASE 
					WHEN (
							fw.qc_state_code NOT IN (
								0
								,4
								)
							AND fw.long_time_state_code = 0
							)
						THEN 1
					ELSE 0
					END AS abnorm_lot
				,fw.pcs * CASE 
					WHEN (
							fw.qc_state_code NOT IN (
								0
								,4
								)
							AND fw.long_time_state_code = 0
							)
						THEN 1
					ELSE 0
					END AS abnorm_pcs
				,fw.lot_count * CASE 
					WHEN (
							fw.qc_state_code NOT IN (
								0
								,4
								)
							AND fw.long_time_state_code = 1
							)
						THEN 1
					ELSE 0
					END AS long_abnorm_lot
				,fw.pcs * CASE 
					WHEN (
							fw.qc_state_code NOT IN (
								0
								,4
								)
							AND fw.long_time_state_code = 1
							)
						THEN 1
					ELSE 0
					END AS long_abnorm_pcs
			FROM APCSProDWH.dwh.fact_wip AS fw WITH (NOLOCK)
			WHERE fw.device_id = @device_id
				AND day_id = (
					SELECT finished_day_id
					FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
					WHERE to_fact_table = 'dwh.fact_wip'
					)
				AND hour_code = (
					SELECT finished_hour_code
					FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
					WHERE to_fact_table = 'dwh.fact_wip'
					)
			) AS t2
		GROUP BY t2.package_id
			,t2.process_id
			,t2.job_id
		) AS wip ON wip.process_id = t1.act_process_id
		AND wip.job_id = t1.job_id
	ORDER BY rownum
END

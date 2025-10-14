
create PROCEDURE [act].[sp_productionipi_wip_current_backup] @device_id INT = NULL
AS
BEGIN
	--DECLARE @device_id INT = 5316
	SELECT ROW_NUMBER() OVER (
			ORDER BY t1.id
			) AS rownum,
		t1.step_no AS step_no,
		t1.next_step_no AS next_step_no,
		t1.act_process_id AS process_id,
		t1.process_name AS process_name,
		t1.job_id AS job_id,
		t1.job_name AS job_name,
		isnull(wip.sum_lot, 0) AS sum_lot_count,
		isnull(convert(DECIMAL, wip.sum_pcs) / 1000, 0) AS sum_kpcs,
		isnull(wip.run_lot, 0) AS run_lot,
		isnull(convert(DECIMAL, wip.run_pcs) / 1000, 0) AS run_kpcs,
		isnull(wip.norm_lot, 0) AS norm_lot,
		isnull(convert(DECIMAL, wip.norm_pcs) / 1000, 0) AS norm_kpcs,
		isnull(wip.long_norm_lot, 0) AS long_norm_lot,
		isnull(convert(DECIMAL, wip.long_norm_pcs) / 1000, 0) AS long_norm_kpcs,
		isnull(wip.abnorm_lot, 0) AS abnorm_lot,
		isnull(convert(DECIMAL, wip.abnorm_pcs) / 1000, 0) AS abnorm_kpcs,
		isnull(wip.long_abnorm_lot, 0) AS long_abnorm_lot,
		isnull(convert(DECIMAL, wip.long_abnorm_pcs) / 1000, 0) AS long_abnorm_kpcs
	FROM (
		SELECT df.*,
			dd.id AS device_id,
			dd.name AS device_name,
			ds.version_num AS version_num,
			dp.name AS process_name,
			dj.name AS job_name
		FROM APCSProDB.method.device_flows AS df with(nolock)
		INNER JOIN APCSProDB.method.device_slips AS ds with(nolock) ON ds.device_slip_id = df.device_slip_id
		INNER JOIN APCSProDWH.dwh.dim_devices AS dd with(nolock) ON dd.id = ds.device_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp with(nolock) ON dp.id = df.act_process_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj with(nolock) ON dj.id = df.job_id
		WHERE df.is_skipped = 0
			AND ds.device_slip_id = (
				SELECT t.device_slip_id AS device_slip_id
				FROM (
					SELECT rank() OVER (
							PARTITION BY device_id ORDER BY version_num DESC
							) AS latest_order,
						device_id AS device_id,
						device_slip_id AS device_slip_id,
						version_num AS version_num
					FROM APCSProDB.method.device_slips AS ds with(nolock)
					LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS dd with(nolock) ON dd.id = ds.device_id
					WHERE ds.device_id = @device_id
					) AS t
				WHERE t.latest_order = 1
				)
		) AS t1
	LEFT OUTER JOIN (
		SELECT t2.package_id,
			t2.process_id,
			t2.job_id,
			SUM(t2.lot_cnt) AS sum_lot,
			sum(t2.pcs) AS sum_pcs,
			sum(t2.run_lot) AS run_lot,
			sum(t2.run_pcs) AS run_pcs,
			sum(t2.norm_lot) AS norm_lot,
			sum(t2.norm_pcs) AS norm_pcs,
			sum(t2.long_norm_lot) AS long_norm_lot,
			sum(t2.long_norm_pcs) AS long_norm_pcs,
			sum(t2.abnorm_lot) AS abnorm_lot,
			sum(t2.abnorm_pcs) AS abnorm_pcs,
			sum(t2.long_abnorm_lot) AS long_abnorm_lot,
			sum(t2.long_abnorm_pcs) AS long_abnorm_pcs
		FROM (
			SELECT fw.day_id AS day_id,
				fw.hour_code AS hour_code,
				fw.id AS wip_id,
				fw.package_group_id AS package_group_id,
				fw.package_id AS package_id,
				fw.process_id AS process_id,
				fw.job_id AS job_id,
				fw.process_state_code AS process_state_code,
				fw.qc_state_code AS qc_state_code,
				fw.long_time_state_code AS long_time_state_code,
				fw.lot_count AS lot_cnt,
				fw.pcs AS pcs,
				fw.lot_count * CASE 
					WHEN (fw.qc_state_code = 0)
						AND (fw.process_state_code % 10 IN (1, 2))
						THEN 1
					ELSE 0
					END AS run_lot,
				fw.pcs * CASE 
					WHEN (fw.qc_state_code = 0)
						AND (fw.process_state_code % 10 IN (1, 2))
						THEN 1
					ELSE 0
					END AS run_pcs,
				fw.lot_count * CASE 
					WHEN (
							fw.process_state_code % 10 NOT IN (1, 2)
							AND fw.qc_state_code = 0
							AND fw.long_time_state_code = 0
							)
						OR (
							fw.qc_state_code = 4
							AND fw.long_time_state_code = 0
							)
						THEN 1
					ELSE 0
					END AS norm_lot,
				fw.pcs * CASE 
					WHEN (
							fw.process_state_code % 10 NOT IN (1, 2)
							AND fw.qc_state_code = 0
							AND fw.long_time_state_code = 0
							)
						OR (
							fw.qc_state_code = 4
							AND fw.long_time_state_code = 0
							)
						THEN 1
					ELSE 0
					END AS norm_pcs,
				fw.lot_count * CASE 
					WHEN (
							fw.process_state_code % 10 NOT IN (1, 2)
							AND fw.qc_state_code = 0
							AND fw.long_time_state_code = 1
							)
						OR (
							fw.qc_state_code = 4
							AND fw.long_time_state_code = 1
							)
						THEN 1
					ELSE 0
					END AS long_norm_lot,
				fw.pcs * CASE 
					WHEN (
							fw.process_state_code % 10 NOT IN (1, 2)
							AND fw.qc_state_code = 0
							AND fw.long_time_state_code = 1
							)
						OR (
							fw.qc_state_code = 4
							AND fw.long_time_state_code = 1
							)
						THEN 1
					ELSE 0
					END AS long_norm_pcs,
				fw.lot_count * CASE 
					WHEN (
							fw.qc_state_code NOT IN (0, 4)
							AND fw.long_time_state_code = 0
							)
						THEN 1
					ELSE 0
					END AS abnorm_lot,
				fw.pcs * CASE 
					WHEN (
							fw.qc_state_code NOT IN (0, 4)
							AND fw.long_time_state_code = 0
							)
						THEN 1
					ELSE 0
					END AS abnorm_pcs,
				fw.lot_count * CASE 
					WHEN (
							fw.qc_state_code NOT IN (0, 4)
							AND fw.long_time_state_code = 1
							)
						THEN 1
					ELSE 0
					END AS long_abnorm_lot,
				fw.pcs * CASE 
					WHEN (
							fw.qc_state_code NOT IN (0, 4)
							AND fw.long_time_state_code = 1
							)
						THEN 1
					ELSE 0
					END AS long_abnorm_pcs
			FROM APCSProDWH.dwh.fact_wip AS fw with(nolock)
			WHERE fw.device_id = @device_id
				AND day_id = (
					SELECT finished_day_id
					FROM APCSProDWH.dwh.function_finish_control with(nolock)
					WHERE to_fact_table = 'dwh.fact_wip'
					)
				AND hour_code = (
					SELECT finished_hour_code
					FROM APCSProDWH.dwh.function_finish_control with(nolock)
					WHERE to_fact_table = 'dwh.fact_wip'
					)
			) AS t2
		GROUP BY t2.package_id,
			t2.process_id,
			t2.job_id
		) AS wip ON wip.process_id = t1.act_process_id
		AND wip.job_id = t1.job_id
	ORDER BY step_no
END

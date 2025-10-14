
CREATE PROCEDURE [act].[sp_productionipi_wip_transition_forpkg] @package_id INT = NULL,
	@device_id INT = NULL,
	@input_limit_id INT = NULL,
	@date_from DATE = NULL,
	@date_to DATE = NULL,
	@target_device NVARCHAR(32) = NULL
AS
BEGIN
	--DECLARE @package_id INT = 242
	--DECLARE @device_id INT = NULL
	--DECLARE @input_limit_id INT = 12
	--DECLARE @debug INT = 1
	--DECLARE @date_from DATE = '2019-05-01'
	--DECLARE @date_to DATE = '2019-05-10'
	DECLARE @from INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days
			WHERE date_value = @date_from
			);
	DECLARE @to INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days
			WHERE date_value = @date_to
			);

	SELECT dd.date_value AS date_value,
		t5.A_lot_target_sum AS A_lot_target_sum,
		t5.A_lot_target_sum_nodevice AS A_lot_target_sum_nodevice,
		t5.A_lot_no_target_sum AS A_lot_no_target_sum,
		t5.A_lot_hold_sum AS A_lot_hold_sum,
		t5.no_A_lot_sum AS no_A_lot_sum,
		isnull(convert(DECIMAL, t5.A_lot_target_sum_pcs) / 1000, 0) AS A_lot_target_sum_kpcs,
		isnull(convert(DECIMAL, t5.A_lot_target_sum_pcs_nodevice) / 1000, 0) AS A_lot_target_sum_kpcs_nodevice,
		isnull(convert(DECIMAL, t5.A_lot_no_target_sum_pcs) / 1000, 0) AS A_lot_no_target_sum_kpcs,
		isnull(convert(DECIMAL, t5.A_lot_hold_sum_pcs) / 1000, 0) AS A_lot_hold_sum_kpcs,
		isnull(convert(DECIMAL, t5.no_A_lot_sum_pcs) / 1000, 0) AS no_A_lot_sum_kpcs,
		t5.UCL AS UCL
	FROM (
		SELECT t4.day_id AS day_id,
			--lots
			sum(t4.A_lot_target_count) AS A_lot_target_sum,
			sum(t4.A_lot_target_count_nodevice) AS A_lot_target_sum_nodevice,
			sum(t4.A_lot_no_target_count) AS A_lot_no_target_sum,
			sum(t4.A_lot_hold_count) AS A_lot_hold_sum,
			sum(t4.no_A_lot_count) AS no_A_lot_sum,
			--pcs
			sum(t4.A_lot_target_pcs) AS A_lot_target_sum_pcs,
			sum(t4.A_lot_target_pcs_nodevice) AS A_lot_target_sum_pcs_nodevice,
			sum(t4.A_lot_no_target_pcs) AS A_lot_no_target_sum_pcs,
			sum(t4.A_lot_hold_pcs) AS A_lot_hold_sum_pcs,
			sum(t4.no_A_lot_pcs) AS no_A_lot_sum_pcs,
			max(t4.alarm_value) AS UCL
		FROM (
			SELECT
				----A LOT
				--HOLD
				t3.lot_count * CASE 
					WHEN (t3.production_category = 0)
						AND (t3.qc_state_code = 3)
						THEN 1
					ELSE 0
					END AS A_lot_hold_count,
				cast(t3.pcs AS BIGINT) * CASE 
					WHEN (t3.production_category = 0)
						AND (t3.qc_state_code = 3)
						THEN 1
					ELSE 0
					END AS A_lot_hold_pcs,
				--target 対象device
				t3.lot_count * CASE 
					WHEN (t3.production_category = 0)
						AND (t3.qc_state_code <> 3)
						AND (target_job_flag = 1)
						AND CHARINDEX(CASE 
								WHEN @target_device IS NULL
									THEN t3.device_name
								ELSE @target_device
								END, t3.device_name) = 1
						THEN 1
					ELSE 0
					END AS A_lot_target_count,
				cast(t3.pcs AS BIGINT) * CASE 
					WHEN (t3.production_category = 0)
						AND (t3.qc_state_code <> 3)
						AND (target_job_flag = 1)
						AND CHARINDEX(CASE 
								WHEN @target_device IS NULL
									THEN t3.device_name
								ELSE @target_device
								END, t3.device_name) = 1
						THEN 1
					ELSE 0
					END AS A_lot_target_pcs,
				--target NOT対象device
				t3.lot_count * CASE 
					WHEN (t3.production_category = 0)
						AND (t3.qc_state_code <> 3)
						AND (target_job_flag = 1)
						AND CHARINDEX(CASE 
								WHEN @target_device IS NULL
									THEN t3.device_name
								ELSE @target_device
								END, t3.device_name) <> 1
						THEN 1
					ELSE 0
					END AS A_lot_target_count_nodevice,
				cast(t3.pcs AS BIGINT) * CASE 
					WHEN (t3.production_category = 0)
						AND (t3.qc_state_code <> 3)
						AND (target_job_flag = 1)
						AND CHARINDEX(CASE 
								WHEN @target_device IS NULL
									THEN t3.device_name
								ELSE @target_device
								END, t3.device_name) <> 1
						THEN 1
					ELSE 0
					END AS A_lot_target_pcs_nodevice,
				--no target
				t3.lot_count * CASE 
					WHEN (t3.production_category = 0)
						AND (t3.qc_state_code <> 3)
						AND (target_job_flag <> 1)
						THEN 1
					ELSE 0
					END AS A_lot_no_target_count,
				cast(t3.pcs AS BIGINT) * CASE 
					WHEN (t3.production_category = 0)
						AND (t3.qc_state_code <> 3)
						AND (target_job_flag <> 1)
						THEN 1
					ELSE 0
					END AS A_lot_no_target_pcs,
				----NOT A LOT
				t3.lot_count * CASE 
					WHEN (t3.production_category <> 0)
						OR (t3.production_category IS NULL)
						THEN 1
					ELSE 0
					END AS no_A_lot_count,
				cast(t3.pcs AS BIGINT) * CASE 
					WHEN (t3.production_category <> 0)
						OR (t3.production_category IS NULL)
						THEN 1
					ELSE 0
					END AS no_A_lot_pcs,
				t3.*
			FROM (
				SELECT isnull(TJ.f, 0) AS target_job_flag,
					TJ.alarm_value AS alarm_value,
					t2.*
				FROM (
					SELECT t1.day_id AS day_id,
						t1.hour_code AS hour_code,
						t1.process_id AS process_id,
						t1.process_name AS process_name,
						t1.job_id AS job_id,
						t1.job_name AS job_name,
						t1.lot_count AS lot_count,
						t1.pcs AS pcs,
						t1.production_category AS production_category,
						t1.qc_state_code AS qc_state_code,
						t1.device_name AS device_name
					FROM (
						SELECT wi.day_id AS day_id,
							wi.hour_code AS hour_code,
							wi.process_id AS process_id,
							dp.name AS process_name,
							wi.job_id AS job_id,
							dj.name AS job_name,
							wi.production_category AS production_category,
							wi.qc_state_code AS qc_state_code,
							wi.lot_count AS lot_count,
							wi.pcs AS pcs,
							wi.device_name AS device_name
						FROM (
							SELECT d.day_id AS day_id,
								d.hour_code AS hour_code,
								w.package_id AS package_id,
								w.process_id AS process_id,
								w.job_id AS job_id,
								w.device_id AS device_id,
								w.production_category AS production_category,
								w.qc_state_code AS qc_state_code,
								w.lot_count AS lot_count,
								w.pcs AS pcs,
								w.device_name AS device_name
							FROM (
								SELECT dd.day_id AS day_id,
									dd.hour_code AS hour_code
								FROM (
									SELECT ddy.id AS day_id,
										dh.code AS hour_code
									FROM apcsprodwh.dwh.dim_days AS ddy
									CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
									) AS dd
								WHERE (dd.hour_code > 0)
									AND (
										dd.day_id BETWEEN @from
											AND @to
										)
								) AS d
							LEFT OUTER JOIN (
								SELECT *
								FROM (
									SELECT fw.*,
										RANK() OVER (
											PARTITION BY day_id ORDER BY hour_code DESC
											) AS latest_hour_code,
										d.name AS device_name
									FROM apcsprodwh.dwh.fact_wip AS fw WITH (NOLOCK)
									INNER JOIN APCSProDB.method.device_names AS d ON d.id = fw.device_id
									WHERE fw.package_id = @package_id
										AND (
											(
												(@device_id IS NOT NULL)
												AND (device_id = @device_id)
												)
											OR (
												(@device_id IS NULL)
												AND (device_id > 0)
												)
											)
											and fw.process_state_code not in (2,102)
									) AS t
								WHERE t.latest_hour_code = 1
								) AS w ON d.day_id = w.day_id
								AND d.hour_code = w.hour_code
							) AS wi
						LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp ON dp.id = wi.process_id
						LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj ON dj.id = wi.job_id
						) AS t1
					) AS t2
				LEFT OUTER JOIN (
					SELECT j.id AS job_id,
						il.alarm_value AS alarm_value,
						1 AS f
					from APCSProDWH.wip_control.monitoring_items AS il WITH (NOLOCK)
					--INNER JOIN APCSProDWH.dwh.setting_job_groups_jobs AS jj WITH (NOLOCK) ON jj.job_group_id = il.target_id
					INNER JOIN APCSProDWH.wip_control.wip_count_jobs AS jj WITH (NOLOCK) ON jj.wip_count_target_id = il.target_id
					INNER JOIN APCSProDWH.dwh.dim_jobs AS j WITH (NOLOCK) ON j.id = jj.job_id
					WHERE il.id = @input_limit_id
					) AS TJ ON TJ.job_id = t2.job_id
				) AS t3
			) AS t4
		GROUP BY t4.day_id
		) AS t5
	LEFT OUTER JOIN APCSProDWH.dwh.dim_days AS dd ON dd.id = t5.day_id
	ORDER BY t5.day_id
END

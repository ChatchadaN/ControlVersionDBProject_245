
CREATE PROCEDURE [act].[sp_productionipi_wip_lotlist_next] (
	@package_id INT = NULL,
	@process_id INT = NULL,
	@job_id INT = NULL,
	@from_at DATE,
	@to_at DATE
	)
AS
BEGIN
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd
			WHERE date_value = @from_at
			)
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd
			WHERE date_value = @to_at
			)

	SELECT u1.flag AS flag,
		u1.lot_id,
		u1.lot_no AS lot_no,
		u1.order_id AS order_id,
		ao.order_no AS order_no,
		u1.process_state AS process_state,
		il.label_eng AS process_state_label,
		u1.package_id AS package_id,
		pk.name AS package_name,
		u1.device_id AS device_id,
		dd.name AS device_name,
		u1.process_id AS process_id,
		dp.name AS process_name,
		u1.job_id AS job_id,
		dj.name AS job_name,
		u1.qty_in AS qty_in,
		u1.qty_pass AS qty_pass,
		u1.qty_fail AS qty_fail,
		u1.act_machine_id AS act_machine_id,
		dm.name AS act_machine_name,
		u1.cur_machine_id AS cur_machine_id,
		dm2.name AS cur_machine_name,
		u1.process_time AS process_time,
		u1.started_at AS started_at,
		u1.finished_at AS finished_at
	FROM (
		SELECT 0 AS flag,
			s1.lot_id,
			s1.lot_no AS lot_no,
			s1.order_id AS order_id,
			s1.process_state AS process_state,
			s1.package_id AS package_id,
			s1.device_id AS device_id,
			s1.process_id AS process_id,
			s1.job_id AS job_id,
			s1.qty_in AS qty_in,
			s1.qty_pass AS qty_pass,
			s1.qty_fail AS qty_fail,
			s1.act_machine_id AS act_machine_id,
			s1.cur_machine_id as cur_machine_id,
			s1.process_time AS process_time,
			s1.recorded_at AS started_at,
			NULL AS finished_at
		FROM (
			SELECT tl.id AS lot_id,
				tl.lot_no AS lot_no,
				NULL AS started_at,
				NULL AS finished_at,
				tl.order_id AS order_id,
				tl.product_family_id AS product_family_id,
				tl.act_device_name_id AS device_id,
				tl.device_slip_id AS device_slip_id,
				tl.act_package_id AS package_id,
				tl.act_process_id AS process_id,
				tl.act_job_id AS job_id,
				tl.qty_in AS qty_in,
				tl.qty_pass AS qty_pass,
				tl.qty_fail AS qty_fail,
				tl.machine_id as act_machine_id,
				tl.machine_id AS cur_machine_id,
				tl.product_class_id AS production_category,
				tl.wip_state AS wip_state,
				tl.process_state AS process_state,
				NULL AS process_time,
				lpr.recorded_at AS recorded_at,
				rank() OVER (
					PARTITION BY lpr.lot_id ORDER BY lpr.recorded_at
					) AS rank_first
			FROM APCSProDB.trans.lots AS tl WITH (NOLOCK)
			LEFT OUTER JOIN APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK) ON lpr.lot_id = tl.id
				AND lpr.process_id = tl.act_process_id
				AND lpr.job_id = tl.act_job_id
			WHERE tl.wip_state = 20
				AND tl.act_job_id = @job_id
				AND tl.act_package_id = @package_id
			) AS s1
		WHERE s1.rank_first = 1
		
		UNION ALL
		
		SELECT 1 AS flag,
			t1.lot_id AS lot_id,
			t1.lot_no AS lot_no,
			t1.order_id AS order_id,
			NULL AS process_state,
			t1.package_id AS package_id,
			t1.device_id AS device_id,
			t1.process_id AS process_id,
			t1.job_id AS job_id,
			t1.input_pcs AS input_pcs,
			t1.pass_pcs AS pass_pcs,
			(t1.input_pcs - t1.pass_pcs) AS fail_pcs,
			t1.act_machine_id AS act_machine_id,
			t1.cur_machine_id as cur_machine_id,
			t1.process_time AS process_time,
			t1.started_at AS started_at,
			t1.recorded_at AS finished_at
		FROM (
			SELECT fe.id AS id,
				tl.id AS lot_id,
				tl.lot_no AS lot_no,
				tl.order_id AS order_id,
				fe.package_group_id AS package_group_id,
				fe.package_id AS package_id,
				fe.device_id AS device_id,
				tl.act_process_id AS process_id,
				tl.act_job_id AS job_id,
				fe.input_pcs AS input_pcs,
				tl.qty_pass AS pass_pcs,
				fe.machine_id AS act_machine_id,
				tl.machine_id as cur_machine_id,
				fe.process_time AS process_time,
				fe.started_at AS started_at,
				lpr.recorded_at AS recorded_at,
				ROW_NUMBER() OVER (
					PARTITION BY lpr.lot_id ORDER BY lpr.recorded_at DESC
					) AS rank_last
			FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
			INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fe.lot_id
			LEFT OUTER JOIN APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK) ON lpr.lot_id = fe.lot_id
				AND lpr.process_id = fe.process_id
				AND lpr.job_id = fe.job_id
			WHERE @from <= fe.day_id
				AND fe.day_id <= @to
				AND fe.package_id = @package_id
				AND fe.job_id = @job_id
			) AS t1
		WHERE t1.rank_last = 1
		) AS u1
	LEFT OUTER JOIN APCSProDB.robin.assy_orders AS ao WITH (NOLOCK) ON ao.id = u1.order_id
	LEFT OUTER JOIN APCSProDB.method.device_names AS dd WITH (NOLOCK) ON dd.id = u1.device_id
	LEFT OUTER JOIN apcsprodwh.dwh.dim_packages AS pk WITH (NOLOCK) ON pk.id = u1.package_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = u1.process_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = u1.job_id
	LEFT OUTER JOIN APCSProDB.mc.machines AS dm WITH (NOLOCK) ON dm.id = u1.act_machine_id
	LEFT OUTER JOIN APCSProDB.mc.machines AS dm2 WITH (NOLOCK) ON dm2.id = u1.cur_machine_id
	LEFT OUTER JOIN APCSProDB.trans.item_labels AS il WITH (NOLOCK) ON il.name = 'lots.process_state'
		AND il.val = u1.process_state
	ORDER BY flag,
		started_at DESC
END

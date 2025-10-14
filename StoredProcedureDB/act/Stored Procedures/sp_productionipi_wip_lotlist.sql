
CREATE PROCEDURE [act].[sp_productionipi_wip_lotlist] (
	@package_id INT = NULL,
	@process_id INT = NULL,
	@job_id INT = NULL,
	@from_at DATE,
	@to_at DATE
	)
AS
BEGIN
	SELECT t2.id AS id,
		t2.lot_id AS lot_id,
		t2.lot_no AS lot_no,
		t2.started_at AS started_at,
		t2.finished_at AS finished_at,
		t2.order_id AS order_id,
		ao.order_no AS order_no,
		t2.product_family_id AS product_family_id,
		t2.device_id AS device_id,
		dd.name AS device_name,
		t2.device_slip_id AS device_slip_id,
		pk.package_group_id AS package_group_id,
		dpg.name AS package_group_name,
		t2.package_id AS package_id,
		pk.name AS package_name,
		t2.process_id AS process_id,
		ddp.name AS process_name,
		t2.job_id AS job_id,
		ddj.name AS job_name,
		t2.qty_in AS qty_in,
		t2.qty_pass AS qty_pass,
		t2.qty_fail AS qty_fail,
		t2.machine_id AS machine_id,
		dm.name AS machine_name,
		t2.production_category AS production_category,
		t2.wip_state AS wip_state,
		t2.process_state AS process_state,
		t2.process_time AS process_time,
		t2.run_time AS run_time
	FROM (
		SELECT - ROW_NUMBER() OVER (
				ORDER BY tl.id
				) AS id,
			tl.id AS lot_id,
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
			tl.machine_id AS machine_id,
			tl.product_class_id AS production_category,
			tl.wip_state AS wip_state,
			tl.process_state AS process_state,
			NULL AS process_time,
			NULL AS run_time
		FROM APCSProDB.trans.lots AS tl with(nolock)
		WHERE tl.wip_state = 20
			AND tl.act_job_id = @job_id
			AND tl.act_package_id = @package_id
		
		UNION ALL
		
		SELECT t1.id AS id,
			t1.lot_id AS lot_id,
			t1.lot_no AS lot_no,
			t1.started_at AS started_at,
			t1.finished_at AS finished_at,
			t1.order_id AS order_id,
			t1.product_family_id AS product_family_id,
			t1.device_id AS device_id,
			t1.device_slip_id AS device_slip_id,
			t1.package_id AS package_id,
			t1.process_id AS process_id,
			t1.job_id AS job_id,
			t1.input_pcs AS qty_in,
			t1.pass_pcs AS qty_pass,
			t1.input_pcs - t1.pass_pcs AS qty_fail,
			t1.machine_id AS machine_id,
			t1.production_category AS production_category,
			- 1 AS wip_state,
			- 1 AS process_state,
			t1.process_time AS process_time,
			t1.run_time AS run_time
		FROM (
			SELECT fpj.id AS id,
				fpj.machine_id AS machine_id,
				fpj.started_at AS started_at,
				fpj.finished_at AS finished_at,
				fpl.pj_id AS pj_id,
				fpl.lot_id AS lot_id,
				dl.lot_no AS lot_no,
				dl.production_category AS production_category,
				dl.package_id AS package_id,
				dl.device_id AS device_id,
				dl.assy_name_id AS assy_name_id,
				dl.product_family_id AS product_family_id,
				--fact_end
				fe.process_id AS process_id,
				fe.job_id AS job_id,
				fe.input_pcs AS input_pcs,
				fe.pass_pcs AS pass_pcs,
				fe.process_time AS process_time,
				fe.run_time AS run_time,
				--lots
				tl.order_id AS order_id,
				tl.device_slip_id AS device_slip_id
			--FROM APCSProDWH.dwh.view_fact_pjs AS fpj
			--INNER JOIN APCSProDWH.dwh.view_fact_pj_lots AS fpl WITH (NOLOCK) ON fpl.pj_id = fpj.id
			FROM APCSProDWH.dwh.fact_pjs AS fpj with(nolock)
			INNER JOIN APCSProDWH.dwh.fact_pj_lots AS fpl WITH (NOLOCK) ON fpl.pj_id = fpj.id
			INNER JOIN APCSProDWH.dwh.dim_lots AS dl WITH (NOLOCK) ON dl.id = fpl.lot_id
			LEFT OUTER JOIN APCSProDWH.dwh.fact_end AS fe with(nolock) ON fe.pj_id = fpl.pj_id
			INNER JOIN APCSProDB.trans.lots AS tl with(nolock) ON tl.id = fpl.lot_id
			) AS t1
		WHERE (
				(
					(t1.started_at >= @from_at)
					AND (t1.started_at <= @to_at)
					)
				OR (
					(t1.finished_at >= @from_at)
					AND (t1.finished_at <= @to_at)
					)
				)
			AND (
				(
					@package_id IS NOT NULL
					AND t1.package_id = @package_id
					)
				OR (
					@package_id IS NULL
					AND (
						t1.package_id > 0
						OR t1.package_id IS NULL
						)
					)
				)
			AND (
				(
					@process_id IS NOT NULL
					AND t1.process_id = @process_id
					)
				OR (
					@process_id IS NULL
					AND (
						t1.process_id >= 0
						OR t1.process_id IS NULL
						)
					)
				)
			AND (
				(
					@job_id IS NOT NULL
					AND t1.job_id = @job_id
					)
				OR (
					@job_id IS NULL
					AND (
						t1.job_id > 0
						OR t1.job_id IS NULL
						)
					)
				)
		) AS t2
	LEFT OUTER JOIN APCSProDB.robin.assy_orders AS ao WITH (NOLOCK) ON ao.id = t2.order_id
	LEFT OUTER JOIN APCSProDB.method.device_names AS dd WITH (NOLOCK) ON dd.id = t2.device_id
	LEFT OUTER JOIN apcsprodwh.dwh.dim_packages AS pk WITH (NOLOCK) ON pk.id = t2.package_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_package_groups AS dpg WITH (NOLOCK) ON dpg.id = pk.package_group_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS ddp WITH (NOLOCK) ON ddp.id = t2.process_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS ddj WITH (NOLOCK) ON ddj.id = t2.job_id
	LEFT OUTER JOIN APCSProDB.mc.machines AS dm WITH (NOLOCK) ON dm.id = t2.machine_id
	ORDER BY t2.wip_state DESC,
		t2.process_state DESC,
		t2.lot_id,
		t2.id;
END

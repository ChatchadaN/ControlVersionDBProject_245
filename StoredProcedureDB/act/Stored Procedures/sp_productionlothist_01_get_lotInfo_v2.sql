
CREATE PROCEDURE [act].[sp_productionlothist_01_get_lotInfo_v2] @lot_no NVARCHAR(32) = NULL
AS
BEGIN
	SELECT tl.id AS lot_id
		,tl.lot_no AS lot_no
		,ao.order_no AS order_no
		,dp.name AS package_name
		,dd.name AS device_name
		,dpg.name AS product_family_name
		,maf.chip_name AS chip_name
		,maf.wafer_lot_no AS wafer_lot_no
		,maf.wafer_no AS wfno
		,tl.qty_in AS qty_in
		,tl.pass_plan_time AS pass_plan_time
		,tl.pass_plan_time_up AS pass_plan_time_up
		,convert(DECIMAL(9, 1), DATEDIFF(hh, tl.pass_plan_time, GETDATE())) / 24 AS delay1
		,convert(DECIMAL(9, 1), DATEDIFF(hh, tl.pass_plan_time_up, GETDATE())) / 24 AS delay2
		,tl.in_at AS in_at
		,ddy.date_value AS out_plan_date
		,ddym.date_value AS modify_out_plan_date
		,tl.step_no AS step_no
		,f.sum_process_minutes AS sum_process_minutes
		,convert(DECIMAL(9, 1), f.sum_process_minutes) / 24 / 60 * 1.5 AS target_leadtime
		,dn.is_assy_only AS is_assy_only
		,pl.lot_no AS parent_lot_no
		,cl.lot_no AS child_lot_no
	FROM apcsprodb.trans.lots AS tl WITH (NOLOCK)
	INNER JOIN (
		SELECT df.device_slip_id
			,sum(df.process_minutes) AS sum_process_minutes
		FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
		WHERE isnull(df.is_skipped, 0) = 0
		GROUP BY device_slip_id
		) AS f ON f.device_slip_id = tl.device_slip_id
	LEFT OUTER JOIN apcsprodb.robin.material_allocates_front AS maf WITH (NOLOCK) ON maf.lot_id = tl.id
		AND maf.order_id = tl.order_id
	LEFT OUTER JOIN apcsprodb.robin.assy_orders AS ao WITH (NOLOCK) ON ao.id = tl.order_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON tl.act_package_id = dp.id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK) ON tl.act_device_name_id = dd.id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_product_families AS dpg WITH (NOLOCK) ON tl.product_family_id = dpg.id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_days AS ddy WITH (NOLOCK) ON ddy.id = tl.out_plan_date_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_days AS ddym WITH (NOLOCK) ON ddym.id = tl.modify_out_plan_date_id
	LEFT OUTER JOIN apcsprodb.method.device_slips AS ds WITH (NOLOCK) ON ds.device_slip_id = tl.device_slip_id
	LEFT OUTER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
	LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS mp WITH (NOLOCK) ON mp.child_lot_id = tl.id
	LEFT OUTER JOIN APCSProDB.trans.lots AS pl WITH (NOLOCK) ON pl.id = mp.lot_id
	LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS m WITH (NOLOCK) ON m.lot_id = tl.id
	LEFT OUTER JOIN APCSProDB.trans.lots AS cl WITH (NOLOCK) ON cl.id = m.child_lot_id
	WHERE tl.lot_no = @lot_no
END


CREATE PROCEDURE [act].[sp_machinestate_list]
AS
BEGIN
	SELECT g.name AS machine_group_name
		,md.name AS machine_model_name
		,mm.name AS maker_name
		,m.id AS machine_id
		,m.name AS machine_name
		,rtrim(lp.name) AS most_recent_package
		,rtrim(ldv.name) AS most_recent_device
		,st.run_state AS run_state
		,st.updated_at AS updated_at
		,i.label_eng AS run_state_label
		,row_number() OVER (
			PARTITION BY m.id ORDER BY r.recorded_at DESC
			) AS lot_idx
		,CASE 
			WHEN l.step_no % 100 > 0
				THEN 'Special'
			ELSE 'Normal'
			END AS flow
		,l.lot_id AS lot_id
		,l.lot_no AS lot_no
		,l.package_group AS package_group_name
		,l.package AS package_name
		,l.device AS device_name
		,l.process_id AS process_id
		,l.process AS process_name
		,l.job_id AS job_id
		,l.job AS job_name
		,r.record_class AS record_class
		,r.recorded_at AS recorded_at
		,a.alarm_on_at AS alarm_on_at
		,ma.alarm_code AS alarm_code
		,tx.alarm_text AS alarm_text
		--,l.out_plan_date_id
		,dd.date_value AS out_plan_date
		,l.qty_pass AS qty_pass
		,l.qty_fail AS qty_fail
	FROM APCSProDB.mc.groups AS g WITH (NOLOCK)
	INNER JOIN APCSProDB.mc.group_models AS gm WITH (NOLOCK) ON gm.machine_group_id = g.id
	INNER JOIN APCSProDB.mc.models AS md WITH (NOLOCK) ON md.id = gm.machine_model_id
	LEFT OUTER JOIN APCSProDB.mc.makers AS mm WITH (NOLOCK) ON mm.id = md.maker_id
	INNER JOIN APCSProDB.mc.machines AS m WITH (NOLOCK) ON m.machine_model_id = md.id
	INNER JOIN APCSProDB.trans.machine_states AS st WITH (NOLOCK) ON st.machine_id = m.id
	LEFT OUTER JOIN APCSProDB.method.packages AS lp WITH (NOLOCK) ON lp.id = st.last_package_id
	LEFT OUTER JOIN APCSProDB.method.device_names AS ldv WITH (NOLOCK) ON ldv.id = st.last_device_id
	LEFT OUTER JOIN APCSProDB.trans.item_labels AS i WITH (NOLOCK) ON i.name = 'machine_states.run_state'
		AND i.val = st.run_state
	LEFT OUTER JOIN (
		SELECT l.id AS lot_id
			,rtrim(l.lot_no) AS lot_no
			,rtrim(pg.name) AS package_group
			,rtrim(p.name) AS package
			,rtrim(d.name) AS device
			,l.machine_id
			,l.step_no
			,mp.id AS process_id
			,mp.name AS process
			,j.id AS job_id
			,j.name AS job
			,l.out_plan_date_id
			,l.qty_pass
			,l.qty_fail
		FROM APCSProDB.trans.lots AS l WITH (NOLOCK)
		INNER JOIN APCSProDB.method.packages AS p WITH (NOLOCK) ON p.id = l.act_package_id
		LEFT OUTER JOIN APCSProDB.method.package_groups AS pg WITH (NOLOCK) ON pg.id = p.package_group_id
		INNER JOIN APCSProDB.method.device_names AS d WITH (NOLOCK) ON d.id = l.act_device_name_id
		INNER JOIN APCSProDB.method.device_flows AS f WITH (NOLOCK) ON f.device_slip_id = l.device_slip_id
			AND f.step_no = l.step_no
		LEFT JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = f.act_process_id
		INNER JOIN APCSProDB.method.jobs AS j WITH (NOLOCK) ON j.id = f.job_id
		WHERE l.wip_state BETWEEN 20
				AND 70
			AND l.is_special_flow = 0
			AND l.process_state IN (
				1
				,2
				,101
				,102
				)
		
		UNION ALL
		
		SELECT l.id AS lot_id
			,rtrim(l.lot_no) AS lot_no
			,rtrim(pg.name) AS package_group
			,rtrim(p.name) AS package
			,rtrim(d.name) AS device
			,s.machine_id
			,s.step_no
			,mp.id AS process_id
			,mp.name AS process
			,j.id AS job_id
			,j.name AS job
			,l.out_plan_date_id
			,l.qty_pass
			,l.qty_fail
		FROM APCSProDB.trans.lots AS l WITH (NOLOCK)
		INNER JOIN APCSProDB.method.packages AS p WITH (NOLOCK) ON p.id = l.act_package_id
		LEFT OUTER JOIN APCSProDB.method.package_groups AS pg WITH (NOLOCK) ON pg.id = p.package_group_id
		INNER JOIN APCSProDB.method.device_names AS d WITH (NOLOCK) ON d.id = l.act_device_name_id
		INNER JOIN APCSProDB.trans.special_flows AS s WITH (NOLOCK) ON s.id = l.special_flow_id
			AND s.lot_id = l.id
		INNER JOIN APCSProDB.trans.lot_special_flows AS lf WITH (NOLOCK) ON lf.special_flow_id = s.id
			AND lf.step_no = s.step_no
		LEFT JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = lf.act_process_id
		INNER JOIN APCSProDB.method.jobs AS j WITH (NOLOCK) ON j.id = lf.job_id
		WHERE l.wip_state BETWEEN 20
				AND 70
			AND l.is_special_flow = 1
			AND s.process_state IN (
				1
				,2
				,101
				,102
				)
		) AS l ON l.machine_id = m.id
	LEFT OUTER JOIN APCSProDB.trans.lot_process_records AS r WITH (NOLOCK) ON r.lot_id = l.lot_id
		AND r.record_class IN (
			1
			,5
			)
		AND r.machine_id = m.id
		AND r.job_id = l.job_id
		AND NOT EXISTS (
			SELECT *
			FROM APCSProDB.trans.lot_process_records AS r2 WITH (NOLOCK)
			WHERE r2.lot_id = r.lot_id
				AND r2.record_class IN (
					1
					,5
					)
				AND r2.machine_id = r.machine_id
				AND r2.job_id = r.job_id
				AND r2.id > r.id
			)
	LEFT OUTER JOIN APCSProDB.trans.machine_alarm_records AS a WITH (NOLOCK) ON a.machine_id = m.id
		AND a.started_at IS NULL
		AND NOT EXISTS (
			SELECT *
			FROM APCSProDB.trans.machine_alarm_records AS a2 WITH (NOLOCK)
			WHERE a2.machine_id = a.machine_id
				AND a2.started_at IS NULL
				AND a2.id > a.id
			)
	LEFT OUTER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.machine_model_id = md.id
		AND ma.id = a.model_alarm_id
	LEFT OUTER JOIN APCSProDB.mc.alarm_texts AS tx WITH (NOLOCK) ON tx.alarm_text_id = ma.alarm_text_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = l.out_plan_date_id
	ORDER BY m.name
		,g.name
		,r.recorded_at
		,l.lot_id
END

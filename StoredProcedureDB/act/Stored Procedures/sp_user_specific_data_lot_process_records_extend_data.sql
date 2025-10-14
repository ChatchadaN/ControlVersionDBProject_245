
CREATE PROCEDURE [act].[sp_user_specific_data_lot_process_records_extend_data] (@lot_no NVARCHAR(32))
AS
BEGIN
	--DECLARE @lot_no NVARCHAR(32) = '2220A4555V'
	SELECT lpr.id
		,lpr.recorded_at
		,mu.name AS operate_name
		,lpr.record_class
		,il1.label_eng AS record_class_name
		,lpr.lot_id
		,tl.lot_no
		,mp.name AS process_name
		,mj.name AS job_name
		,lpr.step_no
		,lpr.qty_in
		,lpr.qty_pass
		,lpr.qty_fail
		,mm.name AS machine_name
		,il2.label_eng AS wip_state
		,il3.label_eng AS process_state
		,il4.label_eng AS quality_state
		,il5.label_eng AS first_ins_state
		,il6.label_eng AS final_ins_state
		,lpr.is_special_flow
		,ler.extend_data
	FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
	INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = lpr.lot_id
	INNER JOIN apcsprodb.trans.lot_extend_records AS ler WITH (NOLOCK) ON ler.id = lpr.id
	LEFT JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = lpr.process_id
	LEFT JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.id = lpr.job_id
	LEFT JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = lpr.machine_id
	LEFT JOIN APCSProDB.man.users AS mu WITH (NOLOCK) ON mu.id = lpr.operated_by
	LEFT JOIN APCSProDB.trans.item_labels AS il1 WITH (NOLOCK) ON il1.name = 'lot_process_records.record_class'
		AND il1.val = lpr.record_class
	LEFT JOIN APCSProDB.trans.item_labels AS il2 WITH (NOLOCK) ON il2.name = 'lots.wip_state'
		AND il2.val = lpr.wip_state
	LEFT JOIN APCSProDB.trans.item_labels AS il3 WITH (NOLOCK) ON il3.name = 'lots.process_state'
		AND il3.val = lpr.process_state
	LEFT JOIN APCSProDB.trans.item_labels AS il4 WITH (NOLOCK) ON il4.name = 'lots.quality_state'
		AND il4.val = lpr.quality_state
	LEFT JOIN APCSProDB.trans.item_labels AS il5 WITH (NOLOCK) ON il5.name = 'lots.first_ins_state'
		AND il5.val = lpr.first_ins_state
	LEFT JOIN APCSProDB.trans.item_labels AS il6 WITH (NOLOCK) ON il6.name = 'lots.final_ins_state'
		AND il6.val = lpr.final_ins_state
	WHERE tl.lot_no = @lot_no
		--AND lpr.record_class = 2
		--AND lpr.extend_data IS NOT NULL
		--AND DATALENGTH(lpr.extend_data) > 0
	ORDER BY lpr.id
END

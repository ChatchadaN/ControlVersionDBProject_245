
CREATE PROCEDURE [act].[sp_home_lot_ranking_state] (@lot_list NVARCHAR(max) = NULL)
AS
BEGIN
	--DECLARE @lot_list NVARCHAR(max) = '1952A3053V,1951A6094V,1951A1046V,2002A2318V,1948A1413V'
SELECT t1.lot_id AS lot_id,
	t1.lot_no AS lot_no,
	t1.machine_id as machine_id,
	dm.name as machine_name,
	t1.package_id AS package_id,
	dp.name AS package_name,
	t1.act_job_id AS act_job_id,
	dj.name AS job_name,
	t1.qty_pass AS qty_pass,
	t1.qty_fail AS qty_fail,
	convert(DECIMAL(9, 1), t1.qty_pass) / nullif((t1.qty_pass + t1.qty_fail),0) * 100 AS yield,
	w.label_eng AS wip_state_label_eng,
	w.label_jpn AS wip_state_label_jpn,
	p.label_eng AS process_state_label_eng,
	p.label_jpn AS process_state_label_jpn,
	q.label_eng AS quality_state_label_eng,
	q.label_jpn AS quality_state_label_jpn
FROM (
	SELECT t0.lot_id AS lot_id,
		t0.lot_no AS lot_no,
		t0.machine_id as machine_id,
		t0.package_id AS package_id,
		t0.qty_pass AS qty_pass,
		t0.qty_fail AS qty_fail,
		t0.wip_state AS wip_state,
		t0.process_state AS process_state,
		t0.quality_state AS quality_state,
		CASE 
			WHEN t0.is_special_flow = 1
				THEN t0.sp_job_id
			ELSE job_id
			END AS act_job_id
	FROM (
		SELECT tl.id AS lot_id,
			tl.lot_no AS lot_no,
			tl.machine_id as machine_id,
			tl.act_package_id AS package_id,
			tl.act_job_id AS job_id,
			tl.qty_pass AS qty_pass,
			tl.qty_fail AS qty_fail,
			tl.wip_state AS wip_state,
			tl.process_state AS process_state,
			tl.quality_state AS quality_state,
			isnull(tl.is_special_flow, 0) AS is_special_flow,
			tl.special_flow_id AS specail_flow_id,
			ls.job_id AS sp_job_id
		FROM apcsprodb.trans.lots AS tl WITH (NOLOCK)
		INNER JOIN (
			SELECT value
			FROM string_split(@lot_list, ',')
			) AS v ON v.value = tl.lot_no
		LEFT OUTER JOIN apcsprodb.trans.special_flows AS sf WITH (NOLOCK) ON sf.id = tl.special_flow_id
		LEFT OUTER JOIN apcsprodb.trans.lot_special_flows AS ls WITH (NOLOCK) ON ls.special_flow_id = sf.id
		) AS t0
	) AS t1
LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = t1.package_id
LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = t1.act_job_id
LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t1.machine_id
LEFT OUTER JOIN APCSProDB.trans.item_labels AS w WITH (NOLOCK) ON w.name = 'lots.wip_state'
	AND w.val = t1.wip_state
LEFT OUTER JOIN APCSProDB.trans.item_labels AS p WITH (NOLOCK) ON p.name = 'lots.process_state'
	AND p.val = t1.process_state
LEFT OUTER JOIN APCSProDB.trans.item_labels AS q WITH (NOLOCK) ON q.name = 'lots.quality_state'
	AND q.val = t1.quality_state

END

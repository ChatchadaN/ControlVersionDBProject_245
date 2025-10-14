
CREATE PROCEDURE [act].[sp_productionlothist_03_get_record_detail] @lot_id INT,
	@step_no INT
AS
BEGIN
	SELECT t1.id AS id,
		t1.recorded_at AS recorded_at,
		t1.operated_by AS operated_by,
		mu.english_name AS operator_name,
		t1.record_class AS record_class,
		i.label_jpn AS record_label_jpn,
		i.label_eng AS record_label_eng,
		t1.wip_state AS wip_state,
		w.label_jpn AS wip_state_label_jpn,
		w.label_eng AS wip_state_label_eng,
		t1.process_state AS process_state,
		p.label_jpn AS process_state_label_jpn,
		p.label_eng AS process_state_label_eng,
		t1.quality_state AS quality_state,
		q.label_jpn AS quality_state_label_jpn,
		q.label_eng AS quality_state_label_eng,
		t1.is_special_flow AS is_special_flow,
		t1.special_flow_id AS special_flow_id,
		t1.new_step_no AS new_step_no
	FROM (
		SELECT t0.id AS id,
			t0.recorded_at AS recorded_at,
			t0.operated_by AS operated_by,
			t0.record_class AS record_class,
			t0.wip_state AS wip_state,
			t0.process_state AS process_state,
			CASE 
				WHEN t0.new_step_no % 100 > 0
					THEN 4
				ELSE t0.quality_state
				END AS quality_state,
			t0.is_special_flow AS is_special_flow,
			t0.special_flow_id AS special_flow_id,
			t0.new_step_no AS new_step_no
		FROM (
			SELECT CASE 
					WHEN lpr.record_class = 25
						THEN lead(lpr.step_no) OVER (
								ORDER BY lpr.id
								)
					WHEN lpr.record_class = 26
						THEN lag(lpr.step_no) OVER (
								ORDER BY lpr.id
								)
					ELSE lpr.step_no
					END AS new_step_no,
				lpr.id AS id,
				lpr.recorded_at AS recorded_at,
				lpr.operated_by AS operated_by,
				lpr.record_class AS record_class,
				lpr.wip_state AS wip_state,
				lpr.process_state AS process_state,
				lpr.quality_state AS quality_state,
				lpr.is_special_flow AS is_special_flow,
				lpr.special_flow_id AS special_flow_id
			FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
			LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = lpr.job_id
			WHERE lot_id = @lot_id
			) AS t0
		) AS t1
	LEFT OUTER JOIN APCSProDB.trans.item_labels AS i WITH (NOLOCK) ON i.name = 'lot_process_records.record_class'
		AND i.val = t1.record_class
	LEFT OUTER JOIN APCSProDB.trans.item_labels AS w WITH (NOLOCK) ON w.name = 'lots.wip_state'
		AND w.val = t1.wip_state
	LEFT OUTER JOIN APCSProDB.trans.item_labels AS p WITH (NOLOCK) ON p.name = 'lots.process_state'
		AND p.val = t1.process_state
	LEFT OUTER JOIN APCSProDB.trans.item_labels AS q WITH (NOLOCK) ON q.name = 'lots.quality_state'
		AND q.val = t1.quality_state
	LEFT OUTER JOIN APCSProDB.man.users AS mu WITH (NOLOCK) ON mu.id = t1.operated_by
	WHERE t1.new_step_no = @step_no
	ORDER BY t1.id;
END

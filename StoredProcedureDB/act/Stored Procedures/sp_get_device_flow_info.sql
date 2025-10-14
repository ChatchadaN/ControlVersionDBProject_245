
CREATE PROCEDURE [act].[sp_get_device_flow_info] (@device_id INT)
AS
BEGIN
	SELECT t1.id AS id,
		t1.device_slip_id AS device_slip_id,
		t1.step_no AS step_no,
		t1.next_step_no AS next_step_no,
		t1.act_process_id AS act_process_id,
		dp.name AS process_name,
		t1.job_id AS job_id,
		dj.name AS job_name
	FROM (
		SELECT *
		FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
		WHERE is_skipped <> 1
			AND device_slip_id IN (
				SELECT device_slip_id
				FROM APCSProDB.method.device_slips AS ds WITH (NOLOCK)
				WHERE ds.device_id = @device_id
				)
		) AS t1
	INNER JOIN APCSProDWH.dwh.dim_processes AS dp ON dp.id = t1.act_process_id
	INNER JOIN APCSProDWH.dwh.dim_jobs AS dj ON dj.id = t1.job_id
	ORDER BY device_slip_id,
		step_no;
END

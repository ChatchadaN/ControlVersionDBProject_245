
CREATE PROCEDURE [act].[sp_user_specific_data_list_of_processing_mc] (
	@date_from DATETIME
	,@date_to DATETIME
	,@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2021-06-01 00:00:00'
	--DECLARE @date_to DATETIME = '2021-07-01 00:00:00'
	--DECLARE @package_id INT = 242
	--DECLARE @process_id INT = 3
	--DECLARE @job_id INT = 29
	SELECT m.name AS machine_name
		--,j.name AS job
		,substring(d.name, 1, 2) AS device_name
	FROM APCSProDB.method.packages AS p WITH (NOLOCK)
	INNER JOIN APCSProDB.method.device_names AS d WITH (NOLOCK) ON d.package_id = p.id
	INNER JOIN APCSProDB.method.device_versions AS v WITH (NOLOCK) ON v.device_name_id = d.id
	INNER JOIN APCSProDB.method.device_slips AS s WITH (NOLOCK) ON s.device_id = v.device_id
	INNER JOIN APCSProDB.method.device_flows AS f WITH (NOLOCK) ON f.device_slip_id = s.device_slip_id
	INNER JOIN APCSProDB.method.jobs AS j WITH (NOLOCK) ON j.id = f.job_id
		AND j.id = @job_id
	INNER JOIN APCSProDB.trans.lots AS l WITH (NOLOCK) ON l.device_slip_id = s.device_slip_id
	INNER JOIN APCSProDB.trans.lot_process_records AS r WITH (NOLOCK) ON r.lot_id = l.id
		AND r.record_class IN (2)
		AND r.recorded_at BETWEEN @date_from
			AND @date_to
		AND r.job_id = f.job_id
	INNER JOIN APCSProDB.mc.machines AS m WITH (NOLOCK) ON m.id = r.machine_id
	WHERE p.id = @package_id
	GROUP BY
		--j.name
		m.name
		,substring(d.name, 1, 2)
	ORDER BY
		--j.name,
		substring(d.name, 1, 2)
		,m.name
END

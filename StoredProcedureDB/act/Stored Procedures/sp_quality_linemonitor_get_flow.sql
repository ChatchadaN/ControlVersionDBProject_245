
CREATE PROCEDURE [act].[sp_quality_linemonitor_get_flow] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	)
AS
BEGIN
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = 242
	----DECLARE @device_id INT = 5316
	--DECLARE @device_id INT = NULL
	--DECLARE @device_name VARCHAR(20) = NULL
	SELECT t2.line_flow_order AS line_flow_order
		,t2.process_id AS process_id
		,t2.process_name AS process_name
		,t2.job_id AS job_id
		,t2.job_name AS job_name
		,CASE 
			WHEN (a1 + a2) >= 1
				THEN 1
			ELSE 0
			END AS process_group
	FROM (
		SELECT t1.line_flow_order AS line_flow_order
			,t1.process_id AS process_id
			,t1.process_name AS process_name
			,t1.job_id AS job_id
			,t1.job_name AS job_name
			,CASE 
				WHEN t1.process_id = lag(t1.process_id, 1) OVER (
						ORDER BY t1.line_flow_order
						)
					THEN 1
				ELSE 0
				END AS a1
			,CASE 
				WHEN t1.process_id = lead(t1.process_id, 1) OVER (
						ORDER BY t1.line_flow_order
						)
					THEN 1
				ELSE 0
				END AS a2
		FROM (
			SELECT ROW_NUMBER() OVER (
					ORDER BY df.step_no
					) AS line_flow_order
				,df.act_process_id AS process_id
				,dp.name AS process_name
				,df.job_id AS job_id
				,dj.name AS job_name
			FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
			INNER JOIN APCSProDB.method.device_slips AS ds WITH (NOLOCK) ON ds.device_slip_id = df.device_slip_id
				AND isnull(df.is_skipped, 0) = 0
			INNER JOIN APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = ds.device_id
			INNER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = df.act_process_id
			INNER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = df.job_id
			WHERE dd.name = @device_name
				AND (
					ds.version_num = (
						SELECT dv.version_num
						FROM APCSProDB.method.device_versions AS dv WITH (NOLOCK)
						INNER JOIN APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = dv.device_id
						WHERE dd.name = @device_name
						)
					)
			) AS t1
		) AS t2
	ORDER BY line_flow_order
END


CREATE PROCEDURE [act].[sp_qualitytoc_leadtime_motion_target_input] (
	@package_id INT
	,@date_from DATE
	,@date_to DATE
	,@target_flag INT = - 1
	,@target_date_from DATE
	,@target_date_to DATE
	)
AS
BEGIN
	--DECLARE @package_id INT = 242
	--DECLARE @date_from DATE = '2020-03-01'
	--DECLARE @date_to DATE = '2020-03-31'
	--declare @target_flag int = 1
	--DECLARE @target_date_from DATE = '2020-03-10'
	--DECLARE @target_date_to DATE = '2020-03-17'
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_from
			)
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_to
			)
	--
	DECLARE @target_from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @target_date_from
			)
	DECLARE @target_to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @target_date_to
			)

	IF OBJECT_ID(N'tempdb..#Table_lot', N'U') IS NOT NULL
		DROP TABLE #Table_lot;

	SELECT t2.id
		,t2.d_lot_flag AS d_lot_flag
		,t2.target_flag AS target_flag
	INTO #Table_lot
	FROM (
		SELECT t1.id AS id
			,CASE 
				WHEN substring(t1.lot_no, 5, 1) = 'D'
					THEN 1
				ELSE 0
				END AS d_lot_flag
			,CASE 
				WHEN @target_from <= t1.in_date_id
					AND t1.in_date_id <= @target_to
					THEN 1
				ELSE 0
				END AS target_flag
		FROM (
			SELECT CONVERT(DATE, in_at) AS date_value
				,DATEPART(hour, in_at) AS h
				,tl.id AS id
				,tl.lot_no AS lot_no
				,tl.in_date_id AS in_date_id
			FROM APCSProDB.trans.lots AS tl WITH (NOLOCK)
			INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
				AND dn.is_assy_only IN (
					0
					,1
					)
			INNER JOIN apcsprodwh.dwh.dim_devices AS dwh_dev WITH (NOLOCK) ON dwh_dev.id = dn.id
			INNER JOIN apcsprodwh.dwh.dim_assy_device_names AS dwh_assy WITH (NOLOCK) ON dwh_assy.id = dn.id
			INNER JOIN apcsprodwh.dwh.dim_packages AS dwh_pkg WITH (NOLOCK) ON dwh_pkg.id = tl.act_package_id
			WHERE tl.in_at IS NOT NULL
				AND @from <= tl.in_date_id
				AND tl.in_date_id <= @to
				AND tl.act_package_id = @package_id
			) AS t1
		INNER JOIN apcsprodwh.dwh.dim_days AS dwh_days WITH (NOLOCK) ON dwh_days.date_value = t1.date_value
		INNER JOIN apcsprodwh.dwh.dim_hours AS dwh_hours WITH (NOLOCK) ON dwh_hours.h = T1.h
		) AS t2
	WHERE (
			@target_flag >= 0
			AND target_flag = @target_flag
			)
		OR (@target_flag < 0);

	SELECT t2.day_id AS day_id
		,count(t2.day_id) OVER (PARTITION BY t2.day_id) AS day_count
		,t2.date_value AS date_value
		,t2.package_id AS package_id
		,t2.process_id AS process_id
		,t2.process_no AS process_no
		,t2.process_name AS process_name
		,t2.job_id AS job_id
		,t2.job_no AS job_no
		,t2.job_name AS job_name
		,DENSE_RANK() OVER (
			PARTITION BY t2.day_id ORDER BY t2.process_no
				,t2.job_no
			) AS x_axis
		,row_number() OVER (
			PARTITION BY t2.day_id
			,t2.job_no ORDER BY t2.process_no
				,t2.job_no
			) AS job_rank
		,t2.d_lot_flag AS d_lot_flag
		,t2.lot_id AS lot_id
		,t2.lot_no AS lot_no
		,row_number() OVER (
			PARTITION BY t2.day_id
			,t2.lot_id
			,t2.process_id
			,t2.job_id ORDER BY t2.day_id
			) AS lot_rank
		,t2.wait_time AS wait_time
		,t2.process_time AS process_time
		,t2.lead_time AS lead_time
		,convert(INT, t2.target_lead_time) AS target_lead_time
		,convert(INT, avg(t2.target_lead_time) OVER (
				PARTITION BY t2.day_id
				,t2.process_id
				,t2.job_id
				)) AS avg_target_lead_time
		,t2.act_lead_time AS act_lead_time
		,PERCENTILE_DISC(0.5) within
	GROUP (
			ORDER BY t2.act_lead_time
			) OVER (
			PARTITION BY t2.day_id
			,t2.process_id
			,t2.job_id
			) AS med_act_lead_time
	FROM (
		SELECT p2.day_id AS day_id
			,p2.date_value AS date_value
			,p2.package_id AS package_id
			,p2.process_id AS process_id
			,p2.process_no AS process_no
			,p2.process_name AS process_name
			,p2.job_id AS job_id
			,p2.job_no AS job_no
			,p2.job_name AS job_name
			,t1.d_lot_flag AS d_lot_flag
			,t1.lot_id AS lot_id
			,t1.lot_no AS lot_no
			,t1.wait_time AS wait_time
			,t1.process_time AS process_time
			,t1.process_time * 1.5 AS target_lead_time
			,t1.lead_time AS lead_time
			,(t1.process_time + t1.wait_time) AS act_lead_time
		FROM (
			SELECT d.day_id AS day_id
				,d.date_value AS date_value
				,p1.package_id AS package_id
				,p1.process_id AS process_id
				,p1.process_no AS process_no
				,p1.process_name AS process_name
				,p1.job_id AS job_id
				,p1.job_no AS job_no
				,p1.job_name AS job_name
			FROM (
				SELECT dd.id AS day_id
					,dd.date_value AS date_value
				FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
				WHERE @from <= dd.id
					AND dd.id <= @to
				) AS d
			CROSS JOIN (
				SELECT p.package_id AS package_id
					,p.job_id AS job_id
					,p.job_no AS job_no
					,p.job_name AS job_name
					,p.is_skipped AS is_skipped
					,p.process_id AS process_id
					,p.process_no AS process_no
					,p.process_name AS process_name
				FROM (
					SELECT pj.package_id AS package_id
						,pj.job_id AS job_id
						,pj.job_no AS job_no
						,pj.job_name AS job_name
						,isnull(pj.is_skipped, 0) AS is_skipped
						,pj.process_id AS process_id
						,pj.process_no AS process_no
						,pj.process_name AS process_name
					FROM APCSProDWH.dwh.dim_package_jobs AS pj WITH (NOLOCK)
					WHERE package_id = @package_id
					) AS p
				WHERE is_skipped = 0
				) AS p1
			) AS p2
		LEFT OUTER JOIN (
			SELECT fe.day_id AS day_id
				,fe.hour_code AS hour_code
				,fe.package_id AS package_id
				,fe.process_id AS process_id
				,fe.job_id AS job_id
				,fe.device_id AS device_id
				,tt.d_lot_flag AS d_lot_flag
				,fe.lot_id AS lot_id
				,fe.pass_pcs AS pass_pcs
				,fe.code AS code
				,fe.std_time AS std_time
				,fe.wait_time AS wait_time
				,fe.process_time AS process_time
				,fe.run_time AS run_time
				,tl.lot_no AS lot_no
				,tl.device_slip_id AS device_slip_id
				,df.process_minutes AS process_minutes
				,df.lead_time AS lead_time
				,df.is_skipped AS is_skipped
				,dn.name AS device_name
				,dn.is_assy_only AS is_assy_only
			FROM apcsprodwh.dwh.fact_end AS fe WITH (NOLOCK)
			INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fe.lot_id
			LEFT OUTER JOIN APCSProDB.method.device_slips AS ds WITH (NOLOCK) ON ds.device_slip_id = tl.device_slip_id
			LEFT OUTER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = fe.device_id
			LEFT OUTER JOIN APCSProDB.method.device_flows AS df WITH (NOLOCK) ON df.device_slip_id = tl.device_slip_id
				AND df.job_id = fe.job_id
			LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fe.device_id
			INNER JOIN #Table_lot AS tt ON tt.id = fe.lot_id
			WHERE fe.package_id = @package_id
				AND @from <= fe.day_id
				AND fe.day_id <= @to
			) AS t1 ON t1.day_id = p2.day_id
			AND t1.process_id = p2.process_id
			AND t1.job_id = p2.job_id
		) AS t2
	ORDER BY date_value
		,process_no
		,job_no
		,lot_id
END

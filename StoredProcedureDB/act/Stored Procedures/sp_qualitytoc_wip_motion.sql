
CREATE PROCEDURE [act].[sp_qualitytoc_wip_motion] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@date_from DATE
	,@date_to DATE
	)
AS
BEGIN
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

	SELECT t1.day_id AS day_id
		,t1.date_value AS date_value
		,t1.package_id AS package_id
		,t1.process_id AS process_id
		,t1.process_no AS process_no
		,t1.process_name AS process_name
		,t1.job_id AS job_id
		,t1.job_no AS job_no
		,t1.job_name AS job_name
		,isnull(t2.cur_lot_count, 0) AS wip_lot_count
		,convert(DECIMAL(16, 1), isnull(t2.cur_pcs, 0)) / 1000 AS wip_kpcs
		,isnull(t3.sum_lot_count, 0) AS input_lot_count
		,convert(DECIMAL(16, 1), isnull(t3.sum_pass_pcs, 0)) / 1000 AS input_kpcs
		,isnull(t4.sum_lot_count, 0) AS output_lot_count
		,convert(DECIMAL(16, 1), isnull(t4.sum_pass_pcs, 0)) / 1000 AS output_kpcs
		,isnull(t4.machine_numbers, 0) AS machine_numbers
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
		) AS t1
	LEFT OUTER JOIN (
		SELECT s3.day_id AS day_id
			,s3.process_id AS process_id
			,s3.job_id AS job_id
			,sum(s3.lot_count) AS cur_lot_count
			,sum(s3.pcs) AS cur_pcs
		FROM (
			SELECT s2.id AS id
				,s2.day_id AS day_id
				,s2.hour_code AS hour_code
				,s2.package_id AS package_id
				,s2.process_id AS process_id
				,s2.job_id AS job_id
				,s2.lot_count AS lot_count
				,s2.pcs AS pcs
				,s2.latest_hour_code AS latest_hour_code
			FROM (
				SELECT s1.id AS id
					,s1.day_id AS day_id
					,s1.hour_code AS hour_code
					,s1.package_id AS package_id
					,s1.process_id AS process_id
					,s1.job_id AS job_id
					,s1.lot_count AS lot_count
					,s1.pcs AS pcs
					,s1.latest_hour_code AS latest_hour_code
				FROM (
					SELECT fw.id AS id
						,fw.day_id AS day_id
						,fw.hour_code AS hour_code
						,fw.package_id AS package_id
						,fw.process_id AS process_id
						,fw.job_id AS job_id
						,fw.lot_count AS lot_count
						,fw.pcs AS pcs
						,dense_rank() OVER (
							PARTITION BY fw.day_id ORDER BY fw.hour_code DESC
							) AS latest_hour_code
					FROM APCSProDWH.dwh.fact_wip AS fw WITH (NOLOCK)
					WHERE @from <= fw.day_id
						AND fw.day_id <= @to
						AND package_id = @package_id
					) AS s1
				WHERE s1.latest_hour_code = 1
				) AS s2
			) AS s3
		GROUP BY s3.day_id
			,s3.process_id
			,s3.job_id
		) AS t2 ON t2.day_id = t1.day_id
		AND t2.process_id = t1.process_id
		AND t2.job_id = t1.job_id
	--input
	LEFT OUTER JOIN (
		SELECT fe.day_id AS day_id
			,fe.next_process_id AS next_process_id
			,fe.next_job_id AS next_job_id
			,sum(fe.pass_pcs) AS sum_pass_pcs
			,count(fe.lot_id) AS sum_lot_count
		FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
		WHERE @from <= fe.day_id
			AND fe.day_id <= @to
			AND package_id = @package_id
		GROUP BY fe.day_id
			,fe.next_process_id
			,fe.next_job_id
		) AS t3 ON t3.day_id = t1.day_id
		AND t3.next_process_id = t1.process_id
		AND t3.next_job_id = t1.job_id
	--output
	LEFT OUTER JOIN (
		SELECT fe2.day_id AS day_id
			,fe2.process_id AS process_id
			,fe2.job_id AS job_id
			,max(fe2.rank_machine_id) AS machine_numbers
			,sum(fe2.pass_pcs) AS sum_pass_pcs
			,count(fe2.lot_id) AS sum_lot_count
		FROM (
			SELECT fe.day_id AS day_id
				,fe.process_id AS process_id
				,fe.job_id AS job_id
				,fe.machine_id AS machine_id
				,dense_rank() OVER (
					PARTITION BY fe.day_id
					,fe.process_id
					,fe.job_id ORDER BY fe.machine_id
					) AS rank_machine_id
				,fe.pass_pcs AS pass_pcs
				,fe.lot_id AS lot_id
			FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
			WHERE @from <= fe.day_id
				AND fe.day_id <= @to
				AND package_id = @package_id
			) AS fe2
		GROUP BY fe2.day_id
			,fe2.process_id
			,fe2.job_id
		) AS t4 ON t4.day_id = t1.day_id
		AND t4.process_id = t1.process_id
		AND t4.job_id = t1.job_id
	ORDER BY t1.day_id
		,t1.process_no
		,t1.job_no
END

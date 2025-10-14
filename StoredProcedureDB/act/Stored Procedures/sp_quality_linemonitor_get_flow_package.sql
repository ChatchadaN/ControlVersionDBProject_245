
CREATE PROCEDURE [act].[sp_quality_linemonitor_get_flow_package] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@range INT = 4
	)
AS
BEGIN
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = 242
	IF @process_id IS NULL
	BEGIN
		SELECT row_number() OVER (
				ORDER BY dp.process_no
				) AS line_flow_order
			,dp.package_id AS package_id
			,dp.process_id AS process_id
			,dp.process_no AS process_no
			,dp.process_name AS process_name
			,null as job_id
			,null as job_name
		FROM APCSProDWH.dwh.dim_package_processes AS dp WITH (NOLOCK)
		WHERE dp.package_id = @package_id
		ORDER BY process_no
	END
	ELSE
	BEGIN
		--process指定のクエリ用
		IF OBJECT_ID(N'tempdb..#p_table', N'U') IS NOT NULL
			DROP TABLE #p_table;

		SELECT *
		INTO #p_table
		FROM (
			SELECT pp.package_id AS package_id
				,pp.process_id AS process_id
				,pp.process_no AS process_no
				,pp.process_name AS process_name
				,pj.job_id AS job_id
				,pj.job_no AS job_no
				,pj.job_name AS job_name
				,pj.is_skipped AS is_skipped
				,dense_rank() OVER (
					ORDER BY pp.process_no
					) AS p_rank
			FROM APCSProDWH.dwh.dim_package_processes AS pp WITH (NOLOCK)
			LEFT OUTER JOIN APCSProDWH.dwh.dim_package_jobs AS pj WITH (NOLOCK) ON pj.package_id = pp.package_id
				AND pj.process_id = pp.process_id
				AND pj.process_no = pp.process_no
			WHERE pp.package_id = @package_id
				AND isnull(pj.is_skipped, 0) = 0
			) AS p

		DECLARE @target_process_rank INT = (
				SELECT min(p_rank)
				FROM #p_table
				WHERE process_id = @process_id
				)

		SELECT row_number() OVER (
				ORDER BY pt3.process_no
					,pt3.job_no
				) AS line_flow_order
			,pt3.package_id AS package_id
			,pt3.process_id AS process_id
			,pt3.process_no AS process_no
			,pt3.process_name AS process_name
			,pt3.job_id AS job_id
			,pt3.job_no AS job_no
			,isnull(pt3.job_name, pt3.process_name) AS job_name
			,pt3.p_rank_group AS p_rank_group
			,pt3.pre_order AS pre_order
			,pt3.pst_order AS pst_order
		FROM (
			SELECT *
				,ROW_NUMBER() OVER (
					PARTITION BY pt2.p_rank_group ORDER BY pt2.process_no DESC
						,pt2.job_no DESC
					) AS pre_order
				,ROW_NUMBER() OVER (
					PARTITION BY pt2.p_rank_group ORDER BY pt2.process_no
						,pt2.job_no
					) AS pst_order
			FROM (
				SELECT pt.*
					,CASE 
						WHEN @target_process_rank > pt.p_rank
							THEN - 1
						WHEN @target_process_rank = pt.p_rank
							THEN 0
						WHEN @target_process_rank < pt.p_rank
							THEN 1
						END AS p_rank_group
				FROM #p_table AS pt
				) AS pt2
			) AS pt3
		WHERE (pt3.p_rank_group = 0)
			OR (
				pt3.p_rank_group = - 1
				AND pt3.pre_order < @range
				)
			OR (
				pt3.p_rank_group = 1
				AND pt3.pst_order < @range
				)
		ORDER BY process_no
			,job_no
	END
END

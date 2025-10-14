
CREATE PROCEDURE [act].[sp_analysis_queue] @date_from DATE = ''
	,@date_to DATE = ''
	,@package_id INT = NULL
AS
BEGIN
	--https://stackoverflow.com/questions/37863125/sql-server-temp-table-not-available-in-pyodbc-code
	SET NOCOUNT ON

	IF OBJECT_ID(N'tempdb..#pkg_list', N'U') IS NOT NULL
		DROP TABLE #pkg_list;

	IF OBJECT_ID(N'tempdb..#process_day_data', N'U') IS NOT NULL
		DROP TABLE #process_day_data;

	IF OBJECT_ID(N'tempdb..#mms_data', N'U') IS NOT NULL
		DROP TABLE #mms_data;

	--MSOP8:103
	--SSOP-B20W:242
	--TO252-3:265
	--DECLARE @package_id INT = 103
	--DECLARE @date_from DATE = '2020-10-01'
	--DECLARE @date_to DATE = '2020-10-27'
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = @date_from
			)
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = @date_to
			)
	DECLARE @span INT = @to - @from + 1

	SELECT TOP 30 t3.package_id
		,t3.package_name
		,percent_Kpcs
	INTO #pkg_list
	FROM (
		SELECT t2.*
			,CONVERT(DECIMAL(4, 1), sum(convert(FLOAT, sum_lots) * 100 / all_lot_count) OVER (
					ORDER BY t2.sum_lots DESC rows unbounded preceding
					)) AS percent_lots
			,CONVERT(DECIMAL(4, 1), sum(convert(FLOAT, sum_Kpcs) * 100 / all_sum_Kpcs) OVER (
					ORDER BY t2.sum_Kpcs DESC rows unbounded preceding
					)) AS percent_Kpcs
			,isnull(t.in_alarm_cnt, 0) AS in_alarm_cnt
		FROM (
			SELECT t1.package_id AS package_id
				,t1.package_name AS package_name
				,isnull(t1.sum_lot_count, 0) AS sum_lots
				,isnull(round(t1.sum_pcs, - 3) / 1000, 0) AS sum_Kpcs
				,sum(isnull(t1.sum_lot_count, 0)) OVER (PARTITION BY const) AS all_lot_count
				,sum(isnull(round(t1.sum_pcs, - 3) / 1000, 0)) OVER (PARTITION BY const) AS all_sum_Kpcs
			FROM (
				SELECT lc.*
				FROM (
					SELECT wi.package_id
						,pc.name AS package_name
						,SUM(wi.lot_count) AS sum_lot_count
						,SUM(wi.pcs) AS sum_pcs
						,1 AS const
					FROM APCSProDWH.dwh.dim_packages AS pc WITH (NOLOCK)
					INNER JOIN APCSProDWH.dwh.fact_wip AS wi WITH (NOLOCK) ON wi.package_id = pc.id
					WHERE (
							day_id = (
								SELECT finished_day_id
								FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
								WHERE to_fact_table = 'dwh.fact_wip'
								)
							)
						AND wi.hour_code = (
							SELECT finished_hour_code
							FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
							WHERE to_fact_table = 'dwh.fact_wip'
							)
					GROUP BY wi.package_id
						,pc.name
					) AS lc
				) AS t1
			) AS t2
		LEFT OUTER JOIN (
			SELECT lim.id AS package_id
				,lim.is_input_stopped AS in_alarm_cnt
			FROM (
				SELECT mp.id AS id
					,mp.is_input_stopped AS is_input_stopped
				FROM APCSProDB.method.packages AS mp WITH (NOLOCK)
				INNER JOIN APCSProDWH.dwh.dim_packages AS p WITH (NOLOCK) ON p.id = mp.id
				) AS lim
			) AS t ON t.package_id = t2.package_id
		) AS t3
	WHERE package_id = @package_id
	ORDER BY percent_Kpcs

	SELECT y1.*
	INTO #process_day_data
	FROM (
		SELECT x1.day_id
			,x1.date_value
			,x1.package_id
			,x1.process_id
			,x1.process_no
			,x1.job_id
			,x1.job_no
			--buffer
			,isnull(x2.buf_lot_count, 0) AS buf_lot_count
			,isnull(x2.buf_pass_pcs, 0) AS buf_pass_pcs
			--output
			,isnull(x3.out_lot_count, 0) AS out_lot_count
			,isnull(x3.out_pass_pcs, 0) AS out_pass_pcs
			,isnull(x3.out_process_time, 0) AS out_process_time
			,isnull(x3.out_wait_time, 0) AS out_wait_time
			--machine
			,isnull(x4.machine_count, 0) AS machine_count
		FROM (
			SELECT d.day_id AS day_id
				,d.date_value AS date_value
				,p.package_id
				,p.process_id
				,p.process_name
				,p.process_no
				,p.job_id
				,p.job_name
				,p.job_no
			FROM (
				SELECT dd.id AS day_id
					,dd.date_value AS date_value
				FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
				WHERE id BETWEEN @from
						AND @to
				) AS d
			CROSS JOIN (
				SELECT pj.*
				FROM APCSProDWH.dwh.dim_package_jobs AS pj WITH (NOLOCK)
				INNER JOIN #pkg_list AS pl ON pl.package_id = pj.package_id
				WHERE isnull(pj.is_skipped, 0) = 0
					AND process_id > 1
				) AS p
			) AS x1
		LEFT OUTER JOIN (
			-------------------------------input(buffer)
			SELECT t1.day_id
				,t1.package_id
				,next_process_id AS process_id
				,next_job_id AS job_id
				,count(t1.lot_id) AS buf_lot_count
				,sum(t1.pass_pcs) AS buf_pass_pcs
			FROM (
				SELECT fe.day_id
					,fe.package_id
					,fe.device_id
					,fe.assy_name_id
					,fe.lot_id
					,fe.job_id
					,fe.next_job_id
					,fe.next_process_id
					,fe.process_id
					,fe.input_pcs
					,fe.pass_pcs
					,fe.machine_id
					,fe.wait_time
					,fe.process_time
					,fe.std_time
				FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
				INNER JOIN #pkg_list AS pl ON pl.package_id = fe.package_id
				WHERE day_id BETWEEN @from
						AND @to
				) AS t1
			GROUP BY t1.day_id
				,t1.package_id
				,t1.next_process_id
				,t1.next_job_id
			) AS x2 ON x2.day_id = x1.day_id
			AND x2.package_id = x1.package_id
			AND x2.process_id = x1.process_id
			AND x2.job_id = x1.job_id
		LEFT OUTER JOIN (
			------------------output
			SELECT t1.day_id
				,t1.package_id
				,t1.process_id
				,t1.job_id
				,count(t1.lot_id) AS out_lot_count
				,sum(t1.pass_pcs) AS out_pass_pcs
				,sum(t1.wait_time) AS out_wait_time
				,sum(t1.process_time) AS out_process_time
			FROM (
				SELECT fe.day_id
					,fe.package_id
					,fe.device_id
					,fe.assy_name_id
					,fe.lot_id
					,fe.job_id
					,fe.process_id
					,fe.input_pcs
					,fe.pass_pcs
					,fe.machine_id
					,fe.wait_time
					,fe.process_time
					,fe.std_time
				FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
				INNER JOIN #pkg_list AS pl ON pl.package_id = fe.package_id
				WHERE day_id BETWEEN @from
						AND @to
				) AS t1
			GROUP BY t1.day_id
				,t1.package_id
				,t1.process_id
				,t1.job_id
			) AS x3 ON x3.day_id = x1.day_id
			AND x3.package_id = x1.package_id
			AND x3.process_id = x1.process_id
			AND x3.job_id = x1.job_id
		LEFT OUTER JOIN (
			SELECT package_id
				,process_id
				,job_id
				,max(machine_count) AS machine_count
			FROM (
				SELECT fe.day_id
					,fe.package_id
					,fe.device_id
					,fe.assy_name_id
					,fe.lot_id
					,fe.job_id
					,fe.process_id
					,fe.machine_id
					,DENSE_RANK() OVER (
						PARTITION BY process_id
						,job_id ORDER BY machine_id
						) AS machine_count
				FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
				INNER JOIN #pkg_list AS pl ON pl.package_id = fe.package_id
				WHERE day_id BETWEEN @from
						AND @to
				) AS t1
			GROUP BY t1.package_id
				,t1.process_id
				,t1.job_id
			) AS x4 ON x4.package_id = x1.package_id
			AND x4.process_id = x1.process_id
			AND x4.job_id = x1.job_id
		) AS y1
	ORDER BY day_id
		,package_id
		,process_id
		,job_id

	--
	SELECT *
		,arrival_lot_count / service_lot_count / machine_count AS lot_rho
		,arrival_pcs / service_pcs / machine_count AS pcs_rho
	INTO #mms_data
	FROM (
		SELECT pd2.package_id
			,rtrim(dp.name) AS package_name
			,pd2.process_id
			,pd2.process_no
			,dr.name AS process_name
			,pd2.job_id
			,pd2.job_no
			,dj.name AS job_name
			,pd2.buf_lot_count
			,pd2.buf_pass_pcs
			,pd2.out_lot_count
			,pd2.out_pass_pcs
			,pd2.out_process_time
			,pd2.out_wait_time
			,pd2.machine_count
			--lot
			,pd2.buf_lot_count / convert(DECIMAL(3, 1), @span) AS arrival_lot_count
			,pd2.out_lot_count / nullif((convert(DECIMAL(15, 3), out_process_time) / 1440), 0) AS service_lot_count
			--pcs
			,pd2.buf_pass_pcs / convert(DECIMAL(3, 1), @span) AS arrival_pcs
			,pd2.out_pass_pcs / nullif((convert(DECIMAL(15, 3), out_process_time) / 1440), 0) AS service_pcs
		FROM (
			SELECT pd.package_id
				,pd.process_id
				,pd.process_no
				,pd.job_id
				,pd.job_no
				,sum(buf_lot_count) AS buf_lot_count
				,sum(buf_pass_pcs) AS buf_pass_pcs
				,sum(out_lot_count) AS out_lot_count
				,sum(out_pass_pcs) AS out_pass_pcs
				,sum(out_process_time) AS out_process_time
				,sum(out_wait_time) AS out_wait_time
				,max(machine_count) AS machine_count
			FROM #process_day_data AS pd
			GROUP BY pd.package_id
				,pd.process_id
				,pd.process_no
				,pd.job_id
				,pd.job_no
			) AS pd2
		INNER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = pd2.package_id
		INNER JOIN APCSProDWH.dwh.dim_processes AS dr WITH (NOLOCK) ON dr.id = pd2.process_id
		INNER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = pd2.job_id
		) AS pd3
	WHERE arrival_lot_count > 0
		AND service_lot_count > 0
		AND machine_count > 0
	ORDER BY package_id
		,process_no
		,job_no

	----------------------------------------------------------------------------------------
	SELECT *
	FROM #mms_data
	ORDER BY package_id
		,process_no
		,job_no

	------------------------------------------------------------------------------------
	SELECT ROW_NUMBER() OVER (
			ORDER BY s4.lot_count DESC
			) AS list_id
		,s4.pj_index_list AS pj_index_list_str
		,s4.lot_count as lot_count
	FROM (
		SELECT s3.pj_index_list AS pj_index_list
			,sum(lot_count) AS lot_count
		FROM (
			SELECT s2.device_slip_id
				,STRING_AGG(s2.step_num_index, ',') within
			GROUP (
					ORDER BY s2.step_no
					) AS pj_index_list
				,max(s2.lot_count) AS lot_count
			FROM (
				SELECT s.*
					,s1.job_name
					,s1.step_num_order
					,s1.step_num_order - 1 AS step_num_index
				FROM (
					SELECT device_slip_id
						,c.step_no
						,c.process_id
						,c.job_id
						,c.lot_count
					FROM (
						SELECT f.device_slip_id
							,f.step_no
							,f.process_id
							,f.job_id
							,s.lot_count
						FROM (
							SELECT df.device_slip_id
								,df.step_no
								,df.act_process_id AS process_id
								,df.job_id
							FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
							WHERE isnull(df.is_skipped, 0) = 0
								AND act_process_id > 1
							) AS f
						INNER JOIN (
							SELECT device_slip_id
								,count(t3.lot_id) AS lot_count
							FROM (
								SELECT *
								FROM (
									SELECT t1.device_slip_id
										,t1.lot_id
										,row_number() OVER (
											PARTITION BY t1.device_slip_id
											,t1.lot_id ORDER BY t1.device_slip_id
											) AS rank_slip
									FROM (
										SELECT fe.lot_id
											,tl.lot_no
											,tl.device_slip_id
										FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
										INNER JOIN #pkg_list AS pl ON pl.package_id = fe.package_id
										INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fe.lot_id
										WHERE day_id BETWEEN @from
												AND @to
										) AS t1
									) AS t2
								WHERE rank_slip = 1
								) AS t3
							GROUP BY device_slip_id
							) AS s ON s.device_slip_id = f.device_slip_id
						) AS c
					) AS s
				LEFT OUTER JOIN (
					SELECT pj.process_id
						,pj.job_id
						,pj.job_name
						,ROW_NUMBER() OVER (
							ORDER BY pj.process_no
								,pj.job_no
							) AS step_num_order
					FROM APCSProDWH.dwh.dim_package_jobs AS pj WITH (NOLOCK)
					INNER JOIN #pkg_list AS pl ON pl.package_id = pj.package_id
					INNER JOIN #mms_data AS mms ON mms.process_id = pj.process_id
						AND mms.job_id = pj.job_id
					WHERE isnull(pj.is_skipped, 0) = 0
					) AS s1 ON s1.process_id = s.process_id
					AND s1.job_id = s.job_id
				) AS s2
			GROUP BY s2.device_slip_id
			) AS s3
		GROUP BY s3.pj_index_list
		) AS s4
	ORDER BY s4.lot_count DESC
END

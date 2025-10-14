
CREATE PROCEDURE [act].[sp_machinemonitor_summary_status_v3] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@machine_id_list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--DECLARE @machine_id_list NVARCHAR(max) = '308,242'
	--DECLARE @date_from DATETIME = '2020-06-04 00:00:00'
	--DECLARE @date_to DATETIME = '2020-06-05 00:00:00'
	--DECLARE @time_offset INT = 0
	------
	DECLARE @local_date_from DATETIME = DATEADD(HOUR, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = CASE 
			WHEN getdate() < DATEADD(HOUR, @time_offset, @date_to)
				THEN format(dateadd(day, 1, GETDATE()), 'yyyy-MM-dd 00:00:00')
			ELSE DATEADD(HOUR, @time_offset, @date_to)
			END
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list
	DECLARE @from_to DECIMAL(9, 1) = isnull(convert(DECIMAL(9, 1), datediff(SECOND, @local_date_from, @local_date_to)) / 60 / 60, NULL);
	DECLARE @fr_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
			WHERE date_value = convert(DATE, @date_from)
			)
	--
	DECLARE @new_date_from DATETIME = (
			SELECT min(pj.started_at) AS oldest_started_at
			FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
			INNER JOIN (
				SELECT CONVERT(INT, value) AS value
				FROM STRING_SPLIT(@local_machine_id_list, ',')
				) AS v ON v.value = pj.machine_id
			WHERE (
					(
						NOT (pj.finished_at < @local_date_from)
						AND NOT (@local_date_to < pj.started_at)
						)
					OR (
						pj.started_at BETWEEN @local_date_from
							AND @local_date_to
						AND pj.finished_at IS NULL
						)
					)
			)
	DECLARE @new_date_to DATETIME = (
			SELECT CASE 
					WHEN t1.finished_at IS NULL
						THEN @local_date_to
					ELSE t1.finished_at
					END AS new_date_to
			FROM (
				SELECT *
					,ROW_NUMBER() OVER (
						ORDER BY pj.started_at DESC
						) AS rn_start
				FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
				INNER JOIN (
					SELECT CONVERT(INT, value) AS value
					FROM STRING_SPLIT(@local_machine_id_list, ',')
					) AS v ON v.value = pj.machine_id
				WHERE (
						(
							NOT (pj.finished_at < @local_date_from)
							AND NOT (@local_date_to < pj.started_at)
							)
						OR (
							pj.started_at BETWEEN @local_date_from
								AND @local_date_to
							AND pj.finished_at IS NULL
							)
						)
				) AS t1
			WHERE t1.rn_start = 1
			)

	IF OBJECT_ID(N'tempdb..#lotend_table', N'U') IS NOT NULL
		DROP TABLE #lotend_table;

	SELECT sf.lot_id
		,sf.process_job_id
		,sf.machine_id
		,sf.started_at
		,CASE 
			WHEN oe.recorded_at IS NOT NULL
				THEN oe.recorded_at
			ELSE sf.finished_at
			END AS online_end_at
		,sf.finished_at
		,oe.online_state
		,oe.record_flag
		,oe.run_state
		,1 AS process_flag
		,1 AS lotendflag
	INTO #lotend_table
	FROM (
		SELECT pl.pj_id AS process_job_id
			,pj.machine_id AS machine_id
			,pj.started_at AS started_at
			,pj.finished_at AS finished_at
			,pl.lot_id AS lot_id
		FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
		INNER JOIN APCSProDWH.dwh.view_fact_pj_lots AS pl WITH (NOLOCK) ON pl.pj_id = pj.id
		INNER JOIN (
			SELECT CONVERT(INT, value) AS value
			FROM STRING_SPLIT(@local_machine_id_list, ',')
			) AS v ON v.value = pj.machine_id
		WHERE (
				(
					NOT (pj.finished_at < @local_date_from)
					AND NOT (@local_date_to < pj.started_at)
					)
				OR (
					pj.started_at BETWEEN @local_date_from
						AND @local_date_to
					AND pj.finished_at IS NULL
					)
				)
		) AS sf
	LEFT JOIN (
		SELECT *
		FROM (
			SELECT lpr.recorded_at
				,lpr.machine_id
				,NULL AS online_state
				,0 AS record_flag
				,record_class AS run_state
				,lot_id
				,process_job_id
				,RANK() OVER (
					PARTITION BY lot_id
					,process_job_id ORDER BY recorded_at DESC
					) AS last_rec
			FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
			INNER JOIN (
				SELECT CONVERT(INT, value) AS value
				FROM STRING_SPLIT(@local_machine_id_list, ',')
				) AS v ON v.value = lpr.machine_id
			WHERE lpr.record_class = 12
				AND recorded_at >= @new_date_from
				AND recorded_at <= @new_date_to
			) AS lpr2
		WHERE last_rec = 1
		) AS oe ON oe.lot_id = sf.lot_id
		AND oe.process_job_id = sf.process_job_id

	------------------Main Query
	SELECT t10.machine_number
		,t10.machine_id
		,t10.machine_name
		,t10.process_flag
		,t10.new_run_state　as run_state
		,t10.name
		,t10.state_sec
		,t10.all_sec AS span
		,t10.lot_sec AS std_all_diff_s
		,convert(DECIMAL(9, 1), sum(t10.state_sec) OVER (
				PARTITION BY t10.machine_id
				,t10.new_run_state
				)) * 100 / t10.all_sec AS percent_effic_total
		,convert(DECIMAL(9, 1), sum(t10.state_sec) OVER (
				PARTITION BY t10.machine_id
				,t10.process_flag
				,t10.new_run_state
				)) * 100 / t10.lot_sec AS percent_effic_class
		,row_number() OVER (
			PARTITION BY t10.machine_id
			,t10.new_run_state ORDER BY t10.new_run_state
			) AS effic_total_rank
	FROM (
		SELECT dense_rank() OVER (
				ORDER BY t9.machine_id
				) AS machine_number
			,t9.machine_id
			,dm.name AS machine_name
			,CASE 
				WHEN t9.process_flag = 1
					THEN 1
				ELSE 0
				END AS process_flag
			,t9.new_run_state
			,de.name AS name
			,t9.state_sec AS state_sec
			,sum(t9.state_sec) OVER (PARTITION BY t9.machine_id) AS all_sec
			,sum(t9.state_sec) OVER (
				PARTITION BY t9.machine_id
				,t9.process_flag
				) AS lot_sec
		FROM (
			SELECT t8.machine_id
				,t8.process_flag
				,t8.new_run_state
				,sum(t8.diff_sec) AS state_sec
			FROM (
				SELECT t7.start_at
					,t7.end_at
					,t7.diff_sec
					,t7.machine_id
					,t7.online_state
					,t7.record_flag
					,CASE 
						WHEN t7.lotendflag = 1
							THEN 199
						ELSE t7.new_run_state
						END AS new_run_state
					,isnull(t7.process_flag, 0) AS process_flag
				FROM (
					SELECT t6.*
						,lt2.process_flag
						,lt.lotendflag
					FROM (
						SELECT t5.start_at
							,t5.end_at
							,DATEDIFf(SECOND, t5.start_at, t5.end_at) AS diff_sec
							,t5.machine_id
							,t5.online_state
							,t5.record_flag
							,t5.run_state
							,t5.pre_run_state
							,t5.new_run_state
						FROM (
							SELECT CASE 
									WHEN t4.updated_at < @local_date_from
										THEN @local_date_from
									ELSE t4.updated_at
									END AS start_at
								,lead(t4.updated_at, 1, CASE 
										WHEN @local_date_to >= GETDATE()
											THEN getdate()
										ELSE @local_date_to
										END) OVER (
									PARTITION BY t4.machine_id ORDER BY t4.machine_id
										,t4.updated_at
									) AS end_at
								,t4.*
							FROM (
								SELECT t3.updated_at
									,t3.machine_id
									,t3.online_state
									,t3.record_flag
									,t3.run_state
									,t3.pre_run_state
									,CASE 
										WHEN t3.run_state = 1
											OR t3.run_state = 2
											THEN lag(t3.run_state, t3._offset) OVER (
													PARTITION BY t3.machine_id ORDER BY t3.updated_at
													)
										ELSE t3.run_state
										END AS new_run_state
									,t3.oor_flag
									,ROW_NUMBER() OVER (
										PARTITION BY t3.machine_id
										,t3.oor_flag ORDER BY t3.updated_at DESC
										) AS latest_stat_rank
								FROM (
									SELECT t2.*
										,row_number() OVER (
											PARTITION BY t2.machine_id
											,t2.record_flag
											,t2._diff_num ORDER BY t2.updated_at
											) AS _offset
									FROM (
										SELECT t1.*
											,ROW_NUMBER() OVER (
												PARTITION BY t1.machine_id ORDER BY t1.updated_at
												) - ROW_NUMBER() OVER (
												PARTITION BY t1.machine_id
												,t1.record_flag ORDER BY t1.updated_at
												) AS _diff_num
										FROM (
											SELECT *
											FROM (
												SELECT ms.updated_at
													,ms.machine_id
													,ms.online_state
													,ms.record_flag
													,ms.run_state
													,LAG(ms.run_state) OVER (
														PARTITION BY ms.machine_id ORDER BY ms.updated_at
														) AS pre_run_state
													,ms.oor_flag
												FROM (
													SELECT top1.updated_at
														,top1.machine_id
														,top1.online_state
														,1 AS record_flag
														,top1.run_state
														,1 AS oor_flag --out of range flag
													FROM (
														SELECT msr.updated_at
															,msr.machine_id
															,msr.online_state
															,msr.run_state
															,ROW_NUMBER() OVER (
																PARTITION BY msr.machine_id ORDER BY msr.updated_at DESC
																) AS up_rank
														FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
														INNER JOIN (
															SELECT CONVERT(INT, value) AS value
															FROM STRING_SPLIT(@local_machine_id_list, ',')
															) AS v ON v.value = msr.machine_id
														WHERE updated_at < @local_date_from
														) AS top1
													WHERE up_rank <= 1
													
													UNION ALL
													
													SELECT msr.updated_at
														,msr.machine_id
														,msr.online_state
														,1 AS record_flag
														,msr.run_state
														,0 AS oor_flag --out of range flag
													FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
													INNER JOIN (
														SELECT CONVERT(INT, value) AS value
														FROM STRING_SPLIT(@local_machine_id_list, ',')
														) AS v ON v.value = msr.machine_id
													WHERE updated_at >= @local_date_from
														AND updated_at <= @local_date_to
													
													UNION ALL
													
													--alarm record
													SELECT top1.alarm_on_at
														,top1.machine_id
														,NULL AS online_state
														,2 AS record_flag
														,99 AS run_state
														,1 AS oor_flag --out of range flag
													FROM (
														SELECT mar.alarm_on_at
															,mar.machine_id
															,ROW_NUMBER() OVER (
																PARTITION BY mar.machine_id ORDER BY mar.alarm_on_at DESC
																) AS up_rank
														FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
														INNER JOIN (
															SELECT CONVERT(INT, value) AS value
															FROM STRING_SPLIT(@local_machine_id_list, ',')
															) AS v ON v.value = mar.machine_id
														WHERE alarm_on_at < @local_date_from
														) AS top1
													WHERE top1.up_rank <= 1
													) AS ms
												) AS msp
											
											UNION ALL
											
											--lot process 
											SELECT top1.recorded_at
												,top1.machine_id
												,NULL AS online_state
												,0 AS record_flag
												,top1.run_state AS run_state
												,NULL AS pre_run_state
												,1 AS oor_flag --out of range flag
											FROM (
												SELECT lpr.recorded_at
													,lpr.machine_id
													,record_class AS run_state
													,ROW_NUMBER() OVER (
														PARTITION BY lpr.machine_id ORDER BY lpr.recorded_at DESC
														) AS up_rank
												FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
												INNER JOIN (
													SELECT CONVERT(INT, value) AS value
													FROM STRING_SPLIT(@local_machine_id_list, ',')
													) AS v ON v.value = lpr.machine_id
												WHERE
													--高速化の為一日前までのデータから絞り込む
													(
														lpr.day_id <= @fr_date
														AND lpr.day_id >= @fr_date - 1
														)
													AND lpr.record_class IN (
														1
														--,11
														,2
														,12
														)
													AND recorded_at < @local_date_from
												) AS top1
											WHERE top1.up_rank <= 1
											
											UNION ALL
											
											SELECT lpr.recorded_at
												,lpr.machine_id
												,NULL AS online_state
												,0 AS record_flag
												,record_class AS run_state
												,NULL AS pre_run_state
												,0 AS oor_flag --out of range flag
											FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
											INNER JOIN (
												SELECT CONVERT(INT, value) AS value
												FROM STRING_SPLIT(@local_machine_id_list, ',')
												) AS v ON v.value = lpr.machine_id
											WHERE lpr.record_class IN (
													1
													--,11
													,2
													,12
													)
												AND recorded_at >= @local_date_from
												AND recorded_at <= @local_date_to
											) AS t1
										) AS t2
									) AS t3
								) AS t4
							WHERE t4.oor_flag = 0
								OR t4.latest_stat_rank <= 1
							) AS t5
						) AS t6
					--最終的にロットエンドステータスを上書きする
					LEFT JOIN #lotend_table AS lt ON lt.machine_id = t6.machine_id
						AND lt.online_end_at <= t6.start_at
						AND t6.start_at < lt.finished_at
					--プロセス中のフラグ作成
					LEFT JOIN #lotend_table AS lt2 ON lt2.machine_id = t6.machine_id
						AND lt2.started_at <= t6.start_at
						AND t6.start_at < lt2.finished_at
					) AS t7
				) AS t8
			GROUP BY t8.machine_id
				,t8.process_flag
				,t8.new_run_state
			) AS t9
		LEFT OUTER JOIN act.fnc_dim_efficiencies() AS de ON de.run_state = t9.new_run_state
		LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t9.machine_id
		) AS t10
	ORDER BY t10.machine_id
		,t10.process_flag
		,t10.new_run_state
END

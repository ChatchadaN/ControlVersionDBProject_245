
CREATE PROCEDURE [act].[sp_machinemonitor_summary_status_v2] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@machine_id_list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--DECLARE @machine_id_list NVARCHAR(max) = '308'
	--DECLARE @date_from DATETIME = '2020-06-04 00:00:00'
	--DECLARE @date_to DATETIME = '2020-06-05 00:00:00'
	--DECLARE @time_offset INT = 0
	----DECLARE @time_offset INT = 8
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

	--IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
	--	DROP TABLE #table;
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
				WHEN t9.new_lotend_flag = 1
					THEN 1
				ELSE 0
				END AS process_flag
			,t9.new_run_state
			,de.name AS name
			,t9.state_sec AS state_sec
			,sum(t9.state_sec) OVER (PARTITION BY t9.machine_id) AS all_sec
			,sum(t9.state_sec) OVER (
				PARTITION BY t9.machine_id
				,t9.new_lotend_flag
				) AS lot_sec
		FROM (
			SELECT t8.machine_id
				,t8.new_lotend_flag
				,t8.new_run_state
				,sum(t8.diff_sec) AS state_sec
			FROM (
				SELECT *
					,CASE 
						WHEN t7.record_flag = 0
							AND t7.run_state = 1
							--execute
							THEN 4
							--THEN 255
						WHEN t7.record_flag = 0
							AND t7.run_state = 2
							AND t7.oor_flag = 0
							--期間内(oor_flag=0)LotEndの場合は、Idleにする
							THEN 1
						WHEN t7.record_flag = 0
							AND t7.run_state = 2
							AND t7.oor_flag = 1
							--期間外(oor_flag=1)LotEndの場合は、直近Stateにする
							THEN run_state_overwrite
						WHEN t7.record_flag = 0
							AND t7.run_state = 12
							--LotEnd status
							THEN 199
						ELSE t7.run_state
						END AS new_run_state
				FROM (
					SELECT t6.start_at
						,t6.end_at
						,DATEDIFf(SECOND, t6.start_at, t6.end_at) AS diff_sec
						,t6.machine_id
						,t6.online_state
						,t6.record_flag
						,t6.run_state
						,t6.lotend_flag
						,t6.new_lotend_flag AS new_lotend_flag
						,t6.oor_flag AS oor_flag
						,t6.run_state_overwrite AS run_state_overwrite
					FROM (
						SELECT CASE 
								WHEN t5.updated_at < @local_date_from
									THEN @local_date_from
								ELSE t5.updated_at
								END AS start_at
							,lead(t5.updated_at, 1, CASE 
									WHEN @local_date_to >= GETDATE()
										THEN getdate()
									ELSE @local_date_to
									END) OVER (
								PARTITION BY t5.machine_id ORDER BY t5.machine_id
									,t5.updated_at
								) AS end_at
							,t5.machine_id AS machine_id
							,t5.online_state AS online_state
							,t5.record_flag AS record_flag
							,t5.run_state AS run_state
							,t5.lotend_flag AS lotend_flag
							,t5.new_lotend_flag AS new_lotend_flag
							,t5.oor_flag AS oor_flag
							,t5.run_state_overwrite AS run_state_overwrite
						FROM (
							SELECT t4.*
								,CASE 
									WHEN t4.lotend_flag = 0
										THEN lag(t4.lotend_flag, t4._offset) OVER (
												PARTITION BY t4.machine_id ORDER BY t4.updated_at
												)
									ELSE t4.lotend_flag
									END AS new_lotend_flag
							FROM (
								SELECT t3.*
									,row_number() OVER (
										PARTITION BY t3.machine_id
										,t3.lotend_flag
										,t3._diff_num ORDER BY t3.updated_at
										) AS _offset
								FROM (
									SELECT t2.*
										,ROW_NUMBER() OVER (
											PARTITION BY t2.machine_id ORDER BY t2.updated_at
											) - ROW_NUMBER() OVER (
											PARTITION BY t2.machine_id
											,t2.lotend_flag ORDER BY t2.updated_at
											) AS _diff_num
									FROM (
										SELECT t1.*
											,ROW_NUMBER() OVER (
												PARTITION BY t1.machine_id
												,t1.oor_flag ORDER BY t1.updated_at DESC
												) AS latest_stat_rank
											,CASE 
												WHEN t1.record_flag = 0 and　t1.run_state = 2
													THEN 2
												WHEN t1.record_flag = 0
													AND t1.run_state = 1
													THEN 1
												ELSE 0
												END AS lotend_flag
											--期間外lot_process_recordの場合は、その直近レコードのstateを用いる
											,lag(t1.run_state, 1) OVER (
												PARTITION BY t1.machine_id
												,t1.oor_flag ORDER BY t1.updated_at
												) AS run_state_overwrite
										FROM (
											----machine_state_records とmachine_alarm_recordsとlot_process_recordsをUNION
											--machine state
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
												--,msr.qc_state
												FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
												INNER JOIN (
													SELECT CONVERT(INT, value) AS value
													FROM STRING_SPLIT(@local_machine_id_list, ',')
													) AS v ON v.value = msr.machine_id
												WHERE
													--machine_id = @machine_id
													--	AND 
													updated_at < @local_date_from
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
											
											UNION ALL
											
											SELECT mar.alarm_on_at
												,mar.machine_id
												,NULL AS online_state
												,2 AS record_flag
												,99 AS run_state
												,0 AS oor_flag --out of range flag
											FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
											INNER JOIN (
												SELECT CONVERT(INT, value) AS value
												FROM STRING_SPLIT(@local_machine_id_list, ',')
												) AS v ON v.value = mar.machine_id
											WHERE alarm_on_at >= @local_date_from
												AND alarm_on_at <= @local_date_to
											
											UNION ALL
											
											--lot process 
											SELECT top1.recorded_at
												,top1.machine_id
												,NULL AS online_state
												,0 AS record_flag
												,top1.run_state AS run_state
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
														,
														2
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
							) AS t5
						WHERE t5.oor_flag = 0
							OR t5.latest_stat_rank <= 1
						) AS t6
					) AS t7
				) AS t8
			GROUP BY t8.machine_id
				,t8.new_lotend_flag
				,t8.new_run_state
			) AS t9
		LEFT OUTER JOIN act.fnc_dim_efficiencies() AS de ON de.run_state = t9.new_run_state
		LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t9.machine_id
		) AS t10
	ORDER BY t10.machine_id
		,t10.process_flag
		,t10.new_run_state
		--OPTION (RECOMPILE)
END

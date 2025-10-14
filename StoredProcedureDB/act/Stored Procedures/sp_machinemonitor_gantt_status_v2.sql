
CREATE PROCEDURE [act].[sp_machinemonitor_gantt_status_v2] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@machine_id_list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2020-06-15 00:00:00'
	--DECLARE @date_to DATETIME = '2020-06-17 00:00:00'
	--DECLARE @machine_id_list NVARCHAR(max) = '19'
	--DECLARE @time_offset INT = 8
	--!!IMPORTANT!! Replace parameter to local variables 
	DECLARE @local_date_from DATETIME = DATEADD(HOUR, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = DATEADD(HOUR, @time_offset, @date_to)
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list

	IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
		DROP TABLE #table;

	SELECT dd.id AS day_id
		,t4.machine_id AS machine_id
		,t4.started_at AS started_at
		,t4.finished_at AS finished_at
		,t4.online_state AS online_state
		,t4.run_state AS run_state
		,t4.start_point AS start_point
		,t4.end_diff AS end_diff
	INTO #table
	FROM (
		SELECT convert(DATE, t3.started_at) AS date_at
			,t3.machine_id AS machine_id
			,t3.started_at AS started_at
			,CASE 
				WHEN t3.ended_at IS NULL
					THEN t3.latest_date
				ELSE t3.ended_at
				END AS finished_at
			,t3.online_state AS online_state
			,t3.run_state AS run_state
			,isnull(convert(DECIMAL(9, 1), datediff(SECOND, @local_date_from, t3.started_at)) / 60 / 60, NULL) AS start_point
			,isnull(convert(DECIMAL(9, 1), datediff(SECOND, t3.started_at, CASE 
							WHEN t3.ended_at IS NOT NULL
								THEN t3.ended_at
							ELSE t3.latest_date
							END)) / 60 / 60, NULL) AS end_diff
		FROM (
			SELECT t2.machine_id AS machine_id
				,t2.updated_at AS started_at
				,t2.ended_at AS ended_at
				,CASE 
					WHEN @local_date_to < GETDATE()
						THEN @local_date_to
					ELSE GETDATE()
					END AS latest_date
				,t2.online_state AS online_state
				,t2.run_state AS run_state
			FROM (
				SELECT t1.machine_id AS machine_id
					,t1.updated_at AS updated_at
					,t1.online_state AS online_state
					,t1.run_state AS run_state
					,lag(t1.updated_at, 1, GETDATE()) OVER (
						PARTITION BY t1.machine_id ORDER BY t1.updated_at DESC
						) AS ended_at
				FROM (
					SELECT top1.updated_at
						,top1.machine_id
						,top1.online_state
						,top1.run_state
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
						WHERE updated_at < @local_date_from
						) AS top1
					WHERE up_rank <= 1
					
					UNION ALL
					
					SELECT msr.updated_at
						,msr.machine_id
						,msr.online_state
						,msr.run_state
					FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
					INNER JOIN (
						SELECT CONVERT(INT, value) AS value
						FROM STRING_SPLIT(@local_machine_id_list, ',')
						) AS v ON v.value = msr.machine_id
					WHERE updated_at >= @local_date_from
						AND updated_at < @local_date_to
					
					UNION ALL
					
					SELECT top1.alarm_on_at
						,top1.machine_id
						,1 AS online_state
						,99 AS run_state
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
						,1 AS online_state
						,99 AS run_state
					FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
					INNER JOIN (
						SELECT CONVERT(INT, value) AS value
						FROM STRING_SPLIT(@local_machine_id_list, ',')
						) AS v ON v.value = mar.machine_id
					WHERE alarm_on_at >= @local_date_from
						AND alarm_on_at < @local_date_to
					) AS t1
				) AS t2
			) AS t3
		) AS t4
	INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.date_value = t4.date_at

	--DECLARE @new_from DATETIME = (
	--		SELECT format(min(started_at), 'yyyy/MM/dd 00:00:00')
	--		FROM #table
	--		);
	--DECLARE @new_to DATETIME = (
	--		SELECT format(max(finished_at), 'yyyy/MM/dd 00:00:00')
	--		FROM #table
	--		);
	SELECT dense_rank() OVER (
			ORDER BY x.value
			) AS machine_number
		,x.value AS machine_id
		,mc.name AS machine_name
		,mc.machine_model_id AS machine_model_id
		,tt.date_value AS date_value
		,tt.std_from AS std_from
		,tt.std_to AS std_to
		,isnull(tt.loop_index, 0) AS loop_index
		,tt.online_state AS online_state
		,tt.code AS code
		,tt.code_name AS code_name
		,tt.started_at AS started_at
		,tt.finished_at AS finished_at
		,isnull(tt.start_point, - 1) AS start_point
		,isnull(tt.end_diff, 0) AS end_diff
		,tt.original_started_at AS original_started_at
		,tt.original_finished_at AS original_finished_at
	FROM (
		SELECT CONVERT(INT, value) AS value
		FROM STRING_SPLIT(@local_machine_id_list, ',')
		) AS x
	LEFT OUTER JOIN (
		SELECT s4.machine_id AS machine_id
			,s4.date_value AS date_value
			,s4.std_from AS std_from
			,s4.std_to AS std_to
			--,DATEDIFF(day, @local_date_from, s4.new_started_at) AS loop_index
			,DATEDIFF(HOUR, @local_date_from, s4.new_started_at) / 24 AS loop_index
			,s4.online_state AS online_state
			,s4.run_state AS code
			,de.name AS code_name
			,s4.new_started_at AS started_at
			,s4.new_finished_at AS finished_at
			,s4.new_start_point AS start_point
			,s4.new_end_diff AS end_diff
			,s4.original_started_at AS original_started_at
			,s4.original_finished_at AS original_finished_at
		FROM (
			SELECT s3.date_value AS date_value
				,s3.std_from AS std_from
				,s3.std_to AS std_to
				,s3.machine_id AS machine_id
				,s3.online_state AS online_state
				,s3.run_state AS run_state
				,s3.new_started_at AS new_started_at
				,s3.new_finished_at AS new_finished_at
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.std_from, s3.new_started_at)) / 60 / 60, NULL) AS new_start_point
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.new_started_at, s3.new_finished_at)) / 60 / 60, NULL) AS new_end_diff
				,s3.original_started_at AS original_started_at
				,s3.original_finished_at AS original_finished_at
			FROM (
				SELECT s2.date_value AS date_value
					,s2.std_from AS std_from
					,s2.std_to AS std_to
					,s2.machine_id AS machine_id
					,s2.online_state AS online_state
					,s2.run_state AS run_state
					,CASE 
						WHEN s2.started_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.started_at
							AND s2.started_at <= s2.std_to
							THEN s2.started_at
						ELSE s2.std_to
						END AS new_started_at
					,CASE 
						WHEN s2.finished_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.finished_at
							AND s2.finished_at <= s2.std_to
							THEN s2.finished_at
						ELSE s2.std_to
						END AS new_finished_at
					,s2.started_at AS original_started_at
					,s2.finished_at AS original_finished_at
				FROM (
					SELECT s1.*
						,tt.*
					FROM (
						SELECT ddy.date_value AS date_value
							,CASE 
								WHEN @time_offset != 0
									THEN dateadd(hour, @time_offset, convert(DATETIME, ddy.date_value))
								ELSE DATEADD(day, ddy.id - (
											SELECT id
											FROM APCSProDWH.dwh.dim_days AS d WITH (NOLOCK)
											WHERE d.date_value = CONVERT(DATE, @local_date_from)
											), @local_date_from)
								END AS std_from
							,CASE 
								WHEN @time_offset != 0
									THEN dateadd(hour, @time_offset, convert(DATETIME, dateadd(day, 1, ddy.date_value)))
								ELSE DATEADD(day, ddy.id + 1 - (
											SELECT id
											FROM APCSProDWH.dwh.dim_days AS d WITH (NOLOCK)
											WHERE d.date_value = CONVERT(DATE, @local_date_from)
											), @local_date_from)
								END AS std_to
						FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
						WHERE convert(DATE, @local_date_from) <= date_value
							AND date_value < convert(DATE, @local_date_to)
						) AS s1
					LEFT OUTER JOIN #table AS tt ON NOT (tt.finished_at < s1.std_from)
						AND NOT (s1.std_to < tt.started_at)
					) AS s2
				) AS s3
			) AS s4
		LEFT OUTER JOIN act.fnc_dim_efficiencies() AS de ON de.run_state = s4.run_state
		WHERE @local_date_from <= s4.std_from
			AND s4.std_to <= @local_date_to
		) AS tt ON tt.machine_id = x.value
	INNER JOIN apcsprodb.[mc].[machines] AS mc WITH (NOLOCK) ON mc.id = x.value
	ORDER BY machine_number
		,started_at;
END

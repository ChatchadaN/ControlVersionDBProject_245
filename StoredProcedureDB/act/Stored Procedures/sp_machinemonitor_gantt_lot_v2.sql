
CREATE PROCEDURE [act].[sp_machinemonitor_gantt_lot_v2] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@machine_id_list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2020-06-16 00:00:00'
	--DECLARE @date_to DATETIME = '2020-06-17 00:00:00'
	--DECLARE @machine_id_list NVARCHAR(max) = '18,19'
	--DECLARE @time_offset INT = 0
	--!!IMPORTANT!! Replace parameter to local variables 
	--ローカル変数に置き換え。速度向上の為
	DECLARE @local_date_from DATETIME = DATEADD(HOUR, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = DATEADD(HOUR, @time_offset, @date_to)
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list

	IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
		DROP TABLE #table;

	SELECT t6.*
	INTO #table
	FROM (
		SELECT t5.*
			,ROW_NUMBER() OVER (
				PARTITION BY t5.process_job_id
				,t5.lot_id ORDER BY t5.onlineend_at DESC
				) AS rank_onlineend
		FROM (
			SELECT t4.process_job_id AS process_job_id
				,t4.process_id AS process_id
				,t4.job_id AS job_id
				,t4.pj_rank AS pj_rank
				,t4.machine_id AS machine_id
				,t4.lot_id AS lot_id
				,t4.setup_at AS setup_at
				,isnull(t4.started_at, t4.setup_at) AS started_at
				,CASE 
					WHEN lpr.recorded_at IS NOT NULL
						THEN lpr.recorded_at
					ELSE t4.finished_at
					END AS onlineend_at
				,t4.finished_at AS finished_at
				,t4.setup_point AS setup_point
				,
				--comment for tooltip
				CASE 
					WHEN t4.started_at IS NULL
						THEN 'START OF DATE IS UNKNOWN'
					WHEN t4.finished_at IS NULL
						THEN 'END OF DATE IS UNKNOWN'
					ELSE ''
					END AS note
			FROM (
				SELECT t3.process_job_id AS process_job_id
					,t3.process_id AS process_id
					,t3.job_id AS job_id
					,t3.pj_rank AS pj_rank
					,t3.machine_id AS machine_id
					,t3.lot_id AS lot_id
					,t3.setup_at AS setup_at
					,t3.started_at AS started_at
					,CASE 
						WHEN t3.finished_at IS NOT NULL
							THEN t3.finished_at
						ELSE lead(t3.setup_at, 1, t3.latest_date) OVER (
								PARTITION BY t3.machine_id ORDER BY t3.setup_at
								)
						END AS finished_at
					,t3.latest_date AS latest_date
					,t3.setup_point AS setup_point
				FROM (
					SELECT t2.process_job_id AS process_job_id
						,t2.process_id AS process_id
						,t2.job_id AS job_id
						,t2.is_special_flow AS is_special_flow
						,t2.machine_id AS machine_id
						,t2.lot_id AS lot_id
						,t2.setup_at AS setup_at
						,t2.started_at AS started_at
						,t2.finished_at AS finished_at
						,t2.latest_date AS latest_date
						,t2.setup_point AS setup_point
						,ROW_NUMBER() OVER (
							PARTITION BY t2.machine_id
							,t2.process_job_id ORDER BY t2.is_special_flow
							) AS pj_rank
					FROM (
						SELECT t1.process_job_id AS process_job_id
							,t1.process_id AS process_id
							,t1.job_id AS job_id
							,t1.is_special_flow AS is_special_flow
							,t1.machine_id AS machine_id
							,t1.lot_id AS lot_id
							,t1.setup_at AS setup_at
							,t1.started_at AS started_at
							,t1.finished_at AS finished_at
							,t1.latest_date AS latest_date
							,t1.setup_point AS setup_point
						FROM (
							SELECT pj.id AS process_job_id
								,lpr.process_id AS process_id
								,lpr.job_id AS job_id
								,lpr.is_special_flow AS is_special_flow
								,pj.machine_id AS machine_id
								,pj.setup_at AS setup_at
								,pj.started_at AS started_at
								,pj.finished_at AS finished_at
								,CASE 
									WHEN @local_date_to < GETDATE()
										THEN @local_date_to
									ELSE GETDATE()
									END AS latest_date
								,isnull(convert(DECIMAL(9, 1), datediff(SECOND, @local_date_from, pj.setup_at)) / 60 / 60, NULL) AS setup_point
								,pj.finished_day_id AS finished_day_id
								,pl.lot_id AS lot_id
								,datepart(hh, pj.setup_at) AS setup_hour
							FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
							INNER JOIN APCSProDWH.dwh.view_fact_pj_lots AS pl WITH (NOLOCK) ON pl.pj_id = pj.id
							INNER JOIN (
								SELECT value
								FROM STRING_SPLIT(@local_machine_id_list, ',')
								) AS v ON v.value = pj.machine_id
							LEFT OUTER JOIN APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK) ON lpr.lot_id = pl.lot_id
								AND lpr.process_job_id = pj.id
								AND lpr.recorded_at = pj.started_at
								AND lpr.record_class = 1
								AND lpr.machine_id = pj.machine_id
							) AS t1
						WHERE (
								--setup_atの検索範囲を@date_from-1とする。@date_fromだとsetup_atが抜け落ちる為、一日前からマージンを持って絞り込む
								(
									(t1.finished_at IS NOT NULL)
									AND (@date_from <= t1.finished_at)
									)
								OR (
									(@date_from - 1 <= t1.setup_at)
									AND (t1.finished_at IS NULL)
									)
								)
							AND (t1.setup_point <= datediff(hour, @local_date_from, @local_date_to))
						) AS t2
					) AS t3
				WHERE t3.pj_rank = 1
				) AS t4
			LEFT JOIN APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK) ON lpr.lot_id = t4.lot_id
				AND lpr.process_job_id = t4.process_job_id
				AND lpr.machine_id = t4.machine_id
				AND lpr.record_class = 12
			) AS t5
		) AS t6
	WHERE t6.rank_onlineend = 1

	--DECLARE @new_from DATETIME = (
	--		SELECT format(min(setup_at), 'yyyy/MM/dd 00:00:00')
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
		,dm.name AS machine_name
		,dm.machine_model_id AS machine_model_id
		,tt.process_id AS process_id
		,tt.job_id AS job_id
		,tt.date_value AS date_value
		,tt.std_from AS std_from
		,tt.std_to AS std_to
		,isnull(tt.loop_index, 0) AS loop_index
		,tt.setup_at AS setup_at
		,tt.started_at AS started_at
		,tt.onlined_at AS onlineend_at
		,tt.finished_at AS finished_at
		,tt.lot_id AS lot_id
		,tt.lot_no AS lot_no
		,tt.package_name AS package_name
		,tt.device_name AS device_name
		,tt.production_category AS production_category
		,tt.production_category_val AS production_category_val
		,tt.device_type AS device_type
		,tt.device_type_name AS device_type_name
		,isnull(tt.setup_point, - 1) AS setup_point
		,isnull(tt.start_diff, 0) AS start_diff
		,isnull(tt.onlineend_diff, 0) AS onlineend_diff
		,isnull(tt.end_diff, 0) AS end_diff
		,tt.original_started_at AS original_started_at
		,tt.original_onlineend_at AS original_onlineend_at
		,tt.original_finished_at AS original_finished_at
		,tt.note AS note
	FROM (
		SELECT CONVERT(INT, value) AS value
		FROM STRING_SPLIT(@local_machine_id_list, ',')
		) AS x
	LEFT OUTER JOIN (
		SELECT
			--dense_rank() OVER (
			--		ORDER BY s4.machine_id
			--		) AS machine_number,
			s4.machine_id AS machine_id
			,s4.process_id AS process_id
			,s4.job_id AS job_id
			,s4.date_value AS date_value
			,s4.std_from AS std_from
			,s4.std_to AS std_to
			--,DATEDIFF(day, @local_date_from, s4.new_setup_at) AS loop_index
			,DATEDIFF(HOUR, @local_date_from, s4.new_setup_at) / 24 AS loop_index
			,s4.new_setup_at AS setup_at
			,s4.new_started_at AS started_at
			,s4.new_onlineend_at AS onlined_at
			,s4.new_finished_at AS finished_at
			,s4.lot_id AS lot_id
			,l.lot_no AS lot_no
			,dp.name AS package_name
			,dd.name AS device_name
			,l.production_category AS production_category
			,il.label_eng AS production_category_val
			,dv.device_type AS device_type
			,CASE 
				WHEN dv.device_type = 0
					THEN 'Mass Products'
				WHEN dv.device_type = 1
					THEN 'Sample Products'
				WHEN dv.device_type = 2
					THEN 'Experimental Products'
				WHEN dv.device_type = 3
					THEN 'Material'
				WHEN dv.device_type = 4
					THEN 'Pilot Sample'
				WHEN dv.device_type = 5
					THEN 'Dummy'
				WHEN dv.device_type = 6
					THEN 'D Lot'
				WHEN dv.device_type = 7
					THEN 'D Lot(Recall)'
				ELSE 'others'
				END AS device_type_name
			,s4.new_setup_point AS setup_point
			,s4.new_start_diff AS start_diff
			,s4.new_onlineend_diff AS onlineend_diff
			,s4.new_end_diff AS end_diff
			,s4.original_started_at AS original_started_at
			,s4.original_onlineend_at AS original_onlineend_at
			,s4.original_finished_at AS original_finished_at
			,s4.note AS note
		FROM (
			SELECT s3.date_value AS date_value
				,s3.std_from AS std_from
				,s3.std_to AS std_to
				,s3.machine_id AS machine_id
				,s3.process_id AS process_id
				,s3.job_id AS job_id
				,s3.lot_id AS lot_id
				,s3.new_setup_at AS new_setup_at
				,s3.new_started_at AS new_started_at
				,s3.new_onlineend_at AS new_onlineend_at
				,s3.new_finished_at AS new_finished_at
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.std_from, s3.new_setup_at)) / 60 / 60, NULL) AS new_setup_point
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.new_setup_at, s3.new_started_at)) / 60 / 60, NULL) AS new_start_diff
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.new_setup_at, s3.new_onlineend_at)) / 60 / 60, NULL) AS new_onlineend_diff
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.new_setup_at, s3.new_finished_at)) / 60 / 60, NULL) AS new_end_diff
				,s3.original_started_at AS original_started_at
				,s3.original_onlineend_at AS original_onlineend_at
				,s3.original_finished_at AS original_finished_at
				,s3.note AS note
			FROM (
				SELECT s2.date_value AS date_value
					,s2.std_from AS std_from
					,s2.std_to AS std_to
					,s2.machine_id AS machine_id
					,s2.process_id AS process_id
					,s2.job_id AS job_id
					,s2.lot_id AS lot_id
					,CASE 
						WHEN s2.setup_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.setup_at
							AND s2.setup_at <= s2.std_to
							THEN s2.setup_at
						ELSE s2.std_to
						END AS new_setup_at
					,CASE 
						WHEN s2.started_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.started_at
							AND s2.started_at <= s2.std_to
							THEN s2.started_at
						ELSE s2.std_to
						END AS new_started_at
					,CASE 
						WHEN s2.onlineend_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.onlineend_at
							AND s2.onlineend_at <= s2.std_to
							THEN s2.onlineend_at
						ELSE s2.std_to
						END AS new_onlineend_at
					,CASE 
						WHEN s2.finished_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.finished_at
							AND s2.finished_at <= s2.std_to
							THEN s2.finished_at
						ELSE s2.std_to
						END AS new_finished_at
					,s2.started_at AS original_started_at
					,s2.onlineend_at AS original_onlineend_at
					,s2.finished_at AS original_finished_at
					,s2.note AS note
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
						--AND NOT (s1.std_to < tt.setup_at)
						AND NOT (s1.std_to < tt.started_at)
					) AS s2
				) AS s3
			) AS s4
		INNER JOIN APCSProDB.trans.lots AS l WITH (NOLOCK) ON l.id = s4.lot_id
		LEFT OUTER JOIN apcsprodwh.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = l.act_package_id
		INNER JOIN APCSProDB.method.device_slips AS ds WITH (NOLOCK) ON ds.device_slip_id = l.device_slip_id
		LEFT OUTER JOIN apcsprodwh.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = l.act_device_name_id
		LEFT OUTER JOIN APCSProDB.method.device_versions AS dv ON dv.device_name_id = l.act_device_name_id
			AND dv.version_num = ds.version_num
		LEFT OUTER JOIN APCSProDWH.dwh.item_labels AS il WITH (NOLOCK) ON il.name = 'fact_wip.production_category'
			AND il.val = l.production_category
		WHERE @local_date_from <= s4.std_from
			AND s4.std_to <= @local_date_to
		) AS tt ON tt.machine_id = x.value
	LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = x.value
	ORDER BY machine_number
		,setup_at;
END

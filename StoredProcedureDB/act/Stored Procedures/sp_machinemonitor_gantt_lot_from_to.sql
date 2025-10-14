
CREATE PROCEDURE [act].[sp_machinemonitor_gantt_lot_from_to] (
	@date_from DATETIME
	,@date_to DATETIME
	,@machine_id_list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2019-09-06 00:00:00'
	--DECLARE @date_to DATETIME = '2019-09-07 00:00:00'
	--DECLARE @machine_id_list NVARCHAR(max) = '21'
	--!!IMPORTANT!! Replace parameter to local variables 
	--ローカル変数に置き換え。速度向上の為
	DECLARE @local_date_from DATETIME = @date_from
	DECLARE @local_date_to DATETIME = format(dateadd(DAY, 1, @date_to), 'yyyy-MM-dd 00:00:00')
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list

	IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
		DROP TABLE #table;

	SELECT t4.process_job_id AS process_job_id
		,t4.process_id AS process_id
		,t4.job_id AS job_id
		,t4.machine_id AS machine_id
		,t4.lot_id AS lot_id
		,t4.setup_at AS setup_at
		,t4.started_at AS started_at
		,CASE 
			WHEN t4.finished_at IS NOT NULL
				THEN t4.finished_at
			ELSE lead(t4.setup_at, 1, t4.latest_date) OVER (
					PARTITION BY t4.machine_id ORDER BY t4.setup_at
					)
			END AS finished_at
		,t4.setup_point AS setup_point
		,
		--comment for tooltip
		CASE 
			WHEN t4.finished_at IS NOT NULL
				THEN ''
			ELSE 'END OF DATE IS UNKNOWN'
			END AS note
	INTO #table
	FROM (
		SELECT t3.process_job_id AS process_job_id
			,t3.process_id AS process_id
			,t3.job_id AS job_id
			,t3.machine_id AS machine_id
			,t3.lot_id AS lot_id
			,t3.setup_at AS setup_at
			,t3.started_at AS started_at
			,t3.finished_at AS finished_at
			,t3.latest_date AS latest_date
			,t3.setup_point AS setup_point
		FROM (
			SELECT t2.process_job_id AS process_job_id
				,t2.process_id AS process_id
				,t2.job_id AS job_id
				,t2.machine_id AS machine_id
				,t2.lot_id AS lot_id
				,t2.setup_at AS setup_at
				,t2.started_at AS started_at
				,t2.finished_at AS finished_at
				,t2.latest_date AS latest_date
				,t2.setup_point AS setup_point
			FROM (
				SELECT t1.process_job_id AS process_job_id
					,t1.process_id AS process_id
					,t1.job_id AS job_id
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
					) AS t1
				WHERE (
						(
							(t1.finished_at IS NOT NULL)
							AND (@local_date_from <= t1.finished_at)
							)
						OR (
							(@local_date_from <= t1.setup_at)
							AND (t1.finished_at IS NULL)
							)
						)
					AND (t1.setup_point <= datediff(hour, @local_date_from, @local_date_to))
				) AS t2
			) AS t3
		) AS t4

	DECLARE @new_from DATETIME = (
			SELECT format(min(setup_at), 'yyyy/MM/dd 00:00:00')
			FROM #table
			);
	DECLARE @new_to DATETIME = (
			SELECT format(max(finished_at), 'yyyy/MM/dd 00:00:00')
			FROM #table
			);

	SELECT dense_rank() OVER (
			ORDER BY x.value
			) AS machine_number
		,x.value AS machine_id
		,
		--tt.machine_id AS machine_id,
		--machine_name AS machine_name,
		dm.name AS machine_name
		,dm.machine_model_id AS machine_model_id
		,
		--dm.machine_model_id AS machine_model_id,
		tt.process_id AS process_id
		,tt.job_id AS job_id
		,tt.date_value AS date_value
		,tt.std_from AS std_from
		,tt.std_to AS std_to
		,isnull(tt.loop_index, 0) AS loop_index
		,tt.setup_at AS setup_at
		,tt.started_at AS started_at
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
		,isnull(tt.end_diff, 0) AS end_diff
		,tt.original_started_at AS original_started_at
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
			,
			--dm.name AS machine_name,
			--dm.machine_model_id AS machine_model_id,
			s4.date_value AS date_value
			,s4.std_from AS std_from
			,s4.std_to AS std_to
			,DATEDIFF(day, @local_date_from, s4.new_setup_at) AS loop_index
			,s4.new_setup_at AS setup_at
			,s4.new_started_at AS started_at
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
				ELSE 'others'
				END AS device_type_name
			,s4.new_setup_point AS setup_point
			,s4.new_start_diff AS start_diff
			,s4.new_end_diff AS end_diff
			,s4.original_started_at AS original_started_at
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
				,s3.new_finished_at AS new_finished_at
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.std_from, s3.new_setup_at)) / 60 / 60, NULL) AS new_setup_point
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.new_setup_at, s3.new_started_at)) / 60 / 60, NULL) AS new_start_diff
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.new_setup_at, s3.new_finished_at)) / 60 / 60, NULL) AS new_end_diff
				,s3.original_started_at AS original_started_at
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
						WHEN s2.finished_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.finished_at
							AND s2.finished_at <= s2.std_to
							THEN s2.finished_at
						ELSE s2.std_to
						END AS new_finished_at
					,s2.started_at AS original_started_at
					,s2.finished_at AS original_finished_at
					,s2.note AS note
				FROM (
					SELECT s1.*
						,tt.*
					FROM (
						SELECT ddy.date_value AS date_value
							,DATEADD(day, ddy.id - (
									SELECT id
									FROM APCSProDWH.dwh.dim_days AS d WITH (NOLOCK)
									WHERE d.date_value = CONVERT(DATE, @new_from)
									), @local_date_from) AS std_from
							,DATEADD(day, ddy.id + 1 - (
									SELECT id
									FROM APCSProDWH.dwh.dim_days AS d WITH (NOLOCK)
									WHERE d.date_value = CONVERT(DATE, @new_from)
									), @local_date_from) AS std_to
						FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
						WHERE @new_from <= date_value
							AND date_value <= @new_to
						) AS s1
					LEFT OUTER JOIN #table AS tt ON NOT (tt.finished_at < s1.std_from)
						--AND NOT (s1.std_to < tt.setup_at)
						AND NOT (s1.std_to < tt.started_at)
					) AS s2
				) AS s3
			) AS s4
		INNER JOIN APCSProDWH.dwh.dim_lots AS l WITH (NOLOCK) ON l.id = s4.lot_id
		LEFT OUTER JOIN apcsprodwh.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = l.package_id
		LEFT OUTER JOIN apcsprodwh.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = l.device_id
		LEFT OUTER JOIN APCSProDB.method.device_versions AS dv ON dv.device_id = l.device_id
		--LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = s4.machine_id
		LEFT OUTER JOIN APCSProDWH.dwh.item_labels AS il WITH (NOLOCK) ON il.name = 'fact_wip.production_category'
			AND il.val = l.production_category
		WHERE @local_date_from <= s4.std_from
			AND s4.std_to <= @local_date_to
		) AS tt ON tt.machine_id = x.value
	LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = x.value
	ORDER BY machine_number
		,setup_at;
END

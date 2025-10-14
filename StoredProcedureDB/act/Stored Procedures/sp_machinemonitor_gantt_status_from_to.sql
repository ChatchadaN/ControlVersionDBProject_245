
CREATE PROCEDURE [act].[sp_machinemonitor_gantt_status_from_to] (
	@date_from DATETIME,
	@date_to DATETIME,
	@machine_id_list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2019-12-12 13:42:41'
	--DECLARE @date_to DATETIME = '2019-12-13 13:42:41'
	--DECLARE @machine_id_list NVARCHAR(max) = '16,21,18,19,20,22,23'
	--!!IMPORTANT!! Replace parameter to local variables 
	--ローカル変数に置き換え。速度向上の為
	DECLARE @local_date_from DATETIME = @date_from
	DECLARE @local_date_to DATETIME = format(dateadd(DAY, 1, @date_to), 'yyyy-MM-dd 00:00:00')
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list

	--IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
	--	DROP TABLE #table;

	SELECT t2.*
	INTO #table
	FROM (
		SELECT t1.day_id AS day_id,
			t1.machine_id AS machine_id,
			t1.started_at AS started_at,
			CASE 
				WHEN t1.ended_at IS NULL
					THEN t1.latest_date
				ELSE t1.ended_at
				END AS finished_at,
			t1.online_state AS online_state,
			t1.run_state AS run_state,
			isnull(convert(DECIMAL(9, 1), datediff(SECOND, @local_date_from, t1.started_at)) / 60 / 60, NULL) AS start_point,
			isnull(convert(DECIMAL(9, 1), datediff(SECOND, t1.started_at, CASE 
							WHEN t1.ended_at IS NOT NULL
								THEN t1.ended_at
							ELSE t1.latest_date
							END)) / 60 / 60, NULL) AS end_diff
		FROM (
			SELECT rec.day_id AS day_id,
				rec.machine_id AS machine_id,
				rec.updated_at AS started_at,
				rec.ended_at AS ended_at,
				CASE 
					WHEN @local_date_to < GETDATE()
						THEN @local_date_to
					ELSE GETDATE()
					END AS latest_date,
				rec.online_state AS online_state,
				rec.run_state AS run_state
			FROM (
				SELECT ms.id AS id,
					ms.day_id AS day_id,
					ms.updated_at AS updated_at,
					ms.machine_id AS machine_id,
					ms.online_state AS online_state,
					ms.run_state AS run_state,
					ms.qc_state AS qc_state,
					ms.check_state AS chekc_state,
					lag(ms.updated_at,1,GETDATE()) OVER (
						PARTITION BY ms.machine_id ORDER BY ms.updated_at DESC
						) AS ended_at
				FROM APCSProDB.trans.machine_state_records AS ms WITH (NOLOCK)
				INNER JOIN (
					SELECT value
					FROM STRING_SPLIT(@local_machine_id_list, ',')
					) AS v ON v.value = ms.machine_id
				) AS rec
			) AS t1
		WHERE (
				(
					(ended_at IS NOT NULL)
					AND (@local_date_from <= ended_at)
					)
				OR (
					(@local_date_from <= started_at)
					AND (ended_at IS NULL)
					)
				)
		) AS t2;

	DECLARE @new_from DATETIME = (
			SELECT format(min(started_at), 'yyyy/MM/dd 00:00:00')
			FROM #table
			);
	DECLARE @new_to DATETIME = (
			SELECT format(max(finished_at), 'yyyy/MM/dd 00:00:00')
			FROM #table
			);

	SELECT dense_rank() OVER (
			ORDER BY x.value
			) AS machine_number,
		x.value AS machine_id,
		mc.name AS machine_name,
		mc.machine_model_id AS machine_model_id,
		tt.date_value AS date_value,
		tt.std_from AS std_from,
		tt.std_to AS std_to,
		isnull(tt.loop_index, 0) AS loop_index,
		tt.online_state AS online_state,
		tt.code AS code,
		tt.code_name AS code_name,
		tt.started_at AS started_at,
		tt.finished_at AS finished_at,
		isnull(tt.start_point, - 1) AS start_point,
		isnull(tt.end_diff, 0) AS end_diff,
		tt.original_started_at AS original_started_at,
		tt.original_finished_at AS original_finished_at
	FROM (
		SELECT CONVERT(int, value) as value
		FROM STRING_SPLIT(@local_machine_id_list, ',')
		) AS x
	LEFT OUTER JOIN (
		SELECT s4.machine_id AS machine_id,
			s4.date_value AS date_value,
			s4.std_from AS std_from,
			s4.std_to AS std_to,
			DATEDIFF(day, @local_date_from, s4.new_started_at) AS loop_index,
			s4.online_state AS online_state,
			s4.run_state AS code,
			eff.name AS code_name,
			s4.new_started_at AS started_at,
			s4.new_finished_at AS finished_at,
			s4.new_start_point AS start_point,
			s4.new_end_diff AS end_diff,
			s4.original_started_at AS original_started_at,
			s4.original_finished_at AS original_finished_at
		FROM (
			SELECT s3.date_value AS date_value,
				s3.std_from AS std_from,
				s3.std_to AS std_to,
				s3.machine_id AS machine_id,
				s3.online_state AS online_state,
				s3.run_state AS run_state,
				s3.new_started_at AS new_started_at,
				s3.new_finished_at AS new_finished_at,
				isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.std_from, s3.new_started_at)) / 60 / 60, NULL) AS new_start_point,
				isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.new_started_at, s3.new_finished_at)) / 60 / 60, NULL) AS new_end_diff,
				s3.original_started_at AS original_started_at,
				s3.original_finished_at AS original_finished_at
			FROM (
				SELECT s2.date_value AS date_value,
					s2.std_from AS std_from,
					s2.std_to AS std_to,
					s2.machine_id AS machine_id,
					s2.online_state AS online_state,
					s2.run_state AS run_state,
					CASE 
						WHEN s2.started_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.started_at
							AND s2.started_at <= s2.std_to
							THEN s2.started_at
						ELSE s2.std_to
						END AS new_started_at,
					CASE 
						WHEN s2.finished_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.finished_at
							AND s2.finished_at <= s2.std_to
							THEN s2.finished_at
						ELSE s2.std_to
						END AS new_finished_at,
					s2.started_at AS original_started_at,
					s2.finished_at AS original_finished_at
				FROM (
					SELECT s1.*,
						tt.*
					FROM (
						SELECT ddy.date_value AS date_value,
							DATEADD(day, ddy.id - (
									SELECT id
									FROM APCSProDWH.dwh.dim_days AS d WITH (NOLOCK)
									WHERE d.date_value = CONVERT(DATE, @new_from)
									), @local_date_from) AS std_from,
							DATEADD(day, ddy.id + 1 - (
									SELECT id
									FROM APCSProDWH.dwh.dim_days AS d WITH (NOLOCK)
									WHERE d.date_value = CONVERT(DATE, @new_from)
									), @local_date_from) AS std_to
						FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
						WHERE @new_from <= date_value
							AND date_value <= @new_to
						) AS s1
					LEFT OUTER JOIN #table AS tt ON NOT (tt.finished_at < s1.std_from)
						AND NOT (s1.std_to < tt.started_at)
					) AS s2
				) AS s3
			) AS s4
		LEFT OUTER JOIN apcsprodwh.[dwh].[dim_efficiencies] AS eff WITH (NOLOCK) ON eff.run_state = s4.run_state
		WHERE @local_date_from <= s4.std_from
			AND s4.std_to <= @local_date_to
		) AS tt ON tt.machine_id = x.value
	INNER JOIN apcsprodb.[mc].[machines] AS mc WITH (NOLOCK) ON mc.id = x.value
	ORDER BY machine_number,
		started_at;
END

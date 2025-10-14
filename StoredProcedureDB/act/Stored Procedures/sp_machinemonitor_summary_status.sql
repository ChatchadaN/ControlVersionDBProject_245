
CREATE PROCEDURE [act].[sp_machinemonitor_summary_status] (
	@date_from DATETIME,
	@date_to DATETIME,
	@machine_id_list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--DECLARE @machine_id_list NVARCHAR(max) = '21'
	--DECLARE @date_from DATETIME = '2019-09-06'
	--DECLARE @date_to DATETIME = '2019-09-07'

	DECLARE @local_date_from DATETIME = @date_from
	DECLARE @local_date_to DATETIME = case when getdate() < @date_to then format(GETDATE(),'yyyy-MM-dd 23:59:59') else @date_to end
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list


	DECLARE @from_to DECIMAL(9, 1) = isnull(convert(DECIMAL(9, 1), datediff(SECOND, @local_date_from, @local_date_to)) / 60 / 60, NULL);

	SELECT t4.*,
		isnull(100 * t4.sum_time_diff / @from_to, 0) AS sum_time_diff_percent,
		isnull(100 * t4.status_Others / @from_to, 0) AS status_Others_percent
	FROM (
		SELECT dense_rank() OVER (
				ORDER BY t3.machine_id
				) AS machine_number,
			t3.machine_id AS machine_id,
			t3.machine_name AS machine_name,
			t3.run_state AS code,
			t3.run_state_name AS code_name,
			isnull(sum(t3.time_diff), 0) AS sum_time_diff,
			(@from_to - sum(isnull(sum(t3.time_diff), 0)) OVER (PARTITION BY machine_id)) AS status_Others
		FROM (
			SELECT t2.*,
				CASE 
					WHEN (t2.started_at < @local_date_from)
						AND (@local_date_from < t2.finished_at)
						AND (t2.finished_at < @local_date_to)
						THEN (t2.start_point + t2.end_diff)
					WHEN (t2.started_at < @local_date_to)
						AND (@local_date_from < t2.started_at)
						AND (@local_date_to < t2.finished_at)
						THEN (@from_to - t2.start_point)
					WHEN (t2.started_at < @local_date_from)
						AND (@local_date_to < t2.finished_at)
						THEN @from_to
					ELSE t2.end_diff
					END AS time_diff
			FROM (
				SELECT dense_rank() OVER (
						ORDER BY dm.id
						) AS machine_number,
					dm.id AS machine_id,
					dm.name AS machine_name,
					dm.machine_model_id AS machine_model_id,
					t3.day_id AS day_id,
					t3.date_value AS date_value,
					t3.h AS h,
					t3.run_state AS run_state,
					t3.run_state_name AS run_state_name,
					t3.started_at AS started_at,
					t3.finished_at AS finished_at,
					--t3.start_point AS start_point,
					--t3.end_diff AS end_diff
					t3.start_point/60/60 AS start_point,
					t3.end_diff/60/60 AS end_diff
				FROM APCSProDWH.dwh.dim_machines AS dm
				LEFT OUTER JOIN (
					SELECT t2.*
					FROM (
						SELECT d.day_id AS day_id,
							d.date_value AS date_value,
							d.h AS h,
							t1.machine_id AS machine_id,
							t1.run_state AS run_state,
							t1.run_state_name AS run_state_name,
							t1.started_at AS started_at,
							t1.ended_at AS finished_at,
							--isnull(convert(DECIMAL(9, 1), datediff(SECOND, @date_from, t1.started_at)) / 60 / 60, NULL) AS start_point,
							--isnull(convert(DECIMAL(9, 1), datediff(SECOND, t1.started_at, t1.ended_at)) / 60 / 60, NULL) AS end_diff
							isnull(convert(DECIMAL(9, 1), datediff(SECOND, @local_date_from, t1.started_at)), NULL) AS start_point,
							isnull(convert(DECIMAL(9, 1), datediff(SECOND, t1.started_at, t1.ended_at)), NULL) AS end_diff
						FROM (
							SELECT ddy.id AS day_id,
								dh.code AS hour_code,
								ddy.date_value AS date_value,
								dh.h AS h
							FROM apcsprodwh.dwh.dim_days AS ddy
							CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
							) AS d
						LEFT OUTER JOIN (
							SELECT me.day_id AS day_id,
								datepart(HOUR, me.started_at) + 1 AS hour_code,
								me.machine_id AS machine_id,
								me.run_state AS run_state,
								me.started_at AS started_at,
								--現在もstatusに変更が無い状態ならば、nullになる為。(最小単位minute)
								isnull(me.ended_at, CASE 
										WHEN GETDATE() < @local_date_to
											THEN dateadd(MINUTE, DATEDIFF(MINUTE, 0, getdate()), 0)
										ELSE dateadd(MINUTE, DATEDIFF(MINUTE, 0, @local_date_to), 0)
										END) AS ended_at,
								de.name AS run_state_name
							FROM (
								SELECT ms.id AS id,
									ms.day_id AS day_id,
									ms.updated_at AS started_at,
									ms.machine_id AS machine_id,
									ms.online_state AS online_state,
									ms.run_state AS run_state,
									ms.qc_state AS qc_state,
									ms.check_state AS chekc_state,
									lag(ms.updated_at) OVER (
										PARTITION BY ms.machine_id ORDER BY ms.updated_at DESC
										) AS ended_at
								FROM APCSProDB.trans.machine_state_records AS ms WITH (NOLOCK)
								INNER JOIN (
									SELECT value
									FROM STRING_SPLIT(@local_machine_id_list, ',')
									) AS v ON v.value = ms.machine_id
								) AS me
							LEFT OUTER JOIN APCSProDWH.dwh.dim_efficiencies AS de ON de.run_state = me.run_state
							) AS t1 ON t1.day_id = d.day_id
							AND t1.hour_code = d.hour_code
						) AS t2
					WHERE (
							(
								(finished_at IS NOT NULL)
								AND (@local_date_from <= finished_at)
								)
							OR (
								(@local_date_from <= started_at)
								AND (finished_at IS NULL)
								)
							)
						--AND (start_point <= datediff(hour, @date_from, @date_to))
						AND (start_point <= datediff(SECOND, @local_date_from, @local_date_to))
					) AS t3 ON t3.machine_id = dm.id
				INNER JOIN (
					SELECT value
					FROM STRING_SPLIT(@local_machine_id_list, ',')
					) AS v ON v.value = dm.id
				) AS t2
			) AS t3
		GROUP BY t3.machine_id,
			t3.machine_name,
			t3.run_state,
			t3.run_state_name
		) AS t4
	ORDER BY machine_number,
		code
END

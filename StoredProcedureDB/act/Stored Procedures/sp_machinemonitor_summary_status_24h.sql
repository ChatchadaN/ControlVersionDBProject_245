
CREATE PROCEDURE [act].[sp_machinemonitor_summary_status_24h] (
	@date_from DATETIME,
	@date_to DATETIME,
	@machine_id_list NVARCHAR(max) = NULL
	)
	--WITH RECOMPILE
AS
BEGIN
	--DECLARE @date_from DATETIME = '2019-11-01 00:00:00'
	--DECLARE @date_to DATETIME = '2019-12-09 23:59:00'
	--DECLARE @machine_id_list NVARCHAR(max) = '16,21,18,19,20,22,23,307'
	--DECLARE @machine_id_list NVARCHAR(max) = '307'
	--!!IMPORTANT!! Replace parameter to local variables 
	--ローカル変数に置き換え。速度向上の為
	DECLARE @local_date_from DATETIME = @date_from
	DECLARE @local_date_to DATETIME = format(dateadd(DAY, 1, @date_to), 'yyyy-MM-dd 00:00:00')
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list

	IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
		DROP TABLE #table;

	IF OBJECT_ID(N'tempdb..#table_proc_idle', N'U') IS NOT NULL
		DROP TABLE #table_proc_idle;

	IF OBJECT_ID(N'tempdb..#table_base', N'U') IS NOT NULL
		DROP TABLE #table_base;

	--IF OBJECT_ID(N'tempdb..#table_p', N'U') IS NOT NULL
	--	DROP TABLE #table_p;
	IF OBJECT_ID(N'tempdb..#table_f', N'U') IS NOT NULL
		DROP TABLE #table_f;

	IF OBJECT_ID(N'tempdb..#table_process', N'U') IS NOT NULL
		DROP TABLE #table_process;

	IF OBJECT_ID(N'tempdb..#table_idle', N'U') IS NOT NULL
		DROP TABLE #table_idle;

	SELECT tt.process_job_id AS process_job_id,
		convert(INT, x.value) AS machine_id,
		isnull(tt.lot_id, - 1) AS lot_id,
		tt.setup_at AS setup_at,
		CASE 
			WHEN tt.machine_id IS NULL
				THEN @local_date_from
			ELSE started_at
			END AS started_at,
		CASE 
			WHEN tt.machine_id IS NULL
				THEN @local_date_to
			ELSE finished_at
			END AS finished_at
	INTO #table
	FROM (
		SELECT value
		FROM STRING_SPLIT(@local_machine_id_list, ',')
		) AS x
	LEFT OUTER JOIN (
		SELECT t4.process_job_id AS process_job_id,
			t4.machine_id AS machine_id,
			t4.lot_id AS lot_id,
			t4.setup_at AS setup_at,
			t4.started_at AS started_at,
			CASE 
				WHEN t4.finished_at IS NOT NULL
					THEN t4.finished_at
				ELSE lead(t4.setup_at, 1, t4.latest_date) OVER (
						PARTITION BY t4.machine_id ORDER BY t4.setup_at
						)
				END AS finished_at
		FROM (
			SELECT t3.process_job_id AS process_job_id,
				t3.machine_id AS machine_id,
				t3.lot_id AS lot_id,
				t3.setup_at AS setup_at,
				t3.started_at AS started_at,
				t3.finished_at AS finished_at,
				t3.latest_date AS latest_date
			FROM (
				SELECT t2.process_job_id AS process_job_id,
					t2.machine_id AS machine_id,
					t2.lot_id AS lot_id,
					t2.setup_at AS setup_at,
					t2.started_at AS started_at,
					t2.finished_at AS finished_at,
					t2.latest_date AS latest_date
				FROM (
					SELECT t1.process_job_id AS process_job_id,
						t1.machine_id AS machine_id,
						t1.lot_id AS lot_id,
						t1.setup_at AS setup_at,
						t1.started_at AS started_at,
						t1.finished_at AS finished_at,
						t1.latest_date AS latest_date
					FROM (
						SELECT pj.id AS process_job_id,
							pj.machine_id AS machine_id,
							pj.setup_at AS setup_at,
							pj.started_at AS started_at,
							pj.finished_at AS finished_at,
							CASE 
								WHEN @local_date_to < GETDATE()
									THEN @local_date_to
								ELSE GETDATE()
								END AS latest_date,
							pl.lot_id AS lot_id
						FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
						INNER JOIN APCSProDWH.dwh.view_fact_pj_lots AS pl WITH (NOLOCK) ON pl.pj_id = pj.id
						INNER JOIN (
							SELECT value
							FROM STRING_SPLIT(@local_machine_id_list, ',')
							) AS v ON v.value = pj.machine_id
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
					) AS t2
				) AS t3
			) AS t4
		) AS tt ON tt.machine_id = x.value

	DECLARE @new_from DATE = (
			SELECT isnull(convert(DATE, min(setup_at)),convert(DATE, min(started_at)))
			FROM #table
			);
	DECLARE @new_to DATE = (
			SELECT convert(DATE, max(finished_at))
			FROM #table
			);

	--Lot history
	SELECT s2.date_value AS date_value,
		s2.machine_id AS machine_id,
		s2.lot_id AS lot_id,
		s2.std_from AS std_from,
		s2.std_to AS std_to,
		s2.original_started_at AS original_started_at,
		s2.original_finished_at AS original_finished_at,
		--new datetime
		CASE 
			WHEN s2.original_started_at < s2.std_from
				THEN s2.std_from
			WHEN s2.std_from <= s2.original_started_at
				AND s2.original_started_at <= s2.std_to
				THEN s2.original_started_at
			ELSE s2.std_to
			END AS started_at,
		CASE 
			WHEN s2.original_finished_at < s2.std_from
				THEN s2.std_from
			WHEN s2.std_from <= s2.original_finished_at
				AND s2.original_finished_at <= s2.std_to
				THEN s2.original_finished_at
			ELSE s2.std_to
			END AS finished_at
	INTO #table_process
	FROM (
		SELECT convert(DATE, s1.std_from) AS date_value,
			tt.machine_id AS machine_id,
			tt.lot_id AS lot_id,
			s1.std_from AS std_from,
			s1.std_to AS std_to,
			tt.started_at AS original_started_at,
			tt.finished_at AS original_finished_at
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
		LEFT OUTER JOIN #table AS tt ON s1.std_from <= tt.finished_at
			AND tt.started_at <= s1.std_to
		) AS s2;

	--ORDER BY std_from,
	--	started_at
	--Idle history
	SELECT p2.date_value AS date_value,
		p2.machine_id AS machine_id,
		p2.lot_id AS lot_id,
		p2.std_from AS std_from,
		p2.std_to AS std_to,
		p2.original_started_at AS original_started_at,
		p2.original_finished_at AS original_finished_at,
		p2.idle_started_at AS idle_started_at,
		p2.idle_finished_at AS idle_finished_at
	INTO #table_idle
	FROM (
		SELECT p1.date_value AS date_value,
			p1.machine_id AS machine_id,
			p1.lot_id AS lot_id,
			p1.std_from AS std_from,
			p1.std_to AS std_to,
			p1.original_started_at AS original_started_at,
			p1.original_finished_at AS original_finished_at,
			p1.idle_started_at AS idle_started_at,
			p1.idle_finished_at AS idle_finished_at
		FROM (
			SELECT p.date_value AS date_value,
				p.machine_id AS machine_id,
				- 1 AS lot_id,
				p.std_from AS std_from,
				p.std_to AS std_to,
				p.original_started_at AS original_started_at,
				p.original_finished_at AS original_finished_at,
				lag(p.finished_at, 1, p.std_from) OVER (
					PARTITION BY p.machine_id ORDER BY p.started_at
					) AS idle_started_at,
				p.started_at AS idle_finished_at
			FROM #table_process AS p
			) AS p1
		WHERE p1.idle_started_at <> p1.idle_finished_at
		) AS p2;

	--ORDER BY p2.std_from,
	--	p2.idle_started_at;
	SELECT date_value AS date_value,
		machine_id AS machine_id,
		lot_id AS lot_id,
		std_from AS std_from,
		std_to AS std_to,
		original_started_at AS original_started_at,
		original_finished_at AS original_finished_at,
		started_at AS started_at,
		finished_at AS finished_at
	INTO #table_proc_idle
	FROM #table_process
	
	UNION ALL
	
	SELECT i2.date_value AS date_value,
		i2.machine_id AS machine_id,
		- 1 AS lot_id,
		i2.std_from AS std_from,
		i2.std_to AS std_to,
		i2.idle_started_at AS idle_started_at,
		i2.idle_finished_at AS idle_finished_at,
		CASE 
			WHEN i2.idle_started_at < i2.std_from
				THEN i2.std_from
			WHEN i2.std_from <= i2.idle_started_at
				AND i2.idle_started_at <= i2.std_to
				THEN i2.idle_started_at
			ELSE i2.std_to
			END AS started_at,
		CASE 
			WHEN i2.idle_finished_at < i2.std_from
				THEN i2.std_from
			WHEN i2.std_from <= i2.idle_finished_at
				AND i2.idle_finished_at <= i2.std_to
				THEN i2.idle_finished_at
			ELSE i2.std_to
			END AS finished_at
	FROM (
		SELECT convert(DATE, i.std_from) AS date_value,
			i.std_from AS std_from,
			i.std_to AS std_to,
			ti.machine_id AS machine_id,
			ti.idle_started_at AS idle_started_at,
			ti.idle_finished_at AS idle_finished_at
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
			) AS i
		LEFT OUTER JOIN #table_idle AS ti ON i.std_from <= ti.idle_finished_at
			AND ti.idle_started_at <= i.std_to
		) AS i2;

	--ORDER BY started_at;
	--Latest FromTo
	SELECT tbl3.date_value AS date_value,
		tbl3.machine_id AS machine_id,
		tbl3.lot_id AS lot_id,
		tbl3.std_from AS std_from,
		tbl3.std_to AS std_to,
		tbl3.original_started_at AS original_started_at,
		tbl3.original_finished_at AS original_finished_at,
		tbl3.started_at AS started_at,
		tbl3.finished_at AS finished_at
	INTO #table_f
	FROM (
		SELECT tbl2.date_value AS date_value,
			tbl2.machine_id AS machine_id,
			tbl2.lot_id AS lot_id,
			tbl2.std_from AS std_from,
			tbl2.std_to AS std_to,
			tbl2.original_started_at AS original_started_at,
			tbl2.original_finished_at AS original_finished_at,
			tbl2.started_at AS started_at,
			tbl2.finished_at AS finished_at,
			ROW_NUMBER() OVER (
				PARTITION BY tbl2.machine_id ORDER BY tbl2.started_at DESC
				) AS f_rank
		FROM (
			SELECT tbl.date_value AS date_value,
				tbl.machine_id AS machine_id,
				- 1 AS lot_id,
				tbl.std_from AS std_from,
				tbl.std_to AS std_to,
				tbl.original_started_at AS original_started_at,
				tbl.original_finished_at AS original_finished_at,
				tbl.finished_at AS started_at,
				lead(tbl.started_at, 1, CASE 
						WHEN GETDATE() < tbl.std_to
							THEN GETDATE()
						ELSE tbl.std_to
						END) OVER (
					PARTITION BY tbl.machine_id ORDER BY tbl.started_at
					) AS finished_at
			FROM #table_proc_idle AS tbl
			) AS tbl2
		) AS tbl3
	WHERE f_rank = 1;

	SELECT dense_rank() OVER (
			ORDER BY machine_id
			) AS machine_number,
		date_value AS date_value,
		machine_id AS machine_id,
		lot_id AS lot_id,
		std_from AS std_from,
		std_to AS std_to,
		DATEDIFF(second, std_from, std_to) AS span,
		original_started_at AS original_started_at,
		original_finished_at AS original_finished_at,
		started_at AS started_at,
		finished_at AS finished_at
	INTO #table_base
	FROM (
		SELECT date_value AS date_value,
			machine_id AS machine_id,
			lot_id AS lot_id,
			std_from AS std_from,
			std_to AS std_to,
			original_started_at AS original_started_at,
			original_finished_at AS original_finished_at,
			started_at AS started_at,
			finished_at AS finished_at
		FROM #table_proc_idle
		
		UNION ALL
		
		SELECT date_value AS date_value,
			machine_id AS machine_id,
			lot_id AS lot_id,
			std_from AS std_from,
			std_to AS std_to,
			original_started_at AS original_started_at,
			original_finished_at AS original_finished_at,
			started_at AS started_at,
			finished_at AS finished_at
		FROM #table_f
		) AS t
	WHERE machine_id IS NOT NULL
		AND (
			@local_date_from <= std_from
			AND std_to <= @local_date_to
			);

	--ORDER BY machine_number,
	--	started_at
	SELECT t4.machine_number AS machine_number,
		t4.machine_id AS machine_id,
		t4.machine_name as machine_name,
		t4.lot_id AS lot_id,
		t4.lot_no as lot_no,
		t4.started_at AS started_at,
		t4.finished_at AS finished_at,
		t4.state_started_at AS state_started_at,
		t4.state_finished_at AS state_finished_at,
		t4.run_state AS run_state,
		t4.process_flag AS process_flag,
		t4.diff_s AS diff_s,
		t4.std_from AS std_from,
		--t4.span AS span,
		sum(isnull(t4.process_sum,0)) over(partition by t4.machine_id) AS span,
		t4.lot_sum AS std_all_diff_s,
		t4.process_sum AS process_sum,
		--Lot処理中とそれ以外で稼働状態毎に分類
		t4.percent_effic_class AS percent_effic_class,
		--Lot処理関係なく日ごとで稼働状態毎に分類
		t4.percent_effic_total AS percent_effic_total,
		t4.effic_class_rank AS effic_class_rank,
		row_number() OVER (
				PARTITION BY t4.machine_id,
				t4.std_from,
				t4.run_state ORDER BY t4.state_started_at
				) AS effic_total_rank
	FROM (
		SELECT t3.machine_number AS machine_number,
			t3.machine_id AS machine_id,
			dm.name as machine_name,
			t3.lot_id AS lot_id,
			l.lot_no as lot_no,
			t3.started_at AS started_at,
			t3.finished_at AS finished_at,
			t3.state_started_at AS state_started_at,
			t3.state_finished_at AS state_finished_at,
			t3.run_state AS run_state,
			t3.process_flag AS process_flag,
			t3.diff_s AS diff_s,
			t3.std_from AS std_from,
			t3.span AS span,
			t3.lot_sum AS lot_sum,
			t3.process_sum AS process_sum,
			convert(DECIMAL(9, 1), sum(t3.diff_s) OVER (
					PARTITION BY t3.machine_id,
					t3.std_from,
					t3.process_flag,
					t3.run_state
					)) / t3.lot_sum * 100 AS percent_effic_class,
			convert(DECIMAL(9, 1), sum(t3.diff_s) OVER (
					PARTITION BY t3.machine_id,
					t3.std_from,
					t3.run_state
					)) / nullif(sum(t3.diff_s) OVER (
					PARTITION BY t3.machine_id,
					t3.std_from
					), 0) * 100 AS percent_effic_total,
			ROW_NUMBER() OVER (
				PARTITION BY t3.machine_id,
				t3.std_from,
				t3.run_state,
				t3.process_flag ORDER BY t3.state_started_at
				) AS effic_class_rank
		FROM (
			SELECT t2.machine_number AS machine_number,
				t2.machine_id AS machine_id,
				t2.lot_id AS lot_id,
				t2.started_at AS started_at,
				t2.finished_at AS finished_at,
				t2.state_started_at AS state_started_at,
				t2.state_finished_at AS state_finished_at,
				t2.run_state AS run_state,
				t2.process_flag AS process_flag,
				isnull(case when t2.diff_s >=0 then t2.diff_s else 0 end, 0) AS diff_s,
				t2.std_from AS std_from,
				t2.span AS span,
				nullif(sum(case when t2.diff_s >=0 then t2.diff_s else 0 end) OVER (
						PARTITION BY t2.machine_id,
						t2.std_from,
						t2.process_flag
						), 0) AS lot_sum,
				nullif(sum(case when t2.diff_s >=0 then t2.diff_s else 0 end) OVER (
						PARTITION BY t2.machine_id,
						t2.std_from,
						t2.process_flag,
						t2.run_state
						), 0) AS process_sum
			FROM (
				SELECT t1.machine_number AS machine_number,
					t1.machine_id AS machine_id,
					t1.lot_id AS lot_id,
					t1.started_at AS started_at,
					t1.finished_at AS finished_at,
					t1.state_started_at AS state_started_at,
					t1.state_finished_at AS state_finished_at,
					t1.run_state AS run_state,
					t1.process_flag AS process_flag,
					isnull(DATEDIFF(SECOND, t1.state_started_at, t1.state_finished_at), 0) AS diff_s,
					t1.std_from AS std_from,
					--t1.std_to as std_to,
					t1.span AS span
				FROM (
					SELECT t0.machine_number AS machine_number,
						t0.machine_id AS machine_id,
						t0.lot_id AS lot_id,
						t0.started_at AS started_at,
						t0.finished_at AS finished_at,
						CASE 
							WHEN ms.state_started_at <= t0.started_at
								THEN t0.started_at
							ELSE ms.state_started_at
							END AS state_started_at,
						CASE 
							WHEN t0.finished_at <= ms.state_finished_at
								THEN CASE 
										WHEN GETDATE() <= t0.finished_at
											THEN getdate()
										ELSE t0.finished_at
										END
							ELSE ms.state_finished_at
							END AS state_finished_at,
						ms.run_state AS run_state,
						CASE 
							WHEN t0.lot_id > 0
								THEN 1
							ELSE 0
							END AS process_flag,
						t0.std_from AS std_from,
						t0.std_to AS std_to,
						t0.span AS span
					FROM (
						SELECT tb.machine_number AS machine_number,
							tb.date_value AS date_value,
							tb.machine_id AS machine_id,
							tb.lot_id AS lot_id,
							tb.started_at AS started_at,
							tb.finished_at AS finished_at,
							tb.std_from AS std_from,
							tb.std_to AS std_to,
							tb.span AS span
						FROM #table_base AS tb
						) AS t0
					LEFT OUTER JOIN (
						SELECT msr.machine_id AS machine_id,
							msr.updated_at AS state_started_at,
							lead(msr.updated_at, 1, @local_date_to) OVER (
								PARTITION BY msr.machine_id ORDER BY msr.updated_at
								) AS state_finished_at,
							msr.run_state AS run_state
						FROM (
							--machine_state_records : previous @from
							SELECT rec3.machine_id,
								rec3.updated_at,
								rec3.run_state
							FROM (
								SELECT ROW_NUMBER() OVER (
										PARTITION BY rec2.machine_id ORDER BY rec2.updated_at DESC
										) AS rank_rec,
									rec2.updated_at AS updated_at,
									rec2.run_state AS run_state,
									rec2.machine_id AS machine_id
								FROM (
									SELECT rec.updated_at AS updated_at,
										rec.run_state AS run_state,
										rec.machine_id AS machine_id
									FROM APCSProDB.trans.machine_state_records AS rec WITH (NOLOCK)
									INNER JOIN (
										SELECT value
										FROM STRING_SPLIT(@local_machine_id_list, ',')
										) AS v ON v.value = rec.machine_id
									WHERE rec.updated_at <= @local_date_from
									) AS rec2
								) AS rec3
							WHERE rec3.rank_rec = 1
							
							UNION ALL
							
							--machine_state_records : @from @to
							SELECT r.machine_id AS machine_id,
								r.updated_at AS updated_at,
								r.run_state AS run_state
							FROM APCSProDB.trans.machine_state_records AS r WITH (NOLOCK)
							INNER JOIN (
								SELECT value
								FROM STRING_SPLIT(@local_machine_id_list, ',')
								) AS v ON v.value = r.machine_id
							WHERE @local_date_from <= r.updated_at
								AND r.updated_at <= @local_date_to
							) AS msr
						) ms ON ms.machine_id = t0.machine_id
						AND t0.started_at <= ms.state_finished_at
						AND t0.finished_at >= ms.state_started_at
					) AS t1
				) AS t2
			) AS t3
			left JOIN APCSProDWH.dwh.dim_lots AS l WITH (NOLOCK) ON l.id = t3.lot_id
			LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t3.machine_id
		) AS t4
	WHERE effic_class_rank = 1
	ORDER BY machine_number,
		started_at,
		state_started_at;
END


CREATE PROCEDURE [act].[sp_machineefficiency_transition] (
	@date_from DATETIME,
	@date_to DATETIME,
	@machine_id_list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
	--	DROP TABLE #table;
	--IF OBJECT_ID(N'tempdb..#date_not_changed', N'U') IS NOT NULL
	--	DROP TABLE #date_not_changed;
	--IF OBJECT_ID(N'tempdb..#date_changed', N'U') IS NOT NULL
	--	DROP TABLE #date_changed;
	--IF OBJECT_ID(N'tempdb..#effic', N'U') IS NOT NULL
	--	DROP TABLE #effic;
	--DECLARE @machine_id_list NVARCHAR(max) = '18'
	--DECLARE @date_from DATETIME = '2019-11-01'
	--DECLARE @date_to DATETIME = '2019-11-07'

	DECLARE @fr_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = convert(DATE, @date_from)
			);
	DECLARE @to_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = convert(DATE, @date_to)
			);
	DECLARE @machines INT = (
			SELECT count(value)
			FROM STRING_SPLIT(@machine_id_list, ',')
			);

	SELECT t3.*
	INTO #table
	FROM (
		SELECT t2.*,
			DATEDIFF(day, t2.max_started_at, t2.ended_at) AS f
		FROM (
			SELECT *,
				max(t1.started_at) OVER (PARTITION BY t1.day_id) AS max_started_at
			FROM (
				SELECT me.day_id AS day_id,
					datepart(HOUR, me.started_at) + 1 AS hour_code,
					me.machine_id AS machine_id,
					me.run_state AS code,
					me.started_at AS started_at,
					--現在もstatusに変更が無い状態ならば、nullになる為。(最小単位minute)
					isnull(me.ended_at, CASE 
							WHEN GETDATE() < @date_to
								THEN dateadd(MINUTE, DATEDIFF(MINUTE, 0, getdate()), 0)
							ELSE dateadd(MINUTE, DATEDIFF(MINUTE, 0, @date_to), 0)
							END) AS ended_at
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
						FROM STRING_SPLIT(@machine_id_list, ',')
						) AS v ON v.value = ms.machine_id
					) AS me
				--LEFT OUTER JOIN APCSProDWH.dwh.dim_efficiencies AS de ON de.run_state = me.run_state
				WHERE (
						day_id BETWEEN @fr_date - 1
							AND @to_date + 1
						)
				) AS t1
			) AS t2
		) AS t3;

	--日付またぎレコードをのぞいたデータ。後で分割した日付またぎレコードをinsertする
	SELECT *
	INTO #date_not_changed
	FROM #table
	WHERE f = 0;

	--日付またぎレコードのみ抽出
	SELECT *
	INTO #date_changed
	FROM #table
	WHERE f > 0;

	DECLARE @cur CURSOR;DECLARE @error_flg INT = 0
		--
		DECLARE @day_id INT DECLARE @hour_code INT DECLARE @machine_id INT DECLARE @code INT DECLARE @started_at DATETIME DECLARE @ended_at DATETIME DECLARE @max_started_at DATETIME DECLARE @f INT
		--
		SET @cur = CURSOR
	FOR
	SELECT *
	FROM #date_changed

	OPEN @cur

	FETCH NEXT
	FROM @cur
	INTO @day_id,
		@hour_code,
		@machine_id,
		@code,
		@started_at,
		@ended_at,
		@max_started_at,
		@f;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--エラー処理
		SET @error_flg = @@ERROR

		IF @error_flg <> 0 --エラーが発生したら
		BEGIN
			CLOSE @cur

			--カーソルクローズ
			DEALLOCATE @cur

			--リソース開放
			RETURN
		END

		--
		DECLARE @temp_day_id INT
		DECLARE @temp_hour_code INT
		DECLARE @temp_machine_id INT
		DECLARE @temp_code INT
		DECLARE @temp_started_at DATETIME
		DECLARE @temp_ended_at DATETIME
		DECLARE @temp_max_started_at DATETIME
		DECLARE @temp_f INT = @f

		--@temp_f : またぎ日数
		WHILE (@temp_f > 0)
		BEGIN
			SET @temp_f = @temp_f - 1;
			SET @temp_day_id = @day_id;
			SET @temp_hour_code = @hour_code;
			SET @temp_machine_id = @machine_id;
			SET @temp_code = @code;
			SET @temp_started_at = @started_at;
			SET @temp_ended_at = FORMAT(dateadd(day, 1, @started_at), 'yyyy-MM-dd 00:00:00.000');
			SET @temp_max_started_at = @max_started_at;

			--日付またぎ前半部(次の日の00:00:00まで)
			INSERT INTO #date_not_changed (
				day_id,
				hour_code,
				machine_id,
				code,
				started_at,
				ended_at,
				max_started_at,
				f
				)
			VALUES (
				@temp_day_id,
				@temp_hour_code,
				@temp_machine_id,
				@temp_code,
				@temp_started_at,
				@temp_ended_at,
				@temp_max_started_at,
				0
				);

			--日付またぎ後半部(00:00:00~)
			SET @temp_day_id = @day_id + 1;
			SET @temp_hour_code = 1;
			SET @temp_machine_id = @machine_id;
			SET @temp_code = @code;
			SET @temp_started_at = FORMAT(dateadd(day, 1, @started_at), 'yyyy-MM-dd 00:00:00.000');
			SET @temp_ended_at = @ended_at;
			SET @temp_max_started_at = @max_started_at;

			IF @temp_f = 0
			BEGIN
				INSERT INTO #date_not_changed (
					day_id,
					hour_code,
					machine_id,
					code,
					started_at,
					ended_at,
					max_started_at,
					f
					)
				VALUES (
					@temp_day_id,
					@temp_hour_code,
					@temp_machine_id,
					@temp_code,
					@temp_started_at,
					@temp_ended_at,
					@temp_max_started_at,
					@temp_f
					);
			END

			--
			SET @day_id = @temp_day_id;
			SET @hour_code = @temp_hour_code;
			SET @machine_id = @temp_machine_id;
			SET @code = @temp_code;
			SET @started_at = @temp_started_at;
			SET @ended_at = @temp_ended_at;
			SET @max_started_at = @temp_max_started_at;
		END

		--次のレコードの取り出し
		FETCH NEXT
		FROM @cur
		INTO @day_id,
			@hour_code,
			@machine_id,
			@code,
			@started_at,
			@ended_at,
			@max_started_at,
			@f;
	END

	CLOSE @cur

	DEALLOCATE @cur

	SELECT day_id,
		hour_code,
		machine_id,
		code,
		started_at,
		ended_at
	INTO #effic
	FROM #date_not_changed
	WHERE day_id BETWEEN @fr_date
			AND @to_date
	ORDER BY day_id,
		hour_code,
		started_at;

	SELECT t3.day_id AS day_id,
		t3.y AS y,
		t3.m AS m,
		t3.week_no AS week_no,
		DATEADD(DAY, 1 - DATEPART(WEEKDAY, t3.date_value), CAST(t3.date_value AS DATE)) AS week_start_day,
		t3.date_value AS date_value,
		t3.day_id_rank AS day_id_rank,
		t3.code AS code,
		de.name AS code_name,
		t3.day_duration_h AS day_duration_percent,
		t3.day_duration_h_others AS day_duration_percent_others,
		t3.week_rank AS week_rank,
		t3.week_duration AS week_duration_percent,
		t3.week_duration_others AS week_duration_percent_others,
		t3.month_rank AS month_rank,
		t3.month_duration AS month_duration_percent,
		t3.month_duration_others AS month_duration_percent_others
	FROM (
		SELECT t2.day_id AS day_id,
			t2.y AS y,
			t2.m AS m,
			t2.week_no AS week_no,
			t2.d AS d,
			t2.date_value AS date_value,
			t2.day_id_rank AS day_id_rank,
			t2.code AS code,
			t2.day_duration_h / (24.0 * @machines) * 100 AS day_duration_h,
			t2.day_duration_h_others / (24.0 * @machines) * 100 AS day_duration_h_others,
			--week
			row_number() OVER (
				PARTITION BY t2.y,
				t2.week_no,
				t2.code ORDER BY t2.y,
					t2.week_no
				) AS week_rank,
			sum(t2.day_duration_h) OVER (
				PARTITION BY t2.y,
				t2.week_no,
				t2.code
				) / (24.0 * @machines) / 7 * 100 AS week_duration,
			sum(CASE 
					WHEN t2.day_id_rank = 1
						THEN t2.day_duration_h_others
					ELSE 0
					END) OVER (
				PARTITION BY t2.y,
				t2.week_no
				) / (24.0 * @machines) / 7 * 100 AS week_duration_others,
			--month
			row_number() OVER (
				PARTITION BY t2.y,
				t2.m,
				t2.code ORDER BY t2.y,
					t2.m,
					t2.week_no
				) AS month_rank,
			sum(t2.day_duration_h) OVER (
				PARTITION BY t2.y,
				t2.m,
				t2.code
				) / (24.0 * @machines) / (
				SELECT DAY(EOMONTH(DATEFROMPARTS(t2.y, t2.m, t2.d)))
				) * 100 AS month_duration,
			sum(CASE 
					WHEN t2.day_id_rank = 1
						THEN t2.day_duration_h_others
					ELSE 0
					END) OVER (
				PARTITION BY t2.y,
				t2.m
				) / (24.0 * @machines) / (
				SELECT DAY(EOMONTH(DATEFROMPARTS(t2.y, t2.m, t2.d)))
				) * 100 AS month_duration_others
		FROM (
			SELECT t1.day_id AS day_id,
				t1.y AS y,
				t1.m AS m,
				t1.d AS d,
				t1.week_no AS week_no,
				t1.date_value AS date_value,
				ROW_NUMBER() OVER (
					PARTITION BY t1.day_id ORDER BY t1.day_id
					) AS day_id_rank,
				t1.code AS code,
				sum(t1.duration_h) AS day_duration_h,
				(24.0 * @machines) - sum(sum(t1.duration_h)) OVER (PARTITION BY t1.day_id) AS day_duration_h_others
			FROM (
				SELECT d.day_id AS day_id,
					d.hour_code AS hour_code,
					d.y AS y,
					d.m AS m,
					d.week_no AS week_no,
					d.d AS d,
					d.date_value AS date_value,
					d.h AS h,
					ef.machine_id AS machine_id,
					ef.code AS code,
					ef.started_at AS started_at,
					ef.ended_at AS ended_at,
					convert(DECIMAL(9, 1), isnull(datediff(second, ef.started_at, ef.ended_at), 0)) / 60 / 60 AS duration_h
				FROM (
					SELECT ddy.id AS day_id,
						dh.code AS hour_code,
						ddy.date_value AS date_value,
						ddy.y AS y,
						ddy.m AS m,
						ddy.quarter_no AS quarter_no,
						ddy.week_no AS week_no,
						ddy.d,
						dh.h AS h
					FROM apcsprodwh.dwh.dim_days AS ddy
					CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
					) AS d
				LEFT OUTER JOIN #effic AS ef ON ef.day_id = d.day_id
					AND ef.hour_code = d.hour_code
				WHERE d.day_id BETWEEN @fr_date
						AND @to_date
				) AS t1
			GROUP BY t1.day_id,
				t1.y,
				t1.m,
				t1.d,
				t1.week_no,
				t1.date_value,
				t1.code
			) AS t2
		) AS t3
	LEFT OUTER JOIN APCSProDWH.dwh.dim_efficiencies AS de WITH (NOLOCK) ON de.code = t3.code
	--where week_rank=1
	--where month_rank = 1
	ORDER BY day_id,
		code
END

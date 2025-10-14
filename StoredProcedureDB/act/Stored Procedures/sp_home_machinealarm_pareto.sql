
CREATE PROCEDURE [act].[sp_home_machinealarm_pareto] (
	@machine_group_id INT = NULL,
	@machine_model_id INT = NULL,
	@machine_id INT = NULL,
	@periodAlarm INT = NULL
	)
AS
BEGIN
	DECLARE @top_group INT = NULL;
	DECLARE @top_model INT = NULL;

	IF OBJECT_ID(N'tempdb..#t_latest_alarms_info', N'U') IS NOT NULL
		DROP TABLE #t_latest_alarms_info;

	SELECT
		--per mc group
		sum(1) OVER (PARTITION BY t2.machine_group_id) AS group_alarm_cnt,
		ROW_NUMBER() OVER (
			PARTITION BY t2.machine_group_id ORDER BY t2.updated_at
			) AS group_alarm_rank,
		--per mc model
		sum(1) OVER (PARTITION BY t2.machine_model_id) AS model_alarm_cnt,
		ROW_NUMBER() OVER (
			PARTITION BY t2.machine_model_id ORDER BY t2.updated_at
			) AS model_alarm_rank,
		--per mc
		sum(1) OVER (PARTITION BY t2.machine_id) AS mc_alarm_cnt,
		ROW_NUMBER() OVER (
			PARTITION BY t2.machine_id ORDER BY t2.updated_at
			) AS mc_alarm_rank,
		--sum
		sum(1) OVER () AS sum_alarm_cnt,
		t2.id AS id,
		t2.updated_at AS updated_at,
		t2.machine_group_id AS machine_group_id,
		t2.machine_group_name AS machine_group_name,
		t2.machine_model_id AS machine_model_id,
		t2.machine_model_name AS machine_model_name,
		t2.machine_id AS machine_id,
		t2.machine_name AS machine_name,
		t2.model_alarm_id AS model_alarm_id,
		t2.alarm_text AS alarm_text,
		t2.alarm_on_at AS alarm_on_at,
		t2.alarm_off_at AS alarm_off_at,
		t2.started_at AS started_at,
		t2.repeat_count AS repeat_count
	INTO #t_latest_alarms_info
	FROM (
		SELECT t1.id AS id,
			t1.updated_at AS updated_at,
			t1.machine_group_id AS machine_group_id,
			t1.machine_group_name AS machine_group_name,
			t1.machine_model_id AS machine_model_id,
			t1.machine_model_name AS machine_model_name,
			t1.machine_id AS machine_id,
			t1.machine_name AS machine_name,
			t1.model_alarm_id AS model_alarm_id,
			t1.alarm_text AS alarm_text,
			t1.alarm_on_at AS alarm_on_at,
			t1.alarm_off_at AS alarm_off_at,
			t1.started_at AS started_at,
			t1.repeat_count AS repeat_count
		FROM (
			SELECT t.id AS id,
				t.updated_at AS updated_at,
				gm.group_id AS machine_group_id,
				mg.name AS machine_group_name,
				mm.id AS machine_model_id,
				mm.name AS machine_model_name,
				t.machine_id AS machine_id,
				dm.name AS machine_name,
				t.model_alarm_id AS model_alarm_id,
				at.alarm_text AS alarm_text,
				t.alarm_on_at AS alarm_on_at,
				t.alarm_off_at AS alarm_off_at,
				t.started_at AS started_at,
				t.repeat_count AS repeat_count
			FROM (
				SELECT mar.id AS id,
					mar.updated_at AS updated_at,
					mar.machine_id AS machine_id,
					mar.model_alarm_id AS model_alarm_id,
					mar.alarm_on_at AS alarm_on_at,
					mar.alarm_off_at AS alarm_off_at,
					mar.started_at AS started_at,
					mar.repeat_count AS repeat_count
				FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
				WHERE dateadd(hour, - isnull(@periodAlarm,1), getdate()) <= mar.alarm_on_at
					AND mar.alarm_on_at <= getdate()
				) AS t
			INNER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t.machine_id
			LEFT JOIN APCSProDWH.dwh.dim_machine_models AS mm WITH (NOLOCK) ON mm.id = dm.machine_model_id
			LEFT JOIN APCSProDWH.dwh.dim_mc_group_models AS gm WITH (NOLOCK) ON gm.model_id = dm.machine_model_id
			LEFT JOIN APCSProDWH.dwh.dim_machine_groups AS mg WITH (NOLOCK) ON mg.id = gm.group_id
			LEFT JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = t.model_alarm_id
			LEFT JOIN APCSProDB.mc.alarm_texts AS at WITH (NOLOCK) ON at.alarm_text_id = ma.alarm_text_id
			) AS t1
		) AS t2

	------------------------
	--machine group pareto--
	------------------------
	SELECT t1.machine_group_id AS machine_group_id,
		t1.machine_group_name AS machine_group_name,
		t1.group_alarm_cnt AS group_alarm_cnt,
		t1.acum_group_alarm_cnt AS acum_group_alarm_cnt,
		CONVERT(DECIMAL(9, 1), t1.acum_group_alarm_cnt) / t1.sum_alarm_cnt * 100 AS acum_group_percent,
		t1.sum_alarm_cnt AS sum_alarm_cnt,
		NULL AS machine_model_id,
		NULL AS machine_model_name,
		NULL AS model_alarm_cnt,
		NULL AS acum_model_alarm_cnt,
		NULL AS acum_model_percent
		--
		,
		NULL AS machine_id,
		NULL AS machine_name,
		NULL AS mc_alarm_cnt,
		NULL AS acum_mc_alarm_cnt,
		NULL AS acum_mc_percent
	FROM (
		SELECT t0.machine_group_id AS machine_group_id,
			t0.machine_group_name AS machine_group_name,
			t0.group_alarm_cnt AS group_alarm_cnt,
			sum(t0.group_alarm_cnt) OVER (
				ORDER BY t0.group_alarm_cnt DESC,
					t0.machine_group_id
				) AS acum_group_alarm_cnt,
			t0.sum_alarm_cnt AS sum_alarm_cnt
		FROM #t_latest_alarms_info AS t0
		WHERE group_alarm_rank = 1
		) AS t1
	ORDER BY t1.acum_group_alarm_cnt;

	------------------------
	--calculate top 1--
	------------------------
	SET @top_group = (
			SELECT TOP 1 t0.machine_group_id
			FROM #t_latest_alarms_info AS t0
			ORDER BY t0.group_alarm_cnt DESC,
				t0.machine_group_id
			);
	SET @top_model = (
			SELECT TOP 1 t0.machine_model_id
			FROM #t_latest_alarms_info AS t0
			WHERE t0.machine_group_id = CASE 
					WHEN @machine_group_id IS NOT NULL
						THEN @machine_group_id
					ELSE @top_group
					END
			ORDER BY t0.model_alarm_cnt DESC,
				t0.machine_model_id
			);
	SET @machine_group_id = CASE 
			WHEN @machine_group_id IS NOT NULL
				THEN @machine_group_id
			ELSE case when @machine_model_id is null then @top_group else null end
			END;
	SET @machine_model_id = CASE 
			WHEN @machine_model_id IS NOT NULL
				THEN @machine_model_id
			ELSE @top_model
			END;

	------------------------
	--machine model pareto--
	------------------------
	SELECT t2.machine_group_id AS machine_group_id,
		t2.machine_group_name AS machine_group_name,
		t2.group_alarm_cnt AS group_alarm_cnt,
		NULL AS acum_group_alarm_cnt,
		NULL AS acum_group_percent,
		t2.sum_alarm_cnt AS sum_alarm_cnt,
		t2.machine_model_id AS machine_model_id,
		t2.machine_model_name AS machine_model_name,
		t2.model_alarm_cnt AS model_alarm_cnt,
		t2.acum_model_alarm_cnt AS acum_model_alarm_cnt,
		t2.acum_model_percent AS acum_model_percent
		--
		,
		NULL AS machine_id,
		NULL AS machine_name,
		NULL AS mc_alarm_cnt,
		NULL AS acum_mc_alarm_cnt,
		NULL AS acum_mc_percent
	FROM (
		SELECT t1.machine_group_id AS machine_group_id,
			t1.machine_group_name AS machine_group_name,
			t1.group_alarm_cnt AS group_alarm_cnt,
			t1.sum_alarm_cnt AS sum_alarm_cnt,
			t1.machine_model_id AS machine_model_id,
			t1.machine_model_name AS machine_model_name,
			t1.model_alarm_cnt AS model_alarm_cnt,
			t1.acum_model_alarm_cnt AS acum_model_alarm_cnt,
			CONVERT(DECIMAL(9, 1), t1.acum_model_alarm_cnt) / t1.group_alarm_cnt * 100 AS acum_model_percent
		FROM (
			SELECT t0.machine_group_id AS machine_group_id,
				t0.machine_group_name AS machine_group_name,
				t0.group_alarm_cnt AS group_alarm_cnt,
				t0.machine_model_id AS machine_model_id,
				t0.machine_model_name AS machine_model_name,
				t0.model_alarm_cnt AS model_alarm_cnt,
				sum(t0.model_alarm_cnt) OVER (
					PARTITION BY t0.machine_group_id ORDER BY t0.model_alarm_cnt DESC,
						t0.machine_model_id
					) AS acum_model_alarm_cnt,
				t0.sum_alarm_cnt AS sum_alarm_cnt
			FROM #t_latest_alarms_info AS t0
			WHERE model_alarm_rank = 1
			) AS t1
		) AS t2
	WHERE (
			(
				@machine_group_id IS NULL
				AND t2.machine_group_id > 0
				)
			OR (
				@machine_group_id IS NOT NULL
				AND t2.machine_group_id = @machine_group_id
				)
			)
	ORDER BY t2.machine_group_id,
		t2.acum_model_alarm_cnt;

	------------------------
	--machine  pareto--
	------------------------
	SELECT t2.machine_group_id AS machine_group_id,
		t2.machine_group_name AS machine_group_name,
		t2.group_alarm_cnt AS group_alarm_cnt,
		NULL AS acum_group_alarm_cnt,
		NULL AS acum_group_percent,
		t2.sum_alarm_cnt AS sum_alarm_cnt,
		t2.machine_model_id AS machine_model_id,
		t2.machine_model_name AS machine_model_name,
		t2.model_alarm_cnt AS model_alarm_cnt,
		NULL AS acum_model_alarm_cnt,
		NULL AS acum_model_percent,
		t2.machine_id AS machine_id,
		t2.machine_name AS machine_name,
		t2.mc_alarm_cnt AS mc_alarm_cnt,
		t2.acum_mc_alarm_cnt AS acum_mc_alarm_cnt,
		t2.acum_mc_percent AS acum_mc_percent
	FROM (
		SELECT t1.machine_group_id AS machine_group_id,
			t1.machine_group_name AS machine_group_name,
			t1.group_alarm_cnt AS group_alarm_cnt,
			t1.sum_alarm_cnt AS sum_alarm_cnt,
			--t1.acum_model_alarm_cnt as acum_model_alarm_cnt
			t1.machine_model_id AS machine_model_id,
			t1.machine_model_name AS machine_model_name,
			t1.model_alarm_cnt AS model_alarm_cnt,
			t1.machine_id AS machine_id,
			t1.machine_name AS machine_name,
			t1.mc_alarm_cnt AS mc_alarm_cnt,
			t1.acum_mc_alarm_cnt AS acum_mc_alarm_cnt,
			CONVERT(DECIMAL(9, 1), t1.acum_mc_alarm_cnt) / t1.model_alarm_cnt * 100 AS acum_mc_percent
		FROM (
			SELECT t0.machine_group_id AS machine_group_id,
				t0.machine_group_name AS machine_group_name,
				t0.group_alarm_cnt AS group_alarm_cnt,
				NULL AS acum_group_alarm_cnt,
				--
				t0.machine_model_id AS machine_model_id,
				t0.machine_model_name AS machine_model_name,
				t0.model_alarm_cnt AS model_alarm_cnt,
				sum(t0.model_alarm_cnt) OVER (
					PARTITION BY t0.machine_group_id ORDER BY t0.model_alarm_cnt DESC,
						t0.machine_model_id
					) AS acum_model_alarm_cnt,
				t0.sum_alarm_cnt AS sum_alarm_cnt,
				--
				t0.machine_id AS machine_id,
				t0.machine_name AS machine_name,
				t0.mc_alarm_cnt AS mc_alarm_cnt,
				sum(t0.mc_alarm_cnt) OVER (
					PARTITION BY t0.machine_model_id ORDER BY t0.mc_alarm_cnt DESC,
						t0.machine_id
					) AS acum_mc_alarm_cnt
			FROM #t_latest_alarms_info AS t0
			WHERE mc_alarm_rank = 1
			) AS t1
		) AS t2
	WHERE (
			(
				@machine_group_id IS NULL
				AND t2.machine_group_id > 0
				)
			OR (
				@machine_group_id IS NOT NULL
				AND t2.machine_group_id = @machine_group_id
				)
			)
		AND (
			(
				@machine_model_id IS NULL
				AND t2.machine_model_id > 0
				)
			OR (
				@machine_model_id IS NOT NULL
				AND t2.machine_model_id = @machine_model_id
				)
			)
	ORDER BY t2.machine_model_id;
END

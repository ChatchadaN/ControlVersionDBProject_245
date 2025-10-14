
CREATE PROCEDURE [act].[sp_machine_commonfilter_machine_list_disp] @process_id INT = NULL
	,@job_id INT = NULL
	,@location_id INT = NULL
	,@machine_group_id INT = NULL
	,@machine_model_id INT = NULL
AS
BEGIN
	DECLARE @date_from DATETIME = DATEADD(MONTH, - 1, getdate())
	DECLARE @date_to DATETIME = getdate()
	DECLARE @fr_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
			WHERE date_value = convert(DATE, @date_from)
			)
	DECLARE @to_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
			WHERE date_value = convert(DATE, @date_to)
			)

	IF OBJECT_ID(N'tempdb..#alarm_master', N'U') IS NOT NULL
		DROP TABLE #alarm_master;

	IF OBJECT_ID(N'tempdb..#alarm_not_exist', N'U') IS NOT NULL
		DROP TABLE #alarm_not_exist;

	IF OBJECT_ID(N'tempdb..#mas_no_rec', N'U') IS NOT NULL
		DROP TABLE #mas_no_rec;

	IF OBJECT_ID(N'tempdb..#state_disp', N'U') IS NOT NULL
		DROP TABLE #state_disp;

	SELECT t1.*
	INTO #alarm_master
	FROM (
		SELECT mm.id AS machine_model_id
			,mm.name AS machine_model_name
			,ma2.alarm_level
			,ma2.cnt_code AS cnt_code
		FROM APCSProDB.mc.models AS mm WITH (NOLOCK)
		LEFT JOIN (
			SELECT ma.machine_model_id
				,ma.alarm_level
				,count(ma.alarm_code) AS cnt_code
			FROM APCSProDB.mc.model_alarms AS ma WITH (NOLOCK)
			GROUP BY ma.machine_model_id
				,ma.alarm_level
			HAVING ma.alarm_level = 0
			) AS ma2 ON ma2.machine_model_id = mm.id
		) AS t1

	--
	SELECT a.id AS machine_id
		,a.name AS machine_name
	INTO #mas_no_rec
	FROM (
		SELECT mm.id
			,mm.name
			,m.machine_model_id
			,m.machine_model_name
		FROM apcsprodb.mc.machines AS mm WITH (NOLOCK)
		INNER JOIN (
			SELECT *
			FROM #alarm_master AS am
			WHERE cnt_code IS NOT NULL
			) AS m ON m.machine_model_id = mm.machine_model_id
		) AS a
	LEFT JOIN (
		SELECT machine_id
		FROM (
			SELECT mar.*
				,ma.alarm_level
			FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
			INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
			WHERE mar.updated_at BETWEEN @date_from
					AND @date_to
				AND ma.alarm_level = 0
			) AS t1
		GROUP BY machine_id
		) AS b ON a.id = b.machine_id
	WHERE b.machine_id IS NULL

	--alarm recordsが存在するmachine
	-- 1-1,1-2
	--
	-----------------------------------------------------
	-------------------state disp flag
	-----------------------------------------------------
	SELECT *
	INTO #state_disp
	FROM (
		SELECT t3.machine_id
			,1 AS flag
		FROM (
			SELECT t2.*
				,mm.name AS machine_name
				,CASE 
					WHEN cnt_alarm_off > 0
						THEN 1
					ELSE 0
					END AS off_or_start_exist
			FROM (
				SELECT machine_id
					,COUNT(t1.id) AS all_alarm
					,SUM(f_alarm_off) AS cnt_alarm_off
					,SUM(f_alarm_keep) AS cnt_alarm_keep
				FROM (
					SELECT mar.*
						,ma.alarm_level
						,CASE 
							WHEN mar.alarm_off_at IS NOT NULL
								OR mar.started_at IS NOT NULL
								THEN 1
							ELSE 0
							END AS f_alarm_off
						,CASE 
							WHEN mar.alarm_off_at IS NULL
								AND mar.started_at IS NULL
								THEN 1
							ELSE 0
							END AS f_alarm_keep
					FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
					INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
					WHERE mar.updated_at BETWEEN @date_from
							AND @date_to
						AND ma.alarm_level = 0
					) AS t1
				GROUP BY machine_id
				) AS t2
			INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = t2.machine_id
				--WHERE t2.cnt_alarm_off = 0
			) AS t3
		WHERE t3.off_or_start_exist = 1
		
		UNION ALL
		
		--ORDER BY machine_id
		--alarm master 登録されているが、alarm_recordsが無い装置
		-- 1-3
		--alarm_recordsが無い装置に装置ステータスにexecute,pauseがあるか
		-- 1-3-1
		--
		SELECT t3.machine_id
			,1 AS flag
		FROM (
			SELECT t2.*
				,ROW_NUMBER() OVER (
					PARTITION BY machine_id ORDER BY run_state
					) AS rn
			FROM (
				SELECT t1.machine_id
					,mm.name AS machine_name
					,t1.run_state
				FROM (
					SELECT msr.*
					FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
					INNER JOIN #mas_no_rec AS ae ON ae.machine_id = msr.machine_id
					WHERE msr.updated_at BETWEEN @date_from
							AND @date_to
					) AS t1
				INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = t1.machine_id
				GROUP BY machine_id
					,mm.name
					,run_state
				) AS t2
			WHERE run_state IN (
					4
					,5
					)
			) AS t3
		WHERE rn = 2
		
		UNION ALL
		
		SELECT t3.machine_id
			,1 AS flag
		FROM (
			SELECT t2.*
				,ROW_NUMBER() OVER (
					PARTITION BY machine_id ORDER BY run_state
					) AS rn
			FROM (
				SELECT t1.machine_id
					,mm.name AS machine_name
					,t1.run_state
				FROM (
					SELECT msr.*
					FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
					INNER JOIN (
						SELECT mm.id AS machine_id
							,mm.name AS machine_name
							,am.machine_model_id
							,am.machine_model_name
						FROM APCSProDB.mc.machines AS mm WITH (NOLOCK)
						INNER JOIN (
							SELECT t1.*
							FROM (
								SELECT mm.id AS machine_model_id
									,mm.name AS machine_model_name
									,ma2.alarm_level
									,ma2.cnt_code AS cnt_code
								FROM APCSProDB.mc.models AS mm WITH (NOLOCK)
								LEFT JOIN (
									SELECT ma.machine_model_id
										,ma.alarm_level
										,count(ma.alarm_code) AS cnt_code
									FROM APCSProDB.mc.model_alarms AS ma WITH (NOLOCK)
									GROUP BY ma.machine_model_id
										,ma.alarm_level
									HAVING ma.alarm_level = 0
									) AS ma2 ON ma2.machine_model_id = mm.id
								) AS t1
							) AS am ON am.machine_model_id = mm.machine_model_id
							AND am.cnt_code IS NULL
						) AS ae ON ae.machine_id = msr.machine_id
					WHERE msr.updated_at BETWEEN @date_from
							AND @date_to
					) AS t1
				INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = t1.machine_id
				GROUP BY machine_id
					,mm.name
					,run_state
				) AS t2
			WHERE run_state IN (
					4
					,5
					)
			) AS t3
		WHERE rn = 2
		) AS sd

	--ORDER BY machine_id
	-----------------------------------------------------
	-------------------machine
	-----------------------------------------------------
	SELECT t3.*
		,isnull(sd.flag, 0) AS disp_flag
	FROM (
		SELECT t2.*
		FROM (
			SELECT t1.*
			FROM (
				SELECT RANK() OVER (
						PARTITION BY mc.id ORDER BY mj.id
						) AS mc_rank
					,mc.id AS machine_id
					,mc.machine_model_id AS machine_model_id
					,md.name AS model_name
					,mk.name AS maker_name
					,mj.machine_group_id AS machine_group_id
					,gp.name AS group_name
					,mc.name AS machine_name
					,mc.short_name1 AS machine_short_name1
					,mc.short_name2 AS machine_short_name2
					,mj.process_id AS process_id
					,dp.name AS process_name
					,mj.id AS job_id
					,dj.name AS job_name
					,mc.location_id AS location_id
					,dl.name AS location_name
				FROM APCSProDB.mc.machines AS mc WITH (NOLOCK)
				LEFT OUTER JOIN APCSProDB.mc.models AS md WITH (NOLOCK) ON mc.machine_model_id = md.id
				LEFT OUTER JOIN APCSProDB.mc.makers AS mk WITH (NOLOCK) ON md.maker_id = mk.id
				LEFT OUTER JOIN APCSProDB.mc.group_models AS gm WITH (NOLOCK) ON md.id = gm.machine_model_id
				LEFT OUTER JOIN APCSProDB.mc.groups AS gp WITH (NOLOCK) ON gm.machine_group_id = gp.id
				LEFT OUTER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.machine_group_id = gm.machine_group_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = mj.process_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = mj.id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_locations AS dl WITH (NOLOCK) ON dl.id = mc.location_id
				WHERE (
						(
							(@job_id IS NOT NULL)
							AND (mj.id = @job_id)
							)
						OR (
							(@job_id IS NULL)
							AND (mj.id > 0)
							)
						)
				) AS t1
			WHERE (t1.mc_rank = 1)
			) AS t2
		WHERE (
				(
					(@process_id IS NOT NULL)
					AND (t2.process_id = @process_id)
					)
				OR (
					(@process_id IS NULL)
					AND (
						(t2.process_id >= 0)
						OR (t2.process_id IS NULL)
						)
					)
				)
			AND (
				(
					(@location_id IS NOT NULL)
					AND (t2.location_id = @location_id)
					)
				OR (
					(@location_id IS NULL)
					AND (
						(t2.location_id >= 0)
						OR (t2.location_id IS NULL)
						)
					)
				)
			AND (
				(
					(@machine_group_id IS NOT NULL)
					AND (t2.machine_group_id = @machine_group_id)
					)
				OR (
					(@machine_group_id IS NULL)
					AND (t2.machine_group_id > 0)
					)
				)
			AND (
				(
					(@machine_model_id IS NOT NULL)
					AND (t2.machine_model_id = @machine_model_id)
					)
				OR (
					(@machine_model_id IS NULL)
					AND (t2.machine_model_id > 0)
					)
				)
		) AS t3
	LEFT JOIN #state_disp AS sd ON sd.machine_id = t3.machine_id
	ORDER BY machine_name
END

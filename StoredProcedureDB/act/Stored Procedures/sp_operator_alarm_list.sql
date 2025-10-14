
CREATE PROCEDURE [act].[sp_operator_alarm_list] (
	@date_from DATETIME
	,@date_to DATETIME
	,@machine_group_id INT = NULL
	,@machine_model_id INT = NULL
	,@machine_id INT = NULL
	,@time_offset INT = 0
	,@one_day INT = 0
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2021-06-01'
	--DECLARE @date_to DATETIME = '2021-06-30'
	--DECLARE @machine_group_id INT = 1
	--DECLARE @machine_model_id INT = 13
	--DECLARE @time_offset INT = 8
	--DECLARE @one_day INT = 1
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

	IF OBJECT_ID(N'tempdb..#ope_alarm_list', N'U') IS NOT NULL
		DROP TABLE #ope_alarm_list;

	SELECT t1.machine_id
		,t1.machine_name
		,t1.machine_group_id
		,t1.machine_model
		,dd.id AS day_id
		,t1.shifted_date_value AS date_value
		,t1.shift_code
		,t1.lot_id
		,t1.lot_no
		,isnull(t1.operated_by, - 1) AS operated_by
		--最長12時間とする
		,CASE 
			WHEN t1.alarm_time > (60 * 60 * 12)
				THEN (60 * 60 * 12)
			ELSE t1.alarm_time
			END AS alarm_time
		,dense_rank() OVER (
			PARTITION BY operated_by
			,shift_code ORDER BY lot_id
			) AS rk_lot
		,sum(CASE 
				WHEN t1.alarm_time > (60 * 60 * 12)
					THEN (60 * 60 * 12)
				ELSE t1.alarm_time
				END) OVER (
			PARTITION BY operated_by
			,shift_code
			) AS sum_alarm_time
	INTO #ope_alarm_list
	FROM (
		SELECT ml.*
			,op.operated_by
			,mar.shifted_alarm_off_at
			,mar.alarm_time
		FROM (
			SELECT t2.machine_id
				,t2.machine_name
				,t2.machine_model
				,t2.machine_model_id
				,t2.machine_group_id
				,t2.process_job_id
				,t2.shifted_started_at
				,t2.shifted_finished_at
				,t2.shifted_date_value
				,t2.shift_code
				,t2.lot_id
				,t2.lot_no
			FROM (
				SELECT t1.machine_id
					,t1.machine_name
					,t1.machine_model
					,t1.machine_model_id
					,t1.machine_group_id
					,t1.process_job_id
					,t1.started_at
					,t1.finished_at
					,DATEADD(HOUR, - 1 * @time_offset, t1.started_at) AS shifted_started_at
					,DATEADD(HOUR, - 1 * @time_offset, t1.finished_at) AS shifted_finished_at
					,CONVERT(DATE, DATEADD(HOUR, - 1 * @time_offset, t1.finished_at)) AS shifted_date_value
					,CASE 
						WHEN datepart(hour, DATEADD(HOUR, - 1 * @time_offset, t1.finished_at)) >= 12
							THEN 1
						ELSE 0
						END AS shift_code
					,t1.lot_id
					,t1.lot_no
				FROM (
					SELECT m.id AS machine_id
						,m.name AS machine_name
						,md.id AS machine_model_id
						,md.name AS machine_model
						,g.id AS machine_group_id
						,pj.process_job_id
						,pj.started_at
						,pj.finished_at
						,lp.idx
						,lp.lot_id
						,rtrim(l.lot_no) AS lot_no
					FROM APCSProDB.mc.groups AS g WITH (NOLOCK)
					INNER JOIN APCSProDB.mc.group_models AS gm WITH (NOLOCK) ON gm.machine_group_id = g.id
					INNER JOIN APCSProDB.mc.models AS md WITH (NOLOCK) ON md.id = gm.machine_model_id
					INNER JOIN APCSProDB.mc.machines AS m WITH (NOLOCK) ON m.machine_model_id = md.id
					LEFT OUTER JOIN APCSProDB.trans.lot_pjs AS pj WITH (NOLOCK) ON pj.machine_id = m.id
						AND pj.finished_at IS NOT NULL
						AND (
							pj.started_at BETWEEN @date_from
								AND DATEADD(day, 1, @date_to)
							OR pj.finished_at BETWEEN @date_from
								AND DATEADD(day, 1, @date_to)
							)
						--データ不具合対策
						AND pj.started_at > DATEADD(day, - 1, pj.finished_at)
					LEFT OUTER JOIN APCSProDB.trans.pj_lots AS lp WITH (NOLOCK) ON lp.process_job_id = pj.process_job_id
					LEFT OUTER JOIN APCSProDB.trans.lots AS l WITH (NOLOCK) ON l.id = lp.lot_id
					LEFT OUTER JOIN APCSProDB.method.device_names AS d WITH (NOLOCK) ON d.id = l.act_device_name_id
						AND d.is_assy_only IN (
							0
							,1
							)
					--WHERE g.name = 'WB'
					WHERE (
							(
								@machine_group_id IS NOT NULL
								AND g.id = @machine_group_id
								)
							OR (
								@machine_group_id IS NULL
								AND g.id > 0
								)
							)
						AND (
							(
								@machine_model_id IS NOT NULL
								AND md.id = @machine_model_id
								)
							OR (
								@machine_model_id IS NULL
								AND md.id > 0
								)
							)
						AND (
							(
								@machine_id IS NOT NULL
								AND m.id = @machine_id
								)
							OR (
								@machine_id IS NULL
								AND m.id > 0
								)
							)
					) AS t1
				) AS t2
			WHERE shifted_date_value BETWEEN @date_from
					AND @date_to
			) AS ml
		--operator
		LEFT JOIN (
			SELECT lpr.id
				,lpr.day_id
				,lpr.recorded_at
				,lpr.operated_by
				,lpr.record_class
				,lpr.lot_id
				,lpr.process_job_id
				,lpr.process_id
				,lpr.job_id
				,lpr.machine_id
			FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
			WHERE record_class = 2
			) AS op ON op.lot_id = ml.lot_id
			AND op.process_job_id = ml.process_job_id
		--alarm
		LEFT JOIN (
			SELECT DATEADD(HOUR, - 1 * @time_offset, a.alarm_on_at) AS shifted_alarm_on_at
				,DATEADD(HOUR, - 1 * @time_offset, a.alarm_off_at) AS shifted_alarm_off_at
				,isnull(convert(DECIMAL(10, 1), DATEDIFF(SECOND, a.alarm_on_at, CASE 
								WHEN a.alarm_off_at IS NOT NULL
									THEN a.alarm_off_at
								ELSE a.started_at
								END)) / 60, 0) AS alarm_time
				,a.machine_id
			FROM APCSProDB.trans.machine_alarm_records AS a WITH (NOLOCK)
			) AS mar ON mar.machine_id = ml.machine_id
			AND (
				mar.shifted_alarm_on_at BETWEEN ml.shifted_started_at
					AND ml.shifted_finished_at
				)
			AND (
				mar.shifted_alarm_off_at BETWEEN ml.shifted_started_at
					AND ml.shifted_finished_at
				)
		) AS t1
	INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.date_value = t1.shifted_date_value
	WHERE dd.id BETWEEN @fr_date
			AND @to_date
				--AND machine_group_id = @machine_group_id
		AND (
			(
				@machine_group_id IS NOT NULL
				AND machine_group_id = @machine_group_id
				)
			OR (
				@machine_group_id IS NULL
				AND machine_group_id > 0
				)
			)
		AND (
			(
				@machine_model_id IS NOT NULL
				AND machine_model_id = @machine_model_id
				)
			OR (
				@machine_model_id IS NULL
				AND machine_model_id > 0
				)
			)
		AND (
			(
				@machine_id IS NOT NULL
				AND machine_id = @machine_id
				)
			OR (
				@machine_id IS NULL
				AND machine_id > 0
				)
			)

	-----------------------debug---------------------
	--SELECT *
	--FROM #ope_alarm_list
	--WHERE operated_by = 638
	---------------------------------
	---------------------------------
	----- 日付毎のオペレータ数とアラーム時間の推移
	--@one_dayフラグが１の時は、既存チャートの特定日クリックによるリクエスト
	IF @one_day = 0
	BEGIN
		SELECT t4.day_id
			,t4.date_value
			,MAX(t4.num_of_mc_day) AS num_of_mc_day
			,MAX(t4.num_of_ope_day) AS num_of_ope_day
			,MAX(t4.num_of_lot_day) AS num_of_lot_day
			,MAX(t4.ave_alarm_minutes_per_lot_day) AS ave_alarm_minutes_per_lot_day
			,MAX(t4.num_of_mc_night) AS num_of_mc_night
			,MAX(t4.num_of_ope_night) AS num_of_ope_night
			,MAX(t4.num_of_lot_night) AS num_of_lot_night
			,MAX(t4.ave_alarm_minutes_per_lot_night) AS ave_alarm_minutes_per_lot_night
			--
			,CASE 
				WHEN max(MAX(t4.num_of_ope_day)) OVER () > max(MAX(t4.num_of_ope_night)) OVER ()
					THEN max(MAX(t4.num_of_ope_day)) OVER ()
				ELSE max(MAX(t4.num_of_ope_night)) OVER ()
				END AS num_of_ope_max
		FROM (
			SELECT d1.day_id
				,d1.date_value
				,CASE 
					WHEN t3.shift_code = 0
						THEN num_of_mc
					ELSE NULL
					END AS num_of_mc_day
				,CASE 
					WHEN t3.shift_code = 1
						THEN num_of_mc
					ELSE NULL
					END AS num_of_mc_night
				,CASE 
					WHEN t3.shift_code = 0
						THEN num_of_ope
					ELSE NULL
					END AS num_of_ope_day
				,CASE 
					WHEN t3.shift_code = 1
						THEN num_of_ope
					ELSE NULL
					END AS num_of_ope_night
				,CASE 
					WHEN t3.shift_code = 0
						THEN num_of_lot
					ELSE NULL
					END AS num_of_lot_day
				,CASE 
					WHEN t3.shift_code = 1
						THEN num_of_lot
					ELSE NULL
					END AS num_of_lot_night
				,CASE 
					WHEN t3.shift_code = 0
						THEN ave_alarm_minutes_per_lot
					ELSE NULL
					END AS ave_alarm_minutes_per_lot_day
				,CASE 
					WHEN t3.shift_code = 1
						THEN ave_alarm_minutes_per_lot
					ELSE NULL
					END AS ave_alarm_minutes_per_lot_night
			FROM (
				SELECT id AS day_id
					,date_value
				FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
				WHERE id BETWEEN @fr_date
						AND @to_date
				) AS d1
			LEFT JOIN (
				SELECT t2.day_id
					,t2.date_value
					,t2.shift_code
					,max(rank_mc) AS num_of_mc
					,max(rank_ope) AS num_of_ope
					,max(rank_lot) AS num_of_lot
					,isnull(convert(DECIMAL(10, 1), max(day_alarm_time) / max(rank_lot)), 0) AS ave_alarm_minutes_per_lot
				FROM (
					SELECT t1.*
						,DENSE_RANK() OVER (
							PARTITION BY date_value
							,shift_code ORDER BY machine_id
							) AS rank_mc
						,DENSE_RANK() OVER (
							PARTITION BY date_value
							,shift_code ORDER BY operated_by
							) AS rank_ope
						,DENSE_RANK() OVER (
							PARTITION BY date_value
							,shift_code ORDER BY lot_id
							) AS rank_lot
						,sum(alarm_time) OVER (
							PARTITION BY date_value
							,shift_code
							) AS day_alarm_time
					FROM #ope_alarm_list AS t1
					) AS t2
				GROUP BY t2.day_id
					,t2.date_value
					,t2.shift_code
				) AS t3 ON t3.day_id = d1.day_id
			) AS t4
		GROUP BY t4.day_id
			,t4.date_value
		ORDER BY day_id
	END
	ELSE
	BEGIN
		SELECT - 1 AS day_id
			,NULL AS date_value
			,NULL AS num_of_mc_day
			,NULL AS num_of_ope_day
			,NULL AS num_of_lot_day
			,NULL AS ave_alarm_minutes_per_lot_day
			,NULL AS num_of_mc_night
			,NULL AS num_of_ope_night
			,NULL AS num_of_lot_night
			,NULL AS ave_alarm_minutes_per_lot_night
			,NULL AS num_of_ope_max
	END

	----- 指定期間、指定プロセスでの各オペレータのロット処理数（LotEnd）とアラーム時間（発生からリセットもしくはリスタート）
	SELECT operated_by AS operated_by
		,shift_code
		,isnull(mu.english_name, 'UNKNOWN') AS operated_by_name
		,max(rk_lot) AS num_of_lots
		,isnull(max(sum_alarm_time), 0) AS sum_alarm_time
		,isnull(convert(DECIMAL(10, 1), max(sum_alarm_time) / max(rk_lot)), 0) AS ave_alarm_minutes_per_lot
	FROM #ope_alarm_list AS l
	LEFT JOIN APCSProDB.man.users AS mu WITH (NOLOCK) ON mu.id = l.operated_by
	GROUP BY operated_by
		,mu.english_name
		,shift_code
		--ORDER BY operated_by
END

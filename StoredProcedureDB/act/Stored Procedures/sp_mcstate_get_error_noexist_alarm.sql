
CREATE PROCEDURE [act].[sp_mcstate_get_error_noexist_alarm]
AS
BEGIN
	DECLARE @date_from DATETIME = DATEADD(MONTH, - 3, getdate())
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

	SELECT
		--gm.machine_group_id AS machine_group_id
		--	,gr.name AS machine_group_name
		md.id AS machine_model_id
		,md.name AS machine_model_name
		,ng_mc.machine_id
		,mm.name AS machine_name
	FROM (
		--------------machine_state_recordsの種類が2以下しかない装置
		SELECT t3.machine_id
		FROM (
			SELECT dense_rank() OVER (
					ORDER BY m.machine_id
					) AS rk_mc
				,m.machine_id
				,r.run_state
				,il.label_eng
				,r.cnt_run_state
				,rank() OVER (
					PARTITION BY m.machine_id ORDER BY r.run_state
					) AS rk
			FROM (
				SELECT machine_id
				FROM (
					SELECT *
					FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
					WHERE lpr.day_id BETWEEN @fr_date
							AND @to_date
					) AS p
				GROUP BY machine_id
				) AS m
			LEFT JOIN (
				SELECT t2.machine_id
					,t2.run_state
					,t2.cnt_run_state
				FROM (
					SELECT t1.machine_id
						,t1.run_state
						,count(machine_id) OVER (PARTITION BY machine_id) AS cnt_run_state
					FROM (
						SELECT *
						FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
						WHERE msr.day_id BETWEEN @fr_date
								AND @to_date
						) AS t1
					GROUP BY t1.machine_id
						,t1.run_state
					) AS t2
				) AS r ON r.machine_id = m.machine_id
			LEFT JOIN APCSProDB.trans.item_labels AS il WITH (NOLOCK) ON il.name = 'machine_states.run_state'
				AND il.val = r.run_state
			WHERE m.machine_id > 0
				AND (
					cnt_run_state IS NULL
					OR cnt_run_state <= 2
					)
			) AS t3
		WHERE rk = 1
		
		UNION
		
		-------------machine_alarm_recordsが存在しない装置
		SELECT m1.machine_id
		FROM (
			SELECT mc.machine_id
			FROM (
				SELECT machine_id
				FROM (
					SELECT *
					FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
					WHERE lpr.day_id BETWEEN @fr_date
							AND @to_date
						AND machine_id > 0
					) AS p
				GROUP BY machine_id
				) AS mc
			LEFT JOIN (
				SELECT a1.machine_id
				FROM (
					SELECT *
					FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
					WHERE mar.updated_at BETWEEN @date_from
							AND @date_to
						AND machine_id > 0
					) AS a1
				GROUP BY a1.machine_id
				) AS alm_mc ON alm_mc.machine_id = mc.machine_id
			WHERE alm_mc.machine_id IS NULL
			) AS m1
		) AS ng_mc
	LEFT JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = ng_mc.machine_id
	LEFT JOIN APCSProDB.mc.models AS md WITH (NOLOCK) ON md.id = mm.machine_model_id
	--LEFT JOIN APCSProDB.mc.group_models AS gm WITH (NOLOCK) ON gm.machine_model_id = md.id
	--LEFT JOIN APCSProDB.mc.groups AS gr WITH (NOLOCK) ON gr.id = gm.machine_group_id
	ORDER BY machine_name
END

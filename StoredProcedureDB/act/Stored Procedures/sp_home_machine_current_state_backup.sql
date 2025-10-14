
CREATE PROCEDURE [act].[sp_home_machine_current_state_backup] (@run_state INT = NULL,@now_on_alarm INT = -1)
AS
BEGIN
	--DECLARE @run_state INT = 5
	--DECLARE @now_on_alarm INT = 1
	SELECT t7.machine_id AS machine_id,
		t7.machine_name AS machine_name,
		t7.machine_model_id AS machine_model_id,
		t7.machine_model_name AS machine_model_name,
		t7.machine_group_id AS machine_group_id,
		t7.machine_group_name AS machine_group_name,
		t7.process_id AS process_id,
		t7.process_name AS process_name,
		t7.online_state AS online_state,
		t7.run_state AS run_state,
		t7.run_state_label AS run_state_label,
		t7.qc_state AS qc_state,
		t7.onlined_at AS onlined_at,
		t7.updated_at AS updated_at,
		t7.latest_state_span AS latest_state_span,
		RANK() OVER (
					PARTITION BY t7.process_id ORDER BY t7.machine_id
					) AS process_id_rank,
		t7.long_term_rank AS long_term_rank,
		t7.alarm_text_id AS alarm_text_id,
		t7.alarm_text AS alarm_text,
		t7.now_on_alarm AS now_on_alarm
	FROM (
		SELECT t6.machine_id AS machine_id,
			t6.machine_name AS machine_name,
			t6.machine_model_id AS machine_model_id,
			t6.machine_model_name AS machine_model_name,
			t6.machine_group_id AS machine_group_id,
			t6.machine_group_name AS machine_group_name,
			t6.process_id AS process_id,
			t6.process_name AS process_name,
			t6.online_state AS online_state,
			t6.run_state AS run_state,
			t6.run_state_label AS run_state_label,
			t6.qc_state AS qc_state,
			t6.onlined_at AS onlined_at,
			t6.updated_at AS updated_at,
			t6.latest_state_span AS latest_state_span,
			t6.long_term_rank AS long_term_rank,
			alm_rec.alarm_text_id AS alarm_text_id,
			alm_rec.alarm_text AS alarm_text,
			isnull(alm_rec.now_on_alarm, 0) AS now_on_alarm
		FROM (
			SELECT t5.machine_id AS machine_id,
				t5.machine_name AS machine_name,
				t5.machine_model_id AS machine_model_id,
				t5.machine_model_name AS machine_model_name,
				t5.machine_group_id AS machine_group_id,
				t5.machine_group_name AS machine_group_name,
				t5.process_id AS process_id,
				t5.process_name AS process_name,
				t5.online_state AS online_state,
				t5.run_state AS run_state,
				t5.run_state_label AS run_state_label,
				t5.qc_state AS qc_state,
				t5.onlined_at AS onlined_at,
				t5.updated_at AS updated_at,
				t5.latest_state_span AS latest_state_span,
				t5.long_term_rank AS long_term_rank
			FROM (
				SELECT t4.machine_id AS machine_id,
					t4.machine_name AS machine_name,
					t4.machine_model_id AS machine_model_id,
					t4.machine_model_name AS machine_model_name,
					t4.machine_group_id AS machine_group_id,
					t4.machine_group_name AS machine_group_name,
					t4.process_id AS process_id,
					t4.process_name AS process_name,
					t4.online_state AS online_state,
					t4.run_state AS run_state,
					t4.run_state_label AS run_state_label,
					t4.qc_state AS qc_state,
					t4.onlined_at AS onlined_at,
					t4.updated_at AS updated_at,
					t4.latest_state_span as latest_state_span,
					rank() OVER (
						PARTITION BY t4.process_id,
						t4.run_state ORDER BY t4.latest_state_span DESC
						) AS long_term_rank
				FROM (
					SELECT t3.mc_rank AS mc_rank,
						t3.machine_id AS machine_id,
						t3.machine_model_id AS machine_model_id,
						t3.machine_model_name AS machine_model_name,
						t3.machine_group_id AS machine_group_id,
						t3.machine_group_name AS machine_group_name,
						t3.machine_name AS machine_name,
						t3.process_id AS process_id,
						t3.process_name AS process_name,
						ms.online_state AS online_state,
						ms.run_state AS run_state,
						l.label_eng AS run_state_label,
						ms.qc_state AS qc_state,
						ms.onlined_at AS onlined_at,
						ms.updated_at AS updated_at,
						CONVERT(decimal(9,1),DATEDIFF(MINUTE,ms.updated_at, GETDATE()))/60 AS latest_state_span
					FROM (
						SELECT t2.mc_rank AS mc_rank,
							t2.machine_id AS machine_id,
							t2.machine_model_id AS machine_model_id,
							t2.machine_model_name AS machine_model_name,
							t2.machine_group_id AS machine_group_id,
							t2.machine_group_name AS machine_group_name,
							t2.machine_name AS machine_name,
							t2.process_id AS process_id,
							t2.process_name AS process_name
						FROM (
							SELECT t1.mc_rank AS mc_rank,
								t1.machine_id AS machine_id,
								t1.machine_model_id AS machine_model_id,
								t1.machine_model_name AS machine_model_name,
								t1.machine_group_id AS machine_group_id,
								t1.machine_group_name AS machine_group_name,
								t1.machine_name AS machine_name,
								t1.process_id AS process_id,
								t1.process_name AS process_name
							FROM (
								SELECT RANK() OVER (
										PARTITION BY mc.id ORDER BY mj.id
										) AS mc_rank,
									mc.id AS machine_id,
									mc.machine_model_id AS machine_model_id,
									md.name AS machine_model_name,
									mj.machine_group_id AS machine_group_id,
									gp.name AS machine_group_name,
									mc.name AS machine_name,
									mj.process_id AS process_id,
									dp.name AS process_name
								FROM APCSProDB.mc.machines AS mc WITH (NOLOCK)
								LEFT OUTER JOIN APCSProDB.mc.models AS md WITH (NOLOCK) ON mc.machine_model_id = md.id
								LEFT OUTER JOIN APCSProDB.mc.makers AS mk WITH (NOLOCK) ON md.maker_id = mk.id
								LEFT OUTER JOIN APCSProDB.mc.group_models AS gm WITH (NOLOCK) ON md.id = gm.machine_model_id
								LEFT OUTER JOIN APCSProDB.mc.groups AS gp WITH (NOLOCK) ON gm.machine_group_id = gp.id
								LEFT OUTER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.machine_group_id = gm.machine_group_id
								LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = mj.process_id
								) AS t1
							WHERE (t1.mc_rank = 1)
							) AS t2
						) AS t3
					LEFT OUTER JOIN APCSProDB.trans.machine_states AS ms WITH (NOLOCK) ON ms.machine_id = t3.machine_id
					LEFT OUTER JOIN APCSProDB.trans.item_labels AS l WITH (NOLOCK) ON l.val = ms.run_state
						AND l.name = 'machine_states.run_state'
					WHERE t3.machine_id > 0
					) AS t4
				) AS t5
			WHERE (
					(
						(@run_state IS NOT NULL)
						AND (t5.run_state = @run_state)
						)
					OR (
						(@run_state IS NULL)
						AND (t5.run_state >= 0)
						)
					)
			) AS t6
		LEFT OUTER JOIN (
			SELECT s1.latest_alarm_rank AS latest_alarm_rank,
				s1.machine_id AS machine_id,
				s1.alarm_text_id AS alarm_text_id,
				s1.alarm_text AS alarm_text,
				s1.now_on_alarm AS now_on_alarm
			FROM (
				SELECT row_number() OVER (
						PARTITION BY mar.machine_id ORDER BY mar.alarm_on_at DESC
						) AS latest_alarm_rank,
					mar.machine_id AS machine_id,
					ma.alarm_text_id AS alarm_text_id,
					atx.alarm_text AS alarm_text,
					CASE 
						WHEN mar.alarm_off_at IS NULL
							THEN 1
						ELSE 0
						END AS now_on_alarm
				FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
				LEFT OUTER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
				LEFT OUTER JOIN APCSProDB.mc.alarm_texts AS atx WITH (NOLOCK) ON atx.alarm_text_id = ma.alarm_text_id
				INNER JOIN (
					SELECT s0.updated_at_rank AS updated_at_rank,
						s0.machine_id AS machine_id,
						s0.updated_at AS updated_at
					FROM (
						SELECT ROW_NUMBER() OVER (
								PARTITION BY ms.machine_id ORDER BY ms.updated_at DESC
								) AS updated_at_rank,
							ms.machine_id AS machine_id,
							ms.updated_at AS updated_at
						FROM APCSProDB.trans.machine_states AS ms WITH (NOLOCK)
						) AS s0
					WHERE s0.updated_at_rank = 1
					) AS mc_st ON mc_st.machine_id = mar.machine_id
					AND mar.alarm_on_at >= mc_st.updated_at
				) AS s1
			WHERE s1.latest_alarm_rank = 1
			) AS alm_rec ON t6.run_state = 5
			AND alm_rec.machine_id = t6.machine_id
		) AS t7
	WHERE (
			@now_on_alarm>=0 and (t7.now_on_alarm = @now_on_alarm)
		  )or(
			@now_on_alarm<0 and t7.now_on_alarm >=0
		  )

	ORDER BY t7.process_id,
		t7.long_term_rank,
		t7.updated_at,
		t7.machine_id
END

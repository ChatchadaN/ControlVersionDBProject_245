
CREATE FUNCTION [act].[fnc_machinealarm_alarm_top_rank_back] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@date_from DATETIME
	,@date_to DATETIME
	,@machine_id_list NVARCHAR(max) = NULL
	,@alarm_level INT = 0
	,@alarm_level_alarm INT = 0
	,@alarm_level_warning INT = 0
	,@alarm_level_caution INT = 0
	,@alarm_id_list NVARCHAR(max) = NULL
	,@top_num INT = 5
	,@unit_type_duration BIT = 0
	,@include_selected_alarm BIT = 1
	,@lot_id INT = NULL
	,@process_job_id INT = NULL
	)
RETURNS @retTbl TABLE (
	selected_alarm INT NULL
	,others_flag_cnt INT NULL
	,message_text_cnt NVARCHAR(max) NULL
	,alarm_id_cnt INT NULL
	,
	--alarm_code_cnt VARCHAR(20) NULL,
	--alarm_text_id_cnt INT NULL,
	rank_percent_alarm_cnt INT NULL
	,sum_alarm_cnt_chart INT NULL
	,percent_alarm_cnt_chart DECIMAL(18, 1) NULL
	,
	--
	others_flag_duration INT NULL
	,message_text_duration NVARCHAR(max) NULL
	,alarm_id_duration INT NULL
	,
	--alarm_code_duration VARCHAR(20) NULL,
	--alarm_text_id_duration INT NULL,
	rank_percent_alarm_duration INT NULL
	,sum_alarm_duration_chart DECIMAL(18, 1) NULL
	,percent_alarm_duration_chart DECIMAL(18, 1) NULL
	)

BEGIN
	INSERT INTO @retTbl
	SELECT
		--count 
		t7.selected_alarm AS selected_alarm
		,t7.others_flag_cnt AS others_flag_cnt
		,t7.message_text_cnt AS message_text_cnt
		,t7.alarm_id_cnt AS alarm_id_cnt
		,t7.rank_percent_alarm_cnt AS rank_percent_alarm_cnt
		,t7.sum_alarm_cnt_chart AS sum_alarm_cnt_chart
		,
		--t7.percent_alarm_cnt_chart,
		convert(DECIMAL(9, 3), (
				(
					sum(t7.sum_alarm_cnt_chart) OVER (
						ORDER BY t7.rank_percent_alarm_cnt
						)
					) * 100
				) / (nullif(sum(convert(DECIMAL(9, 3), t7.sum_alarm_cnt_chart)) OVER (), 0))) AS percent_alarm_cnt_chart
		,
		--duration
		t7.others_flag_duration AS others_flag_duration
		,t7.message_text_duration AS message_text_duration
		,t7.alarm_id_duration AS alarm_id_duration
		,t7.rank_percent_alarm_duration AS rank_percent_alarm_duration
		,t7.sum_alarm_duration_chart AS sum_alarm_duration_chart
		,
		--t7.percent_alarm_duration_chart,
		convert(DECIMAL(9, 1), (
				(
					sum(t7.sum_alarm_duration_chart) OVER (
						ORDER BY t7.rank_percent_alarm_duration
						)
					) * 100
				) / (nullif(sum(t7.sum_alarm_duration_chart) OVER (), 0))) AS percent_alarm_duration_chart
	FROM (
		SELECT
			--selected_alarmを含めたtop_numの中でranking
			t6.selected_alarm AS selected_alarm
			,t6.others_flag_cnt AS others_flag_cnt
			,t6.message_text_cnt AS message_text_cnt
			,t6.alarm_id_cnt AS alarm_id_cnt
			,ROW_NUMBER() OVER (
				ORDER BY t6.others_flag_cnt
					,t6.sum_alarm_cnt_chart DESC
					,t6.message_text_cnt
				) AS rank_percent_alarm_cnt
			,t6.sum_alarm_cnt_chart AS sum_alarm_cnt_chart
			,t6.percent_alarm_cnt_chart AS percent_alarm_cnt_chart
			,t6.others_flag_duration AS others_flag_duration
			,t6.message_text_duration AS message_text_duration
			,t6.alarm_id_duration AS alarm_id_duration
			,ROW_NUMBER() OVER (
				ORDER BY t6.others_flag_duration
					,t6.sum_alarm_duration_chart DESC
					,t6.message_text_duration
				) AS rank_percent_alarm_duration
			,t6.sum_alarm_duration_chart AS sum_alarm_duration_chart
			,t6.percent_alarm_duration_chart AS percent_alarm_duration_chart
		FROM (
			SELECT t5.selected_alarm AS selected_alarm
				,
				--count
				CASE 
					WHEN t5.rank_percent_alarm_cnt <= @top_num
						THEN 0
					ELSE 1
					END AS others_flag_cnt
				,CASE 
					WHEN t5.rank_percent_alarm_cnt <= @top_num
						THEN t5.message_text
					ELSE 'Others'
					END AS message_text_cnt
				,CASE 
					WHEN t5.rank_percent_alarm_cnt <= @top_num
						THEN t5.alarm_id
					ELSE NULL
					END AS alarm_id_cnt
				,t5.rank_percent_alarm_cnt AS rank_percent_alarm_cnt
				,t5.sum_alarm_cnt_chart AS sum_alarm_cnt_chart
				,sum(t5.paritial_alarm_cnt_chart) OVER (
					ORDER BY t5.rank_percent_alarm_cnt
					) AS percent_alarm_cnt_chart
				,
				--duration
				CASE 
					WHEN t5.rank_percent_alarm_duration <= @top_num
						THEN 0
					ELSE 1
					END AS others_flag_duration
				,CASE 
					WHEN t5.rank_percent_alarm_duration <= @top_num
						THEN t5.message_text
					ELSE 'Others'
					END AS message_text_duration
				,CASE 
					WHEN t5.rank_percent_alarm_duration <= @top_num
						THEN t5.alarm_id
					ELSE NULL
					END AS alarm_id_duration
				,t5.rank_percent_alarm_duration AS rank_percent_alarm_duration
				,t5.sum_alarm_duration_chart AS sum_alarm_duration_chart
				,sum(t5.paritial_alarm_duration_chart) OVER (
					ORDER BY t5.rank_percent_alarm_duration
					) AS percent_alarm_duration_chart
			FROM (
				SELECT sum(t4.sum_alarm_cnt) OVER (PARTITION BY t4.f_cnt) AS sum_alarm_cnt_chart
					,sum(t4.percent_alarm_cnt) OVER (PARTITION BY t4.f_cnt) AS paritial_alarm_cnt_chart
					,sum(t4.sum_alarm_duration) OVER (PARTITION BY t4.f_duration) AS sum_alarm_duration_chart
					,sum(t4.percent_alarm_duration) OVER (PARTITION BY t4.f_duration) AS paritial_alarm_duration_chart
					,*
				FROM (
					SELECT CASE 
							WHEN t3.rank_percent_alarm_cnt <= @top_num
								THEN t3.rank_percent_alarm_cnt
							ELSE @top_num + 1
							END AS f_cnt
						,CASE 
							WHEN t3.rank_percent_alarm_duration <= @top_num
								THEN t3.rank_percent_alarm_duration
							ELSE @top_num + 1
							END AS f_duration
						,t3.selected_alarm AS selected_alarm
						,t3.alarm_id AS alarm_id
						,t3.message_text AS message_text
						,
						--count
						t3.sum_alarm_cnt AS sum_alarm_cnt
						,t3.rank_percent_alarm_cnt AS rank_percent_alarm_cnt
						,t3.percent_alarm_cnt AS percent_alarm_cnt
						,
						--duration
						t3.sum_alarm_duration AS sum_alarm_duration
						,t3.rank_percent_alarm_duration AS rank_percent_alarm_duration
						,t3.percent_alarm_duration AS percent_alarm_duration
					FROM (
						SELECT t2.*
							,sum(t2.sum_alarm_cnt) OVER (
								ORDER BY t2.sum_alarm_cnt DESC
									,t2.alarm_id
								) AS cum_alarm_cnt
							,row_number() OVER (
								ORDER BY CASE 
										WHEN @include_selected_alarm = 1
											THEN t2.selected_alarm
										ELSE NULL
										END DESC
									,t2.percent_alarm_cnt DESC
									,t2.alarm_id
									,t2.machine_name
								) AS rank_percent_alarm_cnt
							,sum(t2.sum_alarm_duration) OVER (
								ORDER BY t2.sum_alarm_duration DESC
									,t2.alarm_id
								) AS cum_alarm_duration
							,row_number() OVER (
								ORDER BY CASE 
										WHEN @include_selected_alarm = 1
											THEN t2.selected_alarm
										ELSE NULL
										END DESC
									,t2.percent_alarm_duration DESC
									,t2.alarm_id
									,t2.machine_name
								) AS rank_percent_alarm_duration
						FROM (
							SELECT t1.*
								,ax.message_text AS message_text
								,row_number() OVER (
									PARTITION BY t1.alarm_id ORDER BY t1.alarm_id
									) AS al_rank
								,sum(CASE 
										WHEN t1.id IS NOT NULL
											THEN 1
										ELSE 0
										END) OVER (PARTITION BY t1.alarm_id) AS sum_alarm_cnt
								,convert(DECIMAL(9, 1), (
										sum(CASE 
												WHEN t1.id IS NOT NULL
													THEN 1
												ELSE 0
												END) OVER (PARTITION BY t1.alarm_id)
										) * 100) / (
									nullif(sum(CASE 
												WHEN t1.id IS NOT NULL
													THEN 1
												ELSE 0
												END) OVER (), 0)
									) AS percent_alarm_cnt
								,sum(t1.alarm_duration) OVER (PARTITION BY t1.alarm_id) AS sum_alarm_duration
								,(sum(t1.alarm_duration) OVER (PARTITION BY t1.alarm_id)) * 100 / (nullif(sum(t1.alarm_duration) OVER (), 0)) AS percent_alarm_duration
							FROM (
								SELECT s3.id AS id
									,s3.machine_id AS machine_id
									,s3.machine_name AS machine_name
									,s3.merge_alarm_id AS alarm_id
									,s3.on_at AS on_at
									,s3.off_at AS off_at
									,s3.started_at AS started_at
									,isnull(s3.alarm_duration, 0) AS alarm_duration
									,s3.selected_alarm AS selected_alarm
								FROM (
									SELECT CASE 
											WHEN s2.my_alarm_id IS NOT NULL
												THEN 1
											ELSE 0
											END AS selected_alarm
										,s2.*
										,CASE 
											WHEN s2.my_alarm_id IS NOT NULL
												THEN s2.my_alarm_id
											ELSE s2.alarm_id
											END AS merge_alarm_id
									FROM (
										SELECT value AS my_alarm_id
											,s1.*
										FROM STRING_SPLIT(@alarm_id_list, ',') AS my
										FULL OUTER JOIN (
											SELECT fmc.id AS id
												,fmc.machine_id AS machine_id
												,dm.name AS machine_name
												,alr.lot_id AS lot_id
												,lpr2.process_job_id AS process_job_id
												,fmc.model_alarm_id AS alarm_id
												,ac.code AS alarm_code
												,ac.alarm_text_id AS alarm_text_id
												,ac.is_disabled AS is_disabled
												,fmc.alarm_on_at AS on_at
												,fmc.alarm_off_at AS off_at
												,CASE 
													WHEN fmc.started_at > @date_to
														THEN @date_to
													ELSE started_at
													END AS started_at
												,isnull(convert(DECIMAL(18, 1), datediff_big(SECOND, fmc.alarm_on_at, CASE 
																WHEN fmc.alarm_off_at > @date_to
																	THEN @date_to
																ELSE
																	--1900/01/01 00:00:00対策
																	CASE 
																		WHEN fmc.alarm_on_at < fmc.alarm_off_at
																			THEN fmc.alarm_off_at
																		ELSE fmc.updated_at
																		END
																END)) / 60 / 60, NULL) AS alarm_duration
											FROM APCSProDB.trans.machine_alarm_records AS fmc WITH (NOLOCK)
											INNER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = fmc.machine_id
											LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_codes AS ac WITH (NOLOCK) ON ac.id = fmc.model_alarm_id
											LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_texts AS ax WITH (NOLOCK) ON ax.id = ac.alarm_text_id
											LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_levels AS al WITH (NOLOCK) ON al.code = ac.alarm_level
											INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = fmc.id
											--lot_process_recordsからprocess_job_idを引いてくる
											LEFT OUTER JOIN (
												SELECT u3.start_recorded_at AS start_recorded_at
													,u3.end_recorded_at AS end_recorded_at
													,u3.job_id AS job_id
													,u3.rank_process_job_id AS rank_process_job_id
													,u3.lot_id AS lot_id
													,u3.machine_id AS machine_id
													,u3.process_job_id AS process_job_id
												FROM (
													SELECT u2.recorded_at AS start_recorded_at
														,LEAD(u2.recorded_at, 1, CASE 
																WHEN @date_to >= GETDATE()
																	THEN getdate()
																ELSE @date_to
																END) OVER (
															PARTITION BY u2.job_id
															,u2.process_job_id ORDER BY u2.recorded_at
															) AS end_recorded_at
														,rank() OVER (
															PARTITION BY u2.process_job_id ORDER BY u2.recorded_at
															) AS rank_process_job_id
														,*
													FROM (
														SELECT *
														FROM (
															SELECT lpr.recorded_at AS recorded_at
																,lpr.record_class AS record_class
																,lpr.lot_id AS lot_id
																,lpr.machine_id AS machine_id
																,lpr.job_id AS job_id
																,lpr.process_job_id AS process_job_id
																,rank() OVER (
																	PARTITION BY process_job_id ORDER BY lpr.id
																	) AS rank_job_start
																,rank() OVER (
																	PARTITION BY process_job_id ORDER BY lpr.id DESC
																	) AS rank_job_end
															FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
															LEFT OUTER JOIN APCSProDWH.dwh.dim_lots AS dl WITH (NOLOCK) ON dl.id = lpr.lot_id
															WHERE lpr.lot_id = @lot_id
																AND lpr.machine_id IN (
																	SELECT value
																	FROM STRING_SPLIT(@machine_id_list, ',')
																	)
																AND lpr.record_class IN (
																	1
																	,2
																	,12
																	)
															) AS u1
														WHERE rank_job_start = 1
															OR rank_job_end = 1
														) AS u2
													) AS u3
												WHERE u3.rank_process_job_id = 1
												) AS lpr2 ON lpr2.lot_id = alr.lot_id
												AND lpr2.start_recorded_at <= fmc.alarm_on_at
												AND fmc.alarm_on_at <= lpr2.end_recorded_at
											WHERE fmc.machine_id IN (
													SELECT value
													FROM STRING_SPLIT(@machine_id_list, ',')
													)
												AND (
													(@date_from <= alarm_on_at)
													AND (alarm_on_at <= @date_to)
													)
												AND (
													(
														@alarm_level > 0
														AND (
															(
																@alarm_level_alarm > 0
																AND ac.alarm_level = 0
																)
															OR (
																@alarm_level_warning > 0
																AND ac.alarm_level = 1
																)
															OR (
																@alarm_level_caution > 0
																AND ac.alarm_level = 2
																)
															)
														)
													OR (
														@alarm_level = 0
														AND ac.alarm_level >= 0
														)
													)
												AND (
													(
														@lot_id IS NOT NULL
														AND alr.lot_id = @lot_id
														)
													OR (@lot_id IS NULL)
													AND alr.lot_id > 0
													)
												--
												AND (
													(
														@process_job_id IS NULL
														AND (
															lpr2.process_job_id IS NULL
															OR lpr2.process_job_id > 0
															)
														)
													OR (
														@process_job_id IS NOT NULL
														AND lpr2.process_job_id = @process_job_id
														)
													)
											) AS s1 ON s1.alarm_id = my.value
										) AS s2
									) AS s3
								) AS t1
							LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_texts AS ax WITH (NOLOCK) ON ax.id = t1.alarm_id
							) AS t2
						WHERE t2.al_rank = 1
						) AS t3
					) AS t4
				) AS t5
			WHERE CASE 
					WHEN @unit_type_duration = 0
						THEN rank_percent_alarm_cnt
					ELSE rank_percent_alarm_duration
					END <= @top_num + 1
			) AS t6
		) AS t7
	ORDER BY rank_percent_alarm_cnt

	RETURN
END

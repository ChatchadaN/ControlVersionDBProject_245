
CREATE FUNCTION [act].[fnc_machinealarm_alarm_top_rank_v3] (
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
	,@id_from BIGINT = 0
	,@id_to BIGINT = 0
	)
RETURNS @retTbl TABLE (
	selected_alarm INT NULL
	,machine_model_id INT NULL
	,machine_model_name NVARCHAR(30) NULL
	,others_flag_cnt INT NULL
	,message_text_cnt NVARCHAR(max) NULL
	,alarm_id_cnt INT NULL
	,alarm_code_cnt VARCHAR(20) NULL
	,rank_percent_alarm_cnt INT NULL
	,sum_alarm_cnt_chart INT NULL
	,percent_alarm_cnt_chart DECIMAL(18, 1) NULL
	,
	--
	others_flag_duration INT NULL
	,message_text_duration NVARCHAR(max) NULL
	,alarm_id_duration INT NULL
	,alarm_code_duration VARCHAR(20) NULL
	,rank_percent_alarm_duration INT NULL
	,sum_alarm_duration_chart DECIMAL(10, 3) NULL
	,percent_alarm_duration_chart DECIMAL(10, 1) NULL
	)

BEGIN
	INSERT INTO @retTbl
	SELECT
		--count 
		t7.selected_alarm AS selected_alarm
		,t7.machine_model_id AS machine_model_id
		,t7.machine_model_name AS machine_model_name
		,t7.others_flag_cnt AS others_flag_cnt
		,t7.message_text_cnt AS message_text_cnt
		,t7.alarm_id_cnt AS alarm_id_cnt
		,t7.alarm_code_cnt AS alarm_code_cnt
		,t7.rank_percent_alarm_cnt AS rank_percent_alarm_cnt
		,t7.sum_alarm_cnt_chart AS sum_alarm_cnt_chart
		,convert(DECIMAL(9, 3), (
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
		,t7.alarm_code_duration AS alarm_code_duration
		,t7.rank_percent_alarm_duration AS rank_percent_alarm_duration
		,t7.sum_alarm_duration_chart AS sum_alarm_duration_chart
		,convert(DECIMAL(9, 1), (
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
			,t6.machine_model_id AS machine_model_id
			,t6.machine_model_name AS machine_model_name
			,t6.others_flag_cnt AS others_flag_cnt
			,t6.message_text_cnt AS message_text_cnt
			,t6.alarm_id_cnt AS alarm_id_cnt
			,t6.alarm_code_cnt AS alarm_code_cnt
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
			,t6.alarm_code_duration AS alarm_code_duration
			,ROW_NUMBER() OVER (
				ORDER BY t6.others_flag_duration
					,t6.sum_alarm_duration_chart DESC
					,t6.message_text_duration
				) AS rank_percent_alarm_duration
			,t6.sum_alarm_duration_chart AS sum_alarm_duration_chart
			,t6.percent_alarm_duration_chart AS percent_alarm_duration_chart
		FROM (
			SELECT t5.selected_alarm AS selected_alarm
				,t5.machine_model_id AS machine_model_id
				,t5.machine_model_name AS machine_model_name
				--count
				,CASE 
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
						THEN t5.model_alarm_id
					ELSE NULL
					END AS alarm_id_cnt
				,CASE 
					WHEN t5.rank_percent_alarm_cnt <= @top_num
						THEN t5.alarm_code
					ELSE 'Others'
					END AS alarm_code_cnt
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
						THEN t5.model_alarm_id
					ELSE NULL
					END AS alarm_id_duration
				,CASE 
					WHEN t5.rank_percent_alarm_duration <= @top_num
						THEN t5.alarm_code
					ELSE 'Others'
					END AS alarm_code_duration
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
						,t3.machine_model_id AS machine_model_id
						,t3.machine_model_name AS machine_model_name
						,t3.model_alarm_id AS model_alarm_id
						,t3.alarm_code AS alarm_code
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
							,row_number() OVER (
								ORDER BY CASE 
										WHEN @include_selected_alarm = 1
											THEN t2.selected_alarm
										ELSE NULL
										END DESC
									,t2.percent_alarm_cnt DESC
									,t2.model_alarm_id
									,t2.machine_name
								) AS rank_percent_alarm_cnt
							,row_number() OVER (
								ORDER BY CASE 
										WHEN @include_selected_alarm = 1
											THEN t2.selected_alarm
										ELSE NULL
										END DESC
									,t2.percent_alarm_duration DESC
									,t2.model_alarm_id
									,t2.machine_name
								) AS rank_percent_alarm_duration
						FROM (
							SELECT t1.*
								,t1.alarm_text AS message_text
								,row_number() OVER (
									PARTITION BY t1.model_alarm_id ORDER BY t1.model_alarm_id
									) AS al_rank
								,sum(CASE 
										WHEN t1.id IS NOT NULL
											THEN 1
										ELSE 0
										END) OVER (PARTITION BY t1.model_alarm_id) AS sum_alarm_cnt
								,convert(DECIMAL(9, 1), (
										sum(CASE 
												WHEN t1.id IS NOT NULL
													THEN 1
												ELSE 0
												END) OVER (PARTITION BY t1.model_alarm_id)
										) * 100) / (
									nullif(sum(CASE 
												WHEN t1.id IS NOT NULL
													THEN 1
												ELSE 0
												END) OVER (), 0)
									) AS percent_alarm_cnt
								,sum(t1.alarm_duration) OVER (PARTITION BY t1.model_alarm_id) AS sum_alarm_duration
								,(sum(t1.alarm_duration) OVER (PARTITION BY t1.model_alarm_id)) * 100 / (nullif(sum(t1.alarm_duration) OVER (), 0)) AS percent_alarm_duration
							FROM (
								SELECT x1.id AS id
									,x1.machine_id AS machine_id
									,x1.machine_name AS machine_name
									,x1.machine_model_id AS machine_model_id
									,x1.machine_model_name AS machine_model_name
									,x1.selected_alarm AS selected_alarm
									,x1.model_alarm_id AS model_alarm_id
									,x1.alarm_code AS alarm_code
									,x1.alarm_level AS alarm_level
									,x1.alarm_text_id AS alarm_text_id
									,x1.alarm_text AS alarm_text
									,x1.repeat_count AS repeat_count
									,x1.lot_id AS lot_id
									,x1.process_job_id AS process_job_id
									,isnull(convert(DECIMAL(18, 1), datediff_big(SECOND, x1.alarm_on_at, CASE 
													WHEN x1.alarm_off_at > @date_to
														THEN @date_to
													ELSE
														--1900/01/01 00:00:00対策
														CASE 
															WHEN x1.alarm_on_at < x1.alarm_off_at
																THEN x1.alarm_off_at
															WHEN x1.alarm_on_at < x1.started_at
																THEN x1.started_at
															ELSE x1.updated_at
															END
													END)) / 60 / 60, NULL) AS alarm_duration
								FROM (
									SELECT m.id AS machine_id
										,m.name AS machine_name
										,md.id AS machine_model_id
										,md.name AS machine_model_name
										,isnull(sa.selected_alarm, 0) AS selected_alarm
										,ma.id AS model_alarm_id
										,ma.alarm_code AS alarm_code
										,ma.alarm_level AS alarm_level
										,ma.alarm_text_id AS alarm_text_id
										,CASE 
											WHEN atx.alarm_text = ''
												THEN md.name + '*' + ma.alarm_code
											ELSE atx.alarm_text
											END AS alarm_text
										,mar.id AS id
										,mar.alarm_on_at AS alarm_on_at
										,mar.alarm_off_at AS alarm_off_at
										,mar.started_at AS started_at
										,mar.updated_at AS updated_at
										,mar.repeat_count AS repeat_count
										,mar.lot_id AS lot_id
										,mar.process_job_id AS process_job_id
									FROM APCSProDB.mc.machines AS m WITH (NOLOCK)
									INNER JOIN APCSProDB.mc.models AS md WITH (NOLOCK) ON md.id = m.machine_model_id
									LEFT JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.machine_model_id = md.id
									LEFT JOIN APCSProDB.mc.alarm_texts AS atx WITH (NOLOCK) ON atx.alarm_text_id = ma.alarm_text_id
									LEFT JOIN (
										SELECT convert(INT, value) AS v
											,1 AS selected_alarm
										FROM STRING_SPLIT(@alarm_id_list, ',')
										) AS sa ON sa.v = ma.id
									LEFT JOIN (
										SELECT rec.id AS id
											,rec.machine_id AS machine_id
											,rec.model_alarm_id AS model_alarm_id
											,rec.alarm_on_at AS alarm_on_at
											,rec.alarm_off_at AS alarm_off_at
											,rec.started_at AS started_at
											,rec.updated_at AS updated_at
											,rec.repeat_count AS repeat_count
											,alr.lot_id AS lot_id
											,lpr2.process_job_id AS process_job_id
											,pg.id AS package_group_id
											,tl.act_package_id AS package_id
											,tl.act_device_name_id AS device_name_id
											,dn.name AS device_name
										FROM APCSProDB.trans.machine_alarm_records AS rec WITH (NOLOCK)
										INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = rec.id
										INNER JOIN apcsprodb.trans.lots AS tl WITH (NOLOCK) ON tl.id = alr.lot_id
										INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
										INNER JOIN APCSProDB.method.packages AS p WITH (NOLOCK) ON p.id = tl.act_package_id
										LEFT JOIN APCSProDB.method.package_groups AS pg WITH (NOLOCK) ON pg.id = p.package_group_id
										--lot_process_recordsからprocess_job_idを引いてくる
										LEFT OUTER JOIN (
											SELECT *
											FROM (
												SELECT lpr.recorded_at AS recorded_at
													,lpr.record_class AS record_class
													,lpr.lot_id AS lot_id
													,lpr.machine_id AS machine_id
													,lpr.job_id AS job_id
													,lpr.process_job_id AS process_job_id
													,min(lpr.recorded_at) OVER (PARTITION BY lpr.process_job_id) AS start_recorded_at
													,max(lpr.recorded_at) OVER (PARTITION BY lpr.process_job_id) AS end_recorded_at
													,ROW_NUMBER() OVER (
														PARTITION BY lpr.process_job_id ORDER BY lpr.recorded_at
														) AS rank_process_job_id
												FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
												--LEFT OUTER JOIN APCSProDWH.dwh.dim_lots AS dl WITH (NOLOCK) ON dl.id = lpr.lot_id
												WHERE lpr.lot_id = @lot_id
													AND lpr.machine_id IN (
														SELECT convert(INT, value)
														FROM STRING_SPLIT(@machine_id_list, ',')
														)
													AND lpr.record_class IN (
														1
														,2
														,12
														)
												) AS u1
											WHERE u1.rank_process_job_id = 1
											) AS lpr2 ON lpr2.lot_id = alr.lot_id
											AND lpr2.start_recorded_at <= rec.alarm_on_at
											AND rec.alarm_on_at <= lpr2.end_recorded_at
										WHERE (
												(
													(
														@id_from > 0
														AND @id_to > 0
														)
													AND rec.id BETWEEN @id_from
														AND @id_to
													)
												OR (@id_from * @id_to = 0)
												)
											AND (
												(@date_from <= rec.alarm_on_at)
												AND (rec.alarm_on_at <= @date_to)
												)
											AND rec.machine_id IN (
												SELECT convert(INT, value)
												FROM STRING_SPLIT(@machine_id_list, ',')
												)
											-------------------------------package device 
											AND (
												(
													@package_id IS NOT NULL
													AND p.id = @package_id
													)
												OR (
													@package_id IS NULL
													AND @package_group_id IS NOT NULL
													AND p.package_group_id = @package_group_id
													)
												OR (
													@package_id IS NULL
													AND @package_group_id IS NULL
													AND p.id > 0
													)
												)
											AND (
												(
													@device_name IS NOT NULL
													AND dn.name = @device_name
													)
												OR (@device_name IS NULL)
												)
										) AS mar ON (
											mar.machine_id = m.id
											AND mar.model_alarm_id = ma.id
											)
									WHERE m.id IN (
											SELECT convert(INT, value)
											FROM STRING_SPLIT(@machine_id_list, ',')
											)
									) AS x1
								WHERE (
										x1.id IS NOT NULL
										OR (
											x1.id IS NULL
											AND x1.selected_alarm = 1
											)
										)
									AND (
										(
											@alarm_level > 0
											AND (
												(
													@alarm_level_alarm > 0
													AND x1.alarm_level = 0
													)
												OR (
													@alarm_level_warning > 0
													AND x1.alarm_level = 1
													)
												OR (
													@alarm_level_caution > 0
													AND x1.alarm_level = 2
													)
												)
											)
										OR (
											@alarm_level = 0
											AND x1.alarm_level >= 0
											)
										)
									AND (
										(
											@lot_id IS NOT NULL
											AND x1.lot_id = @lot_id
											)
										OR (@lot_id IS NULL)
										AND (
											x1.lot_id IS NULL
											OR x1.lot_id > 0
											)
										)
									--
									AND (
										(
											@process_job_id IS NULL
											AND (
												x1.process_job_id IS NULL
												OR x1.process_job_id > 0
												)
											)
										OR (
											@process_job_id IS NOT NULL
											AND x1.process_job_id = @process_job_id
											)
										)
								) AS t1
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

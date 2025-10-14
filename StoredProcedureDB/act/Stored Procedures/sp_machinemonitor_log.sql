
CREATE PROCEDURE [act].[sp_machinemonitor_log] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@machine_id INT = - 1
	)
AS
BEGIN
	DECLARE @local_date_from DATETIME = dateadd(hour, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = dateadd(hour, @time_offset, @date_to)

	SELECT t2.pid AS pid
		,t2.category AS category
		,t2.category_name AS category_name
		,t2.machine_id AS machine_id
		,t2.code AS code
		,t2.code_name
		,t2.custom_code AS custom_code
		,t2.event_time AS event_time
		,t2.lot_id AS lot_id
		,t2.alarm_id AS alarm_id
		,t2.machine_name AS machine_name
		,t2.lot_no AS lot_no
		,t2.production_category AS production_category
		,t2.package_id AS package_id
		,t2.package_name AS package_name
		,t2.device_id AS device_id
		,t2.assy_name_id AS assy_name_id
		,t2.assy_name AS assy_name
		,t2.production_category_val AS production_category_val
		,t2.device_type AS device_type
		,t2.alarm_level AS alarm_level
		,t2.alarm_text_id AS alarm_text_id
		,t2.alarm_code AS alarm_code
		,t2.message_text AS message_text
		,t2.start_point AS start_point
		,isnull(lag(t2.start_point) OVER (
				ORDER BY pid
				) - t2.start_point, 0) AS diff
	FROM (
		SELECT ROW_NUMBER() OVER (
				ORDER BY event_time DESC
				) AS pid
			,t1.category AS category
			,t1.category_name AS category_name
			,t1.machine_id AS machine_id
			,t1.code AS code
			,t1.code_name
			,t1.custom_code AS custom_code
			,t1.event_time AS event_time
			,t1.lot_id AS lot_id
			,t1.alarm_id AS alarm_id
			,dm.name AS machine_name
			,l.lot_no AS lot_no
			,l.production_category AS production_category
			,l.package_id AS package_id
			,dp.name AS package_name
			,l.device_id AS device_id
			,l.assy_name_id AS assy_name_id
			,dn.name AS assy_name
			,il.label_eng AS production_category_val
			,dv.device_type AS device_type
			,ac.alarm_level AS alarm_level
			,ac.alarm_text_id AS alarm_text_id
			,ac.code AS alarm_code
			,atx.message_text AS message_text
			,isnull(convert(DECIMAL(9, 1), datediff(SECOND, @local_date_from, t1.event_time)) / 60, NULL) AS start_point
		FROM (
			SELECT 2 AS category
				,'Lot' AS category_name
				,p2.machine_id AS machine_id
				,NULL AS code
				,CASE 
					WHEN p2.record_class = 1
						THEN 'LotStart'
					WHEN p2.record_class = 2
						THEN 'LotEnd'
					ELSE 'OnlineEnd'
					END AS code_name
				,CASE 
					WHEN p2.record_class = 1
						THEN 101
							--WHEN p2.record_class = 2
							--	THEN 102
							--ELSE 112
					ELSE 199
					END AS custom_code
				,p2.recorded_at AS event_time
				,p2.lot_id AS lot_id
				,NULL AS alarm_id
			FROM (
				SELECT lpr.machine_id
					,lpr.recorded_at
					,lpr.lot_id
					,lpr.record_class
				FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
				WHERE lpr.record_class IN (
						1
						,2
						,12
						)
					AND lpr.machine_id = @machine_id
					AND (
						((@local_date_from <= lpr.recorded_at))
						AND ((lpr.recorded_at <= @local_date_to))
						)
				) AS p2
			
			UNION ALL
			
			SELECT 1 AS category
				,'Status' AS category_name
				,e1.machine_id AS machine_id
				,e1.code AS code
				,e1.code_name AS code_name
				,e1.code AS custom_code
				,e1.started_at AS event_time
				,NULL AS lot_id
				,NULL AS alarm_id
			FROM (
				SELECT msr.day_id AS day_id
					,msr.machine_id AS machine_id
					,msr.run_state AS code
					,msr.updated_at AS started_at
					,il.label_eng AS code_name
				FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
				LEFT OUTER JOIN APCSProDB.trans.item_labels AS il WITH (NOLOCK) ON il.name = 'machine_states.run_state' 　and il.val = msr.run_state
				WHERE msr.machine_id = @machine_id
					AND (
						((@local_date_from <= msr.updated_at))
						AND ((msr.updated_at <= @local_date_to))
						)
				) AS e1
			
			UNION ALL
			
			SELECT 1 AS category
				,'Status' AS category_name
				,machine_id AS machine_id
				,NULL AS code
				,CASE 
					WHEN a.alarm_level = 0
						THEN 'Alarm'
					ELSE 'Warning'
					END AS code_name
				,CASE 
					WHEN a.alarm_level = 0
						THEN 99
					ELSE 103
					END AS custom_code
				,alarm_on_at AS event_time
				,NULL AS lot_id
				,model_alarm_id AS alarm_id
			FROM [APCSProDB].[trans].[machine_alarm_records] AS a1 WITH (NOLOCK)
			INNER JOIN APCSProDWH.dwh.dim_alarm_codes AS a WITH (NOLOCK) ON a.id = a1.model_alarm_id
			WHERE a1.machine_id = @machine_id
				AND (
					((@local_date_from <= alarm_on_at))
					AND ((alarm_on_at <= @local_date_to))
					)
			) AS t1
		LEFT JOIN APCSProDWH.dwh.dim_lots AS l WITH (NOLOCK) ON l.id = t1.lot_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = l.package_id
		LEFT OUTER JOIN APCSProDB.method.device_versions AS dv WITH (NOLOCK) ON dv.device_id = l.device_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_assy_device_names AS dn WITH (NOLOCK) ON dn.id = l.assy_name_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t1.machine_id
		LEFT OUTER JOIN APCSProDWH.dwh.item_labels AS il WITH (NOLOCK) ON il.name = 'fact_wip.production_category'
			AND il.val = l.production_category
		LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_codes AS ac WITH (NOLOCK) ON ac.id = t1.alarm_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_texts AS atx WITH (NOLOCK) ON atx.id = ac.alarm_text_id
		WHERE dm.id = @machine_id
			AND (
				((@local_date_from <= event_time))
				AND ((event_time <= @local_date_to))
				)
		) AS t2
	ORDER BY pid
END

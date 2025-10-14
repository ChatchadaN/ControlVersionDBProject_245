
CREATE FUNCTION [act].[fnc_LeadTime_hours] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@from INT
	,@to INT
	,@span NVARCHAR(32)
	)
RETURNS @retTbl TABLE (
	id INT
	,span INT NOT NULL
	,shift_code INT NULL
	,h TINYINT
	,date_value DATE NOT NULL
	,sum_std_time INT NULL
	,sum_lead_time INT NULL
	,sum_wait_time INT NULL
	,sum_process_time INT NULL
	,lead_time_rate FLOAT NULL
	)

BEGIN
	---------------------------------------------------------------------------------------------------------
	-- process指定無し
	---------------------------------------------------------------------------------------------------------
	IF @process_id IS NULL
	BEGIN
		INSERT INTO @retTbl
		SELECT (pm.id) AS id
			,(
				CASE @span
					WHEN 'mm'
						THEN (pm.h)
					END
				) AS span
			,(pm.shift_code) AS shift_code
			,(pm.h) AS h
			,(pm.date_value) AS date_value
			,isnull((pm.sum_std_time), 0) AS sum_std_time
			,isnull((pm.sum_lead_time), 0) AS sum_lead_time
			,isnull((pm.sum_wait_time), 0) AS sum_wait_time
			,isnull((pm.sum_process_time), 0) AS sum_process_time
			,isnull((convert(FLOAT, pm.sum_std_time) / convert(FLOAT, nullif(pm.sum_process_time + pm.sum_wait_time, 0))) * 100, 0) AS lead_time_rate
		FROM (
			SELECT dd.id AS id
				,dd.week_no AS wk
				,dd.date_value AS date_value
				,dh.h AS h
				,CASE 
					WHEN dh.code > 8
						AND dh.code <= 20
						THEN 0
							--  when dh.code < 8 and id=@from  then 2
					WHEN dh.code > 20
						AND id = @to + 1
						THEN 2
					ELSE 1
					END AS shift_code
				,dd.m AS m
				,dd.y AS y
				,isnull(shp.hour_code, 0) AS hour_code
				,shp.sum_std_time AS sum_std_time
				,shp.sum_lead_time AS sum_lead_time
				,shp.sum_wait_time AS sum_wait_time
				,shp.sum_process_time AS sum_process_time
			FROM apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK)
			CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
			LEFT OUTER JOIN (
				SELECT *
				FROM act.fnc_fact_shipment(@package_group_id, @package_id, @device_id, @device_name, @from, @to, 1)
				) AS shp ON shp.day_id = dd.id
				AND shp.hour_code = dh.code
			WHERE dd.id BETWEEN @from
					AND @to
			) AS pm
		ORDER BY date_value
			,hour_code
			-- RETURN
	END
			---------------------------------------------------------------------------------------------------------
			-- process指定有
			---------------------------------------------------------------------------------------------------------
	ELSE
	BEGIN
		INSERT INTO @retTbl
		SELECT (pm.id) AS id
			,(
				CASE @span
					WHEN 'mm'
						THEN (pm.h)
					END
				) AS span
			,(pm.shift_code) AS shift_code
			,(pm.h) AS h
			,(pm.date_value) AS date_value
			,(pm.sum_std_time) AS sum_std_time
			,isnull((pm.sum_lead_time), 0) AS sum_lead_time
			,isnull((pm.sum_wait_time), 0) AS sum_wait_time
			,isnull((pm.sum_process_time), 0) AS sum_process_time
			,isnull((convert(FLOAT, pm.sum_std_time) / convert(FLOAT, nullif(pm.sum_process_time + pm.sum_wait_time, 0))) * 100, 0) AS lead_time_rate
		FROM (
			SELECT dd.id AS id
				,dd.week_no AS wk
				,dd.date_value AS date_value
				,dh.h AS h
				,CASE 
					WHEN dh.code > 8
						AND dh.code <= 20
						THEN 0
							--  when dh.code < 8 and id=@from  then 2
					WHEN dh.code > 20
						AND id = @to + 1
						THEN 2
					ELSE 1
					END AS shift_code
				,dd.m AS m
				,dd.y AS y
				,isnull(fe.hour_code, 0) AS hour_code
				,fe.sum_std_time AS sum_std_time
				,nullif(fe.sum_lead_time, 0) AS sum_lead_time
				,fe.sum_wait_time AS sum_wait_time
				,fe.sum_process_time AS sum_process_time
			FROM apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK)
			CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
			LEFT OUTER JOIN (
				SELECT *
				FROM act.fnc_fact_end(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, 1)
				) AS fe ON fe.day_id = dd.id
				AND fe.hour_code = dh.code
			WHERE dd.id BETWEEN @from
					AND @to
			) AS pm
		ORDER BY date_value
			,hour_code
	END

	RETURN
END

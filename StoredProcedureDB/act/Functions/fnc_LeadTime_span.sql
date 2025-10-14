
CREATE FUNCTION [act].[fnc_LeadTime_span] (
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
	,hour_code TINYINT
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
		SELECT min(pm.id) AS id
			,(
				CASE @span
					WHEN 'wk'
						THEN min(pm.wk)
					WHEN 'm'
						THEN min(pm.m)
					WHEN 'dd'
						THEN min(pm.id)
					END
				) AS span
			,min(pm.hour_code) AS hour_code
			,min(pm.date_value) AS date_value
			,isnull(avg(pm.sum_std_time), 0) AS sum_std_time
			,isnull(avg(pm.sum_lead_time), 0) AS sum_lead_time
			,isnull(avg(pm.sum_wait_time), 0) AS sum_wait_time
			,isnull(avg(pm.sum_process_time), 0) AS sum_process_time
			,isnull((convert(FLOAT, avg(pm.sum_std_time)) / convert(FLOAT, nullif(avg(pm.sum_process_time) + avg(pm.sum_wait_time), 0))) * 100, 0) AS lead_time_rate
		FROM (
			SELECT dd.id AS id
				,dd.week_no AS wk
				,dd.date_value AS date_value
				,dd.m AS m
				,dd.y AS y
				,isnull(shp.hour_code, 0) AS hour_code
				,shp.sum_std_time AS sum_std_time
				,shp.sum_lead_time AS sum_lead_time
				,shp.sum_wait_time AS sum_wait_time
				,shp.sum_process_time AS sum_process_time
			FROM apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK)
			LEFT OUTER JOIN (
				SELECT *
				FROM act.fnc_fact_shipment(@package_group_id, @package_id, @device_id, @device_name, @from, @to, 0)
				) AS shp ON shp.day_id = dd.id
			WHERE dd.id BETWEEN @from
					AND @to
			) AS pm
		GROUP BY (
				CASE @span
					WHEN 'wk'
						THEN SUBSTRING(CONVERT([varchar], pm.date_value), 1, 4) + CONVERT([varchar], pm.wk)
					WHEN 'm'
						THEN SUBSTRING(CONVERT([varchar], pm.date_value), 1, 4) + CONVERT([varchar], pm.m)
					WHEN 'dd'
						THEN pm.id
					END
				)
			-- RETURN
	END
			---------------------------------------------------------------------------------------------------------
			-- process指定有
			---------------------------------------------------------------------------------------------------------
	ELSE
	BEGIN
		INSERT INTO @retTbl
		SELECT min(pm.id) AS id
			,(
				CASE @span
					WHEN 'wk'
						THEN min(pm.wk)
					WHEN 'm'
						THEN min(pm.m)
					WHEN 'dd'
						THEN min(pm.id)
					END
				) AS span
			,min(pm.hour_code) AS hour_code
			,min(pm.date_value) AS date_value
			,isnull(avg(pm.sum_std_time), 0) AS sum_std_time
			,isnull(avg(pm.sum_lead_time), 0) AS sum_lead_time
			,isnull(avg(pm.sum_wait_time), 0) AS sum_wait_time
			,isnull(avg(pm.sum_process_time), 0) AS sum_process_time
			,isnull((convert(FLOAT, avg(pm.sum_std_time)) / convert(FLOAT, nullif(avg(pm.sum_process_time) + avg(pm.sum_wait_time), 0))) * 100, 0) AS lead_time_rate
		FROM (
			SELECT dd.id AS id
				,dd.week_no AS wk
				,dd.date_value AS date_value
				,dd.m AS m
				,dd.y AS y
				,fe.hour_code AS hour_code
				,fe.sum_std_time AS sum_std_time
				,nullif(fe.sum_lead_time, 0) AS sum_lead_time
				,fe.sum_wait_time AS sum_wait_time
				,fe.sum_process_time AS sum_process_time
			FROM apcsprodwh.dwh.dim_days AS dd WITH (NOLOCK)
			LEFT OUTER JOIN (
				SELECT *
				FROM act.fnc_fact_end(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, 0)
				) AS fe ON fe.day_id = dd.id
			WHERE dd.id BETWEEN @from
					AND @to
			) AS pm
		GROUP BY (
				CASE @span
					WHEN 'wk'
						THEN SUBSTRING(CONVERT([varchar], pm.date_value), 1, 4) + CONVERT([varchar], pm.wk)
					WHEN 'm'
						THEN SUBSTRING(CONVERT([varchar], pm.date_value), 1, 4) + CONVERT([varchar], pm.m)
					WHEN 'dd'
						THEN pm.id
					END
				)
			-- RETURN
	END

	RETURN
END

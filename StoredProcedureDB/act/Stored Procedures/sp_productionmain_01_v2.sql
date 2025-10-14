
CREATE PROCEDURE [act].[sp_productionmain_01_v2] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@date_from DATE
	,@date_to DATE
	,@span NVARCHAR(32)
	,@acum BIT
	,@time_offset INT = 0
	)
AS
BEGIN
	DECLARE @from INT
	DECLARE @to INT

	SET @from = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_from
			);
	SET @to = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_to
			);

	--
	IF @span = 'wk'
		OR @span = 'm'
		-------------------------------------------------------------------------------------------------------------------------------------------------------
		--WEEKLY
		-------------------------------------------------------------------------------------------------------------------------------------------------------
	BEGIN
		SELECT *
		INTO #t_weekly
		FROM [act].fnc_ProductionMain_01_weekly_V2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span, @time_offset)

		-------------------------- 累計処理 
		IF @acum = 0
		BEGIN
			SELECT *
			FROM #t_weekly
			ORDER BY date_value
		END

		IF @acum = 1
		BEGIN
			SELECT chart1.id AS id
				,chart1.date_value AS date_value
				,chart1.span AS span
				,chart1.plan_Kpcs AS plan_Kpcs
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN input_lot_cnt
					ELSE 0
					END AS input_lot_cnt
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN input_Kpcs
					ELSE 0
					END AS input_Kpcs
				,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN input_lot_cnt_7ave
				--	ELSE 0
				--	END AS input_lot_cnt_7ave,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN input_Kpcs_7ave
				--	ELSE 0
				--	END AS input_Kpcs_7ave,
				chart1.input_lot_cnt_7ave AS input_lot_cnt_7ave
				,chart1.input_Kpcs_7ave AS input_Kpcs_7ave
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN ship_lot_cnt
					ELSE 0
					END AS ship_lot_cnt
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN ship_Kpcs
					ELSE 0
					END AS ship_Kpcs
				,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN ship_lot_cnt_7ave
				--	ELSE 0
				--	END AS ship_lot_cnt_7ave,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN ship_Kpcs_7ave
				--	ELSE 0
				--	END AS ship_Kpcs_7ave,
				chart1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
				,chart1.ship_Kpcs_7ave AS ship_Kpcs_7ave
				,CASE 
					WHEN date_value < GETDATE()
						THEN wip_days
					ELSE 0
					END AS wip_days
			FROM (
				SELECT min(aa1.id) AS id
					,aa1.date_value AS date_value
					,min(aa1.span) AS span
					,sum(aa2.plan_Kpcs) AS plan_Kpcs
					,sum(aa2.input_lot_cnt) AS input_lot_cnt
					,sum(aa2.input_Kpcs) AS input_Kpcs
					,
					--sum(aa2.input_lot_cnt_7ave) AS input_lot_cnt_7ave,
					--sum(aa2.input_Kpcs_7ave) AS input_Kpcs_7ave,
					aa1.input_lot_cnt_7ave AS input_lot_cnt_7ave
					,aa1.input_Kpcs_7ave AS input_Kpcs_7ave
					,sum(aa2.ship_lot_cnt) AS ship_lot_cnt
					,sum(aa2.ship_Kpcs) AS ship_Kpcs
					,
					--sum(aa2.ship_lot_cnt_7ave) AS ship_lot_cnt_7ave,
					--sum(aa2.ship_Kpcs_7ave) AS ship_Kpcs_7ave,
					aa1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
					,aa1.ship_Kpcs_7ave AS ship_Kpcs_7ave
					,sum(aa2.wip_days) AS wip_days
				FROM #t_weekly AS aa1
				INNER JOIN #t_weekly AS aa2 ON aa1.date_value >= aa2.date_value
				GROUP BY aa1.date_value
					,aa1.input_lot_cnt
					,aa1.input_Kpcs
					,aa1.input_lot_cnt_7ave
					,aa1.input_Kpcs_7ave
					,aa1.ship_lot_cnt
					,aa1.ship_Kpcs
					,aa1.ship_lot_cnt_7ave
					,aa1.ship_Kpcs_7ave
					,aa1.wip_days
				) AS chart1
			ORDER BY date_value
		END
	END

	-------------------------------------------------------------------------------------------------------------------------------------------------------
	--DAILY
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'dd'
	BEGIN
		SELECT *
		INTO #t_daily
		FROM [act].fnc_ProductionMain_01_daily_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span, @time_offset)
		ORDER BY date_value;

		-------------------------- 累計処理 
		IF @acum = 0
		BEGIN
			SELECT *
			FROM #t_daily
			ORDER BY date_value
		END

		IF @acum = 1
		BEGIN
			SELECT chart1.id AS id
				,chart1.date_value AS date_value
				,chart1.span AS span
				,chart1.plan_Kpcs AS plan_Kpcs
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN input_lot_cnt
					ELSE 0
					END AS input_lot_cnt
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN input_Kpcs
					ELSE 0
					END AS input_Kpcs
				,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN input_lot_cnt_7ave
				--	ELSE 0
				--	END AS input_lot_cnt_7ave,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN input_Kpcs_7ave
				--	ELSE 0
				--	END AS input_Kpcs_7ave,
				chart1.input_lot_cnt_7ave AS input_lot_cnt_7ave
				,chart1.input_Kpcs_7ave AS input_Kpcs_7ave
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN ship_lot_cnt
					ELSE 0
					END AS ship_lot_cnt
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN ship_Kpcs
					ELSE 0
					END AS ship_Kpcs
				,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN ship_lot_cnt_7ave
				--	ELSE 0
				--	END AS ship_lot_cnt_7ave,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN ship_Kpcs_7ave
				--	ELSE 0
				--	END AS ship_Kpcs_7ave,
				chart1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
				,chart1.ship_Kpcs_7ave AS ship_Kpcs_7ave
				,CASE 
					WHEN date_value < GETDATE()
						THEN wip_days
					ELSE 0
					END AS wip_days
			FROM (
				SELECT min(aa1.id) AS id
					,aa1.date_value AS date_value
					,min(aa1.span) AS span
					,sum(aa2.plan_Kpcs) AS plan_Kpcs
					,sum(aa2.input_lot_cnt) AS input_lot_cnt
					,sum(aa2.input_Kpcs) AS input_Kpcs
					,
					--sum(aa2.input_lot_cnt_7ave) AS input_lot_cnt_7ave,
					--sum(aa2.input_Kpcs_7ave) AS input_Kpcs_7ave,
					aa1.input_lot_cnt_7ave AS input_lot_cnt_7ave
					,aa1.input_Kpcs_7ave AS input_Kpcs_7ave
					,sum(aa2.ship_lot_cnt) AS ship_lot_cnt
					,sum(aa2.ship_Kpcs) AS ship_Kpcs
					,
					--sum(aa2.ship_lot_cnt_7ave) AS ship_lot_cnt_7ave,
					--sum(aa2.ship_Kpcs_7ave) AS ship_Kpcs_7ave,
					aa1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
					,aa1.ship_Kpcs_7ave AS ship_Kpcs_7ave
					,sum(aa2.wip_days) AS wip_days
				FROM #t_daily AS aa1
				INNER JOIN #t_daily AS aa2 ON aa1.date_value >= aa2.date_value
				GROUP BY aa1.date_value
					,aa1.input_lot_cnt
					,aa1.input_Kpcs
					,aa1.input_lot_cnt_7ave
					,aa1.input_Kpcs_7ave
					,aa1.ship_lot_cnt
					,aa1.ship_Kpcs
					,aa1.ship_lot_cnt_7ave
					,aa1.ship_Kpcs_7ave
					,aa1.wip_days
				) AS chart1
			ORDER BY date_value
		END
	END

	------------------------------------------------------------------------------------------------------------------------------------------------------
	--shift
	------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'shift'
	BEGIN
		SELECT *
		INTO #t_shift
		FROM [act].fnc_ProductionMain_01_shift_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span, @time_offset)
		ORDER BY id
			,shift_code

		-------------------------- 累計処理 
		IF @acum = 0
		BEGIN
			-- daytime data
			SELECT *
			FROM #t_shift
			WHERE shift_code = 0
			ORDER BY date_value;

			-- nighttime data
			SELECT *
			FROM #t_shift
			WHERE shift_code = 1
			ORDER BY date_value;
		END

		IF @acum = 1
		BEGIN
			SELECT chart1.id AS id
				,chart1.date_value AS date_value
				,chart1.shift_code AS shift_code
				,chart1.span AS span
				,chart1.plan_Kpcs AS plan_Kpcs
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN input_lot_cnt
					ELSE 0
					END AS input_lot_cnt
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN input_Kpcs
					ELSE 0
					END AS input_Kpcs
				,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN input_lot_cnt_7ave
				--	ELSE 0
				--	END AS input_lot_cnt_7ave,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN input_Kpcs_7ave
				--	ELSE 0
				--	END AS input_Kpcs_7ave,
				chart1.input_lot_cnt_7ave AS input_lot_cnt_7ave
				,chart1.input_Kpcs_7ave AS input_Kpcs_7ave
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN ship_lot_cnt
					ELSE 0
					END AS ship_lot_cnt
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN ship_Kpcs
					ELSE 0
					END AS ship_Kpcs
				,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN ship_lot_cnt_7ave
				--	ELSE 0
				--	END AS ship_lot_cnt_7ave,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN ship_Kpcs_7ave
				--	ELSE 0
				--	END AS ship_Kpcs_7ave,
				chart1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
				,chart1.ship_Kpcs_7ave AS ship_Kpcs_7ave
				,CASE 
					WHEN date_value < GETDATE()
						THEN wip_days
					ELSE 0
					END AS wip_days
			FROM (
				SELECT min(aa1.id) AS id
					,aa1.date_value AS date_value
					,max(aa1.shift_code) AS shift_code
					,min(aa1.span) AS span
					,sum(aa2.plan_Kpcs) AS plan_Kpcs
					,sum(aa2.input_lot_cnt) AS input_lot_cnt
					,sum(aa2.input_Kpcs) AS input_Kpcs
					,
					--sum(aa2.input_lot_cnt_7ave) AS input_lot_cnt_7ave,
					--sum(aa2.input_Kpcs_7ave) AS input_Kpcs_7ave,
					aa1.input_lot_cnt_7ave AS input_lot_cnt_7ave
					,aa1.input_Kpcs_7ave AS input_Kpcs_7ave
					,sum(aa2.ship_lot_cnt) AS ship_lot_cnt
					,sum(aa2.ship_Kpcs) AS ship_Kpcs
					,
					--sum(aa2.ship_lot_cnt_7ave) AS ship_lot_cnt_7ave,
					--sum(aa2.ship_Kpcs_7ave) AS ship_Kpcs_7ave,
					aa1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
					,aa1.ship_Kpcs_7ave AS ship_Kpcs_7ave
					,sum(aa2.wip_days) AS wip_days
				FROM #t_shift AS aa1
				INNER JOIN #t_shift AS aa2 ON aa1.date_value >= aa2.date_value
					AND (aa2.shift_code = aa1.shift_code)
				GROUP BY aa1.shift_code
					,aa1.date_value
					,aa1.input_lot_cnt
					,aa1.input_Kpcs
					,aa1.input_lot_cnt_7ave
					,aa1.input_Kpcs_7ave
					,aa1.ship_lot_cnt
					,aa1.ship_Kpcs
					,aa1.ship_lot_cnt_7ave
					,aa1.ship_Kpcs_7ave
					,aa1.wip_days
				) AS chart1
			WHERE chart1.shift_code = 0
			ORDER BY chart1.date_value;

			-- nighttime data
			SELECT chart1.id AS id
				,chart1.date_value AS date_value
				,chart1.shift_code AS shift_code
				,chart1.span AS span
				,chart1.plan_Kpcs AS plan_Kpcs
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN input_lot_cnt
					ELSE 0
					END AS input_lot_cnt
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN input_Kpcs
					ELSE 0
					END AS input_Kpcs
				,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN input_lot_cnt_7ave
				--	ELSE 0
				--	END AS input_lot_cnt_7ave,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN input_Kpcs_7ave
				--	ELSE 0
				--	END AS input_Kpcs_7ave,
				chart1.input_lot_cnt_7ave AS input_lot_cnt_7ave
				,chart1.input_Kpcs_7ave AS input_Kpcs_7ave
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN ship_lot_cnt
					ELSE 0
					END AS ship_lot_cnt
				,CASE 
					WHEN chart1.date_value < GETDATE()
						THEN ship_Kpcs
					ELSE 0
					END AS ship_Kpcs
				,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN ship_lot_cnt_7ave
				--	ELSE 0
				--	END AS ship_lot_cnt_7ave,
				--CASE 
				--	WHEN chart1.date_value < GETDATE()
				--		THEN ship_Kpcs_7ave
				--	ELSE 0
				--	END AS ship_Kpcs_7ave,
				chart1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
				,chart1.ship_Kpcs_7ave AS ship_Kpcs_7ave
				,CASE 
					WHEN date_value < GETDATE()
						THEN wip_days
					ELSE 0
					END AS wip_days
			FROM (
				SELECT min(aa1.id) AS id
					,aa1.date_value AS date_value
					,max(aa1.shift_code) AS shift_code
					,min(aa1.span) AS span
					,sum(aa2.plan_Kpcs) AS plan_Kpcs
					,sum(aa2.input_lot_cnt) AS input_lot_cnt
					,sum(aa2.input_Kpcs) AS input_Kpcs
					,
					--sum(aa2.input_lot_cnt_7ave) AS input_lot_cnt_7ave,
					--sum(aa2.input_Kpcs_7ave) AS input_Kpcs_7ave,
					aa1.input_lot_cnt_7ave AS input_lot_cnt_7ave
					,aa1.input_Kpcs_7ave AS input_Kpcs_7ave
					,sum(aa2.ship_lot_cnt) AS ship_lot_cnt
					,sum(aa2.ship_Kpcs) AS ship_Kpcs
					,
					--sum(aa2.ship_lot_cnt_7ave) AS ship_lot_cnt_7ave,
					--sum(aa2.ship_Kpcs_7ave) AS ship_Kpcs_7ave,
					aa1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
					,aa1.ship_Kpcs_7ave AS ship_Kpcs_7ave
					,sum(aa2.wip_days) AS wip_days
				FROM #t_shift AS aa1
				INNER JOIN #t_shift AS aa2 ON aa1.date_value >= aa2.date_value
					AND (aa2.shift_code = aa1.shift_code)
				GROUP BY aa1.shift_code
					,aa1.date_value
					,aa1.input_lot_cnt
					,aa1.input_Kpcs
					,aa1.input_lot_cnt_7ave
					,aa1.input_Kpcs_7ave
					,aa1.ship_lot_cnt
					,aa1.ship_Kpcs
					,aa1.ship_lot_cnt_7ave
					,aa1.ship_Kpcs_7ave
					,aa1.wip_days
				) AS chart1
			WHERE chart1.shift_code = 1
			ORDER BY chart1.date_value;
		END
	END

	-------------------------------------------------------------------------------------------------------------------------------------------------------
	--HOURS
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'mm'
	BEGIN
		SELECT *
		INTO #t_hours
		FROM (
			SELECT *
				,ROW_NUMBER() OVER (
					ORDER BY id
						,span
					) AS row_num
			FROM [act].fnc_ProductionMain_01_hours_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span, @time_offset)
			) AS pm_temp

		-------------------------- 累計処理 
		IF @acum = 0
		BEGIN
			SELECT *
			FROM #t_hours AS aa1
			ORDER BY date_value
				,span;
		END

		IF @acum = 1
		BEGIN
			SELECT chart1.id AS id
				,chart1.date_value AS date_value
				,chart1.span AS span
				,chart1.plan_Kpcs AS plan_Kpcs
				,CASE 
					WHEN (
							chart1.span <= DATEPART(hh, GETDATE())
							AND chart1.date_value = CONVERT(DATE, GETDATE())
							)
						OR chart1.date_value < CONVERT(DATE, GETDATE())
						THEN input_lot_cnt
					ELSE 0
					END AS input_lot_cnt
				,CASE 
					WHEN (
							chart1.span <= DATEPART(hh, GETDATE())
							AND chart1.date_value = CONVERT(DATE, GETDATE())
							)
						OR chart1.date_value < CONVERT(DATE, GETDATE())
						THEN input_Kpcs
					ELSE 0
					END AS input_Kpcs
				,
				--CASE 
				--	WHEN (
				--			chart1.span <= DATEPART(hh, GETDATE())
				--			AND chart1.date_value = CONVERT(DATE, GETDATE())
				--			)
				--		OR chart1.date_value < CONVERT(DATE, GETDATE())
				--		THEN input_lot_cnt_7ave
				--	ELSE 0
				--	END AS input_lot_cnt_7ave,
				--CASE 
				--	WHEN (
				--			chart1.span <= DATEPART(hh, GETDATE())
				--			AND chart1.date_value = CONVERT(DATE, GETDATE())
				--			)
				--		OR chart1.date_value < CONVERT(DATE, GETDATE())
				--		THEN input_Kpcs_7ave
				--	ELSE 0
				--	END AS input_Kpcs_7ave,
				chart1.input_lot_cnt_7ave AS input_lot_cnt_7ave
				,chart1.input_Kpcs_7ave AS input_Kpcs_7ave
				,CASE 
					WHEN (
							chart1.span <= DATEPART(hh, GETDATE())
							AND chart1.date_value = CONVERT(DATE, GETDATE())
							)
						OR chart1.date_value < CONVERT(DATE, GETDATE())
						THEN ship_lot_cnt
					ELSE 0
					END AS ship_lot_cnt
				,CASE 
					WHEN (
							chart1.span <= DATEPART(hh, GETDATE())
							AND chart1.date_value = CONVERT(DATE, GETDATE())
							)
						OR chart1.date_value < CONVERT(DATE, GETDATE())
						THEN ship_Kpcs
					ELSE 0
					END AS ship_Kpcs
				,
				--CASE 
				--	WHEN (
				--			chart1.span <= DATEPART(hh, GETDATE())
				--			AND chart1.date_value = CONVERT(DATE, GETDATE())
				--			)
				--		OR chart1.date_value < CONVERT(DATE, GETDATE())
				--		THEN ship_lot_cnt_7ave
				--	ELSE 0
				--	END AS ship_lot_cnt_7ave,
				--CASE 
				--	WHEN (
				--			chart1.span <= DATEPART(hh, GETDATE())
				--			AND chart1.date_value = CONVERT(DATE, GETDATE())
				--			)
				--		OR chart1.date_value < CONVERT(DATE, GETDATE())
				--		THEN ship_Kpcs_7ave
				--	ELSE 0
				--	END AS ship_Kpcs_7ave,
				chart1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
				,chart1.ship_Kpcs_7ave AS ship_Kpcs_7ave
				,CASE 
					WHEN (
							chart1.span <= DATEPART(hh, GETDATE())
							AND chart1.date_value = CONVERT(DATE, GETDATE())
							)
						OR chart1.date_value < CONVERT(DATE, GETDATE())
						THEN wip_days
					ELSE 0
					END AS wip_days
			FROM (
				SELECT min(aa1.id) AS id
					,aa1.date_value AS date_value
					,min(aa1.span) AS span
					,sum(aa2.plan_Kpcs) AS plan_Kpcs
					,sum(aa2.input_lot_cnt) AS input_lot_cnt
					,sum(aa2.input_Kpcs) AS input_Kpcs
					,
					--sum(aa2.input_lot_cnt_7ave) AS input_lot_cnt_7ave,
					--sum(aa2.input_Kpcs_7ave) AS input_Kpcs_7ave,
					aa1.input_lot_cnt_7ave AS input_lot_cnt_7ave
					,aa1.input_Kpcs_7ave AS input_Kpcs_7ave
					,sum(aa2.ship_lot_cnt) AS ship_lot_cnt
					,sum(aa2.ship_Kpcs) AS ship_Kpcs
					,
					--sum(aa2.ship_lot_cnt_7ave) AS ship_lot_cnt_7ave,
					--sum(aa2.ship_Kpcs_7ave) AS ship_Kpcs_7ave,
					aa1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
					,aa1.ship_Kpcs_7ave AS ship_Kpcs_7ave
					,sum(aa2.wip_days) AS wip_days
				FROM #t_hours AS aa1
				INNER JOIN #t_hours AS aa2 ON aa1.row_num >= aa2.row_num
				GROUP BY aa1.date_value
					,aa1.span
					,aa1.input_lot_cnt
					,aa1.input_Kpcs
					,aa1.input_lot_cnt_7ave
					,aa1.input_Kpcs_7ave
					,aa1.ship_lot_cnt
					,aa1.ship_Kpcs
					,aa1.ship_lot_cnt_7ave
					,aa1.ship_Kpcs_7ave
					,aa1.wip_days
				) AS chart1
			ORDER BY chart1.date_value;
		END
	END
END


CREATE PROCEDURE [act].[sp_productionmain_02_v2] (
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

	-------------------------------------------------------------------------------------------------------------------------------------------------------
	--WEEKLY
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'wk'
		OR @span = 'm'
	BEGIN
		SELECT *
		FROM [act].fnc_ProductionMain_02_weekly_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span, @time_offset)
		ORDER BY date_value;
	END

	-------------------------------------------------------------------------------------------------------------------------------------------------------
	--DAILY
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'dd'
	BEGIN
		SELECT *
		FROM [act].fnc_ProductionMain_02_daily_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span, @time_offset)
		ORDER BY date_value;
	END

	------------------------------------------------------------------------------------------------------------------------------------------------------
	--shift
	------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'shift'
	BEGIN
		SELECT *
		INTO #t_shift
		FROM [act].fnc_ProductionMain_02_shift_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span, @time_offset)
		ORDER BY id
			,shift_code

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

	-------------------------------------------------------------------------------------------------------------------------------------------------------
	--HOURS
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'mm'
	BEGIN
		SELECT *
			,ROW_NUMBER() OVER (
				ORDER BY id
					,span
				) AS row_num
		FROM [act].fnc_ProductionMain_02_hours_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span, @time_offset)
		ORDER BY date_value
			,span;
	END
END

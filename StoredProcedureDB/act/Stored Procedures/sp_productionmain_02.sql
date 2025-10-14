
CREATE PROCEDURE [act].[sp_productionmain_02] (
	@package_group_id INT = NULL,
	@package_id INT = NULL,
	@process_id INT = NULL,
	@device_id INT = NULL,
	@device_name VARCHAR(20) = NULL,
	@date_from DATE,
	@date_to DATE,
	@span NVARCHAR(32),
	@acum BIT
	)
AS
BEGIN
	DECLARE @from INT
	DECLARE @to INT

	SET @from = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days
			WHERE date_value = @date_from
			);
	SET @to = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days
			WHERE date_value = @date_to
			);

	-------------------------------------------------------------------------------------------------------------------------------------------------------
	--WEEKLY
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'wk'
		OR @span = 'm'
	BEGIN
		SELECT *
		--FROM dwh.fnc_ProductionMain_02_weekly(@package_group_id, @package_id, @process_id, @from, @to, @span)
		FROM [act].fnc_ProductionMain_02_weekly(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span)
		ORDER BY date_value;
	END

	-------------------------------------------------------------------------------------------------------------------------------------------------------
	--DAILY
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'dd'
	BEGIN
		SELECT *
		--FROM dwh.fnc_ProductionMain_02_daily(@package_group_id, @package_id, @process_id, @from, @to, @span)
		FROM [act].fnc_ProductionMain_02_daily(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span)
		ORDER BY date_value;
	END

	------------------------------------------------------------------------------------------------------------------------------------------------------
	--shift
	------------------------------------------------------------------------------------------------------------------------------------------------------
	IF @span = 'shift'
	BEGIN
		SELECT *
		INTO #t_shift
		--FROM dwh.fnc_ProductionMain_02_shift(@package_group_id, @package_id, @process_id, @from, @to, @span)
		FROM [act].fnc_ProductionMain_02_shift(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span)
		ORDER BY id,
			shift_code

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
		SELECT *,
			ROW_NUMBER() OVER (
				ORDER BY id,
					span
				) AS row_num
		--FROM dwh.fnc_ProductionMain_02_hours(@package_group_id, @package_id, @process_id, @from, @to, @span)
		FROM [act].fnc_ProductionMain_02_hours(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @span)
		ORDER BY date_value,
			span;
	END
END

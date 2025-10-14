
CREATE PROCEDURE [act].[sp_quality_lot_bin_piechart] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_id INT = NULL
	,@date_from DATE = '2020-08-01'
	,@date_to DATE = '2020-08-10'
	)
AS
BEGIN
	----- only use for TEST
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = @date_from
			)
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = @date_to
			)

	SELECT lpr.qty_last_pass * 100 AS bin_num
		,lpr.qty_last_pass AS bin_count
	FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
	WHERE lot_id = 352734
		AND qty_last_pass IS NOT NULL
		AND lpr.qty_last_pass > 0
	GROUP BY lpr.qty_last_pass
	ORDER BY qty_last_pass DESC
END

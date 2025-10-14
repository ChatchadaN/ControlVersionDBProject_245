
CREATE PROCEDURE [act].[sp_machinemain_ng_pareto] (
	@date_from DATETIME,
	@date_to DATETIME,
	@machine_id_list NVARCHAR(max),
	@lot_id INT
	)
AS
BEGIN
	--DECLARE @machine_id_list NVARCHAR(max) = '18'
	--DECLARE @date_from DATETIME = '2019-09-01 00:00:00'
	--DECLARE @date_to DATETIME = '2019-09-30 00:00:00'
	--DECLARE @top_num INT = 9
	--DECLARE @lot_id INT = NULL
	SELECT ROW_NUMBER() OVER (
			ORDER BY sum(pcs) DESC
			) AS ng_rank,
		t1.fail_bin_id AS fail_bin_id,
		sum(pcs) AS pcs
	FROM (
		SELECT lpr.id AS id,
			lpr.recorded_at AS recorded_at,
			lpr.lot_id AS lot_id,
			lfr.job_id AS job_id,
			lfr.fail_bin_id AS fail_bin_id,
			lfr.pcs AS pcs
		FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
		INNER JOIN APCSProDB.trans.lot_fail_records AS lfr WITH (NOLOCK) ON lfr.record_id = lpr.id
		WHERE @date_from <= lpr.recorded_at
			AND lpr.recorded_at <= @date_to
			AND lpr.machine_id IN (
				SELECT value
				FROM STRING_SPLIT(@machine_id_list, ',')
				)
			AND (
				(
					@lot_id IS NOT NULL
					AND lpr.lot_id = @lot_id
					)
				OR (@lot_id IS NULL)
				)
		) AS t1
	GROUP BY t1.fail_bin_id
	ORDER BY ng_rank
END

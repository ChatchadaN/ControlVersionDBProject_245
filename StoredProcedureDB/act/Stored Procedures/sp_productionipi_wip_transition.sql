
CREATE PROCEDURE [act].[sp_productionipi_wip_transition] @device_id INT = NULL
	,@date_from DATE = NULL
	,@date_to DATE = NULL
AS
BEGIN
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = 242
	--DECLARE @device_id INT = 5316
	--DECLARE @from INT
	--DECLARE @to INT
	--DECLARE @date_from DATE = '2019-04-01'
	--DECLARE @date_to DATE = '2019-04-22'
	DECLARE @from INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_from
			);
	DECLARE @to INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_to
			);

	SELECT dd.id AS day_id
		,dd.date_value AS date_value
		,t3.process_id AS process_id
		,t3.process_name AS process_name
		,t3.sum_lot_count AS sum_lot_count
		,isnull(convert(DECIMAL, t3.sum_pcs) / 1000, 0) AS sum_kpcs
		,t3.process_class_flag AS process_class_flag
	FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
	LEFT OUTER JOIN (
		SELECT t2.day_id AS day_id
			,t2.hour_code AS hour_code
			,t2.process_id AS process_id
			,t2.process_name AS process_name
			,t2.sum_lot_count AS sum_lot_count
			,t2.sum_pcs AS sum_pcs
			,t2.process_class_flag AS process_class_flag
		FROM (
			SELECT t1.day_id AS day_id
				,t1.hour_code AS hour_code
				,t1.process_id AS process_id
				,t1.process_name AS process_name
				,t1.job_id AS job_id
				,t1.latest_hour_code AS latest_hour_code
				,t1.lot_count AS lot_count
				,t1.pcs AS pcs
				,sum(t1.lot_count) OVER (
					PARTITION BY t1.day_id
					,t1.process_id
					) AS sum_lot_count
				,sum(cast(t1.pcs AS BIGINT)) OVER (
					PARTITION BY t1.day_id
					,t1.process_id
					) AS sum_pcs
				,CASE 
					WHEN process_id = 9
						THEN 1
					WHEN process_id = 10
						THEN 2
					ELSE 0
					END AS process_class_flag
				,row_number() OVER (
					PARTITION BY t1.day_id
					,t1.process_id ORDER BY t1.day_id
					) AS process_rank
			FROM (
				SELECT wi.day_id AS day_id
					,wi.hour_code AS hour_code
					,wi.process_id AS process_id
					,dp.name AS process_name
					,wi.job_id AS job_id
					,RANK() OVER (
						PARTITION BY wi.day_id ORDER BY wi.hour_code DESC
						) AS latest_hour_code
					,wi.lot_count AS lot_count
					,wi.pcs AS pcs
				FROM apcsprodwh.dwh.fact_wip AS wi WITH (NOLOCK)
				LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp ON dp.id = wi.process_id
				WHERE (wi.hour_code > 0)
					AND (
						wi.day_id BETWEEN @from
							AND @to
						)
					AND wi.device_id = @device_id
				) AS t1
			WHERE t1.latest_hour_code = 1
			) AS t2
		WHERE t2.process_rank = 1
		) AS t3 ON t3.day_id = dd.id
	WHERE (@from <= t3.day_id)
		AND (t3.day_id <= @to)
	ORDER BY t3.day_id
		,t3.process_id
END

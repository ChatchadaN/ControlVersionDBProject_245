
CREATE FUNCTION [act].[fnc_fact_wip_qc] (
	@package_group_id INT = NULL,
	@package_id INT = NULL,
	@process_id INT = NULL,
	@device_id INT = NULL,
	@device_name VARCHAR(20) = NULL,
	@from INT,
	@to INT,
	@hour_flag BIT
	)
RETURNS @retTbl TABLE (
	day_id INT NOT NULL,
	hour_code TINYINT,
	sum_normal_lot_count INT NOT NULL,
	sum_normal_pcs BIGINT NOT NULL,
	sum_abnormal_lot_count INT NOT NULL,
	sum_abnormal_pcs BIGINT NOT NULL
	)

BEGIN
	--DECLARE @today INT = (
	--		SELECT id
	--		FROM dwh.dim_days
	--		WHERE date_value = CONVERT(DATE, getdate())
	--		)
	--DECLARE @update_h INT = (
	--		SELECT finished_hour_code
	--		FROM dwh.function_finish_control
	--		WHERE to_fact_table = 'dwh.fact_wip'
	--		)
	INSERT INTO @retTbl
	SELECT t2.day_id AS day_id,
		t2.hour_code AS hour_code,
		sum(t2.normal_lot_count) AS sum_normal_lot_count,
		sum(t2.normal_pcs) AS sum_normal_pcs,
		sum(t2.abnormal_lot_count) AS sum_abnormal_lot_count,
		sum(t2.abnormal_pcs) AS sum_abnormal_pcs
	FROM (
		SELECT *
		FROM (
			SELECT wi.day_id AS day_id,
				wi.hour_code AS hour_code,
				wi.qc_state_code AS qc_state_code,
				RANK() OVER (
					PARTITION BY wi.day_id ORDER BY wi.hour_code DESC
					) AS latest_hour_code,
				CASE 
					WHEN wi.qc_state_code NOT IN (1, 2, 3)
						THEN wi.lot_count
					ELSE 0
					END AS normal_lot_count,
				CASE 
					WHEN wi.qc_state_code NOT IN (1, 2, 3)
						THEN cast(wi.pcs AS BIGINT)
					ELSE 0
					END AS normal_pcs,
				CASE 
					WHEN wi.qc_state_code IN (1, 2, 3)
						THEN wi.lot_count
					ELSE 0
					END AS abnormal_lot_count,
				CASE 
					WHEN wi.qc_state_code IN (1, 2, 3)
						THEN cast(wi.pcs AS BIGINT)
					ELSE 0
					END AS abnormal_pcs
			--sum(wi.lot_count) AS sum_lot_count,
			--sum(cast(wi.pcs AS BIGINT)) AS sum_pcs
			FROM apcsprodwh.dwh.fact_wip AS wi WITH (NOLOCK)
			LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = wi.device_id
			WHERE (wi.hour_code > 0)
				AND (
					wi.day_id BETWEEN @from
						AND @to
					)
				AND (
					(
						@package_id IS NOT NULL
						AND wi.package_id = @package_id
						)
					OR (
						@package_id IS NULL
						AND @package_group_id IS NOT NULL
						AND wi.package_group_id = @package_group_id
						)
					OR (
						@package_id IS NULL
						AND @package_group_id IS NULL
						AND wi.package_id > 0
						)
					)
				AND (
					(
						@process_id IS NOT NULL
						AND wi.process_id = @process_id
						)
					OR (
						@process_id IS NULL
						AND wi.process_id >= 0
						)
					)
				AND (
				(
					@device_name IS NOT NULL
					AND ddv.name = @device_name
					)
				OR (@device_name IS NULL)
				)
			) AS t1
		WHERE (
				(
					@hour_flag = 0
					AND t1.latest_hour_code = 1
					)
				OR (@hour_flag = 1)
				)
		) AS t2
	GROUP BY t2.day_id,
		t2.hour_code
	ORDER BY t2.day_id,
		t2.hour_code

	RETURN
END

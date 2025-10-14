
CREATE FUNCTION [act].[fnc_fact_shipment_v2] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@from INT
	,@to INT
	,@hour_flag BIT
	,@time_offset INT = 0
	)
RETURNS @retTbl TABLE (
	day_id INT NOT NULL
	,hour_code TINYINT
	,lot_count INT
	,pcs INT
	,sum_std_time INT
	,sum_lead_time INT
	,sum_process_time INT
	,sum_wait_time INT
	,LotAve7days FLOAT
	,PcsAve7days FLOAT
	)

BEGIN
	INSERT INTO @retTbl
	SELECT t4.day_id AS day_id
		,CASE 
			WHEN @hour_flag = 1
				THEN t4.hour_code
			END AS hour_code
		,isnull(t4.lot_count, 0) AS lot_count
		,isnull(t4.pass_pcs, 0) AS pass_pcs
		,t4.std_time AS std_time
		,t4.lead_time AS lead_time
		,t4.process_time AS process_time
		,t4.wait_time AS wait_time
		,CASE 
			WHEN count(t4.day_id) OVER (
					ORDER BY t4.day_id rows BETWEEN 7 preceding
							AND 1 preceding
					) > 0
				THEN isnull(round(convert(FLOAT, sum(t4.lot_count) OVER (
									ORDER BY t4.day_id rows BETWEEN 7 preceding
											AND 1 preceding
									)) / count(t4.day_id) OVER (
								ORDER BY t4.day_id rows BETWEEN 7 preceding
										AND 1 preceding
								), 0), 1)
			ELSE 0
			END AS LotAve7days
		,CASE 
			WHEN count(t4.day_id) OVER (
					ORDER BY t4.day_id rows BETWEEN 7 preceding
							AND 1 preceding
					) > 0
				THEN isnull(sum(t4.pass_pcs) OVER (
							ORDER BY t4.day_id rows BETWEEN 7 preceding
									AND 1 preceding
							) / count(t4.day_id) OVER (
							ORDER BY t4.day_id rows BETWEEN 7 preceding
									AND 1 preceding
							), 0)
			ELSE 0
			END AS PcsAve7days
	FROM (
		SELECT t3.new_day_id AS day_id
			,CASE 
				WHEN @hour_flag = 1
					THEN t3.hour_code
				END AS hour_code
			,sum(t3.lot_count - t3.d_lot_counter) AS lot_count
			,sum(t3.pass_pcs) AS pass_pcs
			,avg(t3.std_time) AS std_time
			,avg(t3.lead_time) AS lead_time
			,avg(t3.wait_time) AS wait_time
			,avg(t3.process_time) AS process_time
		FROM (
			SELECT t2.new_day_id AS new_day_id
				,t2.hour_code AS hour_code
				,isnull(count(t2.lot_id), 0) AS lot_count
				,isnull(sum(t2.d_lot_counter), 0) AS d_lot_counter
				,isnull(sum(t2.pass_pcs), 0) AS pass_pcs
				,avg(t2.std_time) AS std_time
				,avg(t2.lead_time) AS lead_time
				,avg(t2.wait_time) AS wait_time
				,avg(t2.process_time) AS process_time
			FROM (
				SELECT dd.day_id AS day_id
					,CASE 
						WHEN dd.hour_code < @time_offset + 1
							THEN dd.day_id - 1
						ELSE dd.day_id
						END AS new_day_id
					,dd.hour_code AS hour_code
					,t1.package_id AS package_id
					,t1.lot_id AS lot_id
					,t1.pass_pcs AS pass_pcs
					,t1.std_time AS std_time
					,t1.lead_time AS lead_time
					,t1.wait_time AS wait_time
					,t1.process_time AS process_time
					,t1.lot_no AS lot_no
					,CASE 
						WHEN substring(t1.lot_no, 5, 1) = 'D'
							THEN 1
						ELSE 0
						END AS d_lot_counter
				FROM (
					SELECT ddy.id AS day_id
						,dh.code AS hour_code
					FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
					CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
					) AS dd
				LEFT OUTER JOIN (
					SELECT fs.day_id AS day_id
						,fs.hour_code AS hour_code
						,fs.package_id
						,fs.lot_id
						,fs.pass_pcs
						,fs.std_time
						,fs.lead_time
						,fs.wait_time
						,fs.process_time
						,tl.lot_no AS lot_no
						,tl.wip_state AS wip_state
					FROM apcsprodwh.dwh.fact_shipment AS fs WITH (NOLOCK)
					INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fs.lot_id
					LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fs.device_id
					WHERE (
							(
								@package_id IS NOT NULL
								AND fs.package_id = @package_id
								)
							OR (
								@package_id IS NULL
								AND @package_group_id IS NOT NULL
								AND fs.package_group_id = @package_group_id
								)
							OR (
								@package_id IS NULL
								AND @package_group_id IS NULL
								AND fs.package_id > 0
								)
							)
						AND (
							(
								@device_name IS NOT NULL
								AND ddv.name = @device_name
								)
							OR (@device_name IS NULL)
							)
						AND tl.wip_state <> 101
					) AS t1 ON t1.day_id = dd.day_id
					AND t1.hour_code = dd.hour_code
				WHERE dd.day_id BETWEEN @from - 7
						AND @to + 1
				) AS t2
			GROUP BY t2.new_day_id
				,hour_code
			) AS t3
		GROUP BY t3.new_day_id
			,CASE 
				WHEN @hour_flag = 1
					THEN t3.hour_code
				END
		) AS t4
	WHERE t4.day_id BETWEEN @from - 7
			AND @to + 1

	RETURN
END

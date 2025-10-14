
CREATE PROCEDURE [act].[sp_home_worst] @date DATE = ''
AS
BEGIN
	-- date
	DECLARE @wip_day_id INT
	DECLARE @wip_hour_code INT
	DECLARE @from INT
	DECLARE @to INT

	------------------------------------------------------------------------
	-- Setup date
	------------------------------------------------------------------------
	-- yesterday
	SET @from = (
			SELECT id - 1
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date
			);
	--today
	SET @to = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date
			);
	------------------------------------------------------------------------
	-- Select
	------------------------------------------------------------------------
	SET @wip_day_id = (
			SELECT finished_day_id
			FROM apcsprodwh.dwh.function_finish_control WITH (NOLOCK)
			WHERE to_fact_table = 'dwh.fact_wip'
			);
	SET @wip_hour_code = (
			SELECT finished_hour_code
			FROM apcsprodwh.dwh.function_finish_control WITH (NOLOCK)
			WHERE to_fact_table = 'dwh.fact_wip'
			);

	SELECT t1.package_id AS package_id
		,t1.package_name AS package_name
		,
		-- t1.day_id as day_id,
		-- isnull(t1.pcs,0) as pcs,
		-- isnull(t2.sum_pass_pcs,0) as pass_pcs,
		round(convert(FLOAT, isnull(t2.sum_pass_pcs, 0) - isnull(t1.pcs, 0)) / 1000, 1) AS diff_Kpcs
		,lc.sum_lot_count AS sum_delay_lot
	FROM (
		SELECT fp.package_id AS package_id
			,pc.name AS package_name
			,fp.day_id AS day_id
			,sum(fp.pcs) AS pcs
		FROM apcsprodwh.dwh.dim_packages AS pc WITH (NOLOCK)
		INNER JOIN apcsprodwh.dwh.fact_plan AS fp WITH (NOLOCK) ON fp.package_id = pc.id
		WHERE fp.day_id = @from
		GROUP BY fp.day_id
			,fp.package_id
			,pc.name
		) AS t1
	LEFT OUTER JOIN (
		SELECT t3.package_id AS package_id
			,sum(t3.pass_pcs) AS sum_pass_pcs
		FROM (
			SELECT fs.package_id AS package_id
				,fs.day_id + CASE 
					WHEN fs.hour_code > 8
						THEN 0
					ELSE - 1
					END AS new_day_id
				,fs.hour_code AS hour_code
				,fs.pass_pcs AS pass_pcs
			FROM apcsprodwh.dwh.fact_shipment AS fs WITH (NOLOCK)
			) AS t3
		WHERE t3.new_day_id = @from
		GROUP BY t3.new_day_id
			,t3.package_id
		) AS t2 ON t2.package_id = t1.package_id
	LEFT OUTER JOIN (
		SELECT wi.package_id
			,wi.day_id AS day_id
			,pc.name AS package_name
			,SUM(wi.lot_count) AS sum_lot_count
		FROM apcsprodwh.dwh.dim_packages AS pc WITH (NOLOCK)
		INNER JOIN apcsprodwh.dwh.fact_wip AS wi WITH (NOLOCK) ON wi.package_id = pc.id
		WHERE day_id = @wip_day_id
			AND wi.hour_code = @wip_hour_code
			AND delay_state_code = 10
		GROUP BY wi.package_id
			,wi.day_id
			,pc.name
		) AS lc ON lc.package_id = t1.package_id
	ORDER BY diff_Kpcs
END

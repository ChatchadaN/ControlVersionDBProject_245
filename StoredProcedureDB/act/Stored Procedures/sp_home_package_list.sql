
CREATE PROCEDURE [act].[sp_home_package_list] @unit NVARCHAR(32) = NULL
	,@sort NVARCHAR(32) = NULL
AS
BEGIN
	SELECT t3.*
	INTO #table
	FROM (
		SELECT t2.*
			,CONVERT(DECIMAL(4, 1), sum(convert(FLOAT, sum_lots) * 100 / all_lot_count) OVER (
					ORDER BY t2.sum_lots DESC rows unbounded preceding
					)) AS percent_lots
			,CONVERT(DECIMAL(4, 1), sum(convert(FLOAT, sum_Kpcs) * 100 / all_sum_Kpcs) OVER (
					ORDER BY t2.sum_Kpcs DESC rows unbounded preceding
					)) AS percent_Kpcs
			,isnull(t.in_alarm_cnt, 0) AS in_alarm_cnt
		FROM (
			SELECT t1.package_id AS package_id
				,t1.package_name AS package_name
				,isnull(t1.sum_lot_count, 0) AS sum_lots
				,isnull(round(t1.sum_pcs, - 3) / 1000, 0) AS sum_Kpcs
				,sum(isnull(t1.sum_lot_count, 0)) OVER (PARTITION BY const) AS all_lot_count
				,sum(isnull(round(t1.sum_pcs, - 3) / 1000, 0)) OVER (PARTITION BY const) AS all_sum_Kpcs
			FROM (
				SELECT lc.*
				FROM (
					SELECT wi.package_id
						,pc.name AS package_name
						,SUM(wi.lot_count) AS sum_lot_count
						,SUM(wi.pcs) AS sum_pcs
						,1 AS const
					FROM APCSProDWH.dwh.dim_packages AS pc WITH (NOLOCK)
					INNER JOIN APCSProDWH.dwh.fact_wip AS wi WITH (NOLOCK) ON wi.package_id = pc.id
					WHERE (
							day_id = (
								SELECT finished_day_id
								FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
								WHERE to_fact_table = 'dwh.fact_wip'
								)
							)
						AND wi.hour_code = (
							SELECT finished_hour_code
							FROM APCSProDWH.dwh.function_finish_control WITH (NOLOCK)
							WHERE to_fact_table = 'dwh.fact_wip'
							)
					GROUP BY wi.package_id
						,pc.name
					) AS lc
				) AS t1
			) AS t2
		LEFT OUTER JOIN (
			SELECT lim.id AS package_id
				,lim.is_input_stopped AS in_alarm_cnt
			FROM (
				SELECT mp.id AS id
					,mp.is_input_stopped AS is_input_stopped
				FROM APCSProDB.method.packages AS mp WITH (NOLOCK)
				INNER JOIN APCSProDWH.dwh.dim_packages AS p WITH (NOLOCK) ON p.id = mp.id
				) AS lim
			) AS t ON t.package_id = t2.package_id
		) AS t3;

	IF @sort = 'Pkg'
	BEGIN
		SELECT *
		FROM #table
		ORDER BY package_name
	END
	ELSE
	BEGIN
		IF @unit = 'Kpcs'
		BEGIN
			SELECT *
			FROM #table
			ORDER BY percent_Kpcs
		END
		ELSE
		BEGIN
			SELECT *
			FROM #table
			ORDER BY percent_lots
		END
	END
END

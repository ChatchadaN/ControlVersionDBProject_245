
CREATE PROCEDURE [act].[sp_machinecapa_factend_test] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@date_from DATE
	,@date_to DATE
	,@time_offset INT = 0
	,@machine_id INT
	)
AS
BEGIN
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = 242
	--DECLARE @process_id INT = NULL
	--DECLARE @device_id INT = null
	--DECLARE @machine_id INT = 19
	--DECLARE @device_name VARCHAR(20) = NULL
	--DECLARE @date_from DATE = '2021-04-01'
	--DECLARE @date_to DATE = '2021-05-01'
	--DECLARE @span NVARCHAR(32) = 'dd'
	--DECLARE @acum BIT = 0
	--DECLARE @time_offset INT = 0
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

	SELECT --u1.y
		--,u1.m
		--,u1.day_id
		--,
		u1.date_value
		--,CASE 
		--	WHEN u1.date_value < getdate()
		--		THEN u1.pass_lot
		--	ELSE NULL
		--	END AS pass_lot
		--,CASE 
		--	WHEN u1.date_value < getdate()
		--		THEN u1.pass_kpcs
		--	ELSE NULL
		--	END AS pass_kpcs
		--,CASE 
		--	WHEN u1.date_value < getdate()
		--		THEN u1.other_pass_lot
		--	ELSE NULL
		--	END AS other_pass_lot
		--,CASE 
		--	WHEN u1.date_value < getdate()
		--		THEN u1.other_pass_kpcs
		--	ELSE NULL
		--	END AS other_pass_kpcs
		--,CASE 
		--	WHEN u1.date_value < getdate()
		--		THEN sum(u1.pass_lot) OVER (
		--				ORDER BY day_id
		--				)
		--	ELSE NULL
		--	END AS accum_pass_lot
		--,CASE 
		--	WHEN u1.date_value < getdate()
		--		THEN sum(u1.pass_kpcs) OVER (
		--				ORDER BY day_id
		--				)
		--	ELSE NULL
		--	END AS accum_pass_kpcs
		--,CASE 
		--	WHEN u1.date_value < getdate()
		--		THEN sum(u1.other_pass_lot) OVER (
		--				ORDER BY day_id
		--				)
		--	ELSE NULL
		--	END AS accum_other_pass_lot
		--,CASE 
		--	WHEN u1.date_value < getdate()
		--		THEN sum(u1.other_pass_kpcs) OVER (
		--				ORDER BY day_id
		--				)
		--	ELSE NULL
		--	END AS accum_other_pass_kpcs

		,u1.lot_no
		--,u1.other_lot_no

		,CASE 
			WHEN u1.date_value < getdate()
				THEN u1.pass_kpcs
			ELSE NULL
			END AS pass_kpcss
	FROM (
		SELECT s1.y
			,s1.m
			,s1.day_id
			,s1.date_value
			--,s2.lot_count AS pass_lot
			,convert(DECIMAL(12, 3), s2.pass_pcs) / 1000 AS pass_kpcs
			--,s3.lot_count - s2.lot_count AS other_pass_lot
			--,convert(DECIMAL(12, 3), (s3.pass_pcs - s2.pass_pcs)) / 1000 AS other_pass_kpcs
			,s2.lot_no AS lot_no
		FROM (
			SELECT d.y
				,d.m
				,d.id AS day_id
				,d.date_value
			FROM apcsprodwh.dwh.dim_days AS d WITH (NOLOCK)
			WHERE d.id BETWEEN @from
					AND @to
			) AS s1
		LEFT JOIN (
			SELECT t1.new_day_id AS day_id
				--,isnull(count(t1.lot_id), 0) - isnull(sum(t1.d_lot_counter), 0) AS lot_count
				--,isnull(sum(t1.d_lot_counter), 0) AS d_lot_counter
				--,isnull(sum(t1.pass_pcs), 0) AS pass_pcs
				,t1.pass_pcs AS pass_pcs
				,t1.lot_no AS lot_no
			FROM (
				SELECT dd.day_id AS day_id
					,CASE 
						WHEN dd.hour_code < @time_offset + 1
							THEN dd.day_id - 1
						ELSE dd.day_id
						END AS new_day_id
					,dd.hour_code AS hour_code
					,fe3.package_id AS package_id
					,fe3.lot_id AS lot_id
					,isnull(fe3.pass_pcs, 0) AS pass_pcs
					,fe3.code AS code
					,fe3.lot_no AS lot_no
					,CASE 
						WHEN substring(fe3.lot_no, 5, 1) = 'D'
							THEN 1
						ELSE 0
						END AS d_lot_counter
				FROM (
					SELECT ddy.id AS day_id
						,dh.code AS hour_code
					FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
					CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
					WHERE ddy.id BETWEEN @from - 1
							AND @to + 1
					) AS dd
				LEFT JOIN (
					SELECT fe2.*
					FROM (
						SELECT fe.day_id AS day_id
							,fe.hour_code AS hour_code
							,fe.package_id
							,fe.process_id
							,fe.job_id
							--同工程で複数回処理された時は、一番最後のデータで集計する
							,rank() OVER (
								PARTITION BY fe.lot_id
								,fe.process_id
								,fe.job_id ORDER BY fe.day_id DESC
									,fe.hour_code DESC
								) AS lot_rank
							,fe.lot_id
							,fe.pass_pcs
							,fe.code AS code
							,tl.lot_no AS lot_no
							,tl.wip_state AS wip_state
						FROM apcsprodwh.dwh.fact_end AS fe WITH (NOLOCK)
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fe.lot_id
						LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fe.device_id
						WHERE (
								(
									@package_id IS NOT NULL
									AND fe.package_id = @package_id
									)
								OR (
									@package_id IS NULL
									AND @package_group_id IS NOT NULL
									AND fe.package_group_id = @package_group_id
									)
								OR (
									@package_id IS NULL
									AND @package_group_id IS NULL
									AND fe.package_id > 0
									)
								)
							AND (
								(
									@process_id IS NOT NULL
									AND fe.process_id = @process_id
									)
								OR (
									@process_id IS NULL
									AND fe.process_id >= 0
									)
								)
							AND (
								(
									@device_name IS NOT NULL
									AND ddv.name = @device_name
									)
								OR (@device_name IS NULL)
								)
							--AND fe.code = 2
							AND tl.wip_state <> 101
							AND fe.machine_id = @machine_id
							AND fe.day_id BETWEEN @from - 1
								AND @to + 1
						) AS fe2
					WHERE fe2.lot_rank = 1
					) AS fe3 ON fe3.day_id = dd.day_id
					AND fe3.hour_code = dd.hour_code
				) AS t1
			--GROUP BY t1.new_day_id
			) AS s2 ON s2.day_id = s1.day_id
		LEFT JOIN (
			SELECT t2.new_day_id AS day_id
				,isnull(count(t2.lot_id), 0) - isnull(sum(t2.d_lot_counter), 0) AS lot_count
				--,isnull(sum(t2.d_lot_counter), 0) AS d_lot_counter
				,isnull(sum(t2.pass_pcs), 0) AS pass_pcs
			FROM (
				SELECT dd.day_id AS day_id
					,CASE 
						WHEN dd.hour_code < @time_offset + 1
							THEN dd.day_id - 1
						ELSE dd.day_id
						END AS new_day_id
					,dd.hour_code AS hour_code
					,fe3.package_id AS package_id
					,fe3.lot_id AS lot_id
					,isnull(fe3.pass_pcs, 0) AS pass_pcs
					,fe3.code AS code
					,fe3.lot_no AS lot_no
					,CASE 
						WHEN substring(fe3.lot_no, 5, 1) = 'D'
							THEN 1
						ELSE 0
						END AS d_lot_counter
				FROM (
					SELECT ddy.id AS day_id
						,dh.code AS hour_code
					FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
					CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
					WHERE ddy.id BETWEEN @from - 1
							AND @to + 1
					) AS dd
				LEFT JOIN (
					SELECT fe2.*
					FROM (
						SELECT fe.day_id AS day_id
							,fe.hour_code AS hour_code
							,fe.package_id
							,fe.process_id
							,fe.job_id
							--同工程で複数回処理された時は、一番最後のデータで集計する
							,rank() OVER (
								PARTITION BY fe.lot_id
								,fe.process_id
								,fe.job_id ORDER BY fe.day_id DESC
									,fe.hour_code DESC
								) AS lot_rank
							,fe.lot_id
							,fe.pass_pcs
							,fe.code AS code
							,tl.lot_no AS lot_no
							,tl.wip_state AS wip_state
						FROM apcsprodwh.dwh.fact_end AS fe WITH (NOLOCK)
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fe.lot_id
						WHERE tl.wip_state <> 101
							AND fe.machine_id = @machine_id
							AND fe.day_id BETWEEN @from - 1
								AND @to + 1
						) AS fe2
					WHERE fe2.lot_rank = 1
					) AS fe3 ON fe3.day_id = dd.day_id
					AND fe3.hour_code = dd.hour_code
				) AS t2
			GROUP BY t2.new_day_id
			) AS s3 ON s3.day_id = s1.day_id
		) AS u1
	WHERE [lot_no] IS NOT NULL
	ORDER BY day_id
END

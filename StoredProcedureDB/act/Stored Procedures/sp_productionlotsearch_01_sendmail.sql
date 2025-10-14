
CREATE PROCEDURE [act].[sp_productionlotsearch_01_sendmail]
AS
BEGIN
	DECLARE @package_group_id INT = NULL
	DECLARE @package_id INT = NULL
	DECLARE @process_id INT = NULL
	DECLARE @job_id INT = NULL
	DECLARE @is_assy_only INT = NULL
	DECLARE @lot_type_list NVARCHAR(max) = NULL
	--
	DECLARE @all BIT = 0
	DECLARE @wip BIT = 1
	DECLARE @shipped BIT = 0
	DECLARE @pre_dc BIT = 0
	DECLARE @dc BIT = 0
	DECLARE @lo BIT = 0
	DECLARE @records INT = 20000
	--
	DECLARE @date_from DATE = dateadd(DAY, - 7, convert(DATE, GETDATE()))
	DECLARE @date_to DATE = convert(DATE, GETDATE())
	DECLARE @d_fil INT = 0
	--!!IMPORTANT!! Replace parameter to local variables 
	--ローカル変数に置き換え。速度向上の為
	DECLARE @local_package_group_id INT = @package_group_id
	DECLARE @local_package_id INT = @package_id
	DECLARE @local_process_id INT = @process_id
	DECLARE @local_job_id INT = @job_id
	DECLARE @local_is_assy_only INT = @is_assy_only
	DECLARE @local_lot_type_list NVARCHAR(max) = @lot_type_list
	--
	DECLARE @local_all BIT = @all
	DECLARE @local_wip BIT = @wip
	DECLARE @local_shipped BIT = @shipped
	DECLARE @local_pre_dc BIT = @pre_dc
	DECLARE @local_dc BIT = @dc
	DECLARE @local_lo BIT = @lo
	DECLARE @local_records INT = @records
	--
	DECLARE @local_date_from DATE = @date_from
	DECLARE @local_date_to DATE = @date_to
	DECLARE @local_d_fil INT = @d_fil
	------------------------------------------------------------------------------------------------------------------------
	DECLARE @from INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @local_date_from
			);
	DECLARE @to INT = (
			SELECT id
			FROM apcsprodwh.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @local_date_to
			);
	DECLARE @from_time DATETIME = (
			SELECT DATEADD(HOUR, 8, CONVERT(DATETIME, @local_date_from))
			);
	DECLARE @to_time DATETIME = (
			SELECT DATEADD(HOUR, 8 + 24, CONVERT(DATETIME, @local_date_to))
			);
	DECLARE @wip_state INT = CASE 
			WHEN @local_all = 1
				THEN - 1
			WHEN @local_wip = 1
				THEN 20
			WHEN @local_shipped = 1
				THEN 100
			WHEN @local_pre_dc = 1
				THEN 0
			WHEN @local_dc = 1
				THEN 10
			WHEN @local_lo = 1
				THEN 210
			ELSE - 2
			END;

	-----------------------------------------------------------------------------------------------------------------------
	--IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
	--	DROP TABLE #table;
	------------------------------------------------------------------------------------------------------------------------
	SELECT t1.lot_id AS lot_id
		,t1.lot_no AS lot_no
		,t1.wip_state AS wip_state
		,t1.order_id AS order_id
		,t1.order_no AS order_no
		,t1.package_group_name AS package_group_name
		,t1.package_name AS package_name
		,t1.device_name AS device_name
		,t1.is_assy_only AS is_assy_only
		,t1.step_no AS step_no
		,t1.process_id AS process_id
		,t1.process_name AS process_name
		,t1.job_id AS job_id
		,t1.job_name AS job_name
		,t1.qty_in AS qty_in
		,t1.qty_fail AS qty_fail
		,t1.is_special_flow AS is_special_flow
		,t1.process_state AS process_state
		,t1.process_state_eng AS process_state_eng
		,t1.process_state_jpn AS process_state_jpn
		,t1.quality_state AS quality_state
		,t1.quality_state_eng AS quality_state_eng
		,t1.quality_state_jpn AS quality_state_jpn
		,t1.delay1 AS delay1
		,t1.delay2 AS delay2
		,t1.lot_id_rank AS lot_id_rank
		,t1.chip_name AS chip_name
		,t1.fab_lot_no AS fab_lot_no
		,t1.wafer_no AS wafer_no
		,t1.mno AS mno
		,t1.assy_name AS assy_name
		,t1.ft_name AS ft_name
		,t1.device_slip_id AS device_slip_id
		,t1.version_no AS version_no
		,t1.os_program_name AS os_program_name
		,t1.ft_rank AS ft_rank
		,t1.tp_rank AS tp_rank
		,t1.in_plan_date AS in_plan_date
		,t1.in_at AS in_at
		,t1.out_plan_date AS out_plan_date
		,t1.ship_at AS ship_at
		,t1.modify_out_plan_date AS modify_out_plan_date
		,t1.modified_at AS modified_at
		,t1.modified_by AS modified_by
		,t1.lead_time AS lead_time
		,t1.special_flow_id AS special_flow_id
	INTO #table
	FROM (
		SELECT tl.id AS lot_id
			,tl.lot_no AS lot_no
			,tl.wip_state AS wip_state
			,maf.order_id AS order_id
			,ao.order_no AS order_no
			,dpg.name AS package_group_name
			,dp.name AS package_name
			,dd.name AS device_name
			,dd.is_assy_only AS is_assy_only
			,tl.step_no AS step_no
			,tl.act_process_id AS process_id
			,dpr.name AS process_name
			,tl.act_job_id AS job_id
			,dj.name AS job_name
			,tl.qty_in AS qty_in
			,tl.qty_fail AS qty_fail
			,tl.is_special_flow AS is_special_flow
			,tl.process_state AS process_state
			,il.label_eng AS process_state_eng
			,il.label_jpn AS process_state_jpn
			,tl.quality_state AS quality_state
			,il2.label_eng AS quality_state_eng
			,il2.label_jpn AS quality_state_jpn
			,CASE 
				WHEN (tl.pass_plan_time_up > GETDATE())
					THEN 0
				ELSE isnull(round(convert(FLOAT, datediff(hh, tl.pass_plan_time_up, GETDATE())) / 24, 2), 0)
				END AS delay1
			,CASE 
				WHEN (tl.pass_plan_time > GETDATE())
					THEN 0
				ELSE isnull(round(convert(FLOAT, datediff(hh, tl.pass_plan_time, GETDATE())) / 24, 2), 0)
				END AS delay2
			,row_number() OVER (
				PARTITION BY tl.id ORDER BY tl.id
				) AS lot_id_rank
			,d.chipname AS chip_name
			,d.waferlotno AS fab_lot_no
			,d.waferno AS wafer_no
			,lif.mno AS mno
			,ao.assy_name AS assy_name
			,ao.ft_name AS ft_name
			,pgs.device_slip_id AS device_slip_id
			,pgs.version_num AS version_no
			,pgs.os_program_name AS os_program_name
			,dd.rank AS ft_rank
			,dd.tp_rank AS tp_rank
			,(
				SELECT date_value
				FROM apcsprodb.trans.days AS td WITH (NOLOCK)
				WHERE tl.in_plan_date_id = td.id
				) AS in_plan_date
			,tl.in_at AS in_at
			,(
				SELECT date_value
				FROM apcsprodb.trans.days AS td WITH (NOLOCK)
				WHERE tl.out_plan_date_id = td.id
				) AS out_plan_date
			,tl.ship_at AS ship_at
			,(
				SELECT date_value
				FROM apcsprodb.trans.days AS td WITH (NOLOCK)
				WHERE tl.modify_out_plan_date_id = td.id
				) AS modify_out_plan_date
			,tl.modified_at AS modified_at
			,tl.modified_by AS modified_by
			,CASE 
				WHEN wip_state = 20
					THEN isnull(round(convert(FLOAT, datediff(hh, tl.in_at, GETDATE())) / 24, 1), NULL)
				WHEN wip_state = 100
					THEN isnull(round(convert(FLOAT, datediff(hh, tl.in_at, tl.ship_at)) / 24, 1), NULL)
				ELSE NULL
				END AS lead_time
			,tl.special_flow_id AS special_flow_id
		FROM APCSProDB.trans.lots AS tl WITH (NOLOCK)
		LEFT OUTER JOIN APCSProDB.robin.assy_orders AS ao WITH (NOLOCK) ON ao.id = tl.order_id
		LEFT OUTER JOIN APCSProDB.robin.material_allocates_front AS maf WITH (NOLOCK) ON maf.lot_id = tl.id
			AND maf.order_id = tl.order_id
		LEFT OUTER JOIN (
			SELECT a.lot_id AS lot_id
				,a.united_chipname AS chipname
				,b.united_wafer_lot_no AS waferlotno
				,c.united_wafer_no AS waferno
			FROM (
				SELECT tb3.lot_id AS lot_id
					,string_agg(tb3.chip_name, ',') within
				GROUP (
						ORDER BY tb3.chip_name
						) AS united_chipname
				FROM (
					SELECT tb2.lot_id AS lot_id
						,tb2.chip_name AS chip_name
					FROM (
						SELECT tb1.lot_id AS lot_id
							,tb1.chip_name AS chip_name
						FROM APCSProDB.robin.material_allocates_front AS tb1 WITH (NOLOCK)
						) AS tb2
					GROUP BY tb2.lot_id
						,tb2.chip_name
					) AS tb3
				GROUP BY tb3.lot_id
				) AS a
			INNER JOIN (
				SELECT tb3.lot_id AS lot_id
					,string_agg(tb3.wafer_lot_no, ',') within
				GROUP (
						ORDER BY tb3.wafer_lot_no
						) AS united_wafer_lot_no
				FROM (
					SELECT tb2.lot_id AS lot_id
						,tb2.wafer_lot_no AS wafer_lot_no
					FROM (
						SELECT tb1.lot_id AS lot_id
							,tb1.wafer_lot_no AS wafer_lot_no
						FROM APCSProDB.robin.material_allocates_front AS tb1 WITH (NOLOCK)
						) AS tb2
					GROUP BY tb2.lot_id
						,tb2.wafer_lot_no
					) AS tb3
				GROUP BY tb3.lot_id
				) AS b ON b.lot_id = a.lot_id
			INNER JOIN (
				SELECT tb3.lot_id AS lot_id
					,string_agg(tb3.wafer_no, ',') within
				GROUP (
						ORDER BY tb3.wafer_no
						) AS united_wafer_no
				FROM (
					SELECT tb2.lot_id AS lot_id
						,tb2.wafer_no AS wafer_no
					FROM (
						SELECT tb1.lot_id AS lot_id
							,tb1.wafer_no AS wafer_no
						FROM APCSProDB.robin.material_allocates_front AS tb1 WITH (NOLOCK)
						) AS tb2
					GROUP BY tb2.lot_id
						,tb2.wafer_no
					) AS tb3
				GROUP BY tb3.lot_id
				) AS c ON c.lot_id = a.lot_id
			) AS d ON d.lot_id = tl.id
		LEFT OUTER JOIN APCSProDB.robin.lot_information_front AS lif WITH (NOLOCK) ON lif.lot_id = tl.id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON tl.act_package_id = dp.id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_package_groups AS dpg WITH (NOLOCK) ON dp.package_group_id = dpg.id
		LEFT OUTER JOIN APCSProDB.method.device_names AS dd WITH (NOLOCK) ON tl.act_device_name_id = dd.id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dpr WITH (NOLOCK) ON tl.act_process_id = dpr.id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON tl.act_job_id = dj.id
		LEFT OUTER JOIN APCSProDB.method.device_slips AS pgs WITH (NOLOCK) ON tl.device_slip_id = pgs.device_slip_id
		LEFT OUTER JOIN APCSProDB.trans.item_labels AS il WITH (NOLOCK) ON il.val = tl.process_state
			AND il.name = 'lots.process_state'
		LEFT OUTER JOIN apcsprodb.trans.item_labels AS il2 WITH (NOLOCK) ON il2.val = tl.quality_state
			AND il2.name = 'lots.quality_state'
		WHERE
			--------WIP CONDITION--------
			(
				----PRE_DC----
				(
					(@wip_state = 0)
					AND (tl.wip_state = @wip_state)
					AND (
						(
							@local_process_id IS NULL
							AND tl.act_process_id > - 1
							)
						OR (
							@local_process_id IS NOT NULL
							AND tl.act_process_id = @local_process_id
							)
						)
					AND (
						(
							@local_job_id IS NULL
							AND tl.act_job_id > 0
							)
						OR (
							@local_job_id IS NOT NULL
							AND tl.act_job_id = @local_job_id
							)
						)
					AND (
						(
							(@local_d_fil = 1)
							AND (
								(
									(@local_date_from <= in_plan_date)
									AND (in_plan_date < @local_date_to)
									)
								)
							)
						OR ((@local_d_fil <> 1))
						)
					)
				----DC----
				OR (
					(@wip_state = 10)
					AND (tl.wip_state = @wip_state)
					AND (
						(
							@local_process_id IS NULL
							AND tl.act_process_id > 0
							)
						OR (
							@local_process_id IS NOT NULL
							AND tl.act_process_id = @local_process_id
							)
						)
					AND (
						(
							@local_job_id IS NULL
							AND tl.act_job_id > 0
							)
						OR (
							@local_job_id IS NOT NULL
							AND tl.act_job_id = @local_job_id
							)
						)
					AND (
						(
							(@local_d_fil = 1)
							AND (
								(
									(@from_time <= in_at)
									AND (in_at < @to_time)
									)
								)
							)
						OR ((@local_d_fil <> 1))
						)
					)
				----WIP----
				OR (
					(@wip_state = 20)
					AND (tl.wip_state <= @wip_state)
					AND (
						(
							@local_process_id IS NULL
							AND tl.act_process_id > 0
							)
						OR (
							@local_process_id IS NOT NULL
							AND tl.act_process_id = @local_process_id
							)
						)
					AND (
						(
							@local_job_id IS NULL
							AND tl.act_job_id > 0
							)
						OR (
							@local_job_id IS NOT NULL
							AND tl.act_job_id = @local_job_id
							)
						)
					AND (
						(
							(@local_d_fil = 1)
							AND (
								(
									(@from_time <= in_at)
									AND (in_at < @to_time)
									)
								)
							)
						OR ((@local_d_fil <> 1))
						)
					)
				----SHIPPED----
				OR (
					(@wip_state = 100)
					AND (tl.wip_state = @wip_state)
					AND (
						(
							(@local_d_fil = 1)
							AND (
								(@from_time <= in_at)
								AND (in_at < @to_time)
								)
							)
						OR (
							(@local_d_fil = 2)
							AND (
								(@from_time <= ship_at)
								AND (ship_at < @to_time)
								)
							)
						OR (
							(@local_d_fil = 3)
							AND (
								out_plan_date_id BETWEEN @from
									AND @to
								)
							)
						)
					)
				------ALL----
				OR (
					(@wip_state = - 1)
					AND (
						(
							@local_process_id IS NULL
							AND tl.act_process_id > 0
							)
						OR (
							@local_process_id IS NOT NULL
							AND tl.act_process_id = @local_process_id
							)
						)
					AND (
						(
							@local_job_id IS NULL
							AND tl.act_job_id > 0
							)
						OR (
							@local_job_id IS NOT NULL
							AND tl.act_job_id = @local_job_id
							)
						)
					)
				------LOT OUT----
				OR (
					(@wip_state = 210)
					AND (
						tl.wip_state = @wip_state
						--OR (
						--	tl.wip_state = 200
						--	AND tl.start_step_no < tl.step_no
						--	)
						)
					AND (
						(
							@local_process_id IS NULL
							AND tl.act_process_id > 0
							)
						OR (
							@local_process_id IS NOT NULL
							AND tl.act_process_id = @local_process_id
							)
						)
					AND (
						(
							@local_job_id IS NULL
							AND tl.act_job_id > 0
							)
						OR (
							@local_job_id IS NOT NULL
							AND tl.act_job_id = @local_job_id
							)
						)
					AND (
						(@local_d_fil = 0)
						OR (
							(@local_d_fil = 1)
							AND (
								(@from_time <= in_at)
								AND (in_at < @to_time)
								)
							)
						OR (
							(@local_d_fil = 2)
							AND (
								(@from_time <= ship_at)
								AND (ship_at < @to_time)
								)
							)
						OR (
							(@local_d_fil = 3)
							AND (
								out_plan_date_id BETWEEN @from
									AND @to
								)
							)
						)
					)
				)
			--------Other Condition--------
			------COMMON----
			----Lot type
			AND (
				(@local_lot_type_list IS NULL)
				OR (
					@local_lot_type_list IS NOT NULL
					AND substring(tl.lot_no, 5, 1) IN (
						SELECT value
						FROM STRING_SPLIT(@local_lot_type_list, ',')
						)
					)
				)
			AND (
				(
					@local_is_assy_only IS NULL
					AND dd.is_assy_only IN (
						0
						,1
						)
					)
				OR (
					@local_is_assy_only IS NOT NULL
					AND dd.is_assy_only = @local_is_assy_only
					)
				)
			AND (
				(
					@local_package_id IS NOT NULL
					AND tl.act_package_id = @local_package_id
					)
				OR (
					@local_package_id IS NULL
					AND @local_package_group_id IS NOT NULL
					AND dpg.id = @local_package_group_id
					)
				OR (
					@local_package_id IS NULL
					AND @local_package_group_id IS NULL
					AND tl.act_package_id > 0
					)
				)
		) AS t1
	WHERE t1.lot_id_rank = 1

	IF @local_all = 1
	BEGIN
		SELECT TOP (@local_records) t2.lot_id AS lot_id
			,t2.lot_no AS lot_no
			,t2.wip_state AS wip_state
			,t2.order_id AS order_id
			,t2.order_no AS order_no
			,t2.package_group_name AS package_group_name
			,t2.package_name AS package_name
			,t2.device_name AS device_name
			,t2.is_assy_only AS is_assy_only
			,t2.step_no AS step_no
			,t2.process_id AS process_id
			,t2.process_name AS process_name
			,t2.job_id AS job_id
			,t2.job_name AS job_name
			,t2.qty_in AS qty_in
			,t2.qty_fail AS qty_fail
			,t2.is_special_flow AS is_special_flow
			,t2.process_state AS process_state
			,t2.process_state_eng AS process_state_eng
			,t2.process_state_jpn AS process_state_jpn
			,t2.quality_state AS quality_state
			,t2.quality_state_eng AS quality_state_eng
			,t2.quality_state_jpn AS quality_state_jpn
			,t2.delay1 AS delay1
			,t2.delay2 AS delay2
			,t2.lot_id_rank AS lot_id_rank
			,t2.chip_name AS chip_name
			,t2.fab_lot_no AS fab_lot_no
			,t2.wafer_no AS wafer_no
			,t2.mno AS mno
			,t2.assy_name AS assy_name
			,t2.ft_name AS ft_name
			,t2.device_slip_id AS device_slip_id
			,t2.version_no AS version_no
			,t2.os_program_name AS os_program_name
			,t2.ft_rank AS ft_rank
			,t2.tp_rank AS tp_rank
			,t2.in_plan_date AS in_plan_date
			,t2.in_at AS in_at
			,t2.out_plan_date AS out_plan_date
			,t2.ship_at AS ship_at
			,t2.modify_out_plan_date AS modify_out_plan_date
			,t2.modified_at AS modified_at
			,t2.modified_by AS modified_by
			,t2.lead_time AS lead_time
		FROM #table AS t2
		ORDER BY lot_id ASC
	END
	ELSE
	BEGIN
		SELECT trim(t3.lot_no) AS 'ロットNO'
			,trim(t3.order_no) AS 'オーダーNO'
			,trim(t3.package_group_name) AS 'パッケージグループ'
			,trim(t3.package_name) AS 'パッケージ'
			,trim(t3.device_name) AS '機種'
			,t3.process_name AS 'プロセス'
			,t3.job_name AS '工程'
			,t3.qty_in AS '数量[pcs]'
			,t3.process_state_jpn AS '生産ステータス'
			,t3.quality_state_jpn AS '品質ステータス'
			,t3.qty_fail AS '不良品数[pcs]'
			,convert(DECIMAL(10, 1), convert(DECIMAL, t3.qty_in) / nullif((t3.qty_in + t3.qty_fail), 0) * 100) AS '歩留まり'
			,t3.delay1 AS '遅れ時間１'
			,t3.delay2 AS '遅れ時間２'
			,t3.is_assy_only AS 'Assy工程'
			,t3.chip_name AS 'チップ名'
			,t3.assy_name AS 'Assy名'
			,t3.ft_name AS 'FT名'
			,t3.fab_lot_no AS 'FABロットNO'
			,t3.wafer_no AS 'Wf NO'
			,t3.mno AS 'MNO'
			,t3.device_slip_id AS 'DeviceSlipID'
			,t3.version_no AS '伝票バージョン'
			,t3.os_program_name AS 'OS program'
			,t3.ft_rank AS 'FTランク'
			,t3.tp_rank AS 'TPランク'
			,t3.in_plan_date AS '投入予定日'
			,t3.in_at AS '投入日時'
			,t3.out_plan_date AS '出荷予定日'
			,t3.modify_out_plan_date AS '出荷要求日(修正後)'
			,t3.modified_at AS '出荷回答日'
			,t3.ship_at AS '出荷日時'
			,t3.modified_by AS '出荷回答者ID'
			,t3.lead_time AS 'リードタイム[day]'
		FROM (
			--normal flow lot
			SELECT t2.lot_id AS lot_id
				,t2.lot_no AS lot_no
				,t2.wip_state AS wip_state
				,t2.order_id AS order_id
				,t2.order_no AS order_no
				,t2.package_group_name AS package_group_name
				,t2.package_name AS package_name
				,t2.device_name AS device_name
				,t2.is_assy_only AS is_assy_only
				,t2.step_no AS step_no
				,t2.process_id AS process_id
				,t2.process_name AS process_name
				,t2.job_id AS job_id
				,t2.job_name AS job_name
				,t2.qty_in AS qty_in
				,t2.qty_fail AS qty_fail
				,t2.is_special_flow AS is_special_flow
				,t2.process_state AS process_state
				,t2.process_state_eng AS process_state_eng
				,t2.process_state_jpn AS process_state_jpn
				,t2.quality_state AS quality_state
				,t2.quality_state_eng AS quality_state_eng
				,t2.quality_state_jpn AS quality_state_jpn
				,t2.delay1 AS delay1
				,t2.delay2 AS delay2
				,t2.lot_id_rank AS lot_id_rank
				,t2.chip_name AS chip_name
				,t2.fab_lot_no AS fab_lot_no
				,t2.wafer_no AS wafer_no
				,t2.mno AS mno
				,t2.assy_name AS assy_name
				,t2.ft_name AS ft_name
				,t2.device_slip_id AS device_slip_id
				,t2.version_no AS version_no
				,t2.os_program_name AS os_program_name
				,t2.ft_rank AS ft_rank
				,t2.tp_rank AS tp_rank
				,t2.in_plan_date AS in_plan_date
				,t2.in_at AS in_at
				,t2.out_plan_date AS out_plan_date
				,t2.ship_at AS ship_at
				,t2.modify_out_plan_date AS modify_out_plan_date
				,t2.modified_at AS modified_at
				,t2.modified_by AS modified_by
				,t2.lead_time AS lead_time
			FROM #table AS t2
			WHERE isnull(t2.is_special_flow, 0) = 0
			
			UNION ALL
			
			--special flow lot
			SELECT t2.lot_id AS lot_id
				,t2.lot_no AS lot_no
				,t2.wip_state AS wip_state
				,t2.order_id AS order_id
				,t2.order_no AS order_no
				,t2.package_group_name AS package_group_name
				,t2.package_name AS package_name
				,t2.device_name AS device_name
				,t2.is_assy_only AS is_assy_only
				,s.step_no AS step_no
				,t2.process_id AS process_id
				,ps.name AS process_name
				,t2.job_id AS job_id
				,js.name AS job_name
				,t2.qty_in AS qty_in
				,t2.qty_fail AS qty_fail
				,t2.is_special_flow AS is_special_flow
				,s.process_state AS process_state
				,t2.process_state_eng AS process_state_eng
				,t2.process_state_jpn AS process_state_jpn
				,t2.quality_state AS quality_state
				,t2.quality_state_eng AS quality_state_eng
				,t2.quality_state_jpn AS quality_state_jpn
				,t2.delay1 AS delay1
				,t2.delay2 AS delay2
				,t2.lot_id_rank AS lot_id_rank
				,t2.chip_name AS chip_name
				,t2.fab_lot_no AS fab_lot_no
				,t2.wafer_no AS wafer_no
				,t2.mno AS mno
				,t2.assy_name AS assy_name
				,t2.ft_name AS ft_name
				,t2.device_slip_id AS device_slip_id
				,t2.version_no AS version_no
				,t2.os_program_name AS os_program_name
				,t2.ft_rank AS ft_rank
				,t2.tp_rank AS tp_rank
				,t2.in_plan_date AS in_plan_date
				,t2.in_at AS in_at
				,t2.out_plan_date AS out_plan_date
				,t2.ship_at AS ship_at
				,t2.modify_out_plan_date AS modify_out_plan_date
				,t2.modified_at AS modified_at
				,t2.modified_by AS modified_by
				,t2.lead_time AS lead_time
			--,s.step_no as step_no_sp
			--,s.process_state as process_state_sp
			--,js.name as job_name_sp
			FROM #table AS t2
			INNER JOIN APCSProDB.method.jobs AS j WITH (NOLOCK) ON j.id = t2.job_id
			LEFT OUTER JOIN APCSProDB.trans.special_flows AS s WITH (NOLOCK) ON s.id = t2.special_flow_id
			LEFT OUTER JOIN APCSProDB.trans.lot_special_flows AS ls WITH (NOLOCK) ON ls.special_flow_id = s.id
				AND ls.step_no = s.step_no
			INNER JOIN APCSProDB.method.jobs AS js WITH (NOLOCK) ON js.id = ls.job_id
			INNER JOIN APCSProDB.method.processes AS ps WITH (NOLOCK) ON ps.id = ls.act_process_id
			WHERE isnull(t2.is_special_flow, 0) = 1
			) AS t3
		ORDER BY lot_id ASC
	END
END

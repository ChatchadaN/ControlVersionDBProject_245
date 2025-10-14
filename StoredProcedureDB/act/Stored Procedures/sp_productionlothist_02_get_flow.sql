
CREATE PROCEDURE [act].[sp_productionlothist_02_get_flow] @lot_no NVARCHAR(32) = NULL
AS
BEGIN
	DECLARE @device_slip_id INT = (
			SELECT device_slip_id
			FROM APCSProDB.trans.lots WITH (NOLOCK)
			WHERE lot_no = @lot_no
			);
	DECLARE @lot_id INT = (
			SELECT id AS package_id
			FROM APCSProDB.trans.lots WITH (NOLOCK)
			WHERE lot_no = @lot_no
			);

	IF OBJECT_ID(N'tempdb..#t_act_flow', N'U') IS NOT NULL
		DROP TABLE #t_act_flow;

	---------------
	SELECT t2.*
	INTO #t_act_flow
	FROM (
		SELECT t1.*
			,ROW_NUMBER() OVER (
				PARTITION BY flow_order ORDER BY id
				) AS flow_order_rank
		FROM (
			SELECT t0.*
				,sum(next_flag) OVER (
					ORDER BY id
					) AS flow_order
			FROM (
				SELECT lpr.id AS id
					,lpr.recorded_at AS recorded_at
					,lpr.operated_by AS operated_by
					,lpr.record_class AS record_class
					,lpr.lot_id AS lot_id
					,lpr.process_id AS process_id
					,lpr.job_id AS job_id
					,lpr.step_no AS step_no
					,lag(step_no) OVER (
						ORDER BY id
						) AS pre_step_no
					,CASE 
						WHEN lpr.step_no <> lag(step_no) OVER (
								ORDER BY id
								)
							THEN 1
						ELSE 0
						END AS next_flag
				FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
				WHERE lot_id = @lot_id
					AND record_class <> 25
					AND record_class <> 26
				) AS t0
			) AS t1
		) AS t2
	WHERE t2.flow_order_rank = 1;

	DECLARE @current_job INT = (
			SELECT max(t0.step_no)
			FROM (
				SELECT step_no AS step_no
					,step_no % 100 AS step_no_sp
				FROM #t_act_flow
				) AS t0
			WHERE t0.step_no_sp = 0
			)
	DECLARE @current_job_sp INT = (
			SELECT max(t0.step_no)
			FROM (
				SELECT step_no AS step_no
				FROM #t_act_flow
				) AS t0
			)

	------------------------------------------------------------------------------実績フロー
	SELECT
		--t0.lot_id as lot_id
		t0.process_id AS process_id
		,t0.job_id AS job_id
		,t0.step_no AS step_no
		,0 AS child_flg
		,1 AS act_flow_flg
		,CASE 
			WHEN t0.step_no = @current_job_sp
				THEN 1
			ELSE 0
			END AS current_job_flg
	FROM #t_act_flow AS t0
	
	UNION ALL
	
	-----------------------------------------------------------------------------将来デバイスフロー
	SELECT df.act_process_id AS process_id
		,df.job_id AS job_id
		,df.step_no AS step_no
		,0 AS child_flag
		,0 AS act_flow_flg
		,0 AS current_job_flg
	FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
	LEFT OUTER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.id = df.job_id
	LEFT OUTER JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = mj.process_id
	WHERE df.device_slip_id = @device_slip_id
		AND df.is_skipped = 0
		AND df.step_no > @current_job
	
	UNION ALL
	
	--------------------------------------子チップ
	SELECT df.act_process_id AS process_id
		,df.job_id AS job_id
		,p_step.parent_step_no AS step_no
		,1 AS child_flag
		,1 AS act_flow_flg
		,0 AS current_job_flg
	FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
	LEFT OUTER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.id = df.job_id
	LEFT OUTER JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = mj.process_id
	LEFT OUTER JOIN (
		--子チップprocess_idから親チップのstep_noを取得する
		SELECT step_no AS parent_step_no
			,*
		FROM (
			SELECT df.step_no AS step_no
				,df.next_step_no AS next_step_no
				,df.act_process_id AS act_process_id
				,df.job_id AS job_id
				,RANK() OVER (
					PARTITION BY df.act_process_id ORDER BY df.step_no
					) AS num
			FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
			WHERE df.device_slip_id = @device_slip_id
				AND df.is_skipped = 0
				AND act_process_id IN (
					SELECT cl.act_process_id
					FROM [APCSProDB].[trans].[lots] AS l
					LEFT OUTER JOIN [APCSProDB].[trans].[lot_multi_chips] AS m ON m.lot_id = l.id
					LEFT OUTER JOIN [APCSProDB].[trans].[lots] AS cl ON cl.id = m.child_lot_id
					WHERE l.id = @lot_id
					)
			) AS x
		WHERE x.num = 1
		) AS p_step ON p_step.act_process_id = df.act_process_id
	WHERE df.is_skipped = 0
		AND df.device_slip_id IN (
			SELECT device_slip_id
			FROM APCSProDB.trans.lots WITH (NOLOCK)
			WHERE id IN (
					SELECT cl.id AS child_lot_id
					FROM [APCSProDB].[trans].[lots] AS l WITH (NOLOCK)
					LEFT OUTER JOIN [APCSProDB].[trans].[lot_multi_chips] AS m WITH (NOLOCK) ON m.lot_id = l.id
					LEFT OUTER JOIN [APCSProDB].[trans].[lots] AS cl WITH (NOLOCK) ON cl.id = m.child_lot_id
					WHERE l.id = @lot_id
					)
			)
	ORDER BY step_no
		,job_id
		,child_flg
END

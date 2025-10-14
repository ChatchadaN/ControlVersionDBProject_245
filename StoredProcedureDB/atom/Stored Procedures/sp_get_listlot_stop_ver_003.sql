-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,20223101>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_listlot_stop_ver_003] 
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) = '%'
	, @device varchar(50) = '%'
	, @assy_name varchar(50) = '%'
	, @package varchar(50) = '%'
	, @fab_wafer varchar(50) = '%'
	, @status int  -- 0:list stoplot, 1:release stoplot, 2:cancel stoplot
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@status = 0)
	BEGIN
		---------------------------------------------------------------------
		-- 0:list stoplot
		---------------------------------------------------------------------
		SELECT [lots].[id] AS [id] ,
			   [lots].[lot_no] AS [lot_no] ,
		       [lots].[carrier_no] AS [carrier_no] ,
		       [device_names].[name] AS [device] ,
		       [device_names].[assy_name] AS [assy_name] ,
		       [device_names].[ft_name] AS [ft_device] ,
		       [packages].[name] AS [package] ,
		       [device_names].[tp_rank] AS [tp_rank] ,
		       IIF([lots].[is_special_flow] = 1, [job_special].[name], [jobs].[name]) AS [operation] ,
			   '' AS [operation_stop] ,
		       IIF([lots].[is_special_flow] = 1, [process_special].[name], [processes].[name]) AS [process] ,
		       IIF([lots].[is_special_flow] = 1, [detail_process_state_special].[label_eng], [detail_process_state].[label_eng]) AS [process_state] ,
			   IIF([lots].[is_special_flow] = 1, [detail_process_state_special].[color_code], [detail_process_state].[color_code]) AS [color_label_process_state] ,
		       [detail_quality_state].[label_eng] AS [quality_state] ,
			   [detail_quality_state].[color_code] AS [color_label_quality_state] ,
		       [lots].[updated_at] AS [update_time] ,
		       [lots].[qty_in] AS [total] ,
		       [lots].[qty_pass] AS [good] ,
		       [lots].[qty_fail] AS [ng] ,
		       [users].[emp_num] AS [operator] ,
		       ISNULL([fabwafer].[fab_wf_lot_no], '') AS [fabwf]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id]
			   AND [device_flows].[step_no] = [lots].[step_no]
		INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_in_plan] WITH (NOLOCK) ON [days_in_plan].[id] = [lots].[in_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_out_plan] WITH (NOLOCK) ON [days_out_plan].[id] = [lots].[modify_out_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[item_labels] AS [detail_wip_state] WITH (NOLOCK) ON [detail_wip_state].[name] = 'lots.wip_state'
			   AND [detail_wip_state].[val] = [lots].[wip_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state] WITH (NOLOCK) ON [detail_process_state].[name] = 'lots.process_state'
			   AND [detail_process_state].[val] = [lots].[process_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_quality_state] WITH (NOLOCK) ON [detail_quality_state].[name] = 'lots.quality_state'
			   AND [detail_quality_state].[val] = [lots].[quality_state] 
		--table lot_hold_controls
		LEFT JOIN [APCSProDB].[trans].[lot_hold_controls] WITH (NOLOCK) ON [lot_hold_controls].lot_id = lots.id
			  AND [lot_hold_controls].[system_name] = 'lot stop instruction'
		--table find user
		LEFT JOIN [APCSProDB].[man].[users] WITH (NOLOCK) ON [users].[id] = [lots].[updated_by]
		--table find special_flow
		LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id]
		      AND [special_flows].step_no = [lot_special_flows].step_no
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_special] WITH (NOLOCK) ON [job_special].[id] = [lot_special_flows].[job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_special] WITH (NOLOCK) ON [process_special].[id] = [job_special].[process_id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state_special] WITH (NOLOCK) ON [detail_process_state_special].[name] = 'lots.process_state'
			  AND [detail_process_state_special].[val] = [special_flows].[process_state]
		--table find fab_wf_lot_no
		LEFT JOIN
		  (SELECT [lots].[lot_no],
		          [fab_wf_lot_no]
		   FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		   INNER JOIN [APCSProDB].[robin].[lot1_table_input] WITH (NOLOCK) ON [lots].[lot_no] = [lot1_table_input].[lot_no]
		   WHERE [lots].[wip_state] = 20
		   GROUP BY [lots].[lot_no],
		            [fab_wf_lot_no]) AS [fabwafer] ON [fabwafer].[lot_no] = [lots].[lot_no]
		--table find [lot_future]
		OUTER APPLY
		  (SELECT TOP 1 [lot_stop].[is_finished]
			FROM [APCSProDB].[trans].[lots] as [lot] WITH (NOLOCK) 
		  	LEFT JOIN [APCSProDB].[trans].[lot_hold_controls] as [lot_hold] WITH (NOLOCK) ON [lot_hold].[lot_id] = [lot].[id]
			  AND [lot_hold].[system_name] = 'lot stop instruction'
			LEFT JOIN [APCSProDB].[trans].[lot_stop_instructions] as [lot_stop] WITH (NOLOCK) ON [lot_stop].[lot_id] = [lot].[id]
			  AND [lot_stop].[is_finished] = 0
			WHERE [lot].[wip_state] = 20
			  AND [lot].[id] = [lots].[id]
			) AS [lot_future]  
		WHERE [days_in_plan].[date_value] <= CONVERT(DATE, GETDATE())
		  AND [lots].[wip_state] = 20
		  AND [lots].[lot_no] like @lot_no
		  AND [device_names].[name] like @device
		  AND [device_names].[assy_name] like @assy_name
		  AND [packages].[name] like @package
		  AND ISNULL([fabwafer].[fab_wf_lot_no],'%') like @fab_wafer
		  AND ([lot_hold_controls].[is_held] != 1 OR [lot_hold_controls].[is_held] IS NULL)
		  AND [lot_future].[is_finished] IS NULL;
	END
	ELSE IF (@status = 1)
	BEGIN
		---------------------------------------------------------------------
		-- 1:release stoplot
		---------------------------------------------------------------------
		SELECT [lots].[id] AS [id] ,
			   [lots].[lot_no] AS [lot_no] ,
		       [lots].[carrier_no] AS [carrier_no] ,
		       [device_names].[name] AS [device] ,
		       [device_names].[assy_name] AS [assy_name] ,
		       [device_names].[ft_name] AS [ft_device] ,
		       [packages].[name] AS [package] ,
		       [device_names].[tp_rank] AS [tp_rank] ,
			   IIF([lots].[is_special_flow] = 1, [job_special].[name], [job_master].[name]) AS [operation] ,
		       [jobs].[name] AS [operation_stop] ,
		       IIF([lots].[is_special_flow] = 1, [process_special].[name], [process_master].[name]) AS [process] ,
		       IIF([lots].[is_special_flow] = 1, [detail_process_state_special].[label_eng], [detail_process_state].[label_eng]) AS [process_state] ,
			   IIF([lots].[is_special_flow] = 1, [detail_process_state_special].[color_code], [detail_process_state].[color_code]) AS [color_label_process_state] ,
		       [detail_quality_state].[label_eng] AS [quality_state] ,
			   [detail_quality_state].[color_code] AS [color_label_quality_state] ,
		       [lots].[updated_at] AS [update_time] ,
		       [lots].[qty_in] AS [total] ,
		       [lots].[qty_pass] AS [good] ,
		       [lots].[qty_fail] AS [ng] ,
		       [users].[emp_num] AS [operator] ,
		       ISNULL([fabwafer].[fab_wf_lot_no], '') AS [fabwf]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_in_plan] WITH (NOLOCK) ON [days_in_plan].[id] = [lots].[in_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_out_plan] WITH (NOLOCK) ON [days_out_plan].[id] = [lots].[modify_out_plan_date_id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_wip_state] WITH (NOLOCK) ON [detail_wip_state].[name] = 'lots.wip_state'
		      AND [detail_wip_state].[val] = [lots].[wip_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state] WITH (NOLOCK) ON [detail_process_state].[name] = 'lots.process_state'
		      AND [detail_process_state].[val] = [lots].[process_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_quality_state] WITH (NOLOCK) ON [detail_quality_state].[name] = 'lots.quality_state'
		      AND [detail_quality_state].[val] = [lots].[quality_state] 
		--table lot_hold_controls
		LEFT JOIN [APCSProDB].[trans].[lot_hold_controls] WITH (NOLOCK) ON [lot_hold_controls].lot_id = lots.id
		      AND [lot_hold_controls].[system_name] = 'lot stop instruction'
		INNER JOIN (
			SELECT [lot_id] , 
			       [stop_step_no] AS [step_no] , 
				   ROW_NUMBER() OVER (PARTITION BY [lot_id] ORDER BY [lot_id],[stop_instruction_id] DESC) AS [count_step]
			FROM [APCSProDB].[trans].[lot_stop_instructions] WITH (NOLOCK)
			WHERE [lot_stop_instructions].[is_finished] = 1
		) AS [lot_stop_instructions] ON [lots].[id] = [lot_stop_instructions].[lot_id]
			AND [lot_stop_instructions].[count_step] = 1
		    AND [device_flows].[step_no] = [lot_stop_instructions].[step_no]
		--table find user
		LEFT JOIN [APCSProDB].[man].[users] WITH (NOLOCK) ON [users].[id] = [lot_hold_controls].[updated_by]
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_master] WITH (NOLOCK) ON [job_master].[id] = [lots].[act_job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_master]  WITH (NOLOCK) ON [process_master].[id] = [jobs].[process_id]
		--table find special_flow
		LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id]
		      AND [special_flows].step_no = [lot_special_flows].step_no
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_special] WITH (NOLOCK) ON [job_special].[id] = [lot_special_flows].[job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_special] WITH (NOLOCK) ON [process_special].[id] = [job_special].[process_id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state_special] WITH (NOLOCK) ON [detail_process_state_special].[name] = 'lots.process_state'
		      AND [detail_process_state_special].[val] = [special_flows].[process_state]
		--table find fab_wf_lot_no
		LEFT JOIN
		  (SELECT [lots].[lot_no],
		          [fab_wf_lot_no]
		   FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		   INNER JOIN [APCSProDB].[robin].[lot1_table_input] WITH (NOLOCK) ON [lots].[lot_no] = [lot1_table_input].[lot_no]
		   WHERE [lots].[wip_state] = 20
		   GROUP BY [lots].[lot_no],
		            [fab_wf_lot_no]) AS [fabwafer] ON [fabwafer].[lot_no] = [lots].[lot_no]
		WHERE [days_in_plan].[date_value] <= CONVERT(DATE, GETDATE())
		  AND [lots].[wip_state] = 20
		  AND [lots].[lot_no] like @lot_no
		  AND [device_names].[name] like @device
		  AND [device_names].[assy_name] like @assy_name
		  AND [packages].[name] like @package
		  AND ISNULL([fabwafer].[fab_wf_lot_no],'%') like @fab_wafer
	      AND [lot_hold_controls].[is_held] = 1;
	END
	ELSE IF (@status = 2)
	BEGIN
		---------------------------------------------------------------------
		-- 2:cancel stoplot
		---------------------------------------------------------------------
		SELECT [lots].[id] AS [id] ,
			   [lots].[lot_no] AS [lot_no] ,
			   [lots].[carrier_no] AS [carrier_no] ,
			   [device_names].[name] AS [device] ,
			   [device_names].[assy_name] AS [assy_name] ,
			   [device_names].[ft_name] AS [ft_device] ,
			   [packages].[name] AS [package] ,
			   [device_names].[tp_rank] AS [tp_rank] ,
			   IIF([lots].[is_special_flow] = 1, [job_special].[name], [job_master].[name]) AS [operation] ,
		       [jobs].[name] AS [operation_stop] ,
			   IIF([lots].[is_special_flow] = 1, [process_special].[name], [process_master].[name]) AS [process] ,
			   IIF([lots].[is_special_flow] = 1, [detail_process_state_special].[label_eng], [detail_process_state].[label_eng]) AS [process_state] ,
			   IIF([lots].[is_special_flow] = 1, [detail_process_state_special].[color_code], [detail_process_state].[color_code]) AS [color_label_process_state] ,
			   [detail_quality_state].[label_eng] AS [quality_state] ,
			   [detail_quality_state].[color_code] AS [color_label_quality_state] ,
			   [lots].[updated_at] AS [update_time] ,
			   [lots].[qty_in] AS [total] ,
			   [lots].[qty_pass] AS [good] ,
			   [lots].[qty_fail] AS [ng] ,
			   [users].[emp_num] AS [operator] ,
			   ISNULL([fabwafer].[fab_wf_lot_no], '') AS [fabwf] 
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_in_plan] WITH (NOLOCK) ON [days_in_plan].[id] = [lots].[in_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_out_plan] WITH (NOLOCK) ON [days_out_plan].[id] = [lots].[modify_out_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[item_labels] AS [detail_wip_state] WITH (NOLOCK) ON [detail_wip_state].[name] = 'lots.wip_state'
		       AND [detail_wip_state].[val] = [lots].[wip_state]
		INNER JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state] WITH (NOLOCK) ON [detail_process_state].[name] = 'lots.process_state'
		       AND [detail_process_state].[val] = [lots].[process_state]
		INNER JOIN [APCSProDB].[trans].[item_labels] AS [detail_quality_state] WITH (NOLOCK) ON [detail_quality_state].[name] = 'lots.quality_state'
		       AND [detail_quality_state].[val] = [lots].[quality_state] 
		--table lot_stop_instructions
		LEFT JOIN [APCSProDB].[trans].[lot_stop_instructions] WITH (NOLOCK) ON [lot_stop_instructions].lot_id = lots.id
			AND [device_flows].[step_no] = [lot_stop_instructions].[stop_step_no]
		--table find user
		LEFT JOIN [APCSProDB].[man].[users] WITH (NOLOCK) ON [users].[id] = [lot_stop_instructions].[updated_by]
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_master] WITH (NOLOCK) ON [job_master].[id] = [lots].[act_job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_master]  WITH (NOLOCK) ON [process_master].[id] = [jobs].[process_id]
		--table find special_flow
		LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id]
		      AND [special_flows].step_no = [lot_special_flows].step_no
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_special] WITH (NOLOCK) ON [job_special].[id] = [lot_special_flows].[job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_special] WITH (NOLOCK) ON [process_special].[id] = [job_special].[process_id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state_special] WITH (NOLOCK) ON [detail_process_state_special].[name] = 'lots.process_state'
		      AND [detail_process_state_special].[val] = [special_flows].[process_state]
		--table find fab_wf_lot_no
		LEFT JOIN
		  (SELECT [lots].[lot_no],
				  [fab_wf_lot_no]
		   FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		   INNER JOIN [APCSProDB].[robin].[lot1_table_input] WITH (NOLOCK) ON [lots].[lot_no] = [lot1_table_input].[lot_no]
		   WHERE [lots].[wip_state] = 20
		   GROUP BY [lots].[lot_no],
					[fab_wf_lot_no]) AS [fabwafer] ON [fabwafer].[lot_no] = [lots].[lot_no]
		WHERE [days_in_plan].[date_value] <= CONVERT(DATE, GETDATE())
		  AND [lots].[wip_state] = 20
		  AND [lots].[lot_no] like @lot_no
		  AND [device_names].[name] like @device
		  AND [device_names].[assy_name] like @assy_name
		  AND [packages].[name] like @package
		  AND ISNULL([fabwafer].[fab_wf_lot_no],'%') like @fab_wafer
		  AND [lot_stop_instructions].[is_finished] = 0;
	END
	ELSE IF (@status = 3)
	BEGIN
		---------------------------------------------------------------------
		-- 3:all
		---------------------------------------------------------------------
		SELECT [lots].[id] AS [id] ,
			   [lots].[lot_no] AS [lot_no] ,
			   [lots].[carrier_no] AS [carrier_no] ,
			   [device_names].[name] AS [device] ,
			   [device_names].[assy_name] AS [assy_name] ,
			   [device_names].[ft_name] AS [ft_device] ,
			   [packages].[name] AS [package] ,
			   [device_names].[tp_rank] AS [tp_rank] ,
			   IIF([lots].[is_special_flow] = 1, [job_special].[name], [jobs].[name]) AS [operation] ,
			   '' AS [operation_stop] ,
			   IIF([lots].[is_special_flow] = 1, [process_special].[name], [processes].[name]) AS [process] ,
			   IIF([lots].[is_special_flow] = 1, [detail_process_state_special].[label_eng], [detail_process_state].[label_eng]) AS [process_state] ,
			   IIF([lots].[is_special_flow] = 1, [detail_process_state_special].[color_code], [detail_process_state].[color_code]) AS [color_label_process_state] ,
			   [detail_quality_state].[label_eng] AS [quality_state] ,
			   [detail_quality_state].[color_code] AS [color_label_quality_state] ,
			   [lots].[updated_at] AS [update_time] ,
			   [lots].[qty_in] AS [total] ,
			   [lots].[qty_pass] AS [good] ,
			   [lots].[qty_fail] AS [ng] ,
			   [users].[emp_num] AS [operator] ,
			   ISNULL([fabwafer].[fab_wf_lot_no], '') AS [fabwf] 
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id]
		       AND [device_flows].[step_no] = [lots].[step_no]
		INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_in_plan] WITH (NOLOCK) ON [days_in_plan].[id] = [lots].[in_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_out_plan] WITH (NOLOCK) ON [days_out_plan].[id] = [lots].[modify_out_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[item_labels] AS [detail_wip_state] WITH (NOLOCK) ON [detail_wip_state].[name] = 'lots.wip_state'
		       AND [detail_wip_state].[val] = [lots].[wip_state]
		INNER JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state] WITH (NOLOCK) ON [detail_process_state].[name] = 'lots.process_state'
		       AND [detail_process_state].[val] = [lots].[process_state]
		INNER JOIN [APCSProDB].[trans].[item_labels] AS [detail_quality_state] WITH (NOLOCK) ON [detail_quality_state].[name] = 'lots.quality_state'
		       AND [detail_quality_state].[val] = [lots].[quality_state] 
		LEFT JOIN [APCSProDB].[man].[users] WITH (NOLOCK) ON [users].[id] = [lots].[updated_by]
		--table find special_flow
		LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id]
		      AND [special_flows].step_no = [lot_special_flows].step_no
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_special] WITH (NOLOCK) ON [job_special].[id] = [lot_special_flows].[job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_special] WITH (NOLOCK) ON [process_special].[id] = [job_special].[process_id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state_special] WITH (NOLOCK) ON [detail_process_state_special].[name] = 'lots.process_state'
		      AND [detail_process_state_special].[val] = [special_flows].[process_state]
		--table find fab_wf_lot_no
		LEFT JOIN
		  (SELECT [lots].[lot_no],
				  [fab_wf_lot_no]
		   FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		   INNER JOIN [APCSProDB].[robin].[lot1_table_input] WITH (NOLOCK) ON [lots].[lot_no] = [lot1_table_input].[lot_no]
		   WHERE [lots].[wip_state] = 20
		   GROUP BY [lots].[lot_no],
					[fab_wf_lot_no]) AS [fabwafer] ON [fabwafer].[lot_no] = [lots].[lot_no]
		WHERE [lots].[wip_state] = 20
		  AND [lots].[lot_no] like @lot_no;
	END
END

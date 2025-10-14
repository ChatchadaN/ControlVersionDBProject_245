-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,20223101>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_listlot_stop_ver_006] 
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

	DECLARE @table_stoplot TABLE
	(
		[id] INT,
		[sp_in_id] INT NULL,
		[lot_no] CHAR(20),
		[carrier_no] VARCHAR(50),
		[device] VARCHAR(50),
		[assy_name] VARCHAR(50),
		[ft_device] VARCHAR(50),
		[package] VARCHAR(50),
		[tp_rank] VARCHAR(20),
		[operation] VARCHAR(80),
		[operation_stop] VARCHAR(80),
		[stop_step_no] INT,
		[process] VARCHAR(80),
		[process_state] VARCHAR(80),
		[color_label_process_state] VARCHAR(80),
		[quality_state] VARCHAR(80),
		[color_label_quality_state] VARCHAR(80),
		[update_time] DATETIME,
		[total] INT,
		[good] INT,
		[ng] INT,
		[operator] VARCHAR(10),
		[fabwf] VARCHAR(20),
		[is_combine] INT NULL
	)

	IF (@status = 0)
	BEGIN
		---------------------------------------------------------------------
		-- 0:list stoplot
		---------------------------------------------------------------------
		INSERT INTO @table_stoplot
		SELECT [lots].[id] AS [id] 
			, NULL AS [sp_in_id]
			, [lots].[lot_no] AS [lot_no] 
			, ISNULL([lots].[carrier_no], '-') AS [carrier_no] 
			, [device_names].[name] AS [device] 
			, [device_names].[assy_name] AS [assy_name] 
			, [device_names].[ft_name] AS [ft_device] 
			, [packages].[name] AS [package] 
			, ISNULL([device_names].[tp_rank],'') AS [tp_rank] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [job_special].[name] ELSE [jobs].[name] END) AS [operation] 
			, '' AS [operation_stop] 
			, 0 AS [stop_step_no] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [process_special].[name] ELSE [processes].[name] END) AS [process] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [detail_process_state_special].[label_eng] ELSE [detail_process_state].[label_eng] END) AS [process_state] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [detail_process_state_special].[color_code] ELSE [detail_process_state].[color_code] END) AS [color_label_process_state] 
			, [detail_quality_state].[label_eng] AS [quality_state] 
			, [detail_quality_state].[color_code] AS [color_label_quality_state] 
			, [lots].[updated_at] AS [update_time] 
			, [lots].[qty_in] AS [total] 
			, [lots].[qty_pass] AS [good] 
			, [lots].[qty_fail] AS [ng] 
			, [users].[emp_num] AS [operator] 
			, ISNULL([fabwafer].[fab_wf_lot_no], '') AS [fabwf]
			, ISNULL([combine].[is_combine], 0) AS [is_combine]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[trans].[days] AS [days_in_plan] WITH (NOLOCK) ON [days_in_plan].[id] = [lots].[in_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_out_plan] WITH (NOLOCK) ON [days_out_plan].[id] = [lots].[modify_out_plan_date_id]
		INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id]
			   AND [device_flows].[step_no] = [lots].[step_no]
		INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
		LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id]
		      AND [special_flows].step_no = [lot_special_flows].step_no
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_special] WITH (NOLOCK) ON [job_special].[id] = [lot_special_flows].[job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_special] WITH (NOLOCK) ON [process_special].[id] = [job_special].[process_id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_wip_state] WITH (NOLOCK) ON [detail_wip_state].[name] = 'lots.wip_state'
			   AND [detail_wip_state].[val] = [lots].[wip_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state] WITH (NOLOCK) ON [detail_process_state].[name] = 'lots.process_state'
			   AND [detail_process_state].[val] = [lots].[process_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_quality_state] WITH (NOLOCK) ON [detail_quality_state].[name] = 'lots.quality_state'
			   AND [detail_quality_state].[val] = [lots].[quality_state] 
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state_special] WITH (NOLOCK) ON [detail_process_state_special].[name] = 'lots.process_state'
			  AND [detail_process_state_special].[val] = [special_flows].[process_state]
		OUTER APPLY (
			SELECT TOP 1 [fab_wf_lot_no]
			FROM [APCSProDB].[robin].[lot1_table_input] WITH (NOLOCK)
			WHERE [lot1_table_input].[lot_no] = [lots].[lot_no]
		) AS [fabwafer]  
		OUTER APPLY (
			SELECT TOP 1 1 AS [is_combine]
			FROM [APCSProDB].[trans].[lot_combine] WITH (NOLOCK)
			WHERE [lot_combine].[member_lot_id] = [lots].[id]
				AND [lot_combine].[member_lot_id] != [lot_combine].[lot_id]
		) AS [combine]
		LEFT JOIN [APCSProDB].[trans].[lot_hold_controls] ON [lot_hold_controls].lot_id = lots.id
			  AND [lot_hold_controls].[system_name] = 'lot stop instruction'
		LEFT JOIN [APCSProDB].[man].[users] WITH (NOLOCK) ON [users].[id] = [lots].[updated_by]
		WHERE [lots].[wip_state] = 20
			AND [days_in_plan].[date_value] <= CONVERT(DATE, GETDATE())
			--AND [lots].[id] = 2
			AND NOT EXISTS (
				SELECT TOP 1 [stop_step_no]
				FROM [APCSProDB].[trans].[lot_hold_controls]
				INNER JOIN [APCSProDB].[trans].[lot_stop_instructions] ON [lot_hold_controls].[lot_id] = [lot_stop_instructions].[lot_id]
				WHERE [lot_hold_controls].[lot_id] = [lots].[id]
					AND [lot_hold_controls].[system_name] = 'lot stop instruction'
					AND [lot_stop_instructions].[stop_step_no] = [lots].[step_no] 
					AND [lot_hold_controls].[is_held] = 1
			);

		SELECT [id]
			, [sp_in_id]
			, [lot_no]
			, [carrier_no]
			, [device]
			, [assy_name]
			, [ft_device]
			, [package]
			, [tp_rank]
			, [operation]
			, [operation_stop]
			, [stop_step_no]
			, [process]
			, [process_state]
			, [color_label_process_state]
			, [quality_state]
			, [color_label_quality_state]
			, [update_time]
			, [total]
			, [good]
			, [ng]
			, [operator]
			, [fabwf]
			, [is_combine]
		FROM @table_stoplot
		WHERE [lot_no] LIKE @lot_no
			AND [device] LIKE @device
			AND [assy_name] LIKE @assy_name
			AND [package] LIKE @package
			AND [fabwf] LIKE @fab_wafer;

	END
	ELSE IF (@status = 1)
	BEGIN
		---------------------------------------------------------------------
		-- 1:release stoplot
		---------------------------------------------------------------------
		INSERT INTO @table_stoplot
		SELECT [lots].[id] AS [id] 
			, NULL AS [sp_in_id]
			, [lots].[lot_no] AS [lot_no] 
			, ISNULL([lots].[carrier_no], '-') AS [carrier_no] 
			, [device_names].[name] AS [device] 
			, [device_names].[assy_name] AS [assy_name] 
			, [device_names].[ft_name] AS [ft_device] 
			, [packages].[name] AS [package] 
			, ISNULL([device_names].[tp_rank],'') AS [tp_rank] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [job_special].[name] ELSE [jobs].[name] END) AS [operation] 
			, [jobs].[name] AS [operation_stop] 
			, [lot_stop_instructions].[step_no] AS [stop_step_no] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [process_special].[name] ELSE [processes].[name] END) AS [process] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [detail_process_state_special].[label_eng] ELSE [detail_process_state].[label_eng] END) AS [process_state] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [detail_process_state_special].[color_code] ELSE [detail_process_state].[color_code] END) AS [color_label_process_state] 
			, [detail_quality_state].[label_eng] AS [quality_state] 
			, [detail_quality_state].[color_code] AS [color_label_quality_state] 
			, [lots].[updated_at] AS [update_time] 
			, [lots].[qty_in] AS [total] 
			, [lots].[qty_pass] AS [good] 
			, [lots].[qty_fail] AS [ng] 
			, [users].[emp_num] AS [operator] 
			, ISNULL([fabwafer].[fab_wf_lot_no], '') AS [fabwf] 
			, 0 AS [is_combine]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)		
		INNER JOIN [APCSProDB].[trans].[days] AS [days_in_plan] WITH (NOLOCK) ON [days_in_plan].[id] = [lots].[in_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_out_plan] WITH (NOLOCK) ON [days_out_plan].[id] = [lots].[modify_out_plan_date_id]
		INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id]
			AND [device_flows].[step_no] = [lots].[step_no]
		INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
		LEFT JOIN [APCSProDB].[trans].[lot_hold_controls] ON [lot_hold_controls].[lot_id] = [lots].[id]
			AND [lot_hold_controls].[system_name] = 'lot stop instruction'
		CROSS APPLY (
			SELECT TOP 1 [lot_id] 
				, [stop_step_no] AS [step_no] 
			FROM [APCSProDB].[trans].[lot_stop_instructions] WITH (NOLOCK)
			WHERE [lot_stop_instructions].[lot_id] = [lots].[id]
				AND [lot_stop_instructions].[stop_step_no] = [device_flows].[step_no] 
			ORDER BY [stop_instruction_id] DESC
		) AS [lot_stop_instructions] 
		LEFT JOIN [APCSProDB].[man].[users] WITH (NOLOCK) ON [users].[id] = [lot_hold_controls].[updated_by]
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_master] WITH (NOLOCK) ON [job_master].[id] = [lots].[act_job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_master]  WITH (NOLOCK) ON [process_master].[id] = [jobs].[process_id]
		LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id]
			AND [special_flows].[step_no] = [lot_special_flows].[step_no]
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_special] WITH (NOLOCK) ON [job_special].[id] = [lot_special_flows].[job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_special] WITH (NOLOCK) ON [process_special].[id] = [job_special].[process_id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_wip_state] WITH (NOLOCK) ON [detail_wip_state].[name] = 'lots.wip_state'
			AND [detail_wip_state].[val] = [lots].[wip_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state] WITH (NOLOCK) ON [detail_process_state].[name] = 'lots.process_state'
			AND [detail_process_state].[val] = [lots].[process_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_quality_state] WITH (NOLOCK) ON [detail_quality_state].[name] = 'lots.quality_state'
			AND [detail_quality_state].[val] = [lots].[quality_state] 
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state_special] WITH (NOLOCK) ON [detail_process_state_special].[name] = 'lots.process_state'
			AND [detail_process_state_special].[val]= [special_flows].[process_state]
		OUTER APPLY (
			SELECT TOP 1 [fab_wf_lot_no]
			FROM [APCSProDB].[robin].[lot1_table_input] WITH (NOLOCK)
			WHERE [lot1_table_input].[lot_no] = [lots].[lot_no]
		) AS [fabwafer]  
		WHERE [lots].[wip_state] = 20
			AND [days_in_plan].[date_value] <= CONVERT(DATE, GETDATE())
			--AND [lots].[id] = 2
			AND [lot_hold_controls].[is_held] = 1;

		SELECT [id]
			, [sp_in_id]
			, [lot_no]
			, [carrier_no]
			, [device]
			, [assy_name]
			, [ft_device]
			, [package]
			, [tp_rank]
			, [operation]
			, [operation_stop]
			, [stop_step_no]
			, [process]
			, [process_state]
			, [color_label_process_state]
			, [quality_state]
			, [color_label_quality_state]
			, [update_time]
			, [total]
			, [good]
			, [ng]
			, [operator]
			, [fabwf]
			, [is_combine]
		FROM @table_stoplot
		WHERE [lot_no] LIKE @lot_no
			AND [device] LIKE @device
			AND [assy_name] LIKE @assy_name
			AND [package] LIKE @package
			AND [fabwf] LIKE @fab_wafer;
	END
	ELSE IF (@status = 2)
	BEGIN
		---------------------------------------------------------------------
		-- 2:cancel stoplot
		---------------------------------------------------------------------
		INSERT INTO @table_stoplot
		SELECT DISTINCT [lots].[id] AS [id]
			, [lot_stop_instructions].[stop_instruction_id] AS [sp_in_id]
			, [lots].[lot_no] AS [lot_no] 
			, ISNULL([lots].[carrier_no], '-') AS [carrier_no] 
			, [device_names].[name] AS [device] 
			, [device_names].[assy_name] AS [assy_name] 
			, [device_names].[ft_name] AS [ft_device] 
			, [packages].[name] AS [package] 
			, ISNULL([device_names].[tp_rank],'') AS [tp_rank] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [job_special].[name] ELSE [job_master].[name] END) AS [operation] 
			, [jobs].[name] AS [operation_stop] 
			, [lot_stop_instructions].[step_no] AS [stop_step_no] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [process_special].[name] ELSE [process_master].[name] END) AS [process] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [detail_process_state_special].[label_eng] ELSE [detail_process_state].[label_eng] END) AS [process_state] 
			, (CASE WHEN [lots].[is_special_flow] = 1 THEN [detail_process_state_special].[color_code] ELSE [detail_process_state].[color_code] END) AS [color_label_process_state] 
			, [detail_quality_state].[label_eng] AS [quality_state] 
			, [detail_quality_state].[color_code] AS [color_label_quality_state] 
			, [lots].[updated_at] AS [update_time] 
			, [lots].[qty_in] AS [total] 
			, [lots].[qty_pass] AS [good] 
			, [lots].[qty_fail] AS [ng] 
			, [lot_stop_instructions].[emp_num] AS [operator] 
			, ISNULL([fabwafer].[fab_wf_lot_no], '') AS [fabwf] 
			, 0 AS [is_combine]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[trans].[days] AS [days_in_plan] WITH (NOLOCK) ON [days_in_plan].[id] = [lots].[in_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[days] AS [days_out_plan] WITH (NOLOCK) ON [days_out_plan].[id] = [lots].[modify_out_plan_date_id]
		INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
		CROSS APPLY (
			SELECT [top].[stop_instruction_id]
				, [top].[lot_id] 
				, [top].[step_no] 
				, [top].[is_finished]
				, [top].[emp_num]
				, [top].[count_step]
			FROM (
				SELECT [stop_step_no]
				FROM [APCSProDB].[trans].[lot_stop_instructions] WITH (NOLOCK) 
				WHERE [lot_stop_instructions].[lot_id] = [lots].[id]
				GROUP BY [stop_step_no]
			) AS [lot_stop_instructions]
			CROSS APPLY (
				SELECT [lsi].[stop_instruction_id]
					, [lsi].[lot_id] 
					, [lsi].[stop_step_no] AS [step_no] 
					, [lsi].[is_finished]
					, [users].[emp_num]
					, ROW_NUMBER() OVER (PARTITION BY [lsi].[lot_id] ORDER BY [lsi].[stop_instruction_id] DESC) AS [count_step]
				FROM [APCSProDB].[trans].[lot_stop_instructions] AS [lsi] WITH (NOLOCK)
				LEFT JOIN [APCSProDB].[man].[users] WITH (NOLOCK) ON [users].[id] = [lsi].[updated_by]
				WHERE [lsi].[lot_id] = [lots].[id]
					AND [lsi].[stop_step_no] = [lot_stop_instructions].[stop_step_no] 
			) AS [top]
			WHERE [lot_stop_instructions].[stop_step_no] > [lots].[step_no]
				AND [lot_stop_instructions].[stop_step_no] = [device_flows].[step_no]
				AND [top].[count_step] = 1
		) AS [lot_stop_instructions]
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_master] WITH (NOLOCK) ON [job_master].[id] = [lots].[act_job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_master]  WITH (NOLOCK) ON [process_master].[id] = [jobs].[process_id]
		--table find special_flow
		LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id]
			AND [lots].[is_special_flow] = 1
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id]
			AND [special_flows].step_no = [lot_special_flows].step_no
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_special] WITH (NOLOCK) ON [job_special].[id] = [lot_special_flows].[job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [process_special] WITH (NOLOCK) ON [process_special].[id] = [job_special].[process_id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_wip_state] WITH (NOLOCK) ON [detail_wip_state].[name] = 'lots.wip_state'
			AND [detail_wip_state].[val] = [lots].[wip_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state] WITH (NOLOCK) ON [detail_process_state].[name] = 'lots.process_state'
			AND [detail_process_state].[val] = [lots].[process_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_quality_state] WITH (NOLOCK) ON [detail_quality_state].[name] = 'lots.quality_state'
			AND [detail_quality_state].[val] = [lots].[quality_state] 
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state_special] WITH (NOLOCK) ON [detail_process_state_special].[name] = 'lots.process_state'
			AND [detail_process_state_special].[val] = [special_flows].[process_state]
		--table find fab_wf_lot_no
		OUTER APPLY (
			SELECT TOP 1 [fab_wf_lot_no]
			FROM [APCSProDB].[robin].[lot1_table_input] WITH (NOLOCK)
			WHERE [lot1_table_input].[lot_no] = [lots].[lot_no]
		) AS [fabwafer]  
		WHERE [lots].[wip_state] = 20
			AND [days_in_plan].[date_value] <= CONVERT(DATE, GETDATE())
			--AND [lots].[id] IN (2) --,1295851,1296780)
			AND [lot_stop_instructions].[is_finished] != 2;
			
		SELECT [id]
			, [sp_in_id]
			, [lot_no]
			, [carrier_no]
			, [device]
			, [assy_name]
			, [ft_device]
			, [package]
			, [tp_rank]
			, [operation]
			, [operation_stop]
			, [stop_step_no]
			, [process]
			, [process_state]
			, [color_label_process_state]
			, [quality_state]
			, [color_label_quality_state]
			, [update_time]
			, [total]
			, [good]
			, [ng]
			, [operator]
			, [fabwf]
			, [is_combine]
		FROM @table_stoplot
		WHERE [lot_no] LIKE @lot_no
			AND [device] LIKE @device
			AND [assy_name] LIKE @assy_name
			AND [package] LIKE @package
			AND [fabwf] LIKE @fab_wafer;
	END
	ELSE IF (@status = 3)
	BEGIN
		---------------------------------------------------------------------
		-- 3:all
		---------------------------------------------------------------------
		INSERT INTO @table_stoplot
		SELECT [lots].[id] AS [id] 
			, NULL AS [sp_in_id]
			, [lots].[lot_no] AS [lot_no] 
			, ISNULL([lots].[carrier_no], '-') AS [carrier_no] 
			, [device_names].[name] AS [device] 
			, [device_names].[assy_name] AS [assy_name] 
			, [device_names].[ft_name] AS [ft_device] 
			, [packages].[name] AS [package] 
			, [device_names].[tp_rank] AS [tp_rank] 
			, IIF([lots].[is_special_flow] = 1, [job_special].[name], [jobs].[name]) AS [operation] 
			, '' AS [operation_stop]
			, 0 AS [stop_step_no]
			, IIF([lots].[is_special_flow] = 1, [process_special].[name], [processes].[name]) AS [process] 
			, IIF([lots].[is_special_flow] = 1, [detail_process_state_special].[label_eng], [detail_process_state].[label_eng]) AS [process_state] 
			, IIF([lots].[is_special_flow] = 1, [detail_process_state_special].[color_code], [detail_process_state].[color_code]) AS [color_label_process_state] 
			, [detail_quality_state].[label_eng] AS [quality_state] 
			, [detail_quality_state].[color_code] AS [color_label_quality_state] 
			, [lots].[updated_at] AS [update_time] 
			, [lots].[qty_in] AS [total] 
			, [lots].[qty_pass] AS [good] 
			, [lots].[qty_fail] AS [ng] 
			, [users].[emp_num] AS [operator] 
			, ISNULL([fabwafer].[fab_wf_lot_no], '') AS [fabwf] 
			, 0 AS [is_combine]
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
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_wip_state] WITH (NOLOCK) ON [detail_wip_state].[name] = 'lots.wip_state'
			AND [detail_wip_state].[val] = [lots].[wip_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_process_state] WITH (NOLOCK) ON [detail_process_state].[name] = 'lots.process_state'
			AND [detail_process_state].[val] = [lots].[process_state]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [detail_quality_state] WITH (NOLOCK) ON [detail_quality_state].[name] = 'lots.quality_state'
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
		OUTER APPLY (
			SELECT TOP 1 [fab_wf_lot_no]
			FROM [APCSProDB].[robin].[lot1_table_input] WITH (NOLOCK)
			WHERE [lot1_table_input].[lot_no] = [lots].[lot_no]
		) AS [fabwafer]  
		WHERE [lots].[wip_state] = 20;

		SELECT [id]
			, [sp_in_id]
			, [lot_no]
			, [carrier_no]
			, [device]
			, [assy_name]
			, [ft_device]
			, [package]
			, [tp_rank]
			, [operation]
			, [operation_stop]
			, [stop_step_no]
			, [process]
			, [process_state]
			, [color_label_process_state]
			, [quality_state]
			, [color_label_quality_state]
			, [update_time]
			, [total]
			, [good]
			, [ng]
			, [operator]
			, [fabwf]
			, [is_combine]
		FROM @table_stoplot
		WHERE [lot_no] LIKE @lot_no;
	END
END

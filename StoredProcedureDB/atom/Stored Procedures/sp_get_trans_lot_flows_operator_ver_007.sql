
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_lot_flows_operator_ver_007]
	-- Add the parameters for the stored procedure here
	@lot_id INT	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	DECLARE @step_no_now INT
		, @package_id INT
		, @device_slip_id INT
		, @step_no_mix INT = NULL

	DECLARE @table TABLE
	(
		[step_no] INT, 
		[job_name] VARCHAR(100), 
		[flow] INT
	)

	---- # set parameter
	SELECT @step_no_now = (
		CASE 
			WHEN [lots].[is_special_flow] = 1 THEN ISNULL( [special_flows].[step_no], [lots].[step_no] )
		    ELSE [lots].[step_no]
		END ) 
		, @device_slip_id = [lots].[device_slip_id]
		, @package_id = [lots].[act_package_id] --find package_id = 275 (TO263-3) for condition color
	FROM [APCSProDB].[trans].[lots]
	LEFT JOIN [APCSProDB].[trans].[special_flows] 
		ON [lots].[is_special_flow] = 1
			AND [lots].[special_flow_id] = [special_flows].[id]
	WHERE [lots].[id] = @lot_id;

	---- # find flow
	INSERT INTO @table
	SELECT [lots].[step_no]
		, [lots].[job_name]
		, [lots].[flow]
	FROM (
		SELECT [device_flows].[step_no] AS [step_no]
			, [jobs].[name] AS [job_name]
			, 0 AS [flow]
		FROM [APCSProDB].[method].[device_flows] 
		LEFT JOIN [APCSProDB].[method].[jobs] 
			ON [device_flows].[job_id] = [jobs].[id]
		WHERE [device_flows].[device_slip_id] = @device_slip_id
		UNION ALL
		SELECT [lot_special_flows].[step_no] AS [step_no]
			, [jobs].[name] AS [job_name]
			, 1 AS [flow]
		FROM [APCSProDB].[trans].[special_flows] 
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
			ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
		LEFT JOIN [APCSProDB].[method].[jobs] 
			ON [lot_special_flows].[job_id] = [jobs].[id]
		WHERE [special_flows].[lot_id] = @lot_id
	) AS [lots]
	ORDER BY [step_no]

	IF EXISTS(SELECT [lot_id] FROM [APCSProDB].[trans].[lot_combine] WHERE [lot_id] = @lot_id)
	BEGIN
		IF EXISTS(SELECT [job_name] FROM @table WHERE [flow] = 0 AND [job_name] IN ('TSUGITASHI'))
		BEGIN
			SET @step_no_mix = (SELECT TOP 1 [step_no] FROM @table WHERE [flow] = 0 AND [job_name] IN ('TSUGITASHI') ORDER BY [step_no] ASC);
		END
		ELSE IF EXISTS(SELECT [job_name] FROM @table WHERE [flow] = 0 AND [job_name] IN ('TP-TP','TP','FL','FT-TP','FLFTTP'))
		BEGIN
			SET @step_no_mix = (SELECT TOP 1 [step_no] FROM @table WHERE [flow] = 0 AND [job_name] IN ('TP-TP','TP','FL','FT-TP','FLFTTP') ORDER BY [step_no] DESC);
		END
		ELSE IF EXISTS(SELECT [job_name] FROM @table WHERE [flow] = 1 AND [job_name] IN ('TP-TP','TP','FL','FT-TP','FLFTTP'))
		BEGIN
			SET @step_no_mix = (SELECT TOP 1 [step_no] FROM @table WHERE [flow] = 1 AND [job_name] IN ('TP-TP','TP','FL','FT-TP','FLFTTP') ORDER BY [step_no] ASC);
		END
	END

	---- # select result
	SELECT [StepNo].[step_no]
		, [StepNo].[is_skipped]
		, [jobs].[name] AS [job_name]
		, [StepNoDetail].[record_class] AS [record_class]
		, [StepNoDetail].[qty_in]
		, [StepNoDetail].[qty_pass]
		, [StepNoDetail].[qty_fail]
		, [StepNoDetail].[qty_last_pass]
		, [StepNoDetail].[qty_pass_step_sum]
		, [StepNoDetail].[qty_fail_step_sum]
		, [StepNoDetail].[qty_frame_in]
		, [StepNoDetail].[qty_frame_pass]
		, [StepNoDetail].[qty_frame_fail]
		, [StepNoDetail].[qty_p_nashi]
		, [StepNoDetail].[qty_combined]
		, [StepNoDetail].[qty_hasuu]
		, [StepNoDetail].[qty_out]
		, [StepNoDetail].[qty_front_ng]
		, [StepNoDetail].[qty_marker]
		, [StepNoDetail].[qty_cut_frame]
		, [StepNoDetail].[machine_id]
		, [machines].[name] AS [machine_name]
		, [StepNoDetail].[carrier_no]
		, [StepNoDetail].[next_carrier_no]
		, [users].[emp_num]
		, ISNULL( [tg_record].[Time], [LotStart].[StartTime] ) AS [start_time]
		, ISNULL( [tg_record].[Time], [LotEnd].[EndTime] ) AS [end_time]
		, ISNULL( [tg_record].[Time], [LotSetup].[SetupTime] ) AS [setup_time]
		, [item_labels].[label_eng] AS [label_eng]
		, [StepNo].[special_flow_id]
		, [StepNo].[lot_special_flow_id]
		, [StepNo].[color_text]
		, CASE 
			WHEN [StepNo].[is_skipped] = 1 THEN '#C7C7C7'
			WHEN ([StepNoDetail].[record_class] IS NULL AND [StepNo].[is_skipped] = 0 AND [StepNo].[step_no] != @step_no_now) THEN '#EEEEEF'
			WHEN (([StepNoDetail].[record_class] IS NULL OR [StepNoDetail].[record_class] = 20) AND [StepNo].[is_skipped] = 0 AND [StepNo].[step_no] = @step_no_now) THEN '#FFFD07'
			ELSE [item_labels].[color_code]
		END AS [color_label]
		, CASE 
			WHEN @package_id = 275 AND ([jobs].[id] = 88 OR [jobs].[id] = 106 OR [jobs].[id] = 278) THEN '#E5F9C0'
			ELSE NULL 
		END AS [color_bg]
		, [LotSetup].[recipe]
		, [ocr_record].[job_id] AS [ocr]
		, [d_record].[job_id] AS [resurpluse]
		, [andon_record].[job_id] AS [andon]
		, trc_record.[job_id] AS [trc]
		, IIF( [StepNo].[step_no] = @step_no_mix, 1, 0 ) as [mix]
		, ISNULL( [ChkEnd].[is_h], 0 ) AS [check_end]
	FROM ( ----# from data step no all (master,special)
		---- # master_flows
		SELECT [device_flows].[step_no]
			, [device_flows].[is_skipped]
			, [device_flows].[job_id]
			, 0 as [special_flow_id]
			, 0 as [lot_special_flow_id]
			, '#000000' AS [color_text]
		FROM [APCSProDB].[method].[device_flows] 
		WHERE [device_flows].[device_slip_id] = @device_slip_id
		UNION ALL
		---- # special_flows
		SELECT [lot_special_flows].[step_no]
			, [lot_special_flows].[is_skipped]
			, [lot_special_flows].[job_id]
			, [special_flows].[id] as [special_flow_id]
			, [lot_special_flows].[id] as [lot_special_flow_id]
			, '#CC00B7' AS [color_text]
		FROM [APCSProDB].[trans].[special_flows] 
		INNER JOIN [APCSProDB].[trans].[lot_special_flows] 
			ON [lot_special_flows].[special_flow_id] = [special_flows].[id]
		WHERE [special_flows].[lot_id] = @lot_id
	) AS [StepNo]
	INNER JOIN [APCSProDB].[method].[jobs] ----# join jobs
		ON [StepNo].[job_id] = [jobs].[id]
	LEFT JOIN ( ----# join sub query StepNoDetail
		SELECT [LotDetail].[record_class]
			, [LotDetail].[step_no]
			, [LotDetail].[qty_in]
			, [LotDetail].[qty_pass]
			, [LotDetail].[qty_fail]
			, LAG( [LotDetail].[qty_pass_step_sum], 1, [LotDetail].[qty_in] ) OVER ( ORDER BY [LotDetail].[step_no] ) AS [qty_last_pass]
			, [LotDetail].[qty_pass_step_sum]
			, [LotDetail].[qty_fail_step_sum]
			, LAG( [LotDetail].[qty_frame_pass], 1, [LotDetail].[qty_frame_in] ) OVER ( ORDER BY [LotDetail].[step_no] ) AS [qty_frame_in]
			, [LotDetail].[qty_frame_pass]
			, [LotDetail].[qty_frame_fail]
			, [LotDetail].[qty_p_nashi]
			, [LotDetail].[qty_combined]
			, [LotDetail].[qty_hasuu]
			, [LotDetail].[qty_out]
			, [LotDetail].[qty_front_ng]
			, [LotDetail].[qty_marker]
			, [LotDetail].[qty_cut_frame]
			, [LotDetail].[carrier_no]
			, [LotDetail].[next_carrier_no]
			, [LotDetail].[machine_id]
			, [LotDetail].[job_id]
			, [LotDetail].[user_id]
		FROM (
			SELECT [step_no], MAX( [id] ) AS [max_id]
			FROM [APCSProDB].[trans].[lot_process_records]
			WHERE [lot_id] = @lot_id
				AND [machine_id] > 0
				AND [lot_process_records].[record_class] NOT IN (25,26,52,53)
			GROUP BY [step_no]
		) AS StepFlow
		INNER JOIN (
			SELECT [lot_process_records].[id]
				, [lot_process_records].[record_class]
				, [lot_process_records].[step_no]
				, [lot_process_records].[qty_in]
				, [lot_process_records].[qty_pass]
				, [lot_process_records].[qty_fail]
				, [lot_process_records].[qty_last_pass]
				, [lot_process_records].[qty_pass_step_sum]
				, [lot_process_records].[qty_fail_step_sum]
				, [lot_process_records].[qty_frame_in]
				, [lot_process_records].[qty_frame_pass]
				, [lot_process_records].[qty_frame_fail]
				, [lot_process_records].[qty_p_nashi]
				, [lot_process_records].[qty_combined]
				, [lot_process_records].[qty_hasuu]
				, [lot_process_records].[qty_out]
				, [lot_process_records].[qty_front_ng]
				, [lot_process_records].[qty_marker]
				, [lot_process_records].[qty_cut_frame]
				, [lot_process_records].[carrier_no]
				, [lot_process_records].[next_carrier_no]
				, [lot_process_records].[machine_id]
				, [lot_process_records].[job_id]
				, [lot_process_records].[updated_by] AS [user_id]
			FROM [APCSProDB].[trans].[lot_process_records]
			WHERE [lot_id] = @lot_id 
				AND [lot_process_records].[record_class] NOT IN (25,26,52,53)
		) AS LotDetail ON [LotDetail].[id] = [StepFlow].[max_id]
	) AS [StepNoDetail] ON [StepNo].[step_no] = [StepNoDetail].[step_no]
	LEFT JOIN [APCSProDB].[trans].[item_labels] ----# join item_labels
		ON [item_labels].[name] = 'lot_process_records.record_class' 
			AND [item_labels].[val] = [StepNoDetail].[record_class]
	LEFT JOIN [APCSProDB].[mc].[machines] ----# join machines
		ON [StepNoDetail].[machine_id] = [machines].[id]
	LEFT JOIN [APCSProDB].[man].[users] ----# join users
		ON [StepNoDetail].[user_id] = [users].[id] 
	OUTER APPLY ( ----# join ChkEnd
		SELECT TOP 1 1 AS [is_h]
		FROM [APCSProDB].[trans].[lot_process_records]
		WHERE [lot_process_records].[record_class] IN (2)  ----# 2:LotEnd
			AND [lot_process_records].[lot_id] = @lot_id
			AND [lot_process_records].[step_no] = [StepNoDetail].[step_no]
		ORDER BY [lot_process_records].[recorded_at] DESC
	) AS [ChkEnd]
	OUTER APPLY ( ----# join LotSetup
		SELECT TOP 1 [lot_process_records].[recorded_at] AS [SetupTime]
			, [lot_process_records].[recipe]
		FROM [APCSProDB].[trans].[lot_process_records]
		WHERE [lot_process_records].[record_class] = 5  ----# 5:LotSetup
			AND [lot_process_records].[lot_id] = @lot_id
			AND [lot_process_records].[step_no] = [StepNoDetail].[step_no]
		ORDER BY [lot_process_records].[recorded_at] DESC
	) AS [LotSetup]
	OUTER APPLY ( ----# join LotStart
		SELECT TOP 1 [lot_process_records].[recorded_at] AS [StartTime]
		FROM [APCSProDB].[trans].[lot_process_records]
		WHERE [lot_process_records].[record_class] IN (1,31)  ----# 1:LotStart, 31:LotStart (ATOM)
			AND [lot_process_records].[lot_id] = @lot_id
			AND [lot_process_records].[step_no] = [StepNoDetail].[step_no]
		ORDER BY [lot_process_records].[recorded_at] DESC
	) AS [LotStart]
	OUTER APPLY ( ----# join LotEnd
		SELECT TOP 1 [lot_process_records].[recorded_at] AS [EndTime]
		FROM [APCSProDB].[trans].[lot_process_records]
		WHERE [lot_process_records].[record_class] IN (2,12,32)  ----# 2:LotEnd, 12:OnlineEnd, 32:LotEnd (ATOM)
			AND [lot_process_records].[lot_id] = @lot_id
			AND [lot_process_records].[step_no] = [StepNoDetail].[step_no]
		ORDER BY [lot_process_records].[recorded_at] DESC
	) AS [LotEnd]
	OUTER APPLY ( ----# join ocr_record
		SELECT TOP 1 [job_id]
		FROM  [APCSProDB].[trans].[lot_process_records]
		WHERE [lot_process_records].[record_class] IN (130,131) ----# 130:IntoOCR
			AND [lot_process_records].[lot_id] =  @lot_id
			AND [lot_process_records].[step_no] = [StepNoDetail].[step_no]
		ORDER BY [lot_process_records].[recorded_at] DESC
	) AS [ocr_record]
	OUTER APPLY ( ----# join d_record
		SELECT TOP 1 [job_id]
		FROM  [APCSProDB].[trans].[lot_process_records]
		WHERE [lot_process_records].[record_class] IN (35,36,37) ----# 35:D (ReSurpluse Stock In), 36:D (ReSurpluse Rework), 37:D (TP Rework)
			AND [lot_process_records].[lot_id] =  @lot_id
			AND [lot_process_records].[step_no] = [StepNoDetail].[step_no]
		ORDER BY [lot_process_records].[recorded_at] DESC
	) AS [d_record]
	OUTER APPLY ( ----# join andon_record
		SELECT TOP 1 [job_id]
		FROM  [APCSProDB].[trans].[lot_process_records]
		WHERE [lot_process_records].[record_class] IN (42,43) ----# 42:AndonOccurred, 43:AndonCleared
			AND [lot_process_records].[lot_id] =  @lot_id
			AND [lot_process_records].[step_no] = [StepNoDetail].[step_no]
		ORDER BY [lot_process_records].[recorded_at] DESC
	) AS [andon_record]
	OUTER APPLY ( ----# join tg_record
		SELECT TOP 1 [recorded_at] as [Time]
		FROM [APCSProDB].[trans].[lot_process_records]
		WHERE [lot_process_records].[record_class] IN (46,47) ----# 46:SurplusCombined, 47:CombineCancel
			AND [lot_process_records].[lot_id] = @lot_id
			AND [lot_process_records].[step_no] = [StepNoDetail].[step_no]
	) AS [tg_record]
		OUTER APPLY ( ----# join tg_record
		SELECT TOP 1 [job_id] as [job_id]
		FROM [APCSProDB].[trans].[lot_process_records]
		WHERE [lot_process_records].[record_class] IN (52,53) ----# 52:Request TRC , 53:Cleared TRC 
			AND [lot_process_records].[lot_id] = @lot_id
			AND [lot_process_records].[step_no] = [StepNoDetail].[step_no]
	) AS [trc_record]

	ORDER BY [StepNo].[step_no];

END
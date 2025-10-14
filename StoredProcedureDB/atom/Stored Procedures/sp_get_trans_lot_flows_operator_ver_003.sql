
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_lot_flows_operator_ver_003]
	-- Add the parameters for the stored procedure here
	@lot_id int	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	DECLARE @step_no_now INT
		, @package_id INT
		, @device_slip_id INT

	declare @table table
	(
		[step_no] int
		, [job_name] varchar(100)
		, [flow] int
	)

	declare @step_no_mix int = null

	insert into @table
	select [lots].[step_no]
		, [lots].[job_name]
		, [lots].[flow]
	from (
		select [device_flows].[step_no] as [step_no]
			, [jobs].[name] as [job_name]
			, 0 as [flow]
		from [APCSProDB].[trans].[lots] with (nolock)
		inner join [APCSProDB].[method].[device_flows] with (nolock) on [lots].[device_slip_id] = [device_flows].[device_slip_id]
		left join [APCSProDB].[method].[jobs] with (nolock) on [device_flows].[job_id] = [jobs].[id]
		where [lots].[id] = @lot_id
		union all
		select [lot_special_flows].[step_no] as [step_no]
			, [jobs].[name] as [job_name]
			, 1 as [flow]
		from [APCSProDB].[trans].[lots] with (nolock)
		left join [APCSProDB].[trans].[special_flows] with (nolock) on [lots].[id] = [special_flows].[lot_id]
		left join [APCSProDB].[trans].[lot_special_flows] with (nolock) on [special_flows].[id] = [lot_special_flows].[special_flow_id]
		left join [APCSProDB].[method].[jobs] with (nolock) on [lot_special_flows].[job_id] = [jobs].[id]
		where [lots].[id] = @lot_id
	) as [lots]
	where [job_name] in ('TP-TP','TP','FL','FT-TP','FLFTTP')
	order by [step_no]

	if exists(select lot_id from APCSProDB.trans.lot_combine with (nolock) where lot_id = @lot_id)
	begin
		if exists(select * from @table where flow = 0)
		begin
			set @step_no_mix = (select top 1 step_no from @table where flow = 0 order by step_no desc);
		end
		else if exists(select * from @table where flow = 1)
		begin
			set @step_no_mix = (select top 1 step_no from @table where flow = 1 order by step_no asc);
		end
	end

	SELECT @step_no_now = (
		CASE 
			WHEN [lots].[is_special_flow] = 1 then 
				(SELECT [step_no] FROM [APCSProDB].[trans].[special_flows] WITH (NOLOCK) WHERE [special_flows].[id] = [lots].[special_flow_id]) 
		   ELSE [lots].[step_no]
		END ) 
		, @device_slip_id = device_slip_id
		, @package_id = act_package_id --find package_id = 275 (TO263-3) for condition color
	FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
	WHERE [lots].[id] = @lot_id;

	SELECT [device_flows].[step_no] AS [step_no]
		, [device_flows].[is_skipped] AS [is_skipped]
		, [jobs].[name] AS [job_name]
		, [LotFlow].[record_class] AS [record_class]
		, [LotFlow].[qty_in] AS [qty_in]
		, [LotFlow].[qty_pass] AS [qty_pass]
		, [LotFlow].[qty_fail] AS [qty_fail]
		, [LotFlow].[qty_last_pass] AS [qty_last_pass]
		, [LotFlow].[qty_pass_step_sum] AS [qty_pass_step_sum]
		, [LotFlow].[qty_fail_step_sum] AS [qty_fail_step_sum]
		, [LotFlow].[qty_frame_in] AS [qty_frame_in]
		, [LotFlow].[qty_frame_pass] AS [qty_frame_pass]
		, [LotFlow].[qty_frame_fail] AS [qty_frame_fail]
		, [LotFlow].[machine_id] AS [machine_id]
		, [LotFlow].[name] AS [machine_name]
		, [LotFlow].[carrier_no] AS [carrier_no]
		, [LotFlow].[next_carrier_no] AS [next_carrier_no]
		, [LotFlow].[emp_num] AS [emp_num]
		, [LotFlow].[StartTime] AS [start_time]
		, [LotFlow].[EndTime] AS [end_time]
		, [LotFlow].[SetupTime] AS [setup_time]
		, [LotFlow].[label_eng] AS [label_eng]
		, 0 as [special_flow_id]
		, 0 as [lot_special_flow_id]
		, '#000000' AS [color_text]
		, CASE 
			WHEN [device_flows].[is_skipped] = 1 THEN '#c7c7c7'
			WHEN ([LotFlow].[record_class] IS NULL AND [device_flows].[is_skipped] = 0 AND [device_flows].[step_no] != @step_no_now) THEN '#eeeeef'
			WHEN (([LotFlow].[record_class] IS NULL OR [LotFlow].[record_class] = 20) AND [device_flows].[is_skipped] = 0 AND [device_flows].[step_no] = @step_no_now) THEN '#fffd07'
			ELSE [LotFlow].[color_code]
		END AS [color_label]
		, [LotFlow].[qty_p_nashi] AS [qty_p_nashi]
		, [LotFlow].[qty_combined] AS [qty_combined]
		, [LotFlow].[qty_hasuu] AS [qty_hasuu]
		, [LotFlow].[qty_out] AS [qty_out]
		, [LotFlow].[qty_front_ng] AS [qty_front_ng]
		, [LotFlow].[qty_marker] AS [qty_marker]
		, [LotFlow].[qty_cut_frame] AS [qty_cut_frame]
		, CASE 
			WHEN @package_id = 275 AND ([jobs].[id] = 88 OR [jobs].[id] = 106 OR [jobs].[id] = 278) THEN '#e5f9c0'
			ELSE NULL 
		END AS [color_bg]
		, [device_flows].[recipe] AS [recipe]
		, [ocr_record].[job_id] AS [ocr]
		, [d_record].[job_id] AS [resurpluse]
		, [andon_record].[job_id] AS [andon]
		, IIF([device_flows].[step_no] = @step_no_mix,1,0) as [mix]
	FROM [APCSProDB].[method].[device_flows] WITH (NOLOCK)
	LEFT JOIN (
		SELECT [LotDetail].[record_class]
			, [LotDetail].[step_no]
			, [LotDetail].[qty_in]
			, [LotDetail].[qty_pass]
			, [LotDetail].[qty_fail]
			, LAG([LotDetail].[qty_pass_step_sum],1,[LotDetail].[qty_in]) OVER (ORDER BY [LotDetail].[step_no]) AS [qty_last_pass]
			, [LotDetail].[qty_pass_step_sum]
			, [LotDetail].[qty_fail_step_sum]
			, LAG([LotDetail].[qty_frame_pass],1,[LotDetail].[qty_frame_in]) OVER (ORDER BY [LotDetail].[step_no]) AS [qty_frame_in]
			, [LotDetail].[qty_frame_pass]
			, [LotDetail].[qty_frame_fail]
			, [LotDetail].[machine_id]
			, [LotDetail].[carrier_no]
			, [LotDetail].[next_carrier_no]
			, [LotDetail].[name]
			, [LotDetail].[emp_num]
			, [LotStart].[StartTime]
			, [LotDetail].[qty_p_nashi]
			, [LotDetail].[qty_combined]
			, [LotDetail].[qty_hasuu]
			, [LotDetail].[qty_out]
			, [LotDetail].[qty_front_ng]
			, [LotDetail].[qty_marker]
			, [LotDetail].[qty_cut_frame]
			, CASE 
				WHEN [LotDetail].[record_class] in (46,47) THEN [TG_record].[Time] 
				ELSE 
					CASE 
						WHEN ([LotStart].[StartTime] <= [LotEnd].[EndTime]) THEN cast([LotEnd].[EndTime] AS datetime2) 
						ELSE [LotEnd].[EndTime] 
					END 
			END AS [EndTime]
			, CASE 
				WHEN [LotDetail].[record_class] IN (46,47) THEN [TG_record].[Time] 
				ELSE [LotSetup].[SetupTime] 
			END AS [SetupTime] 
			, [item_labels1].[label_eng]
			, [item_labels1].[color_code]
		FROM (
			SELECT [step_no], MAX([id]) AS max_id
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			WHERE [lot_id] = @lot_id
				AND [machine_id] > 0
				AND [lot_process_records].[record_class] NOT IN (25,26)
			GROUP BY [step_no]
		) as StepFlow
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
				, [lot_process_records].[machine_id]
				, [lot_process_records].[carrier_no]
				, [lot_process_records].[next_carrier_no]
				, [APCSProDB].[mc].[machines].[name]
				, [APCSProDB].[man].[users].[emp_num]
				, [lot_process_records].[qty_p_nashi]
				, [lot_process_records].[qty_combined]
				, [lot_process_records].[qty_hasuu]
				, [lot_process_records].[qty_out]
				, [lot_process_records].[qty_front_ng]
				, [lot_process_records].[qty_marker]
				, [lot_process_records].[qty_cut_frame]
				, [lot_process_records].[job_id]
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			LEFT JOIN [APCSProDB].[mc].[machines] WITH (NOLOCK) on [lot_process_records].[machine_id] = [machines].[id]
			LEFT JOIN [APCSProDB].[man].[users] WITH (NOLOCK) on [lot_process_records].[updated_by] = [users].[id] 
			WHERE [lot_id] = @lot_id 
				AND [lot_process_records].[record_class] NOT IN (25,26)
		) AS LotDetail ON LotDetail.id = StepFlow.max_id
		LEFT JOIN (
			SELECT [step_no]
				, [machine_id]
				, [recorded_at] AS SetupTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			WHERE [record_class] IN (5) 
				AND [lot_id] = @lot_id
		) AS LotSetup ON LotDetail.step_no = LotSetup.step_no 
			AND LotSetup.machine_id = LotSetup.machine_id
			AND LotSetup.rowmax = 1
		LEFT JOIN (
			SELECT [step_no]
				, [machine_id]
				, [recorded_at] AS StartTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			WHERE [record_class] IN (1,31) 
				AND [lot_id] = @lot_id
		) AS LotStart ON LotDetail.step_no = LotStart.step_no 
			AND LotDetail.machine_id = LotStart.machine_id
			AND LotStart.rowmax = 1
		LEFT JOIN (
			SELECT [step_no]
				, [machine_id]
				, [recorded_at] AS EndTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			WHERE [record_class] IN (2,12,32) 
				AND [lot_id] = @lot_id
		) AS LotEnd ON LotDetail.step_no = LotEnd.step_no 
			AND LotDetail.machine_id = LotEnd.machine_id
			AND LotEnd.rowmax = 1
		LEFT JOIN (
			SELECT [step_no]
				, [machine_id]
				, [recorded_at] as [Time]
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			WHERE [record_class] IN (46,47) 
				AND [lot_id] = @lot_id
		) AS TG_record ON LotDetail.step_no = TG_record.step_no 
			AND LotDetail.machine_id = TG_record.machine_id
			AND TG_record.rowmax = 1
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels1] WITH (NOLOCK) ON [item_labels1].[name] = 'lot_process_records.record_class' 
			AND [item_labels1].[val] = [LotDetail].[record_class]
	) AS LotFlow ON [device_flows].[step_no] = [LotFlow].[step_no]
	INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [device_flows].[job_id] = [jobs].[id]
	LEFT JOIN (
		SELECT [job_id]
		FROM  [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
		WHERE [lot_id] =  @lot_id
			AND [record_class] = 130
		GROUP BY [job_id]
	) AS [ocr_record] ON [jobs].[id] = [ocr_record].[job_id]
	LEFT JOIN (
		SELECT [job_id]
		FROM  [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
		WHERE [lot_id] =  @lot_id
			AND [record_class] in (35,36,37)
		GROUP BY [job_id]
	) AS [d_record] ON [jobs].[id] = [d_record].[job_id]
	LEFT JOIN (
		SELECT [job_id]
		FROM  [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
		WHERE [lot_id] =  @lot_id
			AND [record_class] IN (42,43)
		GROUP BY [job_id]
	) AS [andon_record] ON [jobs].[id] = [andon_record].[job_id]
	WHERE [device_flows].[device_slip_id] = @device_slip_id
	UNION ALL
	-- special_flows
	SELECT [lot_special_flows].[step_no] AS [step_no]
		, [lot_special_flows].[is_skipped] AS [is_skipped]
		, [jobs].[name] AS [job_name]
		, [LotFlow].[record_class] AS [record_class]
		, [LotFlow].[qty_in] AS [qty_in]
		, [LotFlow].[qty_pass] AS [qty_pass]
		, [LotFlow].[qty_fail] AS [qty_fail]
		, [LotFlow].[qty_last_pass] AS [qty_last_pass]
		, [LotFlow].[qty_pass_step_sum] AS [qty_pass_step_sum]
		, [LotFlow].[qty_fail_step_sum] AS [qty_fail_step_sum]
		, [LotFlow].[qty_frame_in] AS [qty_frame_in]
		, [LotFlow].[qty_frame_pass] AS [qty_frame_pass]
		, [LotFlow].[qty_frame_fail] AS [qty_frame_fail]
		, [LotFlow].[machine_id] AS [machine_id]
		, [LotFlow].[name] AS [machine_name]
		, [LotFlow].[carrier_no] AS [carrier_no]
		, [LotFlow].[next_carrier_no] AS [next_carrier_no]
		, [LotFlow].[emp_num] AS [emp_num]
		, [LotFlow].[StartTime] AS [start_time]
		, [LotFlow].[EndTime] AS [end_time]
		, [LotFlow].[SetupTime] AS [setup_time]
		, [LotFlow].[label_eng] AS [label_eng]
		, [lot_special_flows].[special_flow_id] as [special_flow_id]
		, [lot_special_flows].[id] as [lot_special_flow_id]
		, '#cc00b7' AS [color_text]
		, CASE 
			WHEN [lot_special_flows].[is_skipped] = 1 THEN '#c7c7c7'
			WHEN ([LotFlow].[record_class] IS NULL AND [lot_special_flows].[is_skipped] = 0 AND [lot_special_flows].[step_no] != @step_no_now) THEN '#eeeeef' 
			WHEN (([LotFlow].[record_class] IS NULL OR [LotFlow].[record_class] = 20) AND [lot_special_flows].[is_skipped] = 0 AND [lot_special_flows].[step_no] = @step_no_now) THEN '#FFFF00' 
			ELSE [LotFlow].[color_code]
		 END AS [color_label]
		, [LotFlow].[qty_p_nashi] AS [qty_p_nashi]
		, [LotFlow].[qty_combined] AS [qty_combined]
		, [LotFlow].[qty_hasuu] AS [qty_hasuu]
		, [LotFlow].[qty_out] AS [qty_out]
		, [LotFlow].[qty_front_ng] AS [qty_front_ng]
		, [LotFlow].[qty_marker] AS [qty_marker]
		, [LotFlow].[qty_cut_frame] AS [qty_cut_frame]
		, CASE 
			WHEN @package_id = 275 AND ([jobs].[id] = 88 OR [jobs].[id] = 106 OR [jobs].[id] = 278) THEN '#e5f9c0'
			ELSE NULL 
		END AS [color_bg]
		, [lot_special_flows].[recipe] AS [recipe]
		, [ocr_record].[job_id] AS [ocr]
		, [d_record].[job_id] AS [resurpluse]
		, [andon_record].[job_id] AS [andon]
		, IIF([lot_special_flows].[step_no] = @step_no_mix,1,0) as [mix]
	FROM [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK)
	INNER JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
	LEFT JOIN (
		SELECT [LotDetail].[record_class]
			, [LotDetail].[step_no]
			, [LotDetail].[qty_in]
			, [LotDetail].[qty_pass]
			, [LotDetail].[qty_fail]
			, LAG([LotDetail].[qty_pass_step_sum],1,[LotDetail].[qty_in]) OVER (ORDER BY [LotDetail].[step_no]) AS [qty_last_pass]
			, [LotDetail].[qty_pass_step_sum]
			, [LotDetail].[qty_fail_step_sum]
			, LAG([LotDetail].[qty_frame_pass],1,[LotDetail].[qty_frame_in]) OVER (ORDER BY [LotDetail].[step_no]) AS [qty_frame_in]
			, [LotDetail].[qty_frame_pass]
			, [LotDetail].[qty_frame_fail]
			, [LotDetail].[machine_id]
			, [LotDetail].[carrier_no]
			, [LotDetail].[next_carrier_no]
			, [LotDetail].[name]
			, [LotDetail].[emp_num]
			, [LotStart].[StartTime]
			, [LotDetail].[qty_p_nashi]
			, [LotDetail].[qty_combined]
			, [LotDetail].[qty_hasuu]
			, [LotDetail].[qty_out]
			, [LotDetail].[qty_front_ng]
			, [LotDetail].[qty_marker]
			, [LotDetail].[qty_cut_frame]
			, CASE WHEN ([LotStart].[StartTime] <= [LotEnd].[EndTime]) THEN CAST([LotEnd].[EndTime] AS datetime2)ELSE [LotEnd].[EndTime] END as [EndTime]
			, [LotSetup].[SetupTime]
			, [item_labels1].[label_eng]
			, [item_labels1].[color_code]
		FROM (
			SELECT [step_no], MAX([id]) AS max_id
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			WHERE [lot_id] = @lot_id
				AND [machine_id] > 0
			GROUP BY [step_no]
		) AS StepFlow
		INNER JOIN (
			select [lot_process_records].[id]
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
				, [lot_process_records].[machine_id]
				, [lot_process_records].[carrier_no]
				, [lot_process_records].[next_carrier_no]
				, [APCSProDB].[mc].[machines].[name]
				, [APCSProDB].[man].[users].[emp_num]
				, [lot_process_records].[qty_p_nashi]
				, [lot_process_records].[qty_combined]
				, [lot_process_records].[qty_hasuu]
				, [lot_process_records].[qty_out]
				, [lot_process_records].[qty_front_ng]
				, [lot_process_records].[qty_marker]
				, [lot_process_records].[qty_cut_frame]
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			LEFT JOIN [APCSProDB].[mc].[machines] WITH (NOLOCK) on [lot_process_records].[machine_id] = [machines].[id]
			LEFT JOIN [APCSProDB].[man].[users] WITH (NOLOCK) on [lot_process_records].[updated_by] = [users].[id] 
			WHERE [lot_id] = @lot_id 
				AND [lot_process_records].[record_class] NOT IN (25,26)
		) AS LotDetail ON LotDetail.id = StepFlow.max_id
		LEFT JOIN (
			SELECT [step_no]
				, [machine_id]
				, [recorded_at] AS SetupTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			WHERE [record_class] IN (5) 
				AND [lot_id] = @lot_id
		) AS LotSetup ON LotDetail.step_no = LotSetup.step_no 
			AND LotSetup.machine_id = LotSetup.machine_id
			AND LotSetup.rowmax = 1
		LEFT JOIN (
			SELECT [step_no]
				, [machine_id]
				, [recorded_at] AS StartTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			WHERE [record_class] IN (1,31) 
				AND [lot_id] = @lot_id
		) AS LotStart ON LotDetail.step_no = LotStart.step_no 
			AND LotDetail.machine_id = LotStart.machine_id
			AND LotStart.rowmax = 1
		LEFT JOIN (
			SELECT [step_no]
				, [machine_id]
				, [recorded_at] AS EndTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			WHERE [record_class] IN (2,12,32) 
				AND [lot_id] = @lot_id
		) AS LotEnd ON LotDetail.step_no = LotEnd.step_no 
			AND LotDetail.machine_id = LotEnd.machine_id
			AND LotEnd.rowmax = 1
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels1] WITH (NOLOCK) ON [item_labels1].[name] = 'lot_process_records.record_class' 
			AND [item_labels1].[val] = [LotDetail].[record_class]
	) AS LotFlow ON [lot_special_flows].[step_no] = [LotFlow].[step_no]
	INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [lot_special_flows].[job_id] = [jobs].[id]
	LEFT JOIN (
		SELECT [job_id]
		FROM  [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
		WHERE [lot_id] =  @lot_id
			AND [record_class] = 130
		GROUP BY [job_id]
	) AS [ocr_record] ON [jobs].[id] = [ocr_record].[job_id]
	LEFT JOIN (
		SELECT [job_id]
		FROM  [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
		WHERE [lot_id] =  @lot_id
			AND [record_class] in (35,36,37)
		GROUP BY [job_id]
	) AS [d_record] ON [jobs].[id] = [d_record].[job_id]
	LEFT JOIN (
		SELECT [job_id]
		FROM  [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
		WHERE [lot_id] =  @lot_id
			AND [record_class] IN (42,43)
		GROUP BY [job_id]
	) AS [andon_record] ON [jobs].[id] = [andon_record].[job_id]
	WHERE [special_flows].[lot_id] = @lot_id
	ORDER BY [device_flows].[step_no], [start_time]
END

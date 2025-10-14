
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_lot_flows_operator_Test]
	-- Add the parameters for the stored procedure here
	@lot_id int	
	--, @device_slip_id int
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	DECLARE @step_no_now INT
		, @package_id INT
		, @device_slip_id INT
		, @lotNo NVARCHAR(10)

		 SET @lotNo = (SELECT lot_no FROM [APCSProDB].trans.lots WHERE  id = @lot_id)

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
	 
	SELECT  @lotNo  AS  LotNo
		,  [jobs].[name] AS [Operation]
		, [device_flows].[step_no] AS Step
		, ISNULL([LotFlow].[name],'') AS Machine
		, ISNULL([LotFlow].[label_eng],'') AS Status
		, [LotFlow].[StartTime] AS [Start Time]
		, [LotFlow].[EndTime] AS [Finish Time]
		, ISNULL([LotFlow].[qty_last_pass],'') AS [Input]
		, ISNULL([LotFlow].[qty_pass_step_sum],'') AS [Good]
		, ISNULL([LotFlow].[qty_fail_step_sum],'') AS [NG]
		, ISNULL([LotFlow].[qty_frame_in],'') AS [Frames Total]
		, ISNULL([LotFlow].[qty_frame_pass],'') AS [Frames Good]
		, ISNULL([LotFlow].[qty_frame_fail],'') AS [Frames NG]
		, ISNULL([LotFlow].[emp_num],'') AS [OPNO.	]
		, ISNULL([LotFlow].[carrier_no],'') AS [CarrierNo]
		, ISNULL([LotFlow].[qty_p_nashi],'') AS [P Nashi]
		, ISNULL([LotFlow].[qty_combined],'') AS [Combined]
		, ISNULL([LotFlow].[qty_hasuu],'') AS [Surplus]
		, ISNULL([LotFlow].[qty_out],'') AS [Shipment]
		, ISNULL([LotFlow].[qty_front_ng],'') AS [Front NG]
		, ISNULL([LotFlow].[qty_marker],'') AS [Marker]
		, ISNULL([device_flows].[recipe],'') AS [Recipe]
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

	SELECT 	 @lotNo AS LotNo
	,[jobs].[name] AS [Operation] 
		, [lot_special_flows].[step_no] AS [step_no]
		, ISNULL([LotFlow].[name],'') AS [machine_name]
		, ISNULL([LotFlow].[label_eng],'') AS [label_eng]
		, [LotFlow].[StartTime] AS [Start Time]
		, [LotFlow].[EndTime] AS [end_time]
		, ISNULL([LotFlow].[qty_last_pass],'') AS [qty_last_pass]
		, ISNULL([LotFlow].[qty_pass_step_sum],'') AS [qty_pass_step_sum]
		, ISNULL([LotFlow].[qty_fail_step_sum],'') AS [qty_fail_step_sum]
		, ISNULL([LotFlow].[qty_frame_in],'') AS [qty_frame_in]
		, ISNULL([LotFlow].[qty_frame_pass],'') AS [qty_frame_pass]
		, ISNULL([LotFlow].[qty_frame_fail],'') AS [qty_frame_fail]
		, ISNULL([LotFlow].[emp_num],'') AS [emp_num]
		, ISNULL([LotFlow].[carrier_no],'') AS [carrier_no]
		, ISNULL([LotFlow].[qty_p_nashi],'') AS [qty_p_nashi]
		, ISNULL([LotFlow].[qty_combined],'') AS [qty_combined]
		, ISNULL([LotFlow].[qty_hasuu],'') AS [qty_hasuu]
		, ISNULL([LotFlow].[qty_out],'') AS [qty_out]
		, ISNULL([LotFlow].[qty_front_ng],'') AS [qty_front_ng]
		, ISNULL([LotFlow].[qty_marker],'') AS [qty_marker]
		, ISNULL([lot_special_flows].[recipe],'') AS [recipe]
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
	ORDER BY [device_flows].[step_no], [Start Time]
END

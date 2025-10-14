-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lots_combine_by_memberlot]
	-- Add the parameters for the stored procedure here
	@lot_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [lot_combine].[lot_id] AS [Id]
		, [lots].[lot_no] AS [LotNo] 
		, ISNULL([lots].[carrier_no], '-') AS [CarrierNo] 
		, case when [lots].[is_special_flow] = 1 THEN [job2].[name] ELSE [jobs].[name] END AS [Operation] 
		, [item_labels1].[label_eng] AS [WipState] 
		, CASE WHEN [lots].[is_special_flow] = 1 THEN [item_labels6].[label_eng] ELSE [item_labels2].[label_eng] END AS [ProcessState]
		, [item_labels3].[label_eng] AS [QualityState]  
		, [lots].[qty_in] AS [Total] 
		, [lots].[qty_pass] AS [Good]  
		, [lots].[qty_fail] AS [NG]  
		, [users1].[emp_num] AS [Operator]
		, [sur_member].[pcs] AS [QTY]
		, [sur_member].[mark_no] AS [Mark_No]
	FROM [APCSProDB].[trans].[lot_combine] WITH (NOLOCK)
	INNER JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [lot_combine].[lot_id] = [lots].[id]
	INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
		AND [device_flows].[step_no] = [lots].[step_no]
	INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
	INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels1] WITH (NOLOCK) ON [item_labels1].[name] = 'lots.wip_state' 
		AND [item_labels1].[val] = [lots].[wip_state]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels2] WITH (NOLOCK) ON [item_labels2].[name] = 'lots.process_state' 
		AND [item_labels2].[val] = [lots].[process_state]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels3] WITH (NOLOCK) ON [item_labels3].[name] = 'lots.quality_state' 
		AND [item_labels3].[val] = [lots].[quality_state]
	LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [lots].[id] = [special_flows].[lot_id]
		AND [lots].[special_flow_id] = [special_flows].[id]
		AND [lots].[is_special_flow] = 1
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
		AND  [special_flows].[step_no] = [lot_special_flows].[step_no]
	LEFT JOIN [APCSProDB].[method].[jobs] AS [job2] WITH (NOLOCK) ON [job2].[id] = [lot_special_flows].[job_id]
	LEFT JOIN [APCSProDB].[method].[processes] AS [processes2] WITH (NOLOCK) ON [processes2].[id] = [job2].[process_id]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels6] WITH (NOLOCK) ON [item_labels6].[name] = 'lots.process_state' 
		AND [item_labels6].[val] = [special_flows].[process_state]
	LEFT JOIN [APCSProDB].[man].[users] AS [users1] WITH (NOLOCK) ON [users1].[id] = [lots].[updated_by]
	LEFT JOIN [APCSProDB].[trans].[surpluses] AS [sur_member] ON  [lots].[id] = [sur_member].[lot_id]
	WHERE [lot_combine].[member_lot_id] = @lot_id
		AND [lot_combine].[member_lot_id] != [lot_combine].[lot_id];
END

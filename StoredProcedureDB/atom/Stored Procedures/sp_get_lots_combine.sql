-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lots_combine]
	-- Add the parameters for the stored procedure here
	@lot_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select	  [member_lot_id]					AS [Id]
			, [lots].[lot_no]					AS [LotNo] 
			, isnull([lots].[carrier_no],'-')	AS [CarrierNo] 
			, case when [lots].[is_special_flow] = 1 then [job2].[name] else [jobs].[name] end AS [Operation] 
			, [item_labels1].[label_eng]		AS [WipState] 
			, case when [lots].[is_special_flow] = 1 then [item_labels6].[label_eng] else [item_labels2].[label_eng] end AS [ProcessState]
			, [item_labels3].[label_eng]		AS [QualityState]  
			, [lots].[qty_in]					AS [Total] 
			, [lots].[qty_pass]					AS [Good]  
			, [lots].[qty_fail]					AS [NG]  
			, [users1].[emp_num]				AS [Operator]
			, sur_member.pcs					AS QTY
			, sur_member.mark_no				AS Mark_No
	from [APCSProDB].[trans].[lot_combine] with (NOLOCK)
	INNER JOIN [APCSProDB].[trans].[lots] with (NOLOCK) 
	ON [lot_combine].[member_lot_id] = [lots].[id]
	INNER JOIN [APCSProDB].[method].[device_slips] with (NOLOCK) 
	ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] with (NOLOCK) 
	ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] with (NOLOCK) 
	ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] with (NOLOCK) 
	ON [packages].[id] = [device_names].[package_id]
	INNER JOIN [APCSProDB].[method].[package_groups] with (NOLOCK) 
	ON [package_groups].[id] = [packages].[package_group_id]
	INNER JOIN [APCSProDB].[method].[device_flows] with (NOLOCK) 
	ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
	and [device_flows].[step_no] = [lots].[step_no]
	INNER JOIN [APCSProDB].[method].[jobs] with (NOLOCK) 
	ON [jobs].[id] = [device_flows].[job_id]
	INNER JOIN [APCSProDB].[method].[processes] with (NOLOCK) 
	ON [processes].[id] = [jobs].[process_id]
	INNER JOIN [APCSProDB].[trans].[days] AS [days1] with (NOLOCK) 
	ON [days1].[id] = [lots].[in_plan_date_id]
	INNER JOIN [APCSProDB].[trans].[days] AS [days2] with (NOLOCK) 
	ON [days2].[id] = [lots].[modify_out_plan_date_id]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels1] with (NOLOCK) 
	ON [item_labels1].[name] = 'lots.wip_state' 
	and [item_labels1].[val] = [lots].[wip_state]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels2] with (NOLOCK) 
	ON [item_labels2].[name] = 'lots.process_state' 
	and [item_labels2].[val] = [lots].[process_state]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels3] with (NOLOCK) 
	ON [item_labels3].[name] = 'lots.quality_state' 
	and [item_labels3].[val] = [lots].[quality_state]
	LEFT JOIN [APCSProDB].[man].[users] AS [users1] with (NOLOCK) 
	ON [users1].[id] = [lots].[updated_by]
	LEFT JOIN [APCSProDB].[trans].[special_flows] with (NOLOCK) 
	ON [special_flows].[id] = [lots].[special_flow_id] 
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) 
	ON [lot_special_flows].[special_flow_id] = [special_flows].[id] 
	and  [special_flows].step_no = [lot_special_flows].step_no
	LEFT JOIN [APCSProDB].[method].[jobs] AS [job2] with (NOLOCK) 
	ON [job2].[id] = [lot_special_flows].[job_id]
	LEFT JOIN [APCSProDB].[method].[processes] AS [processes2] with (NOLOCK) 
	ON [processes2].[id] = [job2].[process_id]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels6] with (NOLOCK) 
	ON [item_labels6].[name] = 'lots.process_state' 
	AND [item_labels6].[val] = [special_flows].[process_state]
	LEFT JOIN APCSProDB.trans.surpluses AS sur_member 
	ON  [lots].id = sur_member.lot_id
	WHERE [lot_combine].[lot_id] = @lot_id


END

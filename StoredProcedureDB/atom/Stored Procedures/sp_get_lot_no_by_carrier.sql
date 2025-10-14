-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lot_no_by_carrier]
	-- Add the parameters for the stored procedure here
	@carrier varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	SELECT [lots].[lot_no] AS [LotNo]
		, IIF([lots].[is_special_flow] = 1,ISNULL([job_special].[name],''),[jobs].[name]) AS [JobName]
		, IIF([lots].[is_special_flow] = 1,ISNULL([item_process_state_sp].[label_eng],''),[item_process_state].[label_eng]) AS [ProcessState]
		, IIF([lots].[carrier_no] IS NULL OR [lots].[carrier_no] = '','-',[lots].[carrier_no]) AS [LoadCarrier]
		, IIF([lots].[next_carrier_no] IS NULL OR [lots].[next_carrier_no] = '','-',[lots].[next_carrier_no]) AS [UnloadCarrier]
	FROM [APCSProDB].[trans].[lots]
	-------------------- master_flows --------------------
	INNER JOIN [APCSProDB].[method].[device_flows]
		ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
			AND [device_flows].[step_no] = [lots].[step_no]
	INNER JOIN [APCSProDB].[method].[jobs]
		ON [jobs].[id] = [device_flows].[job_id]
	-------------------- master_flows --------------------
	-------------------- special_flows -------------------- 
	LEFT JOIN [APCSProDB].[trans].[special_flows]
		ON [special_flows].[id] = [lots].[special_flow_id] 
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows]
		ON [lot_special_flows].[special_flow_id] = [special_flows].[id] 
			AND  [special_flows].[step_no] = [lot_special_flows].[step_no]
	LEFT JOIN [APCSProDB].[method].[jobs] as [job_special]
		ON [job_special].[id] = [lot_special_flows].[job_id]
	-------------------- special_flows -------------------- 
	-------------------- item_labels -------------------- 
	LEFT JOIN [APCSProDB].[trans].[item_labels] as [item_process_state] 
		ON [item_process_state].[name] = 'lots.process_state' 
			AND [item_process_state].[val] = [lots].[process_state]
	LEFT JOIN [APCSProDB].[trans].[item_labels] as [item_process_state_sp] 
		ON [item_process_state_sp].[name] = 'lots.process_state' 
			AND [item_process_state_sp].[val] = [special_flows].[process_state]
	WHERE [lots].[wip_state] = 20
		AND ( [lots].[carrier_no] = @carrier 
			OR [lots].[next_carrier_no] = @carrier );
END

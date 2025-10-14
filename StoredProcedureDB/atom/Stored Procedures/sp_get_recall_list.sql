-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_recall_list]
	-- Add the parameters for the stored procedure here
	@StartDate VARCHAR(20),
	@EndDate VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [lot_master].[created_at] AS [recall_date]
		, [lot_master].[lot_no] AS [recall_lot_no]
		, [lot_member].[lot_no] AS [original_lot_no]
		, [PROCESS_RECALL_IF].[ABNORMALCASE] AS [abnormal_case]
		, [device_names].[name] AS [device]
		, [packages].[name] AS [package]
		, [PROCESS_RECALL_IF].[PD] AS [pd_request]
	FROM [APCSProDB].[trans].[lots] AS [lot_master]
	INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_master].[id] = [lot_combine].[lot_id]
	INNER JOIN [APCSProDB].[trans].[lots] AS [lot_member] ON [lot_combine].[member_lot_id] = [lot_member].[id]
	INNER JOIN [APCSProDWH].[dbo].[PROCESS_RECALL_IF] ON [lot_master].[lot_no] = [PROCESS_RECALL_IF].[NEWLOT]
		AND [lot_member].[lot_no] = [PROCESS_RECALL_IF].[LOTNO]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lot_master].[act_device_name_id] = [device_names].[id]
	INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
	WHERE [lot_master].[created_at] BETWEEN @StartDate + ' 00:00:00' AND @EndDate + ' 23:59:59'
	ORDER BY [lot_master].[created_at] DESC
END

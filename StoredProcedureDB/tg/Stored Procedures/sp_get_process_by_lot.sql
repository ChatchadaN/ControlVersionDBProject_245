-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [tg].[sp_get_process_by_lot]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT IIF([lots].[is_special_flow] = 1, [process_special].[id], [processes].[id]) AS [process_id]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_flows] ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
		AND [device_flows].[step_no] = [lots].[step_no]
	INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[id] = [device_flows].[job_id]
	INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [jobs].[process_id]
	LEFT JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lots].[special_flow_id] 
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = [special_flows].[id] 
		AND  [special_flows].[step_no] = [lot_special_flows].[step_no]
	LEFT JOIN [APCSProDB].[method].[jobs] AS [job_special] ON [job_special].[id] = [lot_special_flows].[job_id]
	LEFT JOIN [APCSProDB].[method].[processes] AS [process_special] ON [process_special].[id] = [job_special].[process_id]
	WHERE [lots].[lot_no] = @lot_no;
END

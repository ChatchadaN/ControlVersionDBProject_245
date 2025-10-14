-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_andon_get_record_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT TOP(10) CAST(1 AS BIT) AS [status]
	, [ProblemsTransaction].[TransactionID] AS [andon_control_id]
	, [processes].[name] AS [process]
	, [machines].[name] AS [machine]
	, [user_request].[emp_num] AS [request_emp_num]
	, [ProblemsTransaction].[LineNo] AS [line_no]
	, [packages].[name] AS [package]
	, [device_names].[name] AS [device]
	, [lots].[lot_no] AS [lot_no]
	, [ProblemsTransaction].[StartTime] AS [start_time]
	, ISNULL([ProblemsTransaction].[EndTime], GETDATE()) AS [end_time]
	, CASE WHEN ([ProblemsTransaction].[Status] = 1)
		THEN 'Cleared'
		ELSE 'Not Cleared' END AS [clear_status]
	FROM [DBx].[dbo].[ProblemsTransaction]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[lot_no] = [ProblemsTransaction].[LotNo]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
	INNER JOIN [APCSProDB].[mc].[machines] ON [machines].[name] = [ProblemsTransaction].[MachineNo]
	INNER JOIN [APCSProDB].[man].[users] AS [user_request] ON [user_request].[emp_num] = [ProblemsTransaction].[OperatorNo]
	INNER JOIN [APCSProDB].[method].[processes] ON [processes].[name] = [ProblemsTransaction].[ProcessName]
	LEFT JOIN [APCSProDB].[man].[users] AS [user_clear] ON [user_clear].[emp_num] = [ProblemsTransaction].[GroupLeaderCheck]
	ORDER BY [ProblemsTransaction].[TransactionID] DESC
END

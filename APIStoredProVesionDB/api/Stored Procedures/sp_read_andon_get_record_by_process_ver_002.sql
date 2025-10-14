-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_andon_get_record_by_process_ver_002]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@list_process_id varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [ProblemsTransaction].[TransactionID]
	FROM [DBx].[dbo].[ProblemsTransaction]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[lot_no] = [ProblemsTransaction].[LotNo]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
	INNER JOIN [APCSProDB].[mc].[machines] ON [machines].[name] = [ProblemsTransaction].[MachineNo]
	LEFT JOIN [APCSProDB].[man].[users] AS [user_request] ON [user_request].[emp_num] = [ProblemsTransaction].[OperatorNo]
	INNER JOIN [APCSProDB].[method].[processes] ON [processes].[name] = [ProblemsTransaction].[ProcessName]
	LEFT JOIN [APCSProDB].[man].[users] AS [user_clear] ON [user_clear].[emp_num] = [ProblemsTransaction].[GroupLeaderCheck]
	LEFT JOIN [DBx].[dbo].[AbnormalMode] ON [AbnormalMode].[AbnormalID] = [ProblemsTransaction].[ProblemVal3]
	WHERE [ProblemsTransaction].[Status] = 0
	AND [processes].[id] IN (SELECT CAST(VALUE AS INT) FROM STRING_SPLIT(@list_process_id,'|')))
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, [ProblemsTransaction].[TransactionID] AS [andon_control_id]
		, [processes].[name] AS [process]
		, [machines].[name] AS [machine]
		, ISNULL([user_request].[emp_num], '') AS [request_emp_num]
		, [ProblemsTransaction].[LineNo] AS [line_no]
		, [packages].[name] AS [package]
		, [device_names].[name] AS [device]
		, [lots].[lot_no] AS [lot_no]
		, [ProblemsTransaction].[StartTime] AS [start_time]
		, ISNULL([ProblemsTransaction].[EndTime], GETDATE()) AS [end_time]
		, CASE WHEN ([ProblemsTransaction].[Status] = 1)
			THEN 'Cleared'
			ELSE 'Not Cleared' END AS [clear_status]
		, ISNULL([user_clear].[emp_num], '') AS [clear_emp_num]
		, CASE WHEN ([ProblemsTransaction].[ProblemVal1] = 'BM Long Time') THEN 1
			WHEN ([ProblemsTransaction].[ProblemVal1] = 'Accident') THEN 2
			WHEN ([ProblemsTransaction].[ProblemVal1] = 'Electrical Shutdown') THEN 3
			WHEN ([ProblemsTransaction].[ProblemVal1] = 'Other') THEN 4
			ELSE CAST([ProblemsTransaction].[ProblemVal3] AS INT)
			END AS [comment_id]
		, CASE WHEN ([ProblemsTransaction].[ProblemVal3] IS NULL) THEN [ProblemsTransaction].[ProblemVal1]
			ELSE [AbnormalMode].[AbnormalTitle]
			END AS [comment_name]
		, [ProblemsTransaction].[ProblemVal2] AS [abnormal_no]
		, [ProblemsTransaction].[ComName] AS [equipment_no]
		FROM [DBx].[dbo].[ProblemsTransaction]
		INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[lot_no] = [ProblemsTransaction].[LotNo]
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[mc].[machines] ON [machines].[name] = [ProblemsTransaction].[MachineNo]
		LEFT JOIN [APCSProDB].[man].[users] AS [user_request] ON [user_request].[emp_num] = [ProblemsTransaction].[OperatorNo]
		INNER JOIN [APCSProDB].[method].[processes] ON [processes].[name] = [ProblemsTransaction].[ProcessName]
		LEFT JOIN [APCSProDB].[man].[users] AS [user_clear] ON [user_clear].[emp_num] = [ProblemsTransaction].[GroupLeaderCheck]
		LEFT JOIN [DBx].[dbo].[AbnormalMode] ON [AbnormalMode].[AbnormalID] = [ProblemsTransaction].[ProblemVal3]
		WHERE [ProblemsTransaction].[Status] = 0
		AND [processes].[id] IN (SELECT CAST(VALUE AS INT) FROM STRING_SPLIT(@list_process_id,'|'))
		ORDER BY [ProblemsTransaction].[TransactionID] DESC
	END
	ELSE
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, 0 AS [andon_control_id]
		, '' AS [process]
		, '' AS [machine]
		, '' AS [request_emp_num]
		, '' AS [line_no]
		, '' AS [package]
		, '' AS [device]
		, '' AS [lot_no]
		, GETDATE() AS [start_time]
		, GETDATE() AS [end_time]
		, '' AS [clear_status]
		, '' AS [clear_emp_num]
		, 0 AS [comment_id]
		, '' AS [comment_name]
		, '' AS [abnormal_no]
		, '' AS [equipment_no]
	END
END

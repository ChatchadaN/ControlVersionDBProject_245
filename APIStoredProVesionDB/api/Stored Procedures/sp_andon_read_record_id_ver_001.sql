-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_andon_read_record_id_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@andon_control_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT CAST(1 AS BIT) AS [status]
	, [ProblemsTransaction].[TransactionID] AS [andon_control_id]
	, [processes].[name] AS [process]
	, ISNULL([machines].[name],[ProblemsTransaction].[MachineNo]) AS [machine]
	--, [user_request].[emp_num] AS [request_emp_num]
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
		WHEN ([ProblemsTransaction].[ProblemVal1] = 'Re-print label') THEN 1030
		WHEN ([ProblemsTransaction].[ProblemVal1] = 'Other') THEN 4
		ELSE CAST(ISNULL([ProblemsTransaction].[ProblemVal3],0) AS INT)
		END AS [comment_id]
	--, CASE WHEN ([ProblemsTransaction].[ProblemVal3] IS NULL) THEN [ProblemsTransaction].[ProblemVal1]
	--	ELSE [AbnormalMode].[AbnormalTitle]
	--	END AS [comment_name]
	--, CASE WHEN ([ProblemsTransaction].[ProblemVal3] IS NULL) THEN [ProblemsTransaction].[ProblemVal1]
	--	ELSE [abnormal_detail].[name]
	--	END AS [comment_name]
	, CASE 
		WHEN ([ProblemsTransaction].[ProblemVal1] IN ('MAJOR Mode','CRITICAL Mode','MINOR Mode'))
		THEN [abnormal_detail].[name]
		WHEN ([ProblemsTransaction].[ProblemVal1] IN ('Major','Minor','Critical','Unclear')) 
		THEN [AbnormalMode].[AbnormalTitle]
		ELSE [ProblemsTransaction].[ProblemVal1]
	END AS [comment_name]
	, [ProblemsTransaction].[ProblemVal2] AS [abnormal_no]
	, [ProblemsTransaction].[ComName] AS [equipment_no]
	, CASE
		WHEN ([ProblemsTransaction].[ProblemType] = 0)
		THEN CAST(1 AS BIT)
		ELSE CAST(0 AS BIT)
	END AS [is_abnormal]
	, ISNULL([andon_controls].[andon_control_no], ' ') AS [andon_control_no]
	, ISNULL([andon_controls].[comments], ' ') AS [comment]
	FROM [DBx].[dbo].[ProblemsTransaction]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[lot_no] = [ProblemsTransaction].[LotNo]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
	LEFT JOIN [APCSProDB].[mc].[machines] ON [machines].[name] = [ProblemsTransaction].[MachineNo]
	--INNER JOIN [APCSProDB].[man].[users] AS [user_request] ON [user_request].[emp_num] = [ProblemsTransaction].[OperatorNo]
	LEFT JOIN [APCSProDB].[man].[users] AS [user_request] ON [user_request].[emp_num] = [ProblemsTransaction].[OperatorNo]
	INNER JOIN [APCSProDB].[method].[processes] ON [processes].[name] = [ProblemsTransaction].[ProcessName]
	LEFT JOIN [APCSProDB].[man].[users] AS [user_clear] ON [user_clear].[emp_num] = [ProblemsTransaction].[GroupLeaderCheck]
	LEFT JOIN [DBx].[dbo].[AbnormalMode] ON [AbnormalMode].[AbnormalID] = [ProblemsTransaction].[ProblemVal3]
	LEFT JOIN [APCSProDB].[trans].[abnormal_detail] ON [abnormal_detail].[id] = [ProblemsTransaction].[ProblemVal3]
	LEFT JOIN [APCSProDB].[trans].[andon_controls] ON [andon_controls].[id] = [ProblemsTransaction].[TransactionID]
	WHERE [ProblemsTransaction].[TransactionID] = @andon_control_id
END

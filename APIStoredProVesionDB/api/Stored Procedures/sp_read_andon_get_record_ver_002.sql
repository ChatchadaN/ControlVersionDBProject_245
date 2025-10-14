-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_andon_get_record_ver_002]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@process_id int
	,	@status_id int
	,	@start_time varchar(max)
	,	@end_time varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @is_not_found BIT

	IF(@process_id = 0)
	BEGIN
		IF(@status_id = 2)
		BEGIN
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
			WHERE [ProblemsTransaction].[StartTime] >= @start_time
			AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59'))
			BEGIN
				SELECT CAST(1 AS BIT) AS [status]
				, [ProblemsTransaction].[TransactionID] AS [andon_control_id]
				, [processes].[name] AS [process]
				, [machines].[name] AS [machine]
				, ISNULL([user_request].[emp_num],'') AS [request_emp_num]
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
				LEFT JOIN [APCSProDB].[man].[users] AS [user_request] ON [user_request].[emp_num] = [ProblemsTransaction].[OperatorNo]
				INNER JOIN [APCSProDB].[method].[processes] ON [processes].[name] = [ProblemsTransaction].[ProcessName]
				LEFT JOIN [APCSProDB].[man].[users] AS [user_clear] ON [user_clear].[emp_num] = [ProblemsTransaction].[GroupLeaderCheck]
				WHERE [ProblemsTransaction].[StartTime] >= @start_time
				AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
				ORDER BY [ProblemsTransaction].[TransactionID] DESC
			END
			ELSE
			BEGIN
				SELECT @is_not_found = CAST(1 AS BIT)
			END
		END
		ELSE
		BEGIN
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
			WHERE [ProblemsTransaction].[Status] = @status_id
			AND [ProblemsTransaction].[StartTime] >= @start_time
			AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59'))
			BEGIN
				SELECT  CAST(1 AS BIT) AS [status]
				, [ProblemsTransaction].[TransactionID] AS [andon_control_id]
				, [processes].[name] AS [process]
				, [machines].[name] AS [machine]
				, ISNULL([user_request].[emp_num],'') AS [request_emp_num]
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
				LEFT JOIN [APCSProDB].[man].[users] AS [user_request] ON [user_request].[emp_num] = [ProblemsTransaction].[OperatorNo]
				INNER JOIN [APCSProDB].[method].[processes] ON [processes].[name] = [ProblemsTransaction].[ProcessName]
				LEFT JOIN [APCSProDB].[man].[users] AS [user_clear] ON [user_clear].[emp_num] = [ProblemsTransaction].[GroupLeaderCheck]
				WHERE [ProblemsTransaction].[Status] = @status_id
				AND [ProblemsTransaction].[StartTime] >= @start_time
				AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
				ORDER BY [ProblemsTransaction].[TransactionID] DESC
			END
			ELSE
			BEGIN
				SELECT @is_not_found = CAST(1 AS BIT)
			END
		END
	END
	ELSE
	BEGIN
		IF(@status_id = 2)
		BEGIN
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
			WHERE [processes].[id] = @process_id
			AND [ProblemsTransaction].[StartTime] >= @start_time
			AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59'))
			BEGIN
				SELECT CAST(1 AS BIT) AS [status]
				, [ProblemsTransaction].[TransactionID] AS [andon_control_id]
				, [processes].[name] AS [process]
				, [machines].[name] AS [machine]
				, ISNULL([user_request].[emp_num],'') AS [request_emp_num]
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
				LEFT JOIN [APCSProDB].[man].[users] AS [user_request] ON [user_request].[emp_num] = [ProblemsTransaction].[OperatorNo]
				INNER JOIN [APCSProDB].[method].[processes] ON [processes].[name] = [ProblemsTransaction].[ProcessName]
				LEFT JOIN [APCSProDB].[man].[users] AS [user_clear] ON [user_clear].[emp_num] = [ProblemsTransaction].[GroupLeaderCheck]
				WHERE [processes].[id] = @process_id
				AND [ProblemsTransaction].[StartTime] >= @start_time
				AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
				ORDER BY [ProblemsTransaction].[TransactionID] DESC
			END
			ELSE
			BEGIN
				SELECT @is_not_found = CAST(1 AS BIT)
			END
		END
		ELSE
		BEGIN
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
			WHERE [processes].[id] = @process_id
			AND [ProblemsTransaction].[Status] = @status_id
			AND [ProblemsTransaction].[StartTime] >= @start_time
			AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59'))
			BEGIN
				SELECT  CAST(1 AS BIT) AS [status]
				, [ProblemsTransaction].[TransactionID] AS [andon_control_id]
				, [processes].[name] AS [process]
				, [machines].[name] AS [machine]
				, ISNULL([user_request].[emp_num],'') AS [request_emp_num]
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
				LEFT JOIN [APCSProDB].[man].[users] AS [user_request] ON [user_request].[emp_num] = [ProblemsTransaction].[OperatorNo]
				INNER JOIN [APCSProDB].[method].[processes] ON [processes].[name] = [ProblemsTransaction].[ProcessName]
				LEFT JOIN [APCSProDB].[man].[users] AS [user_clear] ON [user_clear].[emp_num] = [ProblemsTransaction].[GroupLeaderCheck]
				WHERE [processes].[id] = @process_id
				AND [ProblemsTransaction].[Status] = @status_id
				AND [ProblemsTransaction].[StartTime] >= @start_time
				AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
				ORDER BY [ProblemsTransaction].[TransactionID] DESC
			END
			ELSE
			BEGIN
				SELECT @is_not_found = CAST(1 AS BIT)
			END
		END
	END

	IF(@is_not_found = 1)
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
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
	END
END

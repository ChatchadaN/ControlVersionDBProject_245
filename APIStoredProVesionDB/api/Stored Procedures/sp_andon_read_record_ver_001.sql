-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_andon_read_record_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@process_id int
	,	@status_id int
	,	@lot_no varchar(max)
	,	@package varchar(max)
	,	@device varchar(max)
	,	@machine_name varchar(max)
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
			LEFT JOIN [APCSProDB].[trans].[andon_controls] ON [andon_controls].[id] = [ProblemsTransaction].[TransactionID]
			LEFT JOIN [APCSProDB].[trans].[abnormal_detail] ON [abnormal_detail].[id] = [andon_controls].[comment_id_at_finding]
			LEFT JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
			WHERE [ProblemsTransaction].[StartTime] >= @start_time
			AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
			AND [lots].[lot_no] LIKE CONCAT('%', @lot_no, '%')
			AND [packages].[name] LIKE CONCAT('%', @package, '%')
			AND [device_names].[name] LIKE CONCAT('%', @device, '%')
			AND [machines].[name] LIKE CONCAT('%', @machine_name, '%')
			)
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
				, [ProblemsTransaction].[ComName] AS [equipment]
				, ISNULL([andon_controls].[andon_control_no], ' ') AS [andon_control_no]
				, ISNULL([abnormal_detail].[name], ' ') AS [andon_case]
				, ISNULL([abnormal_mode].[name], ' ') AS [abnormal_mode]
				, ISNULL([ProblemsTransaction].[ProblemVal2], ' ') AS [aqi_no]
				, ISNULL([user_clear].[emp_num],'') AS [clear_emp_num]
				, ISNULL([andon_controls].[comments], ' ') AS [comment]
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
				LEFT JOIN [APCSProDB].[trans].[andon_controls] ON [andon_controls].[id] = [ProblemsTransaction].[TransactionID]
				LEFT JOIN [APCSProDB].[trans].[abnormal_detail] ON [abnormal_detail].[id] = [andon_controls].[comment_id_at_finding]
				LEFT JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
				WHERE [ProblemsTransaction].[StartTime] >= @start_time
				AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
				AND [lots].[lot_no] LIKE CONCAT('%', @lot_no, '%')
				AND [packages].[name] LIKE CONCAT('%', @package, '%')
				AND [device_names].[name] LIKE CONCAT('%', @device, '%')
				AND [machines].[name] LIKE CONCAT('%', @machine_name, '%')
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
			LEFT JOIN [APCSProDB].[trans].[andon_controls] ON [andon_controls].[id] = [ProblemsTransaction].[TransactionID]
			LEFT JOIN [APCSProDB].[trans].[abnormal_detail] ON [abnormal_detail].[id] = [andon_controls].[comment_id_at_finding]
			LEFT JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
			WHERE [ProblemsTransaction].[Status] = @status_id
			AND [ProblemsTransaction].[StartTime] >= @start_time
			AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
			AND [lots].[lot_no] LIKE CONCAT('%', @lot_no, '%')
			AND [packages].[name] LIKE CONCAT('%', @package, '%')
			AND [device_names].[name] LIKE CONCAT('%', @device, '%')
			AND [machines].[name] LIKE CONCAT('%', @machine_name, '%')
			)
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
				, [ProblemsTransaction].[ComName] AS [equipment]
				, ISNULL([andon_controls].[andon_control_no], ' ') AS [andon_control_no]
				, ISNULL([abnormal_detail].[name], ' ') AS [andon_case]
				, ISNULL([abnormal_mode].[name], ' ') AS [abnormal_mode]
				, ISNULL([ProblemsTransaction].[ProblemVal2], ' ') AS [aqi_no]
				, ISNULL([user_clear].[emp_num],'') AS [clear_emp_num]
				, ISNULL([andon_controls].[comments], ' ') AS [comment]
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
				LEFT JOIN [APCSProDB].[trans].[andon_controls] ON [andon_controls].[id] = [ProblemsTransaction].[TransactionID]
				LEFT JOIN [APCSProDB].[trans].[abnormal_detail] ON [abnormal_detail].[id] = [andon_controls].[comment_id_at_finding]
				LEFT JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
				WHERE [ProblemsTransaction].[Status] = @status_id
				AND [ProblemsTransaction].[StartTime] >= @start_time
				AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
				AND [lots].[lot_no] LIKE CONCAT('%', @lot_no, '%')
				AND [packages].[name] LIKE CONCAT('%', @package, '%')
				AND [device_names].[name] LIKE CONCAT('%', @device, '%')
				AND [machines].[name] LIKE CONCAT('%', @machine_name, '%')
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
			LEFT JOIN [APCSProDB].[trans].[andon_controls] ON [andon_controls].[id] = [ProblemsTransaction].[TransactionID]
			LEFT JOIN [APCSProDB].[trans].[abnormal_detail] ON [abnormal_detail].[id] = [andon_controls].[comment_id_at_finding]
			LEFT JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
			WHERE [processes].[id] = @process_id
			AND [ProblemsTransaction].[StartTime] >= @start_time
			AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
			AND [lots].[lot_no] LIKE CONCAT('%', @lot_no, '%')
			AND [packages].[name] LIKE CONCAT('%', @package, '%')
			AND [device_names].[name] LIKE CONCAT('%', @device, '%')
			AND [machines].[name] LIKE CONCAT('%', @machine_name, '%')
			)
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
				, [ProblemsTransaction].[ComName] AS [equipment]
				, ISNULL([andon_controls].[andon_control_no], ' ') AS [andon_control_no]
				, ISNULL([abnormal_detail].[name], ' ') AS [andon_case]
				, ISNULL([abnormal_mode].[name], ' ') AS [abnormal_mode]
				, ISNULL([ProblemsTransaction].[ProblemVal2], ' ') AS [aqi_no]
				, ISNULL([user_clear].[emp_num],'') AS [clear_emp_num]
				, ISNULL([andon_controls].[comments], ' ') AS [comment]
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
				LEFT JOIN [APCSProDB].[trans].[andon_controls] ON [andon_controls].[id] = [ProblemsTransaction].[TransactionID]
				LEFT JOIN [APCSProDB].[trans].[abnormal_detail] ON [abnormal_detail].[id] = [andon_controls].[comment_id_at_finding]
				LEFT JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
				WHERE [processes].[id] = @process_id
				AND [ProblemsTransaction].[StartTime] >= @start_time
				AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
				AND [lots].[lot_no] LIKE CONCAT('%', @lot_no, '%')
				AND [packages].[name] LIKE CONCAT('%', @package, '%')
				AND [device_names].[name] LIKE CONCAT('%', @device, '%')
				AND [machines].[name] LIKE CONCAT('%', @machine_name, '%')
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
			LEFT JOIN [APCSProDB].[trans].[andon_controls] ON [andon_controls].[id] = [ProblemsTransaction].[TransactionID]
			LEFT JOIN [APCSProDB].[trans].[abnormal_detail] ON [abnormal_detail].[id] = [andon_controls].[comment_id_at_finding]
			LEFT JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
			WHERE [processes].[id] = @process_id
			AND [ProblemsTransaction].[Status] = @status_id
			AND [ProblemsTransaction].[StartTime] >= @start_time
			AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
			AND [lots].[lot_no] LIKE CONCAT('%', @lot_no, '%')
			AND [packages].[name] LIKE CONCAT('%', @package, '%')
			AND [device_names].[name] LIKE CONCAT('%', @device, '%')
			AND [machines].[name] LIKE CONCAT('%', @machine_name, '%')
			)
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
				, [ProblemsTransaction].[ComName] AS [equipment]
				, ISNULL([andon_controls].[andon_control_no], ' ') AS [andon_control_no]
				, ISNULL([abnormal_detail].[name], ' ') AS [andon_case]
				, ISNULL([abnormal_mode].[name], ' ') AS [abnormal_mode]
				, ISNULL([ProblemsTransaction].[ProblemVal2], ' ') AS [aqi_no]
				, ISNULL([user_clear].[emp_num],'') AS [clear_emp_num]
				, ISNULL([andon_controls].[comments], ' ') AS [comment]
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
				LEFT JOIN [APCSProDB].[trans].[andon_controls] ON [andon_controls].[id] = [ProblemsTransaction].[TransactionID]
				LEFT JOIN [APCSProDB].[trans].[abnormal_detail] ON [abnormal_detail].[id] = [andon_controls].[comment_id_at_finding]
				LEFT JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
				WHERE [processes].[id] = @process_id
				AND [ProblemsTransaction].[Status] = @status_id
				AND [ProblemsTransaction].[StartTime] >= @start_time
				AND [ProblemsTransaction].[StartTime] < CONCAT(@end_time, ' 23:59:59')
				AND [lots].[lot_no] LIKE CONCAT('%', @lot_no, '%')
				AND [packages].[name] LIKE CONCAT('%', @package, '%')
				AND [device_names].[name] LIKE CONCAT('%', @device, '%')
				AND [machines].[name] LIKE CONCAT('%', @machine_name, '%')
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
		, '' AS [equipment]
		, '' AS [andon_control_no]
		, '' AS [andon_case]
		, '' AS [abnormal_mode]
		, '' AS [aqi_no]
		, '' AS [clear_emp_num]
		, '' AS [comment]
	END
END

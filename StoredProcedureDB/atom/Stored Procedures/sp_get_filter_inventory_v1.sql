create PROCEDURE [atom].[sp_get_filter_inventory_v1]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(20)
	, @filter_no INT  =  NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

	----#001
	--SELECT [class_inventory].[class_no]
	--	, [class_inventory].[process_name]
	--FROM (
	--	SELECT [processes].[name] AS [process]
	--	FROM (
	--		SELECT 
	--			CASE WHEN [lots].[is_special_flow] = 1 THEN [lot_special_flows].[job_id] ELSE [lots].[act_job_id] END AS [job_id]
	--		FROM [APCSProDB].[trans].[lots] 
	--		LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lots].[id] = [special_flows].[lot_id]
	--			AND [lots].[special_flow_id] = [special_flows].[id]
	--			AND [lots].[is_special_flow] = 1
	--		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
	--			AND [special_flows].[step_no] = [lot_special_flows].[step_no]
	--		WHERE [lot_no] = @lot_no
	--	) AS [job_now]
	--	INNER JOIN [APCSProDB].[method].[jobs] ON [job_now].[job_id] = [jobs].[id]
	--	INNER JOIN [APCSProDB].[method].[processes] ON [jobs].[process_id] = [processes].[id]
	--) AS [table]
	--CROSS APPLY (
	--	SELECT [class_no]
	--		, [process_name]
	--	FROM [APCSProDWH].[atom].[sheet_rack_inventory]
	--	WHERE [process_name] LIKE '%' + [table].[process] + '%'
	--	GROUP BY [class_no]
	--		, [process_name]
	--) AS [class_inventory];

	----#002
	
	IF (@filter_no = 1)
	BEGIN 
	IF EXISTS (
		SELECT [special_flows].[process_state]
		FROM [APCSProDB].[trans].[lots] 
		LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lots].[id] = [special_flows].[lot_id]
			AND [lots].[special_flow_id] = [special_flows].[id]
			AND [lots].[is_special_flow] = 1
		WHERE [lot_no] = @lot_no
			AND (CASE WHEN [lots].[is_special_flow] = 1 THEN [special_flows].[process_state] ELSE [lots].[process_state] END) IN (2,102)
	)
	BEGIN
		SELECT [class_inventory].[class_no]
			, [class_inventory].[process_name]
		FROM (
			SELECT [processes].[name] AS [process]
			FROM (
				SELECT 
					CASE WHEN [lots].[is_special_flow] = 1 THEN [lot_special_flows].[job_id] ELSE [lots].[act_job_id] END AS [job_id]
				FROM [APCSProDB].[trans].[lots] 
				LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lots].[id] = [special_flows].[lot_id]
					AND [lots].[special_flow_id] = [special_flows].[id]
					AND [lots].[is_special_flow] = 1
				LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
					AND [special_flows].[step_no] = [lot_special_flows].[step_no]
				WHERE [lot_no] = @lot_no
			) AS [job_now]
			INNER JOIN [APCSProDB].[method].[jobs] ON [job_now].[job_id] = [jobs].[id]
			INNER JOIN [APCSProDB].[method].[processes] ON [jobs].[process_id] = [processes].[id]
		) AS [table]
		CROSS APPLY (
			SELECT [class_no]
				, [process_name]
			FROM [APCSProDWH].[atom].[sheet_rack_inventory]
			WHERE [process_name] LIKE '%' + [table].[process] + '%'
			GROUP BY [class_no]
				, [process_name]
		) AS [class_inventory];
	END
	ELSE
	BEGIN
		IF EXISTS (
			SELECT [class_inventory].[class_no]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[trans].[locations] ON [lots].[location_id] = [locations].[id]
			CROSS APPLY (
				SELECT [class_no]
					, [process_name]
				FROM [APCSProDWH].[atom].[sheet_rack_inventory]
				WHERE [location] = [locations].[name]
				GROUP BY [class_no]
					, [process_name]
			) AS [class_inventory]
			WHERE [lots].[lot_no] = @lot_no
		)
		BEGIN
			SELECT [class_inventory].[class_no]
				, [class_inventory].[process_name]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[trans].[locations] ON [lots].[location_id] = [locations].[id]
			CROSS APPLY (
				SELECT [class_no]
					, [process_name]
				FROM [APCSProDWH].[atom].[sheet_rack_inventory]
				WHERE [location] = [locations].[name]
				GROUP BY [class_no]
					, [process_name]
			) AS [class_inventory]
			WHERE [lots].[lot_no] = @lot_no;
		END
		ELSE
		BEGIN
			SELECT '' AS [class_no]
				, 'Empty' AS [process_name]
		END
	END
	END
	IF (@filter_no = 2)
	BEGIN
		
		SELECT    [class_no]
				,'' AS [process_name]
		FROM [APCSProDWH].[atom].[sheet_rack_inventory]
		GROUP BY class_no
		ORDER BY  class_no


	END 
END

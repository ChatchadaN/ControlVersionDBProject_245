-- =============================================
-- Author:		NUCHA
-- Create date: 2022/06/29
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_reset_rack_001] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	--DECLARE @lot_id INT
	--	, @process_id INT
	--	, @mlocation_id INT
	--	, @hslocation_id INT

	--SELECT @lot_id = [lots].[id]
	--	, @process_id = ( CASE WHEN [job_special].[process_id] IS NOT NULL THEN [job_special].[process_id] ELSE [job_master].[process_id] END )
	--	, @mlocation_id = [lots].[location_id]
	--	, @hslocation_id = [surpluses].[location_id]
	--FROM [APCSProDB].[trans].[lots]
	--LEFT JOIN [APCSProDB].[trans].[special_flows]
	--	ON [lots].[id] = [special_flows].[lot_id]
	--	AND [lots].[special_flow_id] = [special_flows].[id]
	--	AND [lots].[is_special_flow] = 1
	--LEFT JOIN [APCSProDB].[trans].[lot_special_flows]
	--	ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
	--	AND [special_flows].[step_no] = [lot_special_flows].[step_no]
	--LEFT JOIN [APCSProDB].[method].[jobs] AS [job_master]
	--	ON [lots].[act_job_id] = [job_master].[id]
	--LEFT JOIN [APCSProDB].[method].[jobs] AS [job_special]
	--	ON [lot_special_flows].[job_id] = [job_special].[id]
	--LEFT JOIN [APCSProDB].[trans].[surpluses]
	--	ON [lots].[id] = [surpluses].[lot_id]
	--	AND [surpluses].[in_stock] = 2
	--WHERE [lots].[lot_no] = @lot_no;

	--IF (@process_id IN (22,30,36))
	--BEGIN
	--	SELECT 'TRUE' as Is_Pass
	--		, '' AS Error_Message_ENG
	--		, N'' AS Error_Message_THA
	--		, N'' AS Handling
	--		, @mlocation_id AS [location_master]
	--		, @hslocation_id AS [location_hasuu]
	--	RETURN;
	--END
	--ELSE
	--BEGIN
	--	SELECT 'FALSE' as Is_Pass
	--		, 'not control process !!' AS Error_Message_ENG
	--		, N'ไม่ใช่ process ที่ควบคุม !!' AS Error_Message_THA
	--		, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
	--		, NULL AS [location_master]
	--		, NULL AS [location_hasuu]
	--	RETURN;
	--END	

	DECLARE @lot_id INT
		, @process_id INT
		, @mlocation_id INT
		, @hslocation_id INT

	--IF (@lot_no = '2329A5206V')
	--BEGIN
	--	select 'TRUE' as Is_Pass
	--		, '' AS Error_Message_ENG
	--		, N'' AS Error_Message_THA
	--		, N'' AS Handling
	--		, NULL AS [location_master]
	--		, surpluses.location_id AS [location_hasuu]
	--	from APCSProDB.trans.surpluses 
	--	left join APCSProDB.trans.locations
	--		on surpluses.location_id = locations.id
	--	where surpluses.in_stock = 0 
	--		and surpluses.serial_no = '2329A5206V'
	--	order by surpluses.serial_no asc 
	--	RETURN
	--END



	SELECT @lot_id = [lot_id]
		--, [lot_no]
		, @process_id = [process_id]
		, @mlocation_id = [location_master]
		, @hslocation_id = [location_hasuu]
	FROM (
		SELECT [lots].[id] AS [lot_id]
			, [lots].[lot_no]
			, ( CASE 
				WHEN [job_special].[process_id] IS NOT NULL THEN [job_special].[process_id] 
				ELSE [job_master].[process_id] 
			END ) AS [process_id]
			, [lots].[location_id] AS [location_master]
			, [surpluses].[location_id] AS [location_hasuu] 
		FROM [APCSProDB].[trans].[lots]
		LEFT JOIN [APCSProDB].[trans].[special_flows]
			ON [lots].[id] = [special_flows].[lot_id]
			AND [lots].[special_flow_id] = [special_flows].[id]
			AND [lots].[is_special_flow] = 1
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows]
			ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
			AND [special_flows].[step_no] = [lot_special_flows].[step_no]
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_master]
			ON [lots].[act_job_id] = [job_master].[id]
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job_special]
			ON [lot_special_flows].[job_id] = [job_special].[id]
		LEFT JOIN [APCSProDB].[trans].[surpluses]
			ON [lots].[id] = [surpluses].[lot_id]
			AND [surpluses].[in_stock] = 2
		WHERE ([lots].[location_id] IS NOT NULL 
			OR [surpluses].[location_id] IS NOT NULL)
	) AS [TableData]
	WHERE [process_id] IN (22,30,36)
		AND [lot_no] = @lot_no;

	IF (@lot_id IS NOT NULL)
	BEGIN
		SELECT 'TRUE' as Is_Pass
			, '' AS Error_Message_ENG
			, N'' AS Error_Message_THA
			, N'' AS Handling
			, @mlocation_id AS [location_master]
			, @hslocation_id AS [location_hasuu]
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'FALSE' as Is_Pass
			, 'not control process !!' AS Error_Message_ENG
			, N'ไม่ใช่ process ที่ควบคุม !!' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
			, NULL AS [location_master]
			, NULL AS [location_hasuu]
		RETURN;
	END
END

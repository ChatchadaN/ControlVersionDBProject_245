-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_summary_data_testertype]
	-- Add the parameters for the stored procedure here
	@Testertype VARCHAR(20), 
	@LotNo VARCHAR(20),
	@Flow VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@LotNo = '')
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'LotNo is empty !!' AS [Error_Message_ENG]
			, N'LotNo เป็นค่าว่าง !!' AS [Error_Message_THA] 
			, '' AS [Handling]
			, NULL AS [SUMMARY_ID]
			, NULL AS [LOT_NO]
			, NULL AS [FLOW_NAME]
			, NULL AS [PASS]
			, NULL AS [FAIL]
		RETURN;
	END

	IF (@Testertype = '')
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'TesterType is empty !!' AS [Error_Message_ENG]
			, N'TesterType เป็นค่าว่าง !!' AS [Error_Message_THA] 
			, '' AS [Handling]
			, NULL AS [SUMMARY_ID]
			, NULL AS [LOT_NO]
			, NULL AS [FLOW_NAME]
			, NULL AS [PASS]
			, NULL AS [FAIL]
		RETURN;
	END

	IF (@Testertype IN ('RSX5000LLE','RSX5000HE','RSX5000HV','RSX5000HI'))
	BEGIN
		IF EXISTS (
			SELECT TOP 1 [LOT_NO]
			FROM OPENROWSET(
				'SQLNCLI11', 
				'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
				'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[RSX5K_FT_SUMM]'
			)
			WHERE LOT_NO = @LotNo
		) 
		BEGIN
			SELECT TOP 1 'TRUE' AS [Is_Pass] 
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA] 
				, '' AS [Handling]
				, [SUMMARY_ID]
				, [LOT_NO]
				, [FLOW_NAME]
				, [PASS]
				, [FAIL]
			FROM OPENROWSET(
				'SQLNCLI11', 
				'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
				'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[RSX5K_FT_SUMM]'
			)
			WHERE LOT_NO = @LotNo
			ORDER BY [SUMMARY_ID] DESC
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'not found tester type of lot !!' AS [Error_Message_ENG]
				, N'ไม่พบ tester type ของ Lot นี้!!' AS [Error_Message_THA] 
				, '' AS [Handling]
				, NULL AS [SUMMARY_ID]
				, NULL AS [LOT_NO]
				, NULL AS [FLOW_NAME]
				, NULL AS [PASS]
				, NULL AS [FAIL]
		END

	END
	ELSE IF (@Testertype IN ('DXSS'))
	BEGIN
		IF EXISTS (
			SELECT TOP 1 [LOT_NO]
			FROM OPENROWSET(
				'SQLNCLI11', 
				'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
				'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[DX_FT_SUMM]'
			)
			WHERE LOT_NO = @LotNo
		) 
		BEGIN
			SELECT TOP 1 'BYPASS' AS [Is_Pass] 
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA] 
				, '' AS [Handling]
				, [SUMMARY_ID]
				, [LOT_NO]
				, [FLOW_NAME]
				, [PASS]
				, [FAIL]
			FROM OPENROWSET(
				'SQLNCLI11', 
				'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
				'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[DX_FT_SUMM]'
			)
			WHERE LOT_NO = @LotNo
			ORDER BY [SUMMARY_ID] DESC
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'not found tester type of lot !!' AS [Error_Message_ENG]
				, N'ไม่พบ tester type ของ Lot นี้!!' AS [Error_Message_THA] 
				, '' AS [Handling]
				, NULL AS [SUMMARY_ID]
				, NULL AS [LOT_NO]
				, NULL AS [FLOW_NAME]
				, NULL AS [PASS]
				, NULL AS [FAIL]
		END
	END
	ELSE IF (@Testertype IN ('ICT2000/HV','ICT2000'))
	BEGIN
		IF EXISTS (
			SELECT TOP 1 [LOT_NO]
			FROM OPENROWSET(
				'SQLNCLI11', 
				'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
				'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[ICT20_FT_SUMM]'
			)
			WHERE LOT_NO = @LotNo
		) 
		BEGIN
			SELECT TOP 1 'BYPASS' AS [Is_Pass] 
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA] 
				, '' AS [Handling]
				, [SUMMARY_ID]
				, [LOT_NO]
				, [FLOW_NAME]
				, [PASS]
				, [FAIL]
			FROM OPENROWSET(
				'SQLNCLI11', 
				'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
				'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[ICT20_FT_SUMM]'
			)
			WHERE LOT_NO = @LotNo
			ORDER BY [SUMMARY_ID] DESC
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'not found tester type of lot !!' AS [Error_Message_ENG]
				, N'ไม่พบ tester type ของ Lot นี้!!' AS [Error_Message_THA] 
				, '' AS [Handling]
				, NULL AS [SUMMARY_ID]
				, NULL AS [LOT_NO]
				, NULL AS [FLOW_NAME]
				, NULL AS [PASS]
				, NULL AS [FAIL]
		END
	END
	ELSE IF (@Testertype IN ('ICT8000'))
	BEGIN
		IF EXISTS (
			SELECT TOP 1 [LOT_NO]
			FROM OPENROWSET(
				'SQLNCLI11', 
				'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
				'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[ICT80_FT_SUMM]'
			)
			WHERE LOT_NO = @LotNo
		) 
		BEGIN
			SELECT TOP 1 'BYPASS' AS [Is_Pass] 
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA] 
				, '' AS [Handling]
				, [SUMMARY_ID]
				, [LOT_NO]
				, [FLOW_NAME]
				, [PASS]
				, [FAIL]
			FROM OPENROWSET(
				'SQLNCLI11', 
				'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
				'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[ICT80_FT_SUMM]'
			)
			WHERE LOT_NO = @LotNo
			ORDER BY [SUMMARY_ID] DESC
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'not found tester type of lot !!' AS [Error_Message_ENG]
				, N'ไม่พบ tester type ของ Lot นี้!!' AS [Error_Message_THA] 
				, '' AS [Handling]
				, NULL AS [SUMMARY_ID]
				, NULL AS [LOT_NO]
				, NULL AS [FLOW_NAME]
				, NULL AS [PASS]
				, NULL AS [FAIL]
		END
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'not found tester type !!' AS [Error_Message_ENG]
			, N'ไม่พบ tester type !!' AS [Error_Message_THA] 
			, '' AS [Handling]
			, NULL AS [SUMMARY_ID]
			, NULL AS [LOT_NO]
			, NULL AS [FLOW_NAME]
			, NULL AS [PASS]
			, NULL AS [FAIL]
	END

	--# comment
	--IF (@Testertype IN ('RSX5000LLE','RSX5000HE','RSX5000HV','RSX5000HI'))
	--BEGIN
	--	SELECT TOP 1 'TRUE' AS [Is_Pass] 
	--		, '' AS [Error_Message_ENG]
	--		, N'' AS [Error_Message_THA] 
	--		, '' AS [Handling]
	--		, [SUMMARY_ID]
	--		, [LOT_NO]
	--		, [FLOW_NAME]
	--		, [PASS]
	--		, [FAIL]
	--	FROM OPENROWSET(
	--		'SQLNCLI11', 
	--		'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
	--		'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[RSX5K_FT_SUMM]'
	--	)
	--	WHERE LOT_NO = @LotNo
	--	ORDER BY [SUMMARY_ID] DESC
	--END
	--ELSE IF (@Testertype IN ('DXSS'))
	--BEGIN
	--	SELECT TOP 1 'TRUE' AS [Is_Pass] 
	--		, '' AS [Error_Message_ENG]
	--		, N'' AS [Error_Message_THA] 
	--		, '' AS [Handling]
	--		, [SUMMARY_ID]
	--		, [LOT_NO]
	--		, [FLOW_NAME]
	--		, [PASS]
	--		, [FAIL]
	--	FROM OPENROWSET(
	--		'SQLNCLI11', 
	--		'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
	--		'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[DX_FT_SUMM]'
	--	)
	--	WHERE LOT_NO = @LotNo
	--	ORDER BY [SUMMARY_ID] DESC
	--END
	--ELSE IF (@Testertype IN ('ICT2000/HV','ICT2000'))
	--BEGIN
	--	SELECT TOP 1 'TRUE' AS [Is_Pass] 
	--		, '' AS [Error_Message_ENG]
	--		, N'' AS [Error_Message_THA] 
	--		, '' AS [Handling]
	--		, [SUMMARY_ID]
	--		, [LOT_NO]
	--		, [FLOW_NAME]
	--		, [PASS]
	--		, [FAIL]
	--	FROM OPENROWSET(
	--		'SQLNCLI11', 
	--		'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
	--		'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[ICT20_FT_SUMM]'
	--	)
	--	WHERE LOT_NO = @LotNo
	--	ORDER BY [SUMMARY_ID] DESC
	--END
	--ELSE IF (@Testertype IN ('ICT8000'))
	--BEGIN
	--	SELECT TOP 1 'TRUE' AS [Is_Pass] 
	--		, '' AS [Error_Message_ENG]
	--		, N'' AS [Error_Message_THA] 
	--		, '' AS [Handling]
	--		, [SUMMARY_ID]
	--		, [LOT_NO]
	--		, [FLOW_NAME]
	--		, [PASS]
	--		, [FAIL]
	--	FROM OPENROWSET(
	--		'SQLNCLI11', 
	--		'Server=172.16.0.1;Database=SummaryData;Uid=sa;Pwd=edsx01*', 
	--		'SELECT [SUMMARY_ID], [LOT_NO], [FLOW_NAME], [PASS], [FAIL] FROM [SummaryData].[dbo].[ICT80_FT_SUMM]'
	--	)
	--	WHERE LOT_NO = @LotNo
	--	ORDER BY [SUMMARY_ID] DESC
	--END
	--ELSE
	--BEGIN
	--	SELECT 'FALSE' AS [Is_Pass] 
	--		, 'not found tester type !!' AS [Error_Message_ENG]
	--		, N'ไม่พบ tester type !!' AS [Error_Message_THA] 
	--		, '' AS [Handling]
	--		, NULL AS [SUMMARY_ID]
	--		, NULL AS [LOT_NO]
	--		, NULL AS [FLOW_NAME]
	--		, NULL AS [PASS]
	--		, NULL AS [FAIL]
	--END
END

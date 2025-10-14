-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_mix_hist_003]
	-- Add the parameters for the stored procedure here
	--@FromDate DATETIME,
	--@ToDate DATETIME
	@FromDate DATETIME,
	@ToDate DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT '' AS [M_O_No]
		, '' AS [FREQ]
		, [lot_mas].[lot_no] AS [HASUU_LotNo]
		, [lot_mem].[lot_no] AS [LotNo]
		, '' AS [P_O_No] 
		, [sur_lot_master].[stock_class] AS [Stock_Class]
		, [packages].[short_name] AS [Type_Name]
		, [device_names].[name] AS [ROHM_Model_Name]
		, [surpluses].[pdcd] AS [PDCD]
		, [device_names].[assy_name] AS [ASSY_Model_Name]
		, ISNULL([Fukuoka].[R_Fukuoka_Model_Name], '') AS [R_Fukuoka_Model_Name]
		, ISNULL([device_names].[rank], '') AS [TIRank]
		, ISNULL([device_names].[rank], '') AS [Rank]
		, ISNULL([device_names].[tp_rank], '')  AS [TPRank]
		, '' AS [SUBRank]
		, '' AS [Mask]
		, '' AS [KNo]	
		, [surpluses].[mark_no] AS [MNo]
		, '' AS [Tomson1]
		, '' AS [Tomson2]
		, ISNULL([surpluses].[qc_instruction], '') AS [Tomson3]
		, FORMAT(ISNULL([allocat].[allocation_Date], [lot_combine].[created_at]), 'yyyy-MM-dd HH:mm:ss') AS [allocation_Date]
		, ( CASE 
			WHEN SUBSTRING([lot_mem].[lot_no], 5, 1) = 'D' THEN 'NO'
			ELSE ISNULL([allocat].[ORNo], '')
		END ) AS [ORNo]
		, ISNULL([allocat].[WFLotNo], '') AS [WFLotNo]
		, '' AS [User_Code]
		, '' AS [LotNo_Class]
		, ISNULL([surpluses].[label_class], '') AS [Label_Class]
		, '' AS [Multi_Class]
		, ISNULL([surpluses].[product_control_class], '') AS [Product_Control_Clas]
		, [device_names].[pcs_per_pack] AS [Packing_Standerd_QTY]
		, '' AS [Date_Code]
		, '' AS [HASUU_Out_Flag]
		, ( CASE 
				-- D Lot (LotMaster)
				WHEN [lot_combine].[lot_id] = [lot_combine].[member_lot_id] AND SUBSTRING([lot_mas].[lot_no], 5, 1) = 'D' 
					THEN IIF([lot_mas].[pc_instruction_code] IN (1,11,13), [lot_mas].[qty_out], [lot_mem].[qty_in]) 
				-- D Lot (LotMember)
				WHEN [lot_combine].[lot_id] != [lot_combine].[member_lot_id] AND SUBSTRING([lot_mas].[lot_no], 5, 1) = 'D' 
					THEN IIF([lot_mas].[production_category] = 70, [lot_mas].[qty_in], [surpluses].[pcs]) 
				-- A, F, G, B Lot (LotMaster)
				WHEN [lot_combine].[lot_id] = [lot_combine].[member_lot_id] AND SUBSTRING([lot_mas].[lot_no], 5, 1) IN ('A', 'F', 'G', 'B')
					THEN (([dn_mas].[pcs_per_pack]) * (([lot_record].[qty_pass] + [lot_mas].[qty_combined])
						/ ([dn_mas].[pcs_per_pack])) - [lot_mas].[qty_combined])
				-- A, F, G, B Lot (LotMember)
				WHEN [lot_combine].[lot_id] != [lot_combine].[member_lot_id] AND SUBSTRING([lot_mas].[lot_no], 5, 1) IN ('A', 'F', 'G', 'B') 
					THEN [lot_mas].[qty_combined] 
				-- Close
				---ELSE [surpluses].[pcs] 
		END ) AS [QTY]
		, '' AS [Transfer_Flag]
		--, IIF([lot_mem].[pc_instruction_code] = 13, [surpluses].[pcs], 0) AS [Transfer]
		, 0 AS [Transfer]
		, [lot_combine].[created_by] AS [OPNo]
		, '' AS [Theoretical]
		, 'B' AS [OUT_OUT_FLAG]
		, FORMAT([lot_combine].[created_at], 'yyyy-MM-dd HH:mm:ss') AS [MIXD_DATE]
		, FORMAT([lot_combine].[created_at], 'yyyy-MM-dd HH:mm:ss') AS [TimeStamp_date]
		, DATEDIFF(s, CAST([lot_combine].[created_at] AS DATE) , [lot_combine].[created_at]) AS [TimeStamp_time]
		, ISNULL([lot_mas].[pc_instruction_code], 0) AS [pc_instruction_code]
		, SUBSTRING([lot_mas].[lot_no], 5, 1) AS [lot_type]
		, ISNULL([lot_mas].[production_category], 0) AS [production_category]
	INTO #TestTableBass
	FROM (
		SELECT [lot_id]
			, [lot_id] AS [member_lot_id]
			, -1 AS [idx]
			, [created_at]
			, [created_by]
		FROM [APCSProDB].[trans].[lot_combine] WITH (NOLOCK)
		WHERE ([lot_combine].[created_at] BETWEEN @FromDate AND @ToDate)
		GROUP BY [lot_id]
			, [created_at]
			, [created_by]
		UNION
		SELECT [lot_id]
			, [member_lot_id]
			, [idx]
			, [created_at]
			, [created_by]
		FROM [APCSProDB].[trans].[lot_combine] WITH (NOLOCK)
		WHERE ([lot_combine].[created_at] BETWEEN @FromDate AND @ToDate)
			AND [lot_id] != [member_lot_id]
	) AS [lot_combine]
	INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mas] WITH (NOLOCK) ON [lot_combine].[lot_id] = [lot_mas].[id]
	INNER JOIN [APCSProDB].[method].[device_names] AS [dn_mas] WITH (NOLOCK) ON [lot_mas].[act_device_name_id] = [dn_mas].[id]
	INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mem] WITH (NOLOCK) ON [lot_combine].[member_lot_id] = [lot_mem].[id]
	LEFT JOIN [APCSProDB].[method].[allocat_temp] AS [allocat] WITH (NOLOCK) ON [lot_mem].[lot_no] = [allocat].[LotNo]
	INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [lot_mem].[act_device_name_id] = [device_names].[id]
	INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [device_names].[package_id] = [packages].[id]
	INNER JOIN [APCSProDB].[trans].[surpluses] WITH (NOLOCK) ON [surpluses].[lot_id] = [lot_combine].[member_lot_id]
	INNER JOIN [APCSProDB].[trans].[surpluses] AS [sur_lot_master] WITH (NOLOCK) ON [sur_lot_master].[lot_id] = [lot_combine].[lot_id]
	OUTER APPLY (
		SELECT TOP 1 [lot_record].[qty_pass]
		FROM [APCSProDB].[trans].[lot_process_records] AS [lot_record] WITH (NOLOCK) 
		WHERE [lot_record].[record_class] = 46
			AND [lot_record].[lot_id] = [lot_combine].[lot_id] 
		ORDER BY [lot_record].[id] DESC
	) AS [lot_record]
	OUTER APPLY (
		SELECT TOP 1 [R_Fukuoka_Model_Name]
		FROM [APCSProDB].[method].[allocat_temp] WITH (NOLOCK)
		WHERE [allocat_temp].[ROHM_Model_Name] = [device_names].[name]
			AND [allocat_temp].[ASSY_Model_Name] = [device_names].[assy_name]
	) AS [Fukuoka];

	SELECT [A].[M_O_No]
		, [A].[FREQ]
		, [A].[HASUU_LotNo]
		, [A].[LotNo]
		, [A].[P_O_No] 
		, [A].[Stock_Class]
		, [A].[Type_Name]
		, [A].[ROHM_Model_Name]
		, [A].[PDCD]
		, [A].[ASSY_Model_Name]
		, [A].[R_Fukuoka_Model_Name]
		, [A].[TIRank]
		, [A].[Rank]
		, [A].[TPRank]
		, [A].[SUBRank]
		, [A].[Mask]
		, [A].[KNo]	
		, [A].[MNo]
		, [A].[Tomson1]
		, [A].[Tomson2]
		, [A].[Tomson3]
		, [A].[allocation_Date]
		, [A].[ORNo]
		, [A].[WFLotNo]
		, [A].[User_Code]
		, [A].[LotNo_Class]
		, [A].[Label_Class]
		, [A].[Multi_Class]
		, [A].[Product_Control_Clas]
		, [A].[Packing_Standerd_QTY]
		, [A].[Date_Code]
		, [A].[HASUU_Out_Flag]
		, [A].[QTY]
		, [A].[Transfer_Flag]
		, [A].[Transfer]
		, [A].[OPNo]
		, [A].[Theoretical]
		, [A].[OUT_OUT_FLAG]
		, [A].[MIXD_DATE]
		, [A].[TimeStamp_date]
		, [A].[TimeStamp_time]
	FROM (
		SELECT  [A].*
			, [B].[QTY] AS [QTY_Master]
			, CASE 
				WHEN [A].[lot_type] = 'D' AND [A].[pc_instruction_code] IN (1, 11, 13) THEN 0
				WHEN [B].[QTY] < [A].[Packing_Standerd_QTY] THEN 1 
				ELSE 0 
			END AS [condition] 
		FROM #TestTableBass AS [A]
		LEFT JOIN (
			SELECT [AB].[HASUU_LotNo]
				, SUM(ISNULL([AB].[QTY], 0)) AS [QTY] 
			FROM #TestTableBass AS [AB]
			GROUP BY [AB].[HASUU_LotNo]
		) AS [B] ON [A].[HASUU_LotNo] = [B].[HASUU_LotNo]
		WHERE [production_category] NOT IN (21, 22)
			AND ( [pc_instruction_code] != 11 OR ([pc_instruction_code] = 11 AND [lot_type] = 'D') ) 
	) AS [A]
	WHERE [condition] = 0
	ORDER BY [A].[HASUU_LotNo]
		, [A].[LotNo];

	DROP TABLE #TestTableBass;
END

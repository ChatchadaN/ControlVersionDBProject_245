-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_allocat_temp]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-------------------------------------------------------------------------------------------------------
	-- (1) update table allocat
	-------------------------------------------------------------------------------------------------------
	UPDATE [allocat]
	SET [allocat].[Tomson3] = [lot_qc_info].[tomson3_after]
	FROM [APCSProDB].[method].[allocat]
	INNER JOIN [APCSProDB].[trans].[lots] ON [allocat].[LotNo] = [lots].[lot_no]
	INNER JOIN [APCSProDWH].[tg].[lot_qc_info] ON [lots].[id] = [lot_qc_info].[lot_id]
	WHERE [allocat].[Tomson3] != [lot_qc_info].[tomson3_after];

	-------------------------------------------------------------------------------------------------------
	-- (2) insert or update allocat to allocat_temp
	-------------------------------------------------------------------------------------------------------
   	MERGE [APCSProDB].[method].[allocat_temp] AS [atemp]
	USING [APCSProDB].[method].[allocat] AS [a] ON ([atemp].[LotNo] = [a].[LotNo]) 
	WHEN MATCHED AND [atemp].[Tomson3] != [a].[Tomson3]
		THEN UPDATE SET [atemp].[Type_Name] = [a].[Type_Name]
			, [atemp].[ROHM_Model_Name] = [a].[ROHM_Model_Name]
			, [atemp].[ASSY_Model_Name] = [a].[ASSY_Model_Name]
			, [atemp].[R_Fukuoka_Model_Name] = [a].[R_Fukuoka_Model_Name]
			, [atemp].[TIRank] = [a].[TIRank]
			, [atemp].[Rank] = [a].[Rank]
			, [atemp].[TPRank] = [a].[TPRank]
			, [atemp].[SUBRank] = [a].[SUBRank]
			, [atemp].[PDCD] = [a].[PDCD]
			, [atemp].[Mask] = [a].[Mask]
			, [atemp].[KNo] = [a].[KNo]
			, [atemp].[MNo] = [a].[MNo]
			, [atemp].[ORNo] = [a].[ORNo]
			, [atemp].[Packing_Standerd_QTY] = [a].[Packing_Standerd_QTY]
			, [atemp].[Tomson1] = [a].[Tomson1]
			, [atemp].[Tomson2] = [a].[Tomson2]
			, [atemp].[Tomson3] = [a].[Tomson3]
			, [atemp].[WFLotNo] = [a].[WFLotNo]
			, [atemp].[LotNo_Class] = [a].[LotNo_Class]
			, [atemp].[User_Code] = [a].[User_Code]
			, [atemp].[Product_Control_Cl_1] = [a].[Product_Control_Cl_1]
			, [atemp].[Product_Class] = [a].[Product_Class]
			, [atemp].[Production_Class] = [a].[Production_Class]
			, [atemp].[Rank_No] = [a].[Rank_No]
			, [atemp].[HINSYU_Class] = [a].[HINSYU_Class]
			, [atemp].[Label_Class] = [a].[Label_Class]
			, [atemp].[OUT_OUT_FLAG] = [a].[OUT_OUT_FLAG]
			, [atemp].[allocation_Date] = [a].[allocation_Date]
			, [atemp].[allocation_QTY] = [a].[allocation_QTY]
			, [atemp].[Print_Flag] = [a].[Print_Flag]
			, [atemp].[Timestamp_Date] = [a].[Timestamp_Date]
			, [atemp].[Timestamp_Time] = [a].[Timestamp_Time]
	WHEN NOT MATCHED BY TARGET 
		THEN INSERT ( [LotNo]
			, [Type_Name]
			, [ROHM_Model_Name]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
			, [TIRank]
			, [Rank]
			, [TPRank]
			, [SUBRank]
			, [PDCD]
			, [Mask]
			, [KNo]
			, [MNo]
			, [ORNo]
			, [Packing_Standerd_QTY]
			, [Tomson1]
			, [Tomson2]
			, [Tomson3]
			, [WFLotNo]
			, [LotNo_Class]
			, [User_Code]
			, [Product_Control_Cl_1]
			, [Product_Class]
			, [Production_Class]
			, [Rank_No]
			, [HINSYU_Class]
			, [Label_Class]
			, [OUT_OUT_FLAG]
			, [allocation_Date]
			, [allocation_QTY]
			, [Print_Flag]
			, [Timestamp_Date]
			, [Timestamp_Time] ) 
		VALUES ( [a].[LotNo]
			, [a].[Type_Name]
			, [a].[ROHM_Model_Name]
			, [a].[ASSY_Model_Name]
			, [a].[R_Fukuoka_Model_Name]
			, [a].[TIRank]
			, [a].[Rank]
			, [a].[TPRank]
			, [a].[SUBRank]
			, [a].[PDCD]
			, [a].[Mask]
			, [a].[KNo]
			, [a].[MNo]
			, [a].[ORNo]
			, [a].[Packing_Standerd_QTY]
			, [a].[Tomson1]
			, [a].[Tomson2]
			, [a].[Tomson3]
			, [a].[WFLotNo]
			, [a].[LotNo_Class]
			, [a].[User_Code]
			, [a].[Product_Control_Cl_1]
			, [a].[Product_Class]
			, [a].[Production_Class]
			, [a].[Rank_No]
			, [a].[HINSYU_Class]
			, [a].[Label_Class]
			, [a].[OUT_OUT_FLAG]
			, [a].[allocation_Date]
			, [a].[allocation_QTY]
			, [a].[Print_Flag]
			, [a].[Timestamp_Date]
			, [a].[Timestamp_Time] );

	-------------------------------------------------------------------------------------------------------
	-- (3) update table allocat_temp
	-------------------------------------------------------------------------------------------------------
	UPDATE [allocat]
	SET [allocat].[Tomson3] = [lot_qc_info].[tomson3_after]
	FROM [APCSProDB].[method].[allocat_temp] AS [allocat]
	INNER JOIN [APCSProDB].[trans].[lots] ON [allocat].[LotNo] = [lots].[lot_no]
	INNER JOIN [APCSProDWH].[tg].[lot_qc_info] ON [lots].[id] = [lot_qc_info].[lot_id]
	WHERE [allocat].[Tomson3] != [lot_qc_info].[tomson3_after];
END

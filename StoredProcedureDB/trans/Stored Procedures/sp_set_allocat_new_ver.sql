-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_allocat_new_ver]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here
	PRINT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') + '||' + 'start')
	-------------------------------------------------------------------------------------------------------
	-- (1) update table allocat_table
	-------------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT TOP 1 [LotNo] FROM [APCSProDWH].[atom].[allocat_table])
	BEGIN
		-------------------------------------------------------------------------------------------------------
		-- (1.1) check G lot
		-------------------------------------------------------------------------------------------------------
		IF EXISTS(
			SELECT TOP 1 [lots].[lot_no_G] AS [LotNo]
			FROM (
				SELECT SUBSTRING([lots].[lot_no], 1, 4) + 'A' + SUBSTRING([lots].[lot_no], 6, 5) AS [lot_no_A]
					, SUBSTRING([lots].[lot_no], 1, 4) + 'G' + SUBSTRING([lots].[lot_no], 6, 5) AS [lot_no_G]
				FROM [APCSProDB].[trans].[lots]
				LEFT JOIN [APCSProDWH].[atom].[allocat_table] AS [allocat_temp] ON [lots].[lot_no] = [allocat_temp].[LotNo]
				WHERE [lots].[wip_state] IN (0, 10, 20)
					AND SUBSTRING([lots].[lot_no], 5, 1) = 'G'
			) AS [lots]
			INNER JOIN [APCSProDWH].[atom].[allocat_table] AS [allocat_a] ON [lots].[lot_no_A] = [allocat_a].[LotNo]
			LEFT JOIN [APCSProDWH].[atom].[allocat_table] AS [allocat_g] ON [lots].[lot_no_G] = [allocat_g].[LotNo]
			WHERE [allocat_g].[LotNo] IS NULL
		)
		BEGIN
			INSERT INTO [APCSProDWH].[atom].[allocat_table]
			SELECT [lots].[lot_no_G] AS [LotNo]
				, [allocat_a].[Type_Name]
				, [allocat_a].[ROHM_Model_Name]
				, [allocat_a].[ASSY_Model_Name]
				, [allocat_a].[R_Fukuoka_Model_Name]
				, [allocat_a].[TIRank]
				, [allocat_a].[Rank]
				, [allocat_a].[TPRank]
				, [allocat_a].[SUBRank]
				, [allocat_a].[PDCD]
				, [allocat_a].[Mask]
				, [allocat_a].[KNo]
				, [allocat_a].[MNo]
				, [allocat_a].[ORNo]
				, [allocat_a].[Packing_Standerd_QTY]
				, [allocat_a].[Tomson1]
				, [allocat_a].[Tomson2]
				, [allocat_a].[Tomson3]
				, [allocat_a].[WFLotNo]
				, [allocat_a].[LotNo_Class]
				, [allocat_a].[User_Code]
				, [allocat_a].[Product_Control_Cl_1]
				, [allocat_a].[Product_Class]
				, [allocat_a].[Production_Class]
				, [allocat_a].[Rank_No]
				, [allocat_a].[HINSYU_Class]
				, [allocat_a].[Label_Class]
				, [allocat_a].[OUT_OUT_FLAG]
				, [allocat_a].[allocation_Date]
				, [allocat_a].[allocation_QTY]
				, [allocat_a].[Print_Flag]
				--, [allocat_a].[Timestamp_Date]
				, GETDATE() AS [Timestamp_Date]
				, [allocat_a].[Timestamp_Time]
			FROM (
				SELECT SUBSTRING([lots].[lot_no], 1, 4) + 'A' + SUBSTRING([lots].[lot_no], 6, 5) AS [lot_no_A]
					, SUBSTRING([lots].[lot_no], 1, 4) + 'G' + SUBSTRING([lots].[lot_no], 6, 5) AS [lot_no_G]
				FROM [APCSProDB].[trans].[lots]
				LEFT JOIN [APCSProDWH].[atom].[allocat_table] AS [allocat_temp] ON [lots].[lot_no] = [allocat_temp].[LotNo]
				WHERE [lots].[wip_state] IN (0, 10, 20)
					AND SUBSTRING([lots].[lot_no], 5, 1) = 'G'
			) AS [lots]
			INNER JOIN [APCSProDWH].[atom].[allocat_table] AS [allocat_a] ON [lots].[lot_no_A] = [allocat_a].[LotNo]
			LEFT JOIN [APCSProDWH].[atom].[allocat_table] AS [allocat_g] ON [lots].[lot_no_G] = [allocat_g].[LotNo]
			WHERE [allocat_g].[LotNo] IS NULL;
		END

		-------------------------------------------------------------------------------------------------------
		-- (1.2) update Tomson3
		-------------------------------------------------------------------------------------------------------
		UPDATE [allocat_table]
		SET [allocat_table].[Tomson3] = [lot_qc_info].[tomson3_after]
		FROM [APCSProDWH].[atom].[allocat_table]
		INNER JOIN [APCSProDB].[trans].[lots] ON [allocat_table].[LotNo] = [lots].[lot_no]
		INNER JOIN [APCSProDWH].[tg].[lot_qc_info] ON [lots].[id] = [lot_qc_info].[lot_id]
		WHERE [allocat_table].[Tomson3] != [lot_qc_info].[tomson3_after];
	END
	ELSE
	BEGIN
		RETURN;
	END
	PRINT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') + '||' + 'end update table allocat_table')
	-------------------------------------------------------------------------------------------------------
	-- (2) insert & delete table allocat
	-------------------------------------------------------------------------------------------------------
	DELETE FROM [APCSProDB].[method].[allocat];

	INSERT INTO [APCSProDB].[method].[allocat]
	SELECT * FROM [APCSProDWH].[atom].[allocat_table];
	PRINT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') + '||' + 'end insert & delete table allocat')
	-------------------------------------------------------------------------------------------------------
	-- (3) delete table allocat_table
	-------------------------------------------------------------------------------------------------------
	--DELETE FROM [APCSProDWH].[atom].[allocat_table];

	-------------------------------------------------------------------------------------------------------
	-- (4) insert or update allocat to allocat_temp
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

	PRINT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') + '||' + 'end insert or update allocat to allocat_temp')
	-------------------------------------------------------------------------------------------------------
	-- (5) update table allocat_temp
	-------------------------------------------------------------------------------------------------------
	UPDATE [allocat]
	SET [allocat].[Tomson3] = [lot_qc_info].[tomson3_after]
	FROM [APCSProDB].[method].[allocat_temp] AS [allocat]
	INNER JOIN [APCSProDB].[trans].[lots] ON [allocat].[LotNo] = [lots].[lot_no]
	INNER JOIN [APCSProDWH].[tg].[lot_qc_info] ON [lots].[id] = [lot_qc_info].[lot_id]
	WHERE [allocat].[Tomson3] != [lot_qc_info].[tomson3_after];
	PRINT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') + '||' + 'end update table allocat_temp')
	PRINT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') + '||' + 'end')
END

-- =============================================
-- Author:		<Kittitat P.>
-- Create date: <2023/02/16>
-- Description:	<Create recall_lot (D lot) in table interface>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_new_dlot_recall_is_if_002]
	-- Add the parameters for the stored procedure here
	--@new_lotno VARCHAR(10) = '1234D1234V'
	--, @original_lotno VARCHAR(10) = '2304A5528V'
	--, @qty INT = 900 --qty hasuu all
	--, @empid INT = 1339
	--, @flow_pattern_id INT = 1849
	@lotno VARCHAR(10)
	, @qty INT
	, @empid INT
	, @flow_pattern_id INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----------------------------------------------------------------------------
	----- # log exec stored procedure
	----------------------------------------------------------------------------
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, ISNULL('EXEC [atom].[tg_sp_new_dlot_recall_is_if_002] @lotno = ''' + @lotno + '''','EXEC [atom].[tg_sp_new_dlot_recall_is_if_002] @lotno = NULL')
			+ ISNULL(', @qty = ' + CAST(@qty AS VARCHAR),', @qty = NULL')
			+ ISNULL(', @empid = ' + CAST(@empid AS VARCHAR),', @empid = NULL')
			+ ISNULL(', @flow_pattern_id = ' + CAST(@flow_pattern_id AS VARCHAR),', @flow_pattern_id = NULL')
		, @lotno;

	---- set emp_num
	DECLARE @empnum VARCHAR(6) = (SELECT [emp_num] FROM [APCSProDB].[man].[users] WITH (NOLOCK) WHERE [id] = @empid);
	DECLARE @date DATETIME = GETDATE();
	DECLARE @abnormal_mode VARCHAR(255) = (SELECT [comments] FROM [APCSProDB].[method].[flow_patterns] WHERE [id] = @flow_pattern_id);

	DECLARE @lot_combine TABLE (
		lot_id INT
		, member_lot_id INT
		, idx INT
	)
	DECLARE @table_mix_hist TABLE (
		[M_O_No] [char](10) NOT NULL,
		[FREQ] [char](2) NOT NULL,
		[HASUU_LotNo] [char](10) NOT NULL,
		[LotNo] [char](10) NOT NULL,
		[P_O_No] [char](20) NOT NULL,
		[Stock_Class] [char](2) NOT NULL,
		[Type_Name] [char](10) NOT NULL,
		[ROHM_Model_Name] [char](20) NOT NULL,
		[PDCD] [char](5) NOT NULL,
		[ASSY_Model_Name] [char](20) NOT NULL,
		[R_Fukuoka_Model_Name] [char](20) NOT NULL,
		[TIRank] [char](5) NOT NULL,
		[Rank] [char](5) NOT NULL,
		[TPRank] [char](3) NOT NULL,
		[SUBRank] [char](3) NOT NULL,
		[Mask] [char](2) NOT NULL,
		[KNo] [char](3) NOT NULL,
		[MNo] [char](10) NOT NULL,
		[Tomson1] [char](4) NOT NULL,
		[Tomson2] [char](4) NOT NULL,
		[Tomson3] [char](4) NOT NULL,
		[allocation_Date] [datetime] NOT NULL,
		[ORNo] [char](12) NOT NULL,
		[WFLotNo] [char](20) NOT NULL,
		[User_Code] [char](4) NOT NULL,
		[LotNo_Class] [char](1) NOT NULL,
		[Label_Class] [char](1) NOT NULL,
		[Multi_Class] [char](1) NOT NULL,
		[Product_Control_Clas] [char](3) NOT NULL,
		[Packing_Standerd_QTY] [int] NOT NULL,
		[Date_Code] [char](3) NOT NULL,
		[HASUU_Out_Flag] [char](1) NOT NULL,
		[QTY] [int] NOT NULL,
		[Transfer_Flag] [char](1) NOT NULL,
		[Transfer] [int] NOT NULL,
		[OPNo] [char](5) NOT NULL,
		[Theoretical] [char](1) NOT NULL,
		[OUT_OUT_FLAG] [char](1) NOT NULL,
		[MIXD_DATE] [datetime] NOT NULL,
		[TimeStamp_date] [datetime] NOT NULL,
		[TimeStamp_time] [int] NOT NULL
	)

	DECLARE @table_lsi_ship TABLE (
		[LotNo] [char](10) NOT NULL,
		[Type_Name] [char](10) NOT NULL,
		[ROHM_Model_Name] [char](20) NOT NULL,
		[ASSY_Model_Name] [char](20) NOT NULL,
		[R_Fukuoka_Model_Name] [char](20) NOT NULL,
		[TIRank] [char](5) NOT NULL,
		[Rank] [char](5) NOT NULL,
		[TPRank] [char](3) NOT NULL,
		[SUBRank] [char](3) NOT NULL,
		[PDCD] [char](5) NOT NULL,
		[Mask] [char](2) NOT NULL,
		[KNo] [char](3) NOT NULL,
		[MNo] [char](10) NOT NULL,
		[ORNo] [char](12) NOT NULL,
		[Packing_Standerd_QTY] [int] NOT NULL,
		[Tomson1] [char](4) NOT NULL,
		[Tomson2] [char](4) NOT NULL,
		[Tomson3] [char](4) NOT NULL,
		[WFLotNo] [char](20) NOT NULL,
		[LotNo_Class] [char](1) NOT NULL,
		[User_Code] [char](4) NOT NULL,
		[Product_Control_Clas] [char](3) NOT NULL,
		[Product_Class] [char](1) NOT NULL,
		[Production_Class] [char](1) NOT NULL,
		[Rank_No] [char](6) NOT NULL,
		[HINSYU_Class] [char](1) NOT NULL,
		[Label_Class] [char](1) NOT NULL,
		[Standard_LotNo] [char](10) NOT NULL,
		[Complement_LotNo_1] [char](10) NOT NULL,
		[Complement_LotNo_2] [char](10) NOT NULL,
		[Complement_LotNo_3] [char](10) NOT NULL,
		[Standard_MNo] [char](10) NOT NULL,
		[Complement_MNo_1] [char](10) NOT NULL,
		[Complement_MNo_2] [char](10) NOT NULL,
		[Complement_MNo_3] [char](10) NOT NULL,
		[Standerd_QTY] [int] NOT NULL,
		[Complement_QTY_1] [int] NOT NULL,
		[Complement_QTY_2] [int] NOT NULL,
		[Complement_QTY_3] [int] NOT NULL,
		[Shipment_QTY] [int] NOT NULL,
		[Good_Product_QTY] [int] NOT NULL,
		[Used_Fin_Packing_QTY] [int] NOT NULL,
		[HASUU_Out_Flag] [char](1) NOT NULL,
		[OUT_OUT_FLAG] [char](1) NOT NULL,
		[Stock_Class] [char](2) NOT NULL,
		[Label_Confirm_Class] [char](1) NOT NULL,
		[allocation_Date] [datetime] NOT NULL,
		[Delete_Flag] [char](1) NOT NULL,
		[OPNo] [char](5) NOT NULL,
		[Timestamp_Date] [datetime] NOT NULL,
		[Timestamp_Time] [int] NOT NULL
	)

	DECLARE @table_h_stock TABLE (
		[Stock_Class] [char](2) NOT NULL,
		[PDCD] [char](5) NOT NULL,
		[LotNo] [char](10) NOT NULL,
		[Type_Name] [char](10) NOT NULL,
		[ROHM_Model_Name] [char](20) NOT NULL,
		[ASSY_Model_Name] [char](20) NOT NULL,
		[R_Fukuoka_Model_Name] [char](20) NOT NULL,
		[TIRank] [char](5) NOT NULL,
		[Rank] [char](5) NOT NULL,
		[TPRank] [char](3) NOT NULL,
		[SUBRank] [char](3) NOT NULL,
		[Mask] [char](2) NOT NULL,
		[KNo] [char](3) NOT NULL,
		[MNo] [char](10) NOT NULL,
		[ORNo] [char](12) NOT NULL,
		[Packing_Standerd_QTY] [int] NOT NULL,
		[Tomson_Mark_1] [char](4) NOT NULL,
		[Tomson_Mark_2] [char](4) NOT NULL,
		[Tomson_Mark_3] [char](4) NOT NULL,
		[WFLotNo] [char](20) NOT NULL,
		[LotNo_Class] [char](1) NOT NULL,
		[User_Code] [char](4) NOT NULL,
		[Product_Control_Clas] [char](3) NOT NULL,
		[Product_Class] [char](1) NOT NULL,
		[Production_Class] [char](1) NOT NULL,
		[Rank_No] [char](6) NOT NULL,
		[HINSYU_Class] [char](1) NOT NULL,
		[Label_Class] [char](1) NOT NULL,
		[HASU_Stock_QTY] [int] NOT NULL,
		[HASU_WIP_QTY] [int] NOT NULL,
		[HASUU_Working_Flag] [char](1) NOT NULL,
		[OUT_OUT_FLAG] [char](1) NOT NULL,
		[Label_Confirm_Class] [char](1) NOT NULL,
		[OPNo] [char](5) NOT NULL,
		[DMY_IN__Flag] [char](1) NOT NULL,
		[DMY_OUT_Flag] [char](1) NOT NULL,
		[Derivery_Date] [datetime] NOT NULL,
		[Derivery_Time] [int] NOT NULL,
		[Timestamp_Date] [datetime] NOT NULL,
		[Timestamp_Time] [int] NOT NULL
	)

	DECLARE @table_process_recall TABLE (
		[LOTNO] [char](10) NOT NULL,
		[TYPE] [char](20) NULL,
		[DEVICE] [char](20) NULL,
		[PD] [char](10) NULL,
		[MM] [char](10) NULL,
		[SEQNO] [int] NOT NULL,
		[OPNAME] [char](20) NOT NULL,
		[ABNORMALCASE] [char](30) NULL,
		[STDQTY] [int] NULL,
		[HASUUQTY] [int] NULL,
		[FLAG] [char](1) NULL,
		[DATES] [datetime] NULL,
		[TIMER] [int] NULL,
		[FINAL_STD_QTY] [int] NULL,
		[FINAL_HASUU_QTY] [int] NULL,
		[NEWLOT] [char](10) NULL,
		[NEWQTY] [int] NULL,
		[NEWPDCD] [char](5) NULL,
		[RECALL_FIN_DATE] [datetime] NULL,
		[RECALL_FIN_TIME] [int] NULL,
		[WH_OP_RECALL] [char](5) NULL,
		[WH_CANCEL_RECALL] [char](5) NOT NULL,
		[DATE_CANCEL_RECALL] [datetime] NOT NULL,
		[TIME_CANCEL_RECALL] [int] NOT NULL,
		[FLAG_CANCEL_RECALL] [char](1) NULL
	)

	----------------------------------------------------------------------------
	----- # create temp lot_combine
	----------------------------------------------------------------------------
	INSERT INTO @lot_combine (lot_id, member_lot_id, idx)
	------------ idx 0 ------------ 
	SELECT [id] AS [lot_id]
		, [id] AS [member_lot_id] 
		, 0 AS [idx]
	FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
	WHERE [lot_no] = @lotno
	UNION ALL
	------------ idx 1 - end ------------ 
	SELECT [lot_combine].[lot_id] AS [lot_id]
		, [lot_combine].[member_lot_id] AS [member_lot_id] 
		, ([lot_combine].[idx] + 1) AS [idx]
	FROM [APCSProDB].[trans].[lot_combine] WITH (NOLOCK) 
	INNER JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [lot_combine].[lot_id] = [lots].[id]
	WHERE [lots].[lot_no] = @lotno;
	----------------------------------------------------------------------------
	----- # insert to temp mix_hist
	----------------------------------------------------------------------------
	INSERT INTO @table_mix_hist
	SELECT '' AS [M_O_No]
		, '' AS [FREQ]
		, [lot_mas].[lot_no] AS [HASUU_LotNo]
		, [lot_mem].[lot_no] AS [LotNo]
		, '' AS [P_O_No]
		, '01' AS [Stock_Class]
		, [packages].[short_name] AS [Type_Name]
		, [device_names].[name] AS [ROHM_Model_Name]
		, [surpluses].[pdcd] AS [PDCD]
		, [device_names].[assy_name] AS [ASSY_Model_Name]
		, [fukuoka].[R_Fukuoka_Model_Name] AS [R_Fukuoka_Model_Name]
		, ISNULL([device_names].[rank],'') AS [TIRank]
		, ISNULL([device_names].[rank],'') AS [Rank]
		, ISNULL([device_names].[tp_rank],'') AS [TPRank]
		, '' AS [SUBRank]
		, '' AS [Mask]
		, '' AS [KNo]
		, '' AS [MNo]
		, '' AS [Tomson1]
		, '' AS [Tomson2]
		, [surpluses].[qc_instruction] AS [Tomson3]
		, @date AS [allocation_Date]
		, IIF(SUBSTRING([lot_mem].[lot_no],5,1) = 'D','NO',ISNULL([allocat].[ORNo],ISNULL([allocat_temp].[ORNo],''))) AS [ORNo]
		, ISNULL([allocat].[WFLotNo],ISNULL([allocat_temp].[WFLotNo],'')) AS [WFLotNo]
		, '' AS [User_Code]
		, '' AS [LotNo_Class]
		, ISNULL([surpluses].[label_class],'') AS [Label_Class]
		, '' AS [Multi_Class]
		, ISNULL([surpluses].[product_control_class],'') AS [Product_Control_Clas]
		, [device_names].[pcs_per_pack] AS [Packing_Standerd_QTY]
		, '' AS [Date_Code]
		, '' AS [HASUU_Out_Flag]
		, @QTY AS [QTY]
		, IIF([lot_combine].[lot_id] != [lot_combine].[member_lot_id],'1','') AS [Transfer_Flag]
		, 0 AS [Transfer]
		, CAST(@empnum AS INT) AS [OPNo]
		, '' AS [Theoretical]
		, 'B' AS [OUT_OUT_FLAG]
		, @date AS [MIXD_DATE]
		, @date AS [TimeStamp_date]
		, DATEDIFF(s, CAST(@date AS DATE) , CURRENT_TIMESTAMP) AS [TimeStamp_time]
	FROM @lot_combine AS [lot_combine]
	INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mas] WITH (NOLOCK) ON [lot_combine].[lot_id] = [lot_mas].[id]
	INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mem] WITH (NOLOCK) ON [lot_combine].[member_lot_id] = [lot_mem].[id]
	INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [lot_mem].[act_package_id] = [packages].[id]
	INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [lot_mem].[act_device_name_id] = [device_names].[id]
	INNER JOIN [APCSProDB].[trans].[surpluses] WITH (NOLOCK) ON [lot_mem].[id] = [surpluses].[lot_id]
	LEFT JOIN [APCSProDB].[method].[allocat] WITH (NOLOCK) ON [lot_mem].[lot_no] = [allocat].[LotNo]
	LEFT JOIN [APCSProDB].[method].[allocat_temp] WITH (NOLOCK) ON [lot_mem].[lot_no] = [allocat_temp].[LotNo]
	OUTER APPLY (
		SELECT TOP 1 [ROHM_Model_Name]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
		FROM [APCSProDB].[method].[allocat_temp] AS [at] WITH (NOLOCK)
		WHERE TRIM([at].[ROHM_Model_Name]) = TRIM([device_names].[name])
			AND TRIM([at].[ASSY_Model_Name]) = TRIM([device_names].[assy_name]) 
	) AS [fukuoka]	
	ORDER BY [lot_combine].[idx] ASC;
	----------------------------------------------------------------------------
	----- # insert to temp lsi_ship
	----------------------------------------------------------------------------
	INSERT INTO @table_lsi_ship
	SELECT [HASUU_LotNo] AS [LotNo]
      , [data].[Type_Name]
      , [data].[ROHM_Model_Name]
      , [data].[ASSY_Model_Name]
      , [data].[R_Fukuoka_Model_Name]
      , [data].[TIRank]
      , [data].[Rank]
      , [data].[TPRank]
      , [data].[SUBRank]
      , [data].[PDCD]
      , [data].[Mask]
      , [data].[KNo]
      , [data].[MNo]
      , [data].[ORNo]
      , [data].[Packing_Standerd_QTY]
      , [data].[Tomson1]
      , [data].[Tomson2]
      , [data].[Tomson3]
      , [data].[WFLotNo]
      , [data].[LotNo_Class]
      , [data].[User_Code]
      , [Product_Control_Clas]
      , ISNULL([surpluses].[product_class],'') AS [Product_Class]
	  , ISNULL([surpluses].[production_class],'') AS [Production_Class]
      , ISNULL([surpluses].[rank_no],'') AS [Rank_No]
      , ISNULL([surpluses].[hinsyu_class],'') AS [HINSYU_Class]
      , ISNULL([surpluses].[label_class],'') AS [Label_Class]
      , [data].[HASUU_LotNo] AS [Standard_LotNo]
      , [data].[LotNo] AS [Complement_LotNo_1]
      , '' AS [Complement_LotNo_2]
      , '' AS [Complement_LotNo_3]
      , 'MX' AS [Standard_MNo]
      , '' AS [Complement_MNo_1]
      , '' AS [Complement_MNo_2]
      , '' AS [Complement_MNo_3]
      , (([data].[Packing_Standerd_QTY]) * ([data].[QTY]/[data].[Packing_Standerd_QTY])) AS [Standerd_QTY]
      , 0 AS [Complement_QTY_1]
      , 0 AS [Complement_QTY_2]
      , 0 AS [Complement_QTY_3]
      , (([data].[Packing_Standerd_QTY]) * ([data].[QTY]/[data].[Packing_Standerd_QTY])) AS [Shipment_QTY]
      , [data].[QTY] AS [Good_Product_QTY]
      , 0 AS [Used_Fin_Packing_QTY]
      , [data].[HASUU_Out_Flag]
      , [data].[OUT_OUT_FLAG]
      , [data].[Stock_Class]
      , '' AS [Label_Confirm_Class]
      , [data].[allocation_Date]
      , '' AS [Delete_Flag]
      , [data].[OPNo]
      , [data].[Timestamp_Date]
      , [data].[Timestamp_Time]
	FROM @table_mix_hist AS [data]
	LEFT JOIN [APCSProDB].[trans].[surpluses] WITH (NOLOCK) ON [data].[LotNo] = [surpluses].[serial_no]
	WHERE [data].[LotNo] = @lotno;
	----------------------------------------------------------------------------
	----- # insert to temp h_stock
	----------------------------------------------------------------------------
	INSERT INTO @table_h_stock
	SELECT [Stock_Class]
      , [PDCD]
      , [LotNo]
      , [Type_Name]
      , [ROHM_Model_Name]
      , [ASSY_Model_Name]
      , [R_Fukuoka_Model_Name]
      , [TIRank]
      , [Rank]
      , [TPRank]
      , [SUBRank]
      , [Mask]
      , [KNo]
      , [MNo]
      , [ORNo]
      , [Packing_Standerd_QTY]
      , [Tomson1] AS [Tomson_Mark_1]
      , [Tomson2] AS [Tomson_Mark_2]
      , [Tomson3] AS [Tomson_Mark_3]
      , [WFLotNo]
      , [LotNo_Class]
      , [User_Code]
      , [Product_Control_Clas]
      , [Product_Class]
      , [Production_Class]
      , [Rank_No]
      , [HINSYU_Class]
      , [Label_Class]
      , ([Good_Product_QTY]%[Standerd_QTY]) AS [HASU_Stock_QTY]
      , [Standerd_QTY] AS [HASU_WIP_QTY]
      , '1' AS [HASUU_Working_Flag]
      , [OUT_OUT_FLAG]
      , [Label_Confirm_Class]
      , [OPNo]
      , '1' AS [DMY_IN__Flag]
      , '' AS [DMY_OUT_Flag]
      , [Timestamp_Date] AS [Derivery_Date]
      , [Timestamp_Time] AS [Derivery_Time]
      , [Timestamp_Date]
      , [Timestamp_Time]
	FROM @table_lsi_ship AS [data];
	----------------------------------------------------------------------------
	----- # insert to temp process_recall
	----------------------------------------------------------------------------
	INSERT INTO @table_process_recall
	SELECT [data].[LotNo] AS [LOTNO]
		, [data].[Type_Name] AS [TYPE]
		, [data].[ROHM_Model_Name] AS [DEVICE]
		, 'QC' AS [PD]
		, FORMAT([data].[TimeStamp_date],'MM') AS [MM]
		, '' AS [SEQNO]
		, CAST(@empnum AS INT) AS [OPNAME]
		, @abnormal_mode AS [ABNORMALCASE]
		, (([data].[Packing_Standerd_QTY]) * ([data].[QTY]/[data].[Packing_Standerd_QTY])) AS [STDQTY]
		, ([data].[QTY]%(([data].[Packing_Standerd_QTY]) * ([data].[QTY]/[data].[Packing_Standerd_QTY]))) AS [HASUUQTY]
		, 1 AS [FLAG]
		, FORMAT([data].[TimeStamp_date],'yyyy-MM-dd') + ' 00:00:00' AS [DATES]
		, [data].[TimeStamp_time] AS [TIMER]
		, (([data].[Packing_Standerd_QTY]) * ([data].[QTY]/[data].[Packing_Standerd_QTY])) AS [FINAL_STD_QTY]
		, ([data].[QTY]%(([data].[Packing_Standerd_QTY]) * ([data].[QTY]/[data].[Packing_Standerd_QTY]))) AS [FINAL_HASUU_QTY]
		, [data].[HASUU_LotNo] AS [NEWLOT]
		, [data].[QTY] AS [NEWQTY]
		, [data].[PDCD] AS [NEWPDCD]
		, FORMAT([data].[TimeStamp_date],'yyyy-MM-dd') + ' 00:00:00' AS [RECALL_FIN_DATE]
		, [data].[TimeStamp_time] AS [RECALL_FIN_TIME]
		, CAST(@empnum AS INT) AS [WH_OP_RECALL]
		, '' AS [WH_CANCEL_RECALL]
		, '1901-01-01 00:00:00' AS [DATE_CANCEL_RECALL]
		, 0 AS [TIME_CANCEL_RECALL]
		, 0 AS [FLAG_CANCEL_RECALL]
	FROM @table_mix_hist AS [data]
	WHERE [data].[HASUU_LotNo] != [data].[LotNo]
	----------------------------------------------------------------------------
	----- # insert data interface
	----------------------------------------------------------------------------
	BEGIN TRANSACTION
	BEGIN TRY
		----- MIX_HIST
		IF NOT EXISTS(SELECT HASUU_LotNo FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE HASUU_LotNo = @lotno)
		BEGIN
			INSERT INTO [APCSProDWH].[dbo].[MIX_HIST_IF]
			SELECT * FROM @table_mix_hist;
		END
		----- LSI_SHIP
		IF NOT EXISTS(SELECT LotNo FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WHERE LotNo = @lotno)
		BEGIN
			INSERT INTO [APCSProDWH].[dbo].[LSI_SHIP_IF]
			SELECT * FROM @table_lsi_ship;
		END
		----- H_STOCK
		IF NOT EXISTS(SELECT LotNo FROM [APCSProDWH].[dbo].[H_STOCK_IF] WHERE LotNo = @lotno)
		BEGIN
			INSERT INTO [APCSProDWH].[dbo].[H_STOCK_IF]
			SELECT * FROM @table_h_stock;
		END
		----- PROCESS_RECALL
		IF NOT EXISTS(SELECT LotNo FROM [APCSProDWH].[dbo].[PROCESS_RECALL_IF] WHERE [NEWLOT] = @lotno)
		BEGIN
			INSERT INTO [APCSProDWH].[dbo].[PROCESS_RECALL_IF]
			SELECT * FROM @table_process_recall;
		END
		-----------------------------------------------------------------------------
		COMMIT TRANSACTION;
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
		-----------------------------------------------------------------------------
	END TRY
	BEGIN CATCH
		-----------------------------------------------------------------------------
		ROLLBACK TRANSACTION;
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Insert data interface error !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล interface ไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
		-----------------------------------------------------------------------------
	END CATCH
	----------------------------------------------------------------------------
END

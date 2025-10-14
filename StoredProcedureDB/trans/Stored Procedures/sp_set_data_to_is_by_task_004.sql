-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_data_to_is_by_task_004]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	-- Version 003 add update wh_ukeba
	-- Version 004 add process_recall
	SET NOCOUNT ON;

	PRINT '<---- Start ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
	DECLARE @IS_H_STOCK INT = 1 -- 0:disable 1:enable
		, @IS_LSI_SHIP INT = 1 -- 0:disable 1:enable
		, @IS_MIX_HIST INT = 1 -- 0:disable 1:enable
		, @IS_PACKWORK INT = 1 -- 0:disable 1:enable
		, @IS_WH_UKEBA INT = 1 -- 0:disable 1:enable
		, @IS_WORK_R_DB INT = 1 -- 0:disable 1:enable
		, @IS_PROCESS_RECALL INT = 1 -- 0:disable 1:enable

	-------------------------------------------------------------------------------------------------------
	-- (1) Declare table
	-------------------------------------------------------------------------------------------------------
	PRINT '<---- Declare @Table';
	-- /* Declare @Table1 H_STOCK */
	DECLARE @table_h_stock TABLE (
		[History_ID] [int] NOT NULL
		, [History_At] [datetime] NOT NULL
		, [Host_Name] [varchar](50) NULL
		, [History_Class] [int] NOT NULL
		, [Stock_Class] [char](2) NOT NULL
		, [PDCD] [char](5) NOT NULL
		, [LotNo] [char](10) NOT NULL
		, [Type_Name] [char](10) NOT NULL
		, [ROHM_Model_Name] [char](20) NOT NULL
		, [ASSY_Model_Name] [char](20) NOT NULL
		, [R_Fukuoka_Model_Name] [char](20) NOT NULL
		, [TIRank] [char](5) NOT NULL
		, [Rank] [char](5) NOT NULL
		, [TPRank] [char](3) NOT NULL
		, [SUBRank] [char](3) NOT NULL
		, [Mask] [char](2) NOT NULL
		, [KNo] [char](3) NOT NULL
		, [MNo] [char](10) NOT NULL
		, [ORNo] [char](12) NOT NULL
		, [Packing_Standerd_QTY] [int] NOT NULL
		, [Tomson_Mark_1] [char](4) NOT NULL
		, [Tomson_Mark_2] [char](4) NOT NULL
		, [Tomson_Mark_3] [char](4) NOT NULL
		, [WFLotNo] [char](20) NOT NULL
		, [LotNo_Class] [char](1) NOT NULL
		, [User_Code] [char](4) NOT NULL
		, [Product_Control_Clas] [char](3) NOT NULL
		, [Product_Class] [char](1) NOT NULL
		, [Production_Class] [char](1) NOT NULL
		, [Rank_No] [char](6) NOT NULL
		, [HINSYU_Class] [char](1) NOT NULL
		, [Label_Class] [char](1) NOT NULL
		, [HASU_Stock_QTY] [int] NOT NULL
		, [HASU_WIP_QTY] [int] NOT NULL
		, [HASUU_Working_Flag] [char](1) NOT NULL
		, [OUT_OUT_FLAG] [char](1) NOT NULL
		, [Label_Confirm_Class] [char](1) NOT NULL
		, [OPNo] [char](5) NOT NULL
		, [DMY_IN__Flag] [char](1) NOT NULL
		, [DMY_OUT_Flag] [char](1) NOT NULL
		, [Derivery_Date] [datetime] NOT NULL
		, [Derivery_Time] [int] NOT NULL
		, [Timestamp_Date] [datetime] NOT NULL
		, [Timestamp_Time] [int] NOT NULL
		, [State_Flag] [int] NOT NULL
	);
	-- /* Declare @Table2 LSI_SHIP */
	DECLARE @table_lsi_ship TABLE ( 
		[History_ID] [int] NOT NULL
		, [History_At] [datetime] NOT NULL
		, [Host_Name] [varchar](50) NULL
		, [History_Class] [int] NOT NULL
		, [LotNo] [char](10) NOT NULL
		, [Type_Name] [char](10) NOT NULL
		, [ROHM_Model_Name] [char](20) NOT NULL
		, [ASSY_Model_Name] [char](20) NOT NULL
		, [R_Fukuoka_Model_Name] [char](20) NOT NULL
		, [TIRank] [char](5) NOT NULL
		, [Rank] [char](5) NOT NULL
		, [TPRank] [char](3) NOT NULL
		, [SUBRank] [char](3) NOT NULL
		, [PDCD] [char](5) NOT NULL
		, [Mask] [char](2) NOT NULL
		, [KNo] [char](3) NOT NULL
		, [MNo] [char](10) NOT NULL
		, [ORNo] [char](12) NOT NULL
		, [Packing_Standerd_QTY] [int] NOT NULL
		, [Tomson1] [char](4) NOT NULL
		, [Tomson2] [char](4) NOT NULL
		, [Tomson3] [char](4) NOT NULL
		, [WFLotNo] [char](20) NOT NULL
		, [LotNo_Class] [char](1) NOT NULL
		, [User_Code] [char](4) NOT NULL
		, [Product_Control_Clas] [char](3) NOT NULL
		, [Product_Class] [char](1) NOT NULL
		, [Production_Class] [char](1) NOT NULL
		, [Rank_No] [char](6) NOT NULL
		, [HINSYU_Class] [char](1) NOT NULL
		, [Label_Class] [char](1) NOT NULL
		, [Standard_LotNo] [char](10) NOT NULL
		, [Complement_LotNo_1] [char](10) NOT NULL
		, [Complement_LotNo_2] [char](10) NOT NULL
		, [Complement_LotNo_3] [char](10) NOT NULL
		, [Standard_MNo] [char](10) NOT NULL
		, [Complement_MNo_1] [char](10) NOT NULL
		, [Complement_MNo_2] [char](10) NOT NULL
		, [Complement_MNo_3] [char](10) NOT NULL
		, [Standerd_QTY] [int] NOT NULL
		, [Complement_QTY_1] [int] NOT NULL
		, [Complement_QTY_2] [int] NOT NULL
		, [Complement_QTY_3] [int] NOT NULL
		, [Shipment_QTY] [int] NOT NULL
		, [Good_Product_QTY] [int] NOT NULL
		, [Used_Fin_Packing_QTY] [int] NOT NULL
		, [HASUU_Out_Flag] [char](1) NOT NULL
		, [OUT_OUT_FLAG] [char](1) NOT NULL
		, [Stock_Class] [char](2) NOT NULL
		, [Label_Confirm_Class] [char](1) NOT NULL
		, [allocation_Date] [datetime] NOT NULL
		, [Delete_Flag] [char](1) NOT NULL
		, [OPNo] [char](5) NOT NULL
		, [Timestamp_Date] [datetime] NOT NULL
		, [Timestamp_Time] [int] NOT NULL
		, [State_Flag] [int] NOT NULL
	);
	-- /* Declare @Table3 MIX_HIST */
	DECLARE @table_mix_hist TABLE(
		[History_ID] [int] NOT NULL
		, [History_At] [datetime] NOT NULL
		, [Host_Name] [varchar](50) NULL
		, [History_Class] [int] NOT NULL
		, [M_O_No] [char](10) NOT NULL
		, [FREQ] [char](2) NOT NULL
		, [HASUU_LotNo] [char](10) NOT NULL
		, [LotNo] [char](10) NOT NULL
		, [P_O_No] [char](20) NOT NULL
		, [Stock_Class] [char](2) NOT NULL
		, [Type_Name] [char](10) NOT NULL
		, [ROHM_Model_Name] [char](20) NOT NULL
		, [PDCD] [char](5) NOT NULL
		, [ASSY_Model_Name] [char](20) NOT NULL
		, [R_Fukuoka_Model_Name] [char](20) NOT NULL
		, [TIRank] [char](5) NOT NULL
		, [Rank] [char](5) NOT NULL
		, [TPRank] [char](3) NOT NULL
		, [SUBRank] [char](3) NOT NULL
		, [Mask] [char](2) NOT NULL
		, [KNo] [char](3) NOT NULL
		, [MNo] [char](10) NOT NULL
		, [Tomson1] [char](4) NOT NULL
		, [Tomson2] [char](4) NOT NULL
		, [Tomson3] [char](4) NOT NULL
		, [allocation_Date] [datetime] NOT NULL
		, [ORNo] [char](12) NOT NULL
		, [WFLotNo] [char](20) NOT NULL
		, [User_Code] [char](4) NOT NULL
		, [LotNo_Class] [char](1) NOT NULL
		, [Label_Class] [char](1) NOT NULL
		, [Multi_Class] [char](1) NOT NULL
		, [Product_Control_Clas] [char](3) NOT NULL
		, [Packing_Standerd_QTY] [int] NOT NULL
		, [Date_Code] [char](3) NOT NULL
		, [HASUU_Out_Flag] [char](1) NOT NULL
		, [QTY] [int] NOT NULL
		, [Transfer_Flag] [char](1) NOT NULL
		, [Transfer] [int] NOT NULL
		, [OPNo] [char](5) NOT NULL
		, [Theoretical] [char](1) NOT NULL
		, [OUT_OUT_FLAG] [char](1) NOT NULL
		, [MIXD_DATE] [datetime] NOT NULL
		, [TimeStamp_date] [datetime] NOT NULL
		, [TimeStamp_time] [int] NOT NULL
		, [State_Flag] [int] NOT NULL
	);
	-- /* Declare @Table4 PACKWORK */
	DECLARE @table_packwork TABLE(
		[History_ID] [int] NOT NULL
		, [History_At] [datetime] NOT NULL
		, [Host_Name] [varchar](50) NULL
		, [History_Class] [int] NOT NULL
		, [LotNo] [char](10) NOT NULL
		, [Type_Name] [char](10) NOT NULL
		, [ROHM_Model_Name] [char](20) NOT NULL
		, [R_Fukuoka_Model_Name] [char](20) NOT NULL
		, [Rank] [char](5) NOT NULL
		, [TPRank] [char](3) NOT NULL
		, [PDCD] [char](5) NOT NULL
		, [Quantity] [int] NOT NULL
		, [ORNo] [char](12) NOT NULL
		, [OPNo] [char](5) NOT NULL
		, [Delete_Flag] [char](1) NOT NULL
		, [Timestamp_Date] [datetime] NOT NULL
		, [Timestamp_time] [int] NOT NULL
		, [SEQNO] [float] NOT NULL
		, [State_Flag] [int] NOT NULL
	);
	-- /* Declare @Table5 WH_UKEBA */
	DECLARE @table_wh_ukeba TABLE(
		[History_ID] [int] NOT NULL
		, [History_At] [datetime] NOT NULL
		, [Host_Name] [varchar](50) NULL
		, [History_Class] [int] NOT NULL
		, [Record_Class] [char](2) NOT NULL
		, [ROHM_Model_Name] [char](20) NULL
		, [LotNo] [char](10) NULL
		, [OccurDate] [datetime] NULL
		, [R_Fukuoka_Model_Name] [char](20) NULL
		, [Rank] [char](5) NULL
		, [TPRank] [char](3) NULL
		, [RED_BLACK_Flag] [char](1) NULL
		, [QTY] [int] NULL
		, [StockQTY] [int] NULL
		, [Warehouse_Code] [char](5) NULL
		, [ORNo] [char](12) NULL
		, [OPNO] [char](5) NULL
		, [PROC1] [char](6) NULL
		, [Making_Date_Date] [datetime] NULL
		, [Making_Date_Time] [int] NULL
		, [Data__send_Flag] [smallint] NULL
		, [Delete_Flag] [char](1) NULL
		, [TimeStamp_date] [datetime] NULL
		, [TimeStamp_time] [int] NULL
		, [SEQNO] [float] NULL
		, [State_Flag] [int] NOT NULL
	);
	-- /* Declare @Table6 WORK_R_DB */
	DECLARE @table_work_r_db TABLE(
		[History_ID] [int] NOT NULL
		, [History_At] [datetime] NOT NULL
		, [Host_Name] [varchar](50) NULL
		, [History_Class] [int] NOT NULL
		, [LotNo] [char](10) NOT NULL
		, [Process_No] [int] NOT NULL
		, [Process_Date] [datetime] NOT NULL
		, [Process_Time] [char](6) NOT NULL
		, [Back_Process_No] [int] NOT NULL
		, [Good_QTY] [int] NOT NULL
		, [NG_QTY] [int] NOT NULL
		, [NG_QTY1] [int] NOT NULL
		, [Cause_Code_of_NG1] [char](3) NOT NULL
		, [NG_QTY2] [int] NOT NULL
		, [Cause_Code_of_NG2] [char](3) NOT NULL
		, [NG_QTY3] [int] NOT NULL
		, [Cause_Code_of_NG3] [char](3) NOT NULL
		, [NG_QTY4] [int] NOT NULL
		, [Cause_Code_of_NG4] [char](3) NOT NULL
		, [Shipment_QTY] [int] NOT NULL
		, [OPNo] [char](5) NOT NULL
		, [TERM_ID] [smallint] NOT NULL
		, [TimeStamp_Date] [datetime] NOT NULL
		, [TimeStamp_Time] [char](6) NOT NULL
		, [Send_Flag] [char](1) NOT NULL
		, [Making_Date] [datetime] NOT NULL
		, [Making_Time] [char](6) NOT NULL
		, [SEQNO_SQL10] [float] NOT NULL
		, [State_Flag] [int] NOT NULL
	);
	-- /* Declare @Table7 PROCESS_RECALL */
	DECLARE @table_process_recall TABLE(
		[History_ID] [int] NOT NULL
		, [History_At] [datetime] NOT NULL
		, [Host_Name] [varchar](50) NULL
		, [History_Class] [int] NOT NULL
		, [LOTNO] [char](10) NOT NULL
		, [TYPE] [char](20) NULL
		, [DEVICE] [char](20) NULL
		, [PD] [char](10) NULL
		, [MM] [char](10) NULL
		, [SEQNO] [int] NOT NULL
		, [OPNAME] [char](20) NOT NULL
		, [ABNORMALCASE] [char](30) NULL
		, [STDQTY] [int] NULL
		, [HASUUQTY] [int] NULL
		, [FLAG] [char](1) NULL
		, [DATES] [datetime] NULL
		, [TIMER] [int] NULL
		, [FINAL_STD_QTY] [int] NULL
		, [FINAL_HASUU_QTY] [int] NULL
		, [NEWLOT] [char](10) NULL
		, [NEWQTY] [int] NULL
		, [NEWPDCD] [char](5) NULL
		, [RECALL_FIN_DATE] [datetime] NULL
		, [RECALL_FIN_TIME] [int] NULL
		, [WH_OP_RECALL] [char](5) NULL
		, [WH_CANCEL_RECALL] [char](5) NOT NULL
		, [DATE_CANCEL_RECALL] [datetime] NOT NULL
		, [TIME_CANCEL_RECALL] [int] NOT NULL
		, [FLAG_CANCEL_RECALL] [char](1) NULL
		, [State_Flag] [int] NOT NULL
	)
	-------------------------------------------------------------------------------------------------------
	-- (2) Insert data to @Table
	-------------------------------------------------------------------------------------------------------
	PRINT '<---- Insert @Table';
	-- /* Insert @Table1 H_STOCK */
	PRINT 'Insert @Table1 H_STOCK';
	INSERT INTO @table_h_stock
	SELECT * FROM APCSProDWH.dbo.H_STOCK_IF_HIST
	WHERE State_Flag = 0;
	-- /* Insert @Table2 LSI_SHIP */
	PRINT 'Insert @Table2 LSI_SHIP';
	INSERT INTO @table_lsi_ship
	SELECT * FROM APCSProDWH.dbo.LSI_SHIP_IF_HIST
	WHERE State_Flag = 0;
	-- /* Insert @Table3 MIX_HIST */
	PRINT 'Insert @Table3 MIX_HIST';
	INSERT INTO @table_mix_hist
	SELECT * FROM APCSProDWH.dbo.MIX_HIST_IF_HIST
	WHERE State_Flag = 0 AND History_Class in (1,3); -- History_Class 1:Insert 2:Update 3:Delete
	-- /* Insert @Table4 PACKWORK */
	PRINT 'Insert @Table4 PACKWORK';
	INSERT INTO @table_packwork
	SELECT * FROM APCSProDWH.dbo.PACKWORK_IF_HIST
	WHERE State_Flag = 0 AND History_Class in (1,3); -- History_Class 1:Insert 2:Update 3:Delete
	-- /* Insert @Table5 WH_UKEBA */
	PRINT 'Insert @Table5 WH_UKEBA';
	INSERT INTO @table_wh_ukeba
	SELECT * FROM APCSProDWH.dbo.WH_UKEBA_IF_HIST
	WHERE State_Flag = 0;
	-- /* Insert @Table6 WORK_R_DB */
	PRINT 'Insert @Table6 WORK_R_DB';
	INSERT INTO @table_work_r_db
	SELECT * FROM APCSProDWH.dbo.WORK_R_DB_IF_HIST
	WHERE State_Flag = 0 AND History_Class in (1,3); -- History_Class 1:Insert 2:Update 3:Delete
	-- /* Insert @Table7 PROCESS_RECALL */
	PRINT 'Insert @Table7 PROCESS_RECALL';
	INSERT INTO @table_process_recall
	SELECT * FROM APCSProDWH.dbo.PROCESS_RECALL_IF_HIST
	WHERE State_Flag = 0 AND History_Class in (1,3); -- History_Class 1:Insert 2:Update 3:Delete
	
	-------------------------------------------------------------------------------------------------------
	-- (3) Declare cursor
	-------------------------------------------------------------------------------------------------------
	PRINT '<---- Declare cursor';
	-- /* Declare cursor H_STOCK */
	DECLARE @h_History_ID INT 
		, @h_History_At DATETIME 
		, @h_Host_Name VARCHAR(50)
		, @h_History_Class INT 
		, @h_Stock_Class CHAR(2) 
		, @h_PDCD CHAR(5) 
		, @h_LotNo CHAR(10) 
		, @h_Type_Name CHAR(10) 
		, @h_ROHM_Model_Name CHAR(20) 
		, @h_ASSY_Model_Name CHAR(20) 
		, @h_R_Fukuoka_Model_Name CHAR(20) 
		, @h_TIRank CHAR(5) 
		, @h_Rank CHAR(5) 
		, @h_TPRank CHAR(3) 
		, @h_SUBRank CHAR(3) 
		, @h_Mask CHAR(2) 
		, @h_KNo CHAR(3) 
		, @h_MNo CHAR(10) 
		, @h_ORNo CHAR(12) 
		, @h_Packing_Standerd_QTY INT 
		, @h_Tomson_Mark_1 CHAR(4) 
		, @h_Tomson_Mark_2 CHAR(4) 
		, @h_Tomson_Mark_3 CHAR(4) 
		, @h_WFLotNo CHAR(20) 
		, @h_LotNo_Class CHAR(1) 
		, @h_User_Code CHAR(4) 
		, @h_Product_Control_Clas CHAR(3) 
		, @h_Product_Class CHAR(1) 
		, @h_Production_Class CHAR(1) 
		, @h_Rank_No CHAR(6) 
		, @h_HINSYU_Class CHAR(1) 
		, @h_Label_Class CHAR(1) 
		, @h_HASU_Stock_QTY INT 
		, @h_HASU_WIP_QTY INT 
		, @h_HASUU_Working_Flag CHAR(1) 
		, @h_OUT_OUT_FLAG CHAR(1) 
		, @h_Label_Confirm_Class CHAR(1) 
		, @h_OPNo CHAR(5) 
		, @h_DMY_IN__Flag CHAR(1) 
		, @h_DMY_OUT_Flag CHAR(1) 
		, @h_Derivery_Date DATETIME 
		, @h_Derivery_Time INT 
		, @h_Timestamp_Date DATETIME 
		, @h_Timestamp_Time INT 
		, @h_State_Flag INT;
	-- /* Declare cursor LSI_SHIP */
	DECLARE @l_History_ID INT 
		, @l_History_At DATETIME 
		, @l_Host_Name VARCHAR(50)
		, @l_History_Class INT 
		, @l_LotNo CHAR(10) 
		, @l_Type_Name CHAR(10) 
		, @l_ROHM_Model_Name CHAR(20) 
		, @l_ASSY_Model_Name CHAR(20) 
		, @l_R_Fukuoka_Model_Name CHAR(20) 
		, @l_TIRank CHAR(5) 
		, @l_Rank CHAR(5) 
		, @l_TPRank CHAR(3) 
		, @l_SUBRank CHAR(3) 
		, @l_PDCD CHAR(5) 
		, @l_Mask CHAR(2) 
		, @l_KNo CHAR(3) 
		, @l_MNo CHAR(10) 
		, @l_ORNo CHAR(12) 
		, @l_Packing_Standerd_QTY INT 
		, @l_Tomson1 CHAR(4) 
		, @l_Tomson2 CHAR(4) 
		, @l_Tomson3 CHAR(4) 
		, @l_WFLotNo CHAR(20) 
		, @l_LotNo_Class CHAR(1) 
		, @l_User_Code CHAR(4) 
		, @l_Product_Control_Clas CHAR(3) 
		, @l_Product_Class CHAR(1) 
		, @l_Production_Class CHAR(1) 
		, @l_Rank_No CHAR(6) 
		, @l_HINSYU_Class CHAR(1) 
		, @l_Label_Class CHAR(1) 
		, @l_Standard_LotNo CHAR(10) 
		, @l_Complement_LotNo_1 CHAR(10) 
		, @l_Complement_LotNo_2 CHAR(10) 
		, @l_Complement_LotNo_3 CHAR(10) 
		, @l_Standard_MNo CHAR(10) 
		, @l_Complement_MNo_1 CHAR(10) 
		, @l_Complement_MNo_2 CHAR(10) 
		, @l_Complement_MNo_3 CHAR(10) 
		, @l_Standerd_QTY INT 
		, @l_Complement_QTY_1 INT 
		, @l_Complement_QTY_2 INT 
		, @l_Complement_QTY_3 INT 
		, @l_Shipment_QTY INT 
		, @l_Good_Product_QTY INT 
		, @l_Used_Fin_Packing_QTY INT 
		, @l_HASUU_Out_Flag CHAR(1) 
		, @l_OUT_OUT_FLAG CHAR(1) 
		, @l_Stock_Class CHAR(2) 
		, @l_Label_Confirm_Class CHAR(1) 
		, @l_allocation_Date DATETIME 
		, @l_Delete_Flag CHAR(1) 
		, @l_OPNo CHAR(5) 
		, @l_Timestamp_Date DATETIME 
		, @l_Timestamp_Time INT 
		, @l_State_Flag INT; 
	-- /* Declare cursor MIX_HIST */
	DECLARE @m_History_ID INT
		, @m_History_At DATETIME
		, @m_Host_Name VARCHAR(50)
		, @m_History_Class INT
		, @m_M_O_No CHAR(10)
		, @m_FREQ CHAR(2)
		, @m_HASUU_LotNo CHAR(10)
		, @m_LotNo CHAR(10)
		, @m_P_O_No CHAR(20)
		, @m_Stock_Class CHAR(2)
		, @m_Type_Name CHAR(10)
		, @m_ROHM_Model_Name CHAR(20)
		, @m_PDCD CHAR(5)
		, @m_ASSY_Model_Name CHAR(20)
		, @m_R_Fukuoka_Model_Name CHAR(20)
		, @m_TIRank CHAR(5)
		, @m_Rank CHAR(5)
		, @m_TPRank CHAR(3)
		, @m_SUBRank CHAR(3)
		, @m_Mask CHAR(2)
		, @m_KNo CHAR(3)
		, @m_MNo CHAR(10)
		, @m_Tomson1 CHAR(4)
		, @m_Tomson2 CHAR(4)
		, @m_Tomson3 CHAR(4)
		, @m_allocation_Date DATETIME
		, @m_ORNo CHAR(12)
		, @m_WFLotNo CHAR(20)
		, @m_User_Code CHAR(4)
		, @m_LotNo_Class CHAR(1)
		, @m_Label_Class CHAR(1)
		, @m_Multi_Class CHAR(1)
		, @m_Product_Control_Clas CHAR(3)
		, @m_Packing_Standerd_QTY INT
		, @m_Date_Code CHAR(3)
		, @m_HASUU_Out_Flag CHAR(1)
		, @m_QTY INT
		, @m_Transfer_Flag CHAR(1)
		, @m_Transfer INT
		, @m_OPNo CHAR(5)
		, @m_Theoretical CHAR(1)
		, @m_OUT_OUT_FLAG CHAR(1)
		, @m_MIXD_DATE DATETIME 
		, @m_TimeStamp_date DATETIME
		, @m_TimeStamp_time INT
		, @m_State_Flag INT;
	-- /* Declare cursor PACKWORK */
	DECLARE @p_History_ID INT
		, @p_History_At DATETIME
		, @p_Host_Name VARCHAR(50)
		, @p_History_Class INT
		, @p_LotNo CHAR(10)
		, @p_Type_Name CHAR(10) 
		, @p_ROHM_Model_Name CHAR(20)
		, @p_R_Fukuoka_Model_Name CHAR(20)
		, @p_Rank CHAR(5)
		, @p_TPRank CHAR(3)
		, @p_PDCD CHAR(5)
		, @p_Quantity INT
		, @p_ORNo CHAR(12)
		, @p_OPNo CHAR(5)
		, @p_Delete_Flag CHAR(1)
		, @p_Timestamp_Date DATETIME
		, @p_Timestamp_time INT
		, @p_SEQNO FLOAT
		, @p_State_Flag INT;
	-- /* Declare cursor WH_UKEBA */
	DECLARE @wh_History_ID INT
		, @wh_History_At DATETIME
		, @wh_Host_Name VARCHAR(50)
		, @wh_History_Class INT
		, @wh_Record_Class CHAR(2)
		, @wh_ROHM_Model_Name CHAR(20)
		, @wh_LotNo CHAR(10)
		, @wh_OccurDate DATETIME
		, @wh_R_Fukuoka_Model_Name CHAR(20)
		, @wh_Rank CHAR(5)
		, @wh_TPRank CHAR(3)
		, @wh_RED_BLACK_Flag CHAR(1)
		, @wh_QTY INT
		, @wh_StockQTY INT
		, @wh_Warehouse_Code CHAR(5)
		, @wh_ORNo CHAR(12)
		, @wh_OPNO CHAR(5)
		, @wh_PROC1 CHAR(6)
		, @wh_Making_Date_Date DATETIME
		, @wh_Making_Date_Time INT
		, @wh_Data__send_Flag SMALLINT
		, @wh_Delete_Flag CHAR(1)
		, @wh_TimeStamp_date DATETIME
		, @wh_TimeStamp_time INT
		, @wh_SEQNO FLOAT
		, @wh_State_Flag INT;
	-- /* Declare cursor WORK_R_DB */
	DECLARE @w_History_ID INT
		, @w_History_At DATETIME
		, @w_Host_Name VARCHAR(50)
		, @w_History_Class INT
		, @w_LotNo CHAR(10)
		, @w_Process_No INT
		, @w_Process_Date DATETIME
		, @w_Process_Time CHAR(6)
		, @w_Back_Process_No INT
		, @w_Good_QTY INT
		, @w_NG_QTY INT
		, @w_NG_QTY1 INT
		, @w_Cause_Code_of_NG1 CHAR(3)
		, @w_NG_QTY2 INT
		, @w_Cause_Code_of_NG2 CHAR(3)
		, @w_NG_QTY3 INT
		, @w_Cause_Code_of_NG3 CHAR(3)
		, @w_NG_QTY4 INT
		, @w_Cause_Code_of_NG4 CHAR(3)
		, @w_Shipment_QTY INT
		, @w_OPNo CHAR(5) 
		, @w_TERM_ID SMALLINT
		, @w_TimeStamp_Date DATETIME
		, @w_TimeStamp_Time CHAR(6)
		, @w_Send_Flag CHAR(1)
		, @w_Making_Date DATETIME
		, @w_Making_Time CHAR(6)
		, @w_SEQNO_SQL10 FLOAT
		, @w_State_Flag INT;
	-- /* Declare cursor PROCESS_RECALL */
	DECLARE @pr_History_ID INT
		, @pr_History_At DATETIME
		, @pr_Host_Name VARCHAR(50)
		, @pr_History_Class INT
		, @pr_LOTNO CHAR(10)
		, @pr_TYPE CHAR(20)
		, @pr_DEVICE CHAR(20)
		, @pr_PD CHAR(10)
		, @pr_MM CHAR(10)
		, @pr_SEQNO INT
		, @pr_OPNAME CHAR(20)
		, @pr_ABNORMALCASE CHAR(30)
		, @pr_STDQTY INT
		, @pr_HASUUQTY INT
		, @pr_FLAG CHAR(1)
		, @pr_DATES DATETIME
		, @pr_TIMER INT
		, @pr_FINAL_STD_QTY INT
		, @pr_FINAL_HASUU_QTY INT
		, @pr_NEWLOT CHAR(10)
		, @pr_NEWQTY INT
		, @pr_NEWPDCD CHAR(5)
		, @pr_RECALL_FIN_DATE DATETIME
		, @pr_RECALL_FIN_TIME INT
		, @pr_WH_OP_RECALL CHAR(5)
		, @pr_WH_CANCEL_RECALL CHAR(5)
		, @pr_DATE_CANCEL_RECALL DATETIME
		, @pr_TIME_CANCEL_RECALL INT
		, @pr_FLAG_CANCEL_RECALL CHAR(1) 
		, @pr_State_Flag INT

	-------------------------------------------------------------------------------------------------------
	-- (4) Cursor
	-------------------------------------------------------------------------------------------------------
	PRINT '<---- Cursor';

	--------------------------------------------------- /* Cursor H_STOCK */ ---------------------------------------------------
	IF (@IS_H_STOCK = 1)
	BEGIN
		PRINT '-- Cursor H_STOCK';
		-- Cursor Table
		DECLARE cursor_h_stock_if CURSOR FOR 
		SELECT * FROM @table_h_stock
		ORDER BY History_ID;
		-- Open cursor
		OPEN cursor_h_stock_if
		FETCH NEXT FROM cursor_h_stock_if
		INTO @h_History_ID  
			, @h_History_At  
			, @h_Host_Name
			, @h_History_Class  
			, @h_Stock_Class  
			, @h_PDCD  
			, @h_LotNo 
			, @h_Type_Name  
			, @h_ROHM_Model_Name 
			, @h_ASSY_Model_Name  
			, @h_R_Fukuoka_Model_Name 
			, @h_TIRank  
			, @h_Rank  
			, @h_TPRank 
			, @h_SUBRank  
			, @h_Mask 
			, @h_KNo  
			, @h_MNo 
			, @h_ORNo  
			, @h_Packing_Standerd_QTY 
			, @h_Tomson_Mark_1  
			, @h_Tomson_Mark_2 
			, @h_Tomson_Mark_3  
			, @h_WFLotNo 
			, @h_LotNo_Class 
			, @h_User_Code 
			, @h_Product_Control_Clas 
			, @h_Product_Class 
			, @h_Production_Class 
			, @h_Rank_No 
			, @h_HINSYU_Class 
			, @h_Label_Class  
			, @h_HASU_Stock_QTY 
			, @h_HASU_WIP_QTY 
			, @h_HASUU_Working_Flag
			, @h_OUT_OUT_FLAG
			, @h_Label_Confirm_Class
			, @h_OPNo
			, @h_DMY_IN__Flag 
			, @h_DMY_OUT_Flag 
			, @h_Derivery_Date 
			, @h_Derivery_Time 
			, @h_Timestamp_Date 
			, @h_Timestamp_Time 
			, @h_State_Flag 
		-- Loop cursor
		WHILE (@@FETCH_STATUS = 0) -- @@FETCH_STATUS -1 End, 0 Loop 
		BEGIN 
			IF (@h_History_Class = 1) -- Insert
			BEGIN
				-- Insert
				IF NOT EXISTS(SELECT [LotNo] FROM [ISDB].[DBLSISHT].[dbo].[H_STOCK] WHERE [LotNo] = @h_LotNo)
				BEGIN
					PRINT 'Insert H_STOCK LotNo : ' + @h_LotNo;
					INSERT INTO [ISDB].[DBLSISHT].[dbo].[H_STOCK]
					(
						[Stock_Class]
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
						, [Tomson_Mark_1]
						, [Tomson_Mark_2]
						, [Tomson_Mark_3]
						, [WFLotNo]
						, [LotNo_Class]
						, [User_Code]
						, [Product_Control_Clas]
						, [Product_Class]
						, [Production_Class]
						, [Rank_No]
						, [HINSYU_Class]
						, [Label_Class]
						, [HASU_Stock_QTY]
						, [HASU_WIP_QTY]
						, [HASUU_Working_Flag]
						, [OUT_OUT_FLAG]
						, [Label_Confirm_Class]
						, [OPNo]
						, [DMY_IN__Flag]
						, [DMY_OUT_Flag]
						, [Derivery_Date]
						, [Derivery_Time]
						, [Timestamp_Date]
						, [Timestamp_Time]
					)
					SELECT @h_Stock_Class
						, @h_PDCD
						, @h_LotNo
						, @h_Type_Name
						, @h_ROHM_Model_Name
						, @h_ASSY_Model_Name
						, @h_R_Fukuoka_Model_Name
						, @h_TIRank
						, @h_Rank
						, @h_TPRank
						, @h_SUBRank
						, @h_Mask
						, @h_KNo
						, @h_MNo
						, @h_ORNo 
						, @h_Packing_Standerd_QTY
						, @h_Tomson_Mark_1
						, @h_Tomson_Mark_2
						, @h_Tomson_Mark_3
						, @h_WFLotNo
						, @h_LotNo_Class
						, @h_User_Code
						, @h_Product_Control_Clas
						, @h_Product_Class
						, @h_Production_Class
						, @h_Rank_No
						, @h_HINSYU_Class
						, @h_Label_Class
						, @h_HASU_Stock_QTY
						, @h_HASU_WIP_QTY
						, @h_HASUU_Working_Flag
						, @h_OUT_OUT_FLAG
						, @h_Label_Confirm_Class
						, @h_OPNo
						, @h_DMY_IN__Flag
						, @h_DMY_OUT_Flag
						, @h_Derivery_Date
						, @h_Derivery_Time
						, @h_Timestamp_Date
						, @h_Timestamp_Time;
				END
				------------------------------------------------------------------------------------
				PRINT 'Update H_STOCK_IF_HIST History_ID : ' + CAST(@h_History_ID AS VARCHAR) + ', LotNo : ' + @h_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.H_STOCK_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @h_History_ID;
			END
			ELSE IF (@h_History_Class = 2) -- Update
			BEGIN
				-- Update
				PRINT 'Update H_STOCK LotNo : ' + @h_LotNo;
				UPDATE [ISDB].[DBLSISHT].[dbo].[H_STOCK]
				SET  [HASU_Stock_QTY] = @h_HASU_Stock_QTY
					, [HASU_WIP_QTY] = @h_HASU_WIP_QTY 
					, [DMY_IN__Flag] = @h_DMY_IN__Flag
					, [DMY_OUT_Flag] = @h_DMY_OUT_Flag
				WHERE [LotNo] = @h_LotNo;
				------------------------------------------------------------------------------------
				PRINT 'Update H_STOCK_IF_HIST History_ID : ' + CAST(@h_History_ID AS VARCHAR) + ', LotNo : ' + @h_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.H_STOCK_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @h_History_ID;
			END
			ELSE IF (@h_History_Class = 3) -- Delete
			BEGIN
				-- Delete
				PRINT 'Delete H_STOCK LotNo : ' + @h_LotNo;
				DELETE FROM [ISDB].[DBLSISHT].[dbo].[H_STOCK]
				WHERE [LotNo] = @h_LotNo;
				------------------------------------------------------------------------------------
				PRINT 'Update H_STOCK_IF_HIST History_ID : ' + CAST(@h_History_ID AS VARCHAR) + ', LotNo : ' + @h_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.H_STOCK_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @h_History_ID;
			END

			-- Next cursor
			FETCH NEXT FROM cursor_h_stock_if -- Fetch next cursor
			INTO @h_History_ID  
				, @h_History_At
				, @h_Host_Name
				, @h_History_Class  
				, @h_Stock_Class  
				, @h_PDCD  
				, @h_LotNo 
				, @h_Type_Name  
				, @h_ROHM_Model_Name 
				, @h_ASSY_Model_Name  
				, @h_R_Fukuoka_Model_Name 
				, @h_TIRank  
				, @h_Rank  
				, @h_TPRank 
				, @h_SUBRank  
				, @h_Mask 
				, @h_KNo  
				, @h_MNo 
				, @h_ORNo  
				, @h_Packing_Standerd_QTY 
				, @h_Tomson_Mark_1  
				, @h_Tomson_Mark_2 
				, @h_Tomson_Mark_3  
				, @h_WFLotNo 
				, @h_LotNo_Class 
				, @h_User_Code 
				, @h_Product_Control_Clas 
				, @h_Product_Class 
				, @h_Production_Class 
				, @h_Rank_No 
				, @h_HINSYU_Class 
				, @h_Label_Class  
				, @h_HASU_Stock_QTY 
				, @h_HASU_WIP_QTY 
				, @h_HASUU_Working_Flag
				, @h_OUT_OUT_FLAG
				, @h_Label_Confirm_Class
				, @h_OPNo
				, @h_DMY_IN__Flag 
				, @h_DMY_OUT_Flag 
				, @h_Derivery_Date 
				, @h_Derivery_Time 
				, @h_Timestamp_Date 
				, @h_Timestamp_Time 
				, @h_State_Flag;  -- Next into variable
		END
		-- Close cursor
		CLOSE cursor_h_stock_if; 
		DEALLOCATE cursor_h_stock_if; 
	END
	ELSE
	BEGIN
		PRINT '-- Disable Cursor H_STOCK';
	END
	--------------------------------------------------- /* Cursor LSI_SHIP */ ---------------------------------------------------
	IF (@IS_LSI_SHIP = 1)
	BEGIN
		PRINT '-- Cursor LSI_SHIP';
		-- Cursor Table
		DECLARE cursor_lsi_ship_if CURSOR FOR 
		SELECT * FROM @table_lsi_ship
		ORDER BY History_ID;
		-- Open cursor
		OPEN cursor_lsi_ship_if
		FETCH NEXT FROM cursor_lsi_ship_if
		INTO @l_History_ID
			, @l_History_At
			, @l_Host_Name
			, @l_History_Class
			, @l_LotNo 
			, @l_Type_Name 
			, @l_ROHM_Model_Name
			, @l_ASSY_Model_Name
			, @l_R_Fukuoka_Model_Name
			, @l_TIRank 
			, @l_Rank
			, @l_TPRank 
			, @l_SUBRank
			, @l_PDCD 
			, @l_Mask
			, @l_KNo 
			, @l_MNo
			, @l_ORNo
			, @l_Packing_Standerd_QTY
			, @l_Tomson1
			, @l_Tomson2
			, @l_Tomson3
			, @l_WFLotNo
			, @l_LotNo_Class 
			, @l_User_Code 
			, @l_Product_Control_Clas
			, @l_Product_Class 
			, @l_Production_Class
			, @l_Rank_No
			, @l_HINSYU_Class
			, @l_Label_Class
			, @l_Standard_LotNo
			, @l_Complement_LotNo_1
			, @l_Complement_LotNo_2
			, @l_Complement_LotNo_3
			, @l_Standard_MNo
			, @l_Complement_MNo_1
			, @l_Complement_MNo_2
			, @l_Complement_MNo_3
			, @l_Standerd_QTY
			, @l_Complement_QTY_1
			, @l_Complement_QTY_2
			, @l_Complement_QTY_3
			, @l_Shipment_QTY
			, @l_Good_Product_QTY
			, @l_Used_Fin_Packing_QTY
			, @l_HASUU_Out_Flag
			, @l_OUT_OUT_FLAG
			, @l_Stock_Class 
			, @l_Label_Confirm_Class
			, @l_allocation_Date
			, @l_Delete_Flag
			, @l_OPNo
			, @l_Timestamp_Date
			, @l_Timestamp_Time
			, @l_State_Flag
		-- Loop cursor
		WHILE (@@FETCH_STATUS = 0) -- @@FETCH_STATUS -1 End, 0 Loop 
		BEGIN 
			IF (@l_History_Class = 1) -- Insert
			BEGIN
				-- Insert
				IF NOT EXISTS(SELECT [LotNo] FROM [ISDB].[DBLSISHT].[dbo].[LSI_SHIP] WHERE [LotNo] = @l_LotNo)
				BEGIN
					PRINT 'Insert LSI_SHIP LotNo : ' + @l_LotNo;
					INSERT INTO [ISDB].[DBLSISHT].[dbo].[LSI_SHIP]
					(
						[LotNo]
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
						, [Product_Control_Clas]
						, [Product_Class]
						, [Production_Class]
						, [Rank_No]
						, [HINSYU_Class]
						, [Label_Class]
						, [Standard_LotNo]
						, [Complement_LotNo_1]
						, [Complement_LotNo_2]
						, [Complement_LotNo_3]
						, [Standard_MNo]
						, [Complement_MNo_1]
						, [Complement_MNo_2]
						, [Complement_MNo_3]
						, [Standerd_QTY]
						, [Complement_QTY_1]
						, [Complement_QTY_2]
						, [Complement_QTY_3]
						, [Shipment_QTY]
						, [Good_Product_QTY]
						, [Used_Fin_Packing_QTY]
						, [HASUU_Out_Flag]
						, [OUT_OUT_FLAG]
						, [Stock_Class]
						, [Label_Confirm_Class]
						, [allocation_Date]
						, [Delete_Flag]
						, [OPNo]
						, [Timestamp_Date]
						, [Timestamp_Time]
					)
					SELECT @l_LotNo 
						, @l_Type_Name 
						, @l_ROHM_Model_Name
						, @l_ASSY_Model_Name
						, @l_R_Fukuoka_Model_Name
						, @l_TIRank 
						, @l_Rank
						, @l_TPRank 
						, @l_SUBRank
						, @l_PDCD 
						, @l_Mask
						, @l_KNo 
						, @l_MNo
						, @l_ORNo
						, @l_Packing_Standerd_QTY
						, @l_Tomson1
						, @l_Tomson2
						, @l_Tomson3
						, @l_WFLotNo
						, @l_LotNo_Class 
						, @l_User_Code 
						, @l_Product_Control_Clas
						, @l_Product_Class 
						, @l_Production_Class
						, @l_Rank_No
						, @l_HINSYU_Class
						, @l_Label_Class
						, @l_Standard_LotNo
						, @l_Complement_LotNo_1
						, @l_Complement_LotNo_2
						, @l_Complement_LotNo_3
						, @l_Standard_MNo
						, @l_Complement_MNo_1
						, @l_Complement_MNo_2
						, @l_Complement_MNo_3
						, @l_Standerd_QTY
						, @l_Complement_QTY_1
						, @l_Complement_QTY_2
						, @l_Complement_QTY_3
						, @l_Shipment_QTY
						, @l_Good_Product_QTY
						, @l_Used_Fin_Packing_QTY
						, @l_HASUU_Out_Flag
						, @l_OUT_OUT_FLAG
						, @l_Stock_Class 
						, @l_Label_Confirm_Class
						, @l_allocation_Date
						, @l_Delete_Flag
						, @l_OPNo
						, @l_Timestamp_Date
						, @l_Timestamp_Time
				END
				------------------------------------------------------------------------------------
				PRINT 'Update LSI_SHIP_IF_HIST History_ID : ' + CAST(@l_History_ID AS VARCHAR) + ', LotNo : ' + @l_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.LSI_SHIP_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @l_History_ID;
			END
			ELSE IF (@l_History_Class = 2) -- Update
			BEGIN
				-- Update
				PRINT 'Update LSI_SHIP LotNo : ' + @l_LotNo;
				UPDATE [ISDB].[DBLSISHT].[dbo].[LSI_SHIP]
				SET [Shipment_QTY] = @l_Shipment_QTY
					, [Good_Product_QTY] = @l_Good_Product_QTY
					, [Delete_Flag] = @l_Delete_Flag
				WHERE [LotNo] = @l_LotNo;
				------------------------------------------------------------------------------------
				PRINT 'Update LSI_SHIP_IF_HIST History_ID : ' + CAST(@l_History_ID AS VARCHAR) + ', LotNo : ' + @l_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.LSI_SHIP_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @l_History_ID;
			END
			ELSE IF (@l_History_Class = 3) -- Delete
			BEGIN
				-- Delete
				PRINT 'Delete LSI_SHIP LotNo : ' + @l_LotNo;
				DELETE FROM [ISDB].[DBLSISHT].[dbo].[LSI_SHIP]
				WHERE [LotNo] = @l_LotNo; 
				------------------------------------------------------------------------------------
				PRINT 'Update LSI_SHIP_IF_HIST History_ID : ' + CAST(@l_History_ID AS VARCHAR) + ', LotNo : ' + @l_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.LSI_SHIP_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @l_History_ID;
			END

			-- Next cursor
			FETCH NEXT FROM cursor_lsi_ship_if -- Fetch next cursor
			INTO @l_History_ID
				, @l_History_At
				, @l_Host_Name
				, @l_History_Class
				, @l_LotNo 
				, @l_Type_Name 
				, @l_ROHM_Model_Name
				, @l_ASSY_Model_Name
				, @l_R_Fukuoka_Model_Name
				, @l_TIRank 
				, @l_Rank
				, @l_TPRank 
				, @l_SUBRank
				, @l_PDCD 
				, @l_Mask
				, @l_KNo 
				, @l_MNo
				, @l_ORNo
				, @l_Packing_Standerd_QTY
				, @l_Tomson1
				, @l_Tomson2
				, @l_Tomson3
				, @l_WFLotNo
				, @l_LotNo_Class 
				, @l_User_Code 
				, @l_Product_Control_Clas
				, @l_Product_Class 
				, @l_Production_Class
				, @l_Rank_No
				, @l_HINSYU_Class
				, @l_Label_Class
				, @l_Standard_LotNo
				, @l_Complement_LotNo_1
				, @l_Complement_LotNo_2
				, @l_Complement_LotNo_3
				, @l_Standard_MNo
				, @l_Complement_MNo_1
				, @l_Complement_MNo_2
				, @l_Complement_MNo_3
				, @l_Standerd_QTY
				, @l_Complement_QTY_1
				, @l_Complement_QTY_2
				, @l_Complement_QTY_3
				, @l_Shipment_QTY
				, @l_Good_Product_QTY
				, @l_Used_Fin_Packing_QTY
				, @l_HASUU_Out_Flag
				, @l_OUT_OUT_FLAG
				, @l_Stock_Class 
				, @l_Label_Confirm_Class
				, @l_allocation_Date
				, @l_Delete_Flag
				, @l_OPNo
				, @l_Timestamp_Date
				, @l_Timestamp_Time
				, @l_State_Flag;  -- Next into variable
		END
		-- Close cursor
		CLOSE cursor_lsi_ship_if; 
		DEALLOCATE cursor_lsi_ship_if; 
	END
	ELSE
	BEGIN
		PRINT '-- Disable Cursor LSI_SHIP';
	END
	--------------------------------------------------- /* Cursor MIX_HIST */ ---------------------------------------------------
	IF (@IS_MIX_HIST = 1)
	BEGIN
		PRINT '-- Cursor MIX_HIST';
		-- Cursor Table
		DECLARE cursor_mix_hist__if CURSOR FOR 
		SELECT * FROM @table_mix_hist
		ORDER BY History_ID;
		-- Open cursor
		OPEN cursor_mix_hist__if
		FETCH NEXT FROM cursor_mix_hist__if
		INTO @m_History_ID
			, @m_History_At
			, @m_Host_Name
			, @m_History_Class
			, @m_M_O_No
			, @m_FREQ
			, @m_HASUU_LotNo
			, @m_LotNo
			, @m_P_O_No
			, @m_Stock_Class
			, @m_Type_Name
			, @m_ROHM_Model_Name
			, @m_PDCD
			, @m_ASSY_Model_Name
			, @m_R_Fukuoka_Model_Name
			, @m_TIRank
			, @m_Rank
			, @m_TPRank
			, @m_SUBRank
			, @m_Mask
			, @m_KNo
			, @m_MNo
			, @m_Tomson1
			, @m_Tomson2
			, @m_Tomson3 
			, @m_allocation_Date
			, @m_ORNo
			, @m_WFLotNo
			, @m_User_Code
			, @m_LotNo_Class
			, @m_Label_Class
			, @m_Multi_Class
			, @m_Product_Control_Clas
			, @m_Packing_Standerd_QTY
			, @m_Date_Code
			, @m_HASUU_Out_Flag
			, @m_QTY
			, @m_Transfer_Flag
			, @m_Transfer
			, @m_OPNo
			, @m_Theoretical
			, @m_OUT_OUT_FLAG
			, @m_MIXD_DATE
			, @m_TimeStamp_date
			, @m_TimeStamp_time
			, @m_State_Flag
		-- Loop cursor
		WHILE (@@FETCH_STATUS = 0) -- @@FETCH_STATUS -1 End, 0 Loop 
		BEGIN 
			IF (@m_History_Class = 1) -- Insert
			BEGIN
				-- Insert
				IF NOT EXISTS(SELECT [LotNo] FROM [ISDB].[DBLSISHT].[dbo].[MIX_HIST] WHERE [HASUU_LotNo] = @m_HASUU_LotNo AND [LotNo] = @m_LotNo)
				BEGIN
					PRINT 'Insert MIX_HIST HASUU_LotNo : ' + @m_HASUU_LotNo + ' LotNo : ' + @m_LotNo;
					INSERT INTO [ISDB].[DBLSISHT].[dbo].[MIX_HIST]
					(
						[M_O_No]
						, [FREQ]
						, [HASUU_LotNo]
						, [LotNo]
						, [P_O_No]
						, [Stock_Class]
						, [Type_Name]
						, [ROHM_Model_Name]
						, [PDCD]
						, [ASSY_Model_Name]
						, [R_Fukuoka_Model_Name]
						, [TIRank]
						, [Rank]
						, [TPRank]
						, [SUBRank]
						, [Mask]
						, [KNo]
						, [MNo]
						, [Tomson1]
						, [Tomson2]
						, [Tomson3]
						, [allocation_Date]
						, [ORNo]
						, [WFLotNo]
						, [User_Code]
						, [LotNo_Class]
						, [Label_Class]
						, [Multi_Class]
						, [Product_Control_Clas]
						, [Packing_Standerd_QTY]
						, [Date_Code]
						, [HASUU_Out_Flag]
						, [QTY]
						, [Transfer_Flag]
						, [Transfer]
						, [OPNo]
						, [Theoretical]
						, [OUT_OUT_FLAG]
						, [MIXD_DATE]
						, [TimeStamp_date]
						, [TimeStamp_time]
					)
					SELECT @m_M_O_No
						, @m_FREQ
						, @m_HASUU_LotNo
						, @m_LotNo
						, @m_P_O_No
						, @m_Stock_Class
						, @m_Type_Name
						, @m_ROHM_Model_Name
						, @m_PDCD
						, @m_ASSY_Model_Name
						, @m_R_Fukuoka_Model_Name
						, @m_TIRank
						, @m_Rank
						, @m_TPRank
						, @m_SUBRank
						, @m_Mask
						, @m_KNo
						, @m_MNo
						, @m_Tomson1
						, @m_Tomson2
						, @m_Tomson3 
						, @m_allocation_Date
						, @m_ORNo
						, @m_WFLotNo
						, @m_User_Code
						, @m_LotNo_Class
						, @m_Label_Class
						, @m_Multi_Class
						, @m_Product_Control_Clas
						, @m_Packing_Standerd_QTY
						, @m_Date_Code
						, @m_HASUU_Out_Flag
						, @m_QTY
						, @m_Transfer_Flag
						, @m_Transfer
						, @m_OPNo
						, @m_Theoretical
						, @m_OUT_OUT_FLAG
						, @m_MIXD_DATE
						, @m_TimeStamp_date
						, @m_TimeStamp_time
				END
				------------------------------------------------------------------------------------
				PRINT 'Update MIX_HIST_IF_HIST History_ID : ' + CAST(@m_History_ID AS VARCHAR) + ', LotNo : ' + @m_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.MIX_HIST_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @m_History_ID;
			END
			ELSE IF (@m_History_Class = 3) -- Delete
			BEGIN
				-- Delete
				PRINT 'Delete MIX_HIST HASUU_LotNo : ' + @m_HASUU_LotNo + ' LotNo : ' + @m_LotNo;
				DELETE FROM [ISDB].[DBLSISHT].[dbo].[MIX_HIST]
				WHERE HASUU_LotNo = @m_HASUU_LotNo AND LotNo = @m_LotNo;
				------------------------------------------------------------------------------------
				PRINT 'Update MIX_HIST_IF_HIST History_ID : ' + CAST(@m_History_ID AS VARCHAR) + ', LotNo : ' + @m_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.MIX_HIST_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @m_History_ID;
			END

			-- Next cursor
			FETCH NEXT FROM cursor_mix_hist__if -- Fetch next cursor
			INTO @m_History_ID
				, @m_History_At
				, @m_Host_Name
				, @m_History_Class
				, @m_M_O_No
				, @m_FREQ
				, @m_HASUU_LotNo
				, @m_LotNo
				, @m_P_O_No
				, @m_Stock_Class
				, @m_Type_Name
				, @m_ROHM_Model_Name
				, @m_PDCD
				, @m_ASSY_Model_Name
				, @m_R_Fukuoka_Model_Name
				, @m_TIRank
				, @m_Rank
				, @m_TPRank
				, @m_SUBRank
				, @m_Mask
				, @m_KNo
				, @m_MNo
				, @m_Tomson1
				, @m_Tomson2
				, @m_Tomson3 
				, @m_allocation_Date
				, @m_ORNo
				, @m_WFLotNo
				, @m_User_Code
				, @m_LotNo_Class
				, @m_Label_Class
				, @m_Multi_Class
				, @m_Product_Control_Clas
				, @m_Packing_Standerd_QTY
				, @m_Date_Code
				, @m_HASUU_Out_Flag
				, @m_QTY
				, @m_Transfer_Flag
				, @m_Transfer
				, @m_OPNo
				, @m_Theoretical
				, @m_OUT_OUT_FLAG
				, @m_MIXD_DATE
				, @m_TimeStamp_date
				, @m_TimeStamp_time
				, @m_State_Flag;  -- Next into variable
		END
		-- Close cursor
		CLOSE cursor_mix_hist__if; 
		DEALLOCATE cursor_mix_hist__if;
	END
	ELSE
	BEGIN
		PRINT '-- Disable Cursor MIX_HIST';
	END
	--------------------------------------------------- /* Cursor PACKWORK */ ---------------------------------------------------
	IF (@IS_PACKWORK = 1)
	BEGIN
		PRINT '-- Cursor PACKWORK';
		-- Cursor Table
		DECLARE cursor_packwork_if CURSOR FOR 
		SELECT * FROM @table_packwork
		ORDER BY History_ID;
		-- Open cursor
		OPEN cursor_packwork_if
		FETCH NEXT FROM cursor_packwork_if
		INTO @p_History_ID
			, @p_History_At
			, @p_Host_Name
			, @p_History_Class
			, @p_LotNo
			, @p_Type_Name
			, @p_ROHM_Model_Name
			, @p_R_Fukuoka_Model_Name
			, @p_Rank
			, @p_TPRank
			, @p_PDCD
			, @p_Quantity
			, @p_ORNo
			, @p_OPNo
			, @p_Delete_Flag
			, @p_Timestamp_Date
			, @p_Timestamp_time
			, @p_SEQNO
			, @p_State_Flag
		-- Loop cursor
		WHILE (@@FETCH_STATUS = 0) -- @@FETCH_STATUS -1 End, 0 Loop 
		BEGIN 
			IF (@p_History_Class = 1) -- Insert
			BEGIN
				-- Insert
				IF NOT EXISTS(SELECT [LotNo] FROM [ISDB].[DBLSISHT].[dbo].[PACKWORK] WHERE [LotNo] = @p_LotNo)
				BEGIN
					PRINT 'Insert PACKWORK LotNo : ' + @p_LotNo;
					INSERT INTO [ISDB].[DBLSISHT].[dbo].[PACKWORK]
					(
						[LotNo]
						, [Type_Name]
						, [ROHM_Model_Name]
						, [R_Fukuoka_Model_Name]
						, [Rank]
						, [TPRank]
						, [PDCD]
						, [Quantity]
						, [ORNo]
						, [OPNo]
						, [Delete_Flag]
						, [Timestamp_Date]
						, [Timestamp_time]
						, [SEQNO]
					)
					SELECT @p_LotNo
						, @p_Type_Name
						, @p_ROHM_Model_Name
						, @p_R_Fukuoka_Model_Name
						, @p_Rank
						, @p_TPRank
						, @p_PDCD
						, @p_Quantity
						, @p_ORNo
						, @p_OPNo
						, @p_Delete_Flag
						, @p_Timestamp_Date
						, @p_Timestamp_time
						, @p_SEQNO;
				END
				------------------------------------------------------------------------------------
				PRINT 'Update PACKWORK_IF_HIST History_ID : ' + CAST(@p_History_ID AS VARCHAR) + ', LotNo : ' + @p_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.PACKWORK_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @p_History_ID;
			END
			ELSE IF (@p_History_Class = 3) -- Delete
			BEGIN
				-- Delete
				PRINT 'Delete PACKWORK LotNo : ' + @p_LotNo;
				DELETE FROM [ISDB].[DBLSISHT].[dbo].[PACKWORK]
				WHERE [LotNo] = @p_LotNo;
				------------------------------------------------------------------------------------
				PRINT 'Update PACKWORK_IF_HIST History_ID : ' + CAST(@p_History_ID AS VARCHAR) + ', LotNo : ' + @p_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.PACKWORK_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @p_History_ID;
			END

			-- Next cursor
			FETCH NEXT FROM cursor_packwork_if -- Fetch next cursor
			INTO @p_History_ID
				, @p_History_At
				, @p_Host_Name
				, @p_History_Class
				, @p_LotNo
				, @p_Type_Name
				, @p_ROHM_Model_Name
				, @p_R_Fukuoka_Model_Name
				, @p_Rank
				, @p_TPRank
				, @p_PDCD
				, @p_Quantity
				, @p_ORNo
				, @p_OPNo
				, @p_Delete_Flag
				, @p_Timestamp_Date
				, @p_Timestamp_time
				, @p_SEQNO
				, @p_State_Flag;  -- Next into variable
		END
		-- Close cursor
		CLOSE cursor_packwork_if; 
		DEALLOCATE cursor_packwork_if; 
	END
	ELSE
	BEGIN
		PRINT '-- Disable Cursor PACKWORK';
	END
	--------------------------------------------------- /* Cursor WH_UKEBA */ ---------------------------------------------------
	IF (@IS_WH_UKEBA = 1)
	BEGIN
		PRINT '-- Cursor WH_UKEBA';
		-- Cursor Table
		DECLARE cursor_wh_ukeba_if CURSOR FOR 
		SELECT * FROM @table_wh_ukeba
		ORDER BY History_ID;
		-- Open cursor
		OPEN cursor_wh_ukeba_if
		FETCH NEXT FROM cursor_wh_ukeba_if
		INTO @wh_History_ID
			, @wh_History_At
			, @wh_Host_Name
			, @wh_History_Class
			, @wh_Record_Class
			, @wh_ROHM_Model_Name
			, @wh_LotNo
			, @wh_OccurDate
			, @wh_R_Fukuoka_Model_Name
			, @wh_Rank
			, @wh_TPRank
			, @wh_RED_BLACK_Flag
			, @wh_QTY
			, @wh_StockQTY
			, @wh_Warehouse_Code
			, @wh_ORNo
			, @wh_OPNO
			, @wh_PROC1
			, @wh_Making_Date_Date
			, @wh_Making_Date_Time
			, @wh_Data__send_Flag
			, @wh_Delete_Flag
			, @wh_TimeStamp_date
			, @wh_TimeStamp_time
			, @wh_SEQNO
			, @wh_State_Flag
		-- Loop cursor
		WHILE (@@FETCH_STATUS = 0) -- @@FETCH_STATUS -1 End, 0 Loop 
		BEGIN 
			IF (@wh_History_Class = 1) -- Insert
			BEGIN
				-- Insert
				IF NOT EXISTS(SELECT [LotNo] FROM [ISDB].[DBLSISHT].[dbo].[WH_UKEBA] WHERE [LotNo] = @wh_LotNo)
				BEGIN
					PRINT 'Insert WH_UKEBA LotNo : ' + @wh_LotNo;
					INSERT INTO [ISDB].[DBLSISHT].[dbo].[WH_UKEBA]
					(
						[Record_Class]
						, [ROHM_Model_Name]
						, [LotNo]
						, [OccurDate]
						, [R_Fukuoka_Model_Name]
						, [Rank]
						, [TPRank]
						, [RED_BLACK_Flag]
						, [QTY]
						, [StockQTY]
						, [Warehouse_Code]
						, [ORNo]
						, [OPNO]
						, [PROC1]
						, [Making_Date_Date]
						, [Making_Date_Time]
						, [Data__send_Flag]
						, [Delete_Flag]
						, [TimeStamp_date]
						, [TimeStamp_time]
						, [SEQNO]
					)
					SELECT @wh_Record_Class
						, @wh_ROHM_Model_Name
						, @wh_LotNo
						, @wh_OccurDate
						, @wh_R_Fukuoka_Model_Name
						, @wh_Rank
						, @wh_TPRank
						, @wh_RED_BLACK_Flag
						, @wh_QTY
						, @wh_StockQTY
						, @wh_Warehouse_Code
						, @wh_ORNo
						, @wh_OPNO
						, @wh_PROC1
						, @wh_Making_Date_Date
						, @wh_Making_Date_Time
						, @wh_Data__send_Flag
						, @wh_Delete_Flag
						, @wh_TimeStamp_date
						, @wh_TimeStamp_time
						, @wh_SEQNO;
				END
				------------------------------------------------------------------------------------
				PRINT 'Update WH_UKEBA_IF_HIST History_ID : ' + CAST(@wh_History_ID AS VARCHAR) + ', LotNo : ' + @wh_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.WH_UKEBA_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @wh_History_ID;
			END
			ELSE IF (@wh_History_Class = 2) -- Update
			BEGIN
				-- Update
				PRINT 'Update WH_UKEBA LotNo : ' + @wh_LotNo;
				UPDATE [ISDB].[DBLSISHT].[dbo].[WH_UKEBA]
				SET  [QTY] = @wh_QTY
				WHERE [LotNo] = @wh_LotNo;
				------------------------------------------------------------------------------------
				PRINT 'Update WH_UKEBA_IF_HIST History_ID : ' + CAST(@wh_History_ID AS VARCHAR) + ', LotNo : ' + @wh_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.WH_UKEBA_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @wh_History_ID;
			END
			ELSE IF (@wh_History_Class = 3) -- Delete
			BEGIN
				-- Delete
				PRINT 'Delete WH_UKEBA LotNo : ' + @wh_LotNo;
				DELETE FROM [ISDB].[DBLSISHT].[dbo].[WH_UKEBA]
				WHERE [LotNo] = @wh_LotNo;
				------------------------------------------------------------------------------------
				PRINT 'Update WH_UKEBA_IF_HIST History_ID : ' + CAST(@wh_History_ID AS VARCHAR) + ', LotNo : ' + @wh_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.WH_UKEBA_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @wh_History_ID;
			END

			-- Next cursor
			FETCH NEXT FROM cursor_wh_ukeba_if -- Fetch next cursor
			INTO @wh_History_ID
				, @wh_History_At
				, @wh_Host_Name
				, @wh_History_Class
				, @wh_Record_Class
				, @wh_ROHM_Model_Name
				, @wh_LotNo
				, @wh_OccurDate
				, @wh_R_Fukuoka_Model_Name
				, @wh_Rank
				, @wh_TPRank
				, @wh_RED_BLACK_Flag
				, @wh_QTY
				, @wh_StockQTY
				, @wh_Warehouse_Code
				, @wh_ORNo
				, @wh_OPNO
				, @wh_PROC1
				, @wh_Making_Date_Date
				, @wh_Making_Date_Time
				, @wh_Data__send_Flag
				, @wh_Delete_Flag
				, @wh_TimeStamp_date
				, @wh_TimeStamp_time
				, @wh_SEQNO
				, @wh_State_Flag;  -- Next into variable
		END
		-- Close cursor
		CLOSE cursor_wh_ukeba_if; 
		DEALLOCATE cursor_wh_ukeba_if; 
	END
	ELSE
	BEGIN
		PRINT '-- Disable Cursor WH_UKEBA';
	END
	--------------------------------------------------- /* Cursor WORK_R_DB */ ---------------------------------------------------
	IF (@IS_WORK_R_DB = 1)
	BEGIN	
		PRINT '-- Cursor WORK_R_DB';
		-- Cursor Table
		DECLARE cursor_work_r_db_if CURSOR FOR 
		SELECT * FROM @table_work_r_db
		ORDER BY History_ID;
		-- Open cursor
		OPEN cursor_work_r_db_if
		FETCH NEXT FROM cursor_work_r_db_if
		INTO @w_History_ID
			, @w_History_At
			, @w_Host_Name
			, @w_History_Class
			, @w_LotNo
			, @w_Process_No
			, @w_Process_Date
			, @w_Process_Time
			, @w_Back_Process_No
			, @w_Good_QTY
			, @w_NG_QTY
			, @w_NG_QTY1
			, @w_Cause_Code_of_NG1
			, @w_NG_QTY2
			, @w_Cause_Code_of_NG2
			, @w_NG_QTY3
			, @w_Cause_Code_of_NG3
			, @w_NG_QTY4
			, @w_Cause_Code_of_NG4
			, @w_Shipment_QTY
			, @w_OPNo
			, @w_TERM_ID
			, @w_TimeStamp_Date
			, @w_TimeStamp_Time
			, @w_Send_Flag
			, @w_Making_Date
			, @w_Making_Time
			, @w_SEQNO_SQL10
			, @w_State_Flag
		-- Loop cursor
		WHILE (@@FETCH_STATUS = 0) -- @@FETCH_STATUS -1 End, 0 Loop 
		BEGIN 
			IF (@w_History_Class = 1) -- Insert
			BEGIN
				-- Insert
				IF NOT EXISTS(SELECT [LotNo] FROM [ISDB].[DBLSISHT].[dbo].[WORK_R_DB] WHERE [LotNo] = @w_LotNo)
				BEGIN
					PRINT 'Insert WORK_R_DB LotNo : ' + @w_LotNo;
					INSERT INTO [ISDB].[DBLSISHT].[dbo].[WORK_R_DB]
					(
						[LotNo]
						, [Process_No]
						, [Process_Date]
						, [Process_Time]
						, [Back_Process_No]
						, [Good_QTY]
						, [NG_QTY]
						, [NG_QTY1]
						, [Cause_Code_of_NG1]
						, [NG_QTY2]
						, [Cause_Code_of_NG2]
						, [NG_QTY3]
						, [Cause_Code_of_NG3]
						, [NG_QTY4]
						, [Cause_Code_of_NG4]
						, [Shipment_QTY]
						, [OPNo]
						, [TERM_ID]
						, [TimeStamp_Date]
						, [TimeStamp_Time]
						, [Send_Flag]
						, [Making_Date]
						, [Making_Time]
						, [SEQNO_SQL10]
					)
					SELECT @w_LotNo
						, @w_Process_No
						, @w_Process_Date
						, @w_Process_Time
						, @w_Back_Process_No
						, @w_Good_QTY
						, @w_NG_QTY
						, @w_NG_QTY1
						, @w_Cause_Code_of_NG1
						, @w_NG_QTY2
						, @w_Cause_Code_of_NG2
						, @w_NG_QTY3
						, @w_Cause_Code_of_NG3
						, @w_NG_QTY4
						, @w_Cause_Code_of_NG4
						, @w_Shipment_QTY
						, @w_OPNo
						, @w_TERM_ID
						, @w_TimeStamp_Date
						, @w_TimeStamp_Time
						, @w_Send_Flag
						, @w_Making_Date
						, @w_Making_Time
						, @w_SEQNO_SQL10;
				END
				------------------------------------------------------------------------------------
				PRINT 'Update WORK_R_DB_IF_HIST History_ID : ' + CAST(@w_History_ID AS VARCHAR) + ', LotNo : ' + @w_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.WORK_R_DB_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @w_History_ID;
			END
			ELSE IF (@w_History_Class = 3) -- Delete
			BEGIN
				-- Delete
				PRINT 'Delete WORK_R_DB LotNo : ' + @w_LotNo;
				DELETE FROM [ISDB].[DBLSISHT].[dbo].[WORK_R_DB]
				WHERE [LotNo] = @w_LotNo;
				------------------------------------------------------------------------------------
				PRINT 'Update WORK_R_DB_IF_HIST History_ID : ' + CAST(@w_History_ID AS VARCHAR) + ', LotNo : ' + @w_LotNo + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.WORK_R_DB_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @w_History_ID;
			END

			-- Next cursor
			FETCH NEXT FROM cursor_work_r_db_if -- Fetch next cursor
			INTO @w_History_ID
				, @w_History_At
				, @w_Host_Name
				, @w_History_Class
				, @w_LotNo
				, @w_Process_No
				, @w_Process_Date
				, @w_Process_Time
				, @w_Back_Process_No
				, @w_Good_QTY
				, @w_NG_QTY
				, @w_NG_QTY1
				, @w_Cause_Code_of_NG1
				, @w_NG_QTY2
				, @w_Cause_Code_of_NG2
				, @w_NG_QTY3
				, @w_Cause_Code_of_NG3
				, @w_NG_QTY4
				, @w_Cause_Code_of_NG4
				, @w_Shipment_QTY
				, @w_OPNo
				, @w_TERM_ID
				, @w_TimeStamp_Date
				, @w_TimeStamp_Time
				, @w_Send_Flag
				, @w_Making_Date
				, @w_Making_Time
				, @w_SEQNO_SQL10
				, @w_State_Flag;  -- Next into variable
		END
		-- Close cursor
		CLOSE cursor_work_r_db_if; 
		DEALLOCATE cursor_work_r_db_if; 
	END
	ELSE
	BEGIN
		PRINT '-- Disable Cursor WORK_R_DB';
	END
	--------------------------------------------------- /* Cursor PROCESS_RECALL */ ---------------------------------------------------
	IF (@IS_PROCESS_RECALL = 1)
	BEGIN	
		PRINT '-- Cursor PROCESS_RECALL';
		-- Cursor Table
		DECLARE cursor_process_recall_if CURSOR FOR 
		SELECT * FROM @table_process_recall
		ORDER BY History_ID;
		-- Open cursor
		OPEN cursor_process_recall_if
		FETCH NEXT FROM cursor_process_recall_if
		INTO @pr_History_ID
			, @pr_History_At
			, @pr_Host_Name
			, @pr_History_Class
			, @pr_LOTNO
			, @pr_TYPE
			, @pr_DEVICE
			, @pr_PD
			, @pr_MM
			, @pr_SEQNO
			, @pr_OPNAME
			, @pr_ABNORMALCASE
			, @pr_STDQTY
			, @pr_HASUUQTY
			, @pr_FLAG
			, @pr_DATES
			, @pr_TIMER
			, @pr_FINAL_STD_QTY
			, @pr_FINAL_HASUU_QTY
			, @pr_NEWLOT
			, @pr_NEWQTY
			, @pr_NEWPDCD
			, @pr_RECALL_FIN_DATE
			, @pr_RECALL_FIN_TIME
			, @pr_WH_OP_RECALL
			, @pr_WH_CANCEL_RECALL
			, @pr_DATE_CANCEL_RECALL
			, @pr_TIME_CANCEL_RECALL
			, @pr_FLAG_CANCEL_RECALL
			, @pr_State_Flag
		-- Loop cursor
		WHILE (@@FETCH_STATUS = 0) -- @@FETCH_STATUS -1 End, 0 Loop 
		BEGIN 
			IF (@pr_History_Class = 1) -- Insert
			BEGIN
				-- Insert
				IF NOT EXISTS(SELECT [LotNo] FROM [ISDB].[DBLSISHT].[dbo].[PROCESS_RECALL] WHERE [NEWLOT] = @pr_NEWLOT)
				BEGIN
					PRINT 'Insert PROCESS_RECALL LotNo : ' + @pr_NEWLOT;
					INSERT INTO [ISDB].[DBLSISHT].[dbo].[PROCESS_RECALL]
					(
						[LOTNO]
						, [TYPE]
						, [DEVICE]
						, [PD]
						, [MM]
						, [SEQNO]
						, [OPNAME]
						, [ABNORMALCASE]
						, [STDQTY]
						, [HASUUQTY]
						, [FLAG]
						, [DATES]
						, [TIMER]
						, [FINAL_STD_QTY]
						, [FINAL_HASUU_QTY]
						, [NEWLOT]
						, [NEWQTY]
						, [NEWPDCD]
						, [RECALL_FIN_DATE]
						, [RECALL_FIN_TIME]
						, [WH_OP_RECALL]
						, [WH_CANCEL_RECALL]
						, [DATE_CANCEL_RECALL]
						, [TIME_CANCEL_RECALL]
						, [FLAG_CANCEL_RECALL]
					)
					SELECT @pr_LOTNO
						, @pr_TYPE
						, @pr_DEVICE
						, @pr_PD
						, @pr_MM
						, @pr_SEQNO
						, @pr_OPNAME
						, @pr_ABNORMALCASE
						, @pr_STDQTY
						, @pr_HASUUQTY
						, @pr_FLAG
						, @pr_DATES
						, @pr_TIMER
						, @pr_FINAL_STD_QTY
						, @pr_FINAL_HASUU_QTY
						, @pr_NEWLOT
						, @pr_NEWQTY
						, @pr_NEWPDCD
						, @pr_RECALL_FIN_DATE
						, @pr_RECALL_FIN_TIME
						, @pr_WH_OP_RECALL
						, @pr_WH_CANCEL_RECALL
						, @pr_DATE_CANCEL_RECALL
						, @pr_TIME_CANCEL_RECALL
						, @pr_FLAG_CANCEL_RECALL;
				END
				------------------------------------------------------------------------------------
				PRINT 'Update PROCESS_RECALL_IF_HIST History_ID : ' + CAST(@pr_History_ID AS VARCHAR) + ', LotNo : ' + @pr_NEWLOT + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.PROCESS_RECALL_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @pr_History_ID;
			END
			ELSE IF (@pr_History_Class = 3) -- Delete
			BEGIN
				-- Delete
				PRINT 'Delete PROCESS_RECALL LotNo : ' + @pr_NEWLOT;
				DELETE FROM [ISDB].[DBLSISHT].[dbo].[PROCESS_RECALL]
				WHERE [NEWLOT] = @pr_NEWLOT;
				------------------------------------------------------------------------------------
				PRINT 'Update PROCESS_RECALL_IF_HIST History_ID : ' + CAST(@pr_History_ID AS VARCHAR) + ', LotNo : ' + @pr_NEWLOT + ' State_Flag = 1';
				UPDATE APCSProDWH.dbo.PROCESS_RECALL_IF_HIST
				SET State_Flag = 1
				WHERE History_ID = @pr_History_ID;
			END

			-- Next cursor
			FETCH NEXT FROM cursor_process_recall_if -- Fetch next cursor
			INTO @pr_History_ID
				, @pr_History_At
				, @pr_Host_Name
				, @pr_History_Class
				, @pr_LOTNO
				, @pr_TYPE
				, @pr_DEVICE
				, @pr_PD
				, @pr_MM
				, @pr_SEQNO
				, @pr_OPNAME
				, @pr_ABNORMALCASE
				, @pr_STDQTY
				, @pr_HASUUQTY
				, @pr_FLAG
				, @pr_DATES
				, @pr_TIMER
				, @pr_FINAL_STD_QTY
				, @pr_FINAL_HASUU_QTY
				, @pr_NEWLOT
				, @pr_NEWQTY
				, @pr_NEWPDCD
				, @pr_RECALL_FIN_DATE
				, @pr_RECALL_FIN_TIME
				, @pr_WH_OP_RECALL
				, @pr_WH_CANCEL_RECALL
				, @pr_DATE_CANCEL_RECALL
				, @pr_TIME_CANCEL_RECALL
				, @pr_FLAG_CANCEL_RECALL
				, @pr_State_Flag;  -- Next into variable
		END
		-- Close cursor
		CLOSE cursor_process_recall_if; 
		DEALLOCATE cursor_process_recall_if; 
	END
	ELSE
	BEGIN
		PRINT '-- Disable Cursor PROCESS_RECALL';
	END
	---------------------------------------------------------------------------------------------
	SELECT 'Success' AS [Status];
	PRINT '<---- End ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_webdemo_set_data_interface]
	-- Add the parameters for the stored procedure here
	@new_lotno VARCHAR(10), 
	@original_lotno atom.trans_lots READONLY, 
	@empid INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [lot_no]
		, [command_text] )
	SELECT GETDATE() --AS [record_at]
		, 4 AS [record_class]
		, ORIGINAL_LOGIN() --AS [login_name]
		, HOST_NAME() --AS [hostname]
		, APP_NAME() --AS [appname]
		, @new_lotno --AS [lot_no]
		, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_data_interface]' 
			+ ' @new_lotno = ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
			+ ' ,@original_lotno = ' + ISNULL( '''' + CAST( STUFF((SELECT CONCAT(',', [lot_no]) FROM @original_lotno FOR XML PATH ('')), 1, 1, '') AS VARCHAR(MAX) ) + '''', 'NULL' ) 
			+ ' ,@empid = ' + ISNULL( CAST( @empid AS VARCHAR(10) ), 'NULL' ); --AS [command_text]

	DECLARE @empnum VARCHAR(6) 
	SET @empnum = (SELECT [emp_num] FROM [APCSProDB].[man].[users] WITH (NOLOCK) WHERE [id] = @empid);

	---- # 'MIX_HIST_IF' AS [table_name]
	INSERT INTO [APCSProDWH].[dbo].[MIX_HIST_IF]
		( [M_O_No]
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
		, [TimeStamp_time] )
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
		, ISNULL([device_names].[rank], '') AS [TIRank]
		, ISNULL([device_names].[rank], '') AS [Rank]
		, ISNULL([device_names].[tp_rank], '') AS [TPRank]
		, '' AS [SUBRank]
		, '' AS [Mask]
		, '' AS [KNo]
		, '' AS [MNo]
		, '' AS [Tomson1]
		, '' AS [Tomson2]
		, [surpluses].[qc_instruction] AS [Tomson3]
		, GETDATE() AS [allocation_Date]
		, IIF(SUBSTRING([lot_mem].[lot_no],5,1) = 'D', 'NO', ISNULL([allocat].[ORNo], ISNULL([allocat_temp].[ORNo], ''))) AS [ORNo]
		, ISNULL([allocat].[WFLotNo], ISNULL([allocat_temp].[WFLotNo], '')) AS [WFLotNo]
		, '' AS [User_Code]
		, '' AS [LotNo_Class]
		, ISNULL([surpluses].[label_class], '') AS [Label_Class]
		, '' AS [Multi_Class]
		, ISNULL([surpluses].[product_control_class], '') AS [Product_Control_Clas]
		, [device_names].[pcs_per_pack] AS [Packing_Standerd_QTY]
		, '' AS [Date_Code]
		, '' AS [HASUU_Out_Flag]
		, [surpluses].[pcs] AS [QTY]
		, '' AS [Transfer_Flag]
		, 0 AS [Transfer]
		, CAST(@empnum AS INT) AS [OPNo]
		, '' AS [Theoretical]
		, 'B' AS [OUT_OUT_FLAG]
		, GETDATE() AS [MIXD_DATE]
		, GETDATE() AS [TimeStamp_date]
		, DATEDIFF(s, CAST(GETDATE() AS DATE) , CURRENT_TIMESTAMP) AS [TimeStamp_time]
	FROM (
		SELECT 0 AS [idx]
			, @new_lotno AS [lot_no]
			, @new_lotno AS [member_lot_no]
		UNION
		SELECT (ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS [idx]
			, @new_lotno AS [lot_no]
			, [lot_no] AS [member_lot_no]
		FROM @original_lotno
	) AS [lot_combine]
	INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mas] ON [lot_combine].[lot_no] = [lot_mas].[lot_no]
	INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mem] ON [lot_combine].[member_lot_no] = [lot_mem].[lot_no]
	LEFT JOIN [APCSProDB].[trans].[surpluses] ON [lot_mem].[lot_no] = [surpluses].[serial_no]
	INNER JOIN [APCSProDB].[method].[packages] ON [lot_mem].[act_package_id] = [packages].[id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lot_mem].[act_device_name_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[method].[allocat] ON [lot_mem].[lot_no] = [allocat].[LotNo]
	LEFT JOIN [APCSProDB].[method].[allocat_temp] ON [lot_mem].[lot_no] = [allocat_temp].[LotNo]
	OUTER APPLY (
		SELECT TOP 1 [ROHM_Model_Name]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
		FROM [APCSProDB].[method].[allocat_temp] AS [at]
		WHERE TRIM([at].[ROHM_Model_Name]) = TRIM([device_names].[name])
			AND TRIM([at].[ASSY_Model_Name]) = TRIM([device_names].[assy_name]) 
	) AS [fukuoka]	
	ORDER BY [lot_combine].[idx] ASC;

	---- # check 'MIX_HIST_IF' AS [table_name]
	IF NOT EXISTS ( SELECT [HASUU_LotNo] FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE [HASUU_LotNo] = @new_lotno )
	BEGIN
		DELETE FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE [HASUU_LotNo] = @new_lotno;

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [lot_no]
			, [command_text] )
		SELECT GETDATE() --AS [record_at]
			, 4 AS [record_class]
			, ORIGINAL_LOGIN() --AS [login_name]
			, HOST_NAME() --AS [hostname]
			, APP_NAME() --AS [appname]
			, @new_lotno --AS [lot_no]
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_data_interface]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : insert data interface error [MIX_HIST_IF].'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'insert data interface error [MIX_HIST_IF] !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล interface ผิดพลาด [MIX_HIST_IF] !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END

	---- # 'LSI_SHIP_IF' AS [table_name]
	INSERT INTO [APCSProDWH].[dbo].[LSI_SHIP_IF]
		( [LotNo]
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
		, [Timestamp_Time] )
	SELECT [lots].[lot_no] AS [LotNo]
		, [packages].[short_name] AS [Type_Name]
		, [device_names].[name] AS [ROHM_Model_Name]
		, [device_names].[assy_name] AS [ASSY_Model_Name]
		, [fukuoka].[R_Fukuoka_Model_Name] AS [R_Fukuoka_Model_Name]
		, ISNULL([device_names].[rank], '') AS [TIRank]
		, ISNULL([device_names].[rank], '') AS [Rank]
		, ISNULL([device_names].[tp_rank], '') AS [TPRank]
		, '' AS [SUBRank]
		, [surpluses].[pdcd] AS [PDCD]
		, '' AS [Mask]
		, '' AS [KNo]
		, '' AS [MNo]
		, IIF(SUBSTRING([lots].[lot_no],5,1) = 'D', 'NO', ISNULL([allocat].[ORNo], ISNULL([allocat_temp].[ORNo], ''))) AS [ORNo]
		, [device_names].[pcs_per_pack] AS [Packing_Standerd_QTY]
		, '' AS [Tomson1]
		, '' AS [Tomson2]
		, [surpluses].[qc_instruction] AS [Tomson3]
		, ISNULL([allocat].[WFLotNo], ISNULL([allocat_temp].[WFLotNo], '')) AS [WFLotNo]
		, '' AS [LotNo_Class]
		, '' AS [User_Code]
		, ISNULL([surpluses].[product_control_class], '') AS [Product_Control_Clas]
		, ISNULL([surpluses].[product_class],'') AS [Product_Class]
		, ISNULL([surpluses].[production_class],'') AS [Production_Class]
		, ISNULL([surpluses].[rank_no],'') AS [Rank_No]
		, ISNULL([surpluses].[hinsyu_class],'') AS [HINSYU_Class]
		, ISNULL([surpluses].[label_class],'') AS [Label_Class]
		, [lots].[lot_no] AS [Standard_LotNo]
		, ISNULL([LotNo_1], '') AS [Complement_LotNo_1]
		, ISNULL([LotNo_2], '') AS [Complement_LotNo_2]
		, ISNULL([LotNo_3], '') AS [Complement_LotNo_3]
		, 'MX' AS [Standard_MNo]
		, '' AS [Complement_MNo_1]
		, '' AS [Complement_MNo_2]
		, '' AS [Complement_MNo_3]
		, IIF([lots].[qty_hasuu] < [device_names].[pcs_per_pack],[lots].[qty_hasuu],(([device_names].[pcs_per_pack]) * ([lots].[qty_hasuu]/[device_names].[pcs_per_pack]))) AS [Standerd_QTY]
		, 0 AS [Complement_QTY_1]
		, 0 AS [Complement_QTY_2]
		, 0 AS [Complement_QTY_3]
		, 0 AS [Shipment_QTY]
		, [lots].[qty_hasuu] AS [Good_Product_QTY]
		, '' AS [Used_Fin_Packing_QTY]
		, '' AS [HASUU_Out_Flag]
		, 'B'  AS [OUT_OUT_FLAG]
		, '01' AS [Stock_Class]
		, '1' AS [Label_Confirm_Class]
		, GETDATE() AS [allocation_Date]
		, '' AS [Delete_Flag]
		, CAST(@empnum AS INT) AS [OPNo]
		, CURRENT_TIMESTAMP AS [Timestamp_Date]
		, DATEDIFF(s, CAST(GETDATE() AS DATE), CURRENT_TIMESTAMP) AS [Timestamp_Time]
	FROM [APCSProDB].[trans].[lots]
	LEFT JOIN [APCSProDB].[trans].[surpluses] ON [lots].[lot_no] = [surpluses].[serial_no]
	INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[method].[allocat] ON [lots].[lot_no] = [allocat].[LotNo]
	LEFT JOIN [APCSProDB].[method].[allocat_temp] ON [lots].[lot_no] = [allocat_temp].[LotNo]
	OUTER APPLY (
		SELECT TOP 1 [ROHM_Model_Name]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
		FROM [APCSProDB].[method].[allocat_temp] AS [at]
		WHERE TRIM([at].[ROHM_Model_Name]) = TRIM([device_names].[name])
			AND TRIM([at].[ASSY_Model_Name]) = TRIM([device_names].[assy_name]) 
	) AS [fukuoka]
	OUTER APPLY (
		SELECT [LotNo_1], [LotNo_2], [LotNo_3]
		FROM (
			SELECT TOP 3 [lot_no]
				, 'LotNo_' + CAST([idx] AS VARCHAR(2)) AS [col_name]
			FROM (
				SELECT (ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS [idx]
					, [lot_no]
				FROM @original_lotno
			) AS [data_lot_1]
		) AS [data_lot_2]
		PIVOT (
			MAX([lot_no])
			FOR [col_name] IN ([LotNo_1], [LotNo_2], [LotNo_3])
		) AS [pvt]
	) AS [other_lot]
	WHERE [lots].[lot_no] = @new_lotno;

	---- # check 'LSI_SHIP_IF' AS [table_name]
	IF NOT EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WHERE [LotNo] = @new_lotno )
	BEGIN
		DELETE FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE [HASUU_LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WHERE [LotNo] = @new_lotno;

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [lot_no]
			, [command_text] )
		SELECT GETDATE() --AS [record_at]
			, 4 AS [record_class]
			, ORIGINAL_LOGIN() --AS [login_name]
			, HOST_NAME() --AS [hostname]
			, APP_NAME() --AS [appname]
			, @new_lotno --AS [lot_no]
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_data_interface]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : insert data interface error [LSI_SHIP_IF].'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'insert data interface error [LSI_SHIP_IF] !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล interface ผิดพลาด [LSI_SHIP_IF] !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END

	---- # 'H_STOCK_IF' AS [table_name]
	INSERT INTO [APCSProDWH].[dbo].[H_STOCK_IF]
		( [Stock_Class]
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
		, [Timestamp_Time] )
	SELECT '01' AS [Stock_Class]
		, [surpluses].[pdcd] AS [PDCD]
		, [lots].[lot_no] AS [LotNo]
		, [packages].[short_name] AS [Type_Name]
		, [device_names].[name] AS [ROHM_Model_Name]
		, [device_names].[assy_name] AS [ASSY_Model_Name]
		, [fukuoka].[R_Fukuoka_Model_Name] AS [R_Fukuoka_Model_Name]
		, ISNULL([device_names].[rank], '') AS [TIRank]
		, ISNULL([device_names].[rank], '') AS [Rank]
		, ISNULL([device_names].[tp_rank], '') AS [TPRank]
		, '' AS [SUBRank]
		, '' AS [Mask]
		, '' AS [KNo]
		, 'MX' AS [MNo]
		, 'NO' AS [ORNo]
		, [device_names].[pcs_per_pack] AS [Packing_Standerd_QTY]
		, '' AS [Tomson_Mark_1]
		, '' AS [Tomson_Mark_2]
		, [surpluses].[qc_instruction] AS [Tomson_Mark_3]
		, ISNULL([allocat].[WFLotNo], ISNULL([allocat_temp].[WFLotNo], '')) AS [WFLotNo]
		, '' AS [LotNo_Class]
		, '' AS [User_Code]
		, ISNULL([surpluses].[product_control_class], '') AS [Product_Control_Clas]
		, ISNULL([surpluses].[product_class],'') AS [Product_Class]
		, ISNULL([surpluses].[production_class],'') AS [Production_Class]
		, ISNULL([surpluses].[rank_no],'') AS [Rank_No]
		, ISNULL([surpluses].[hinsyu_class],'') AS [HINSYU_Class]
		, ISNULL([surpluses].[label_class],'') AS [Label_Class]
		, 0 AS [HASU_Stock_QTY]
		, [lots].[qty_hasuu] AS [HASU_WIP_QTY]
		, '1' AS [HASUU_Working_Flag]
		, 'B'  AS [OUT_OUT_FLAG]
		, '1' AS [Label_Confirm_Class]
		, CAST(@empnum AS INT) AS [OPNo]
		, '1' AS [DMY_IN__Flag]
		, '' AS [DMY_OUT_Flag]
		, GETDATE() AS [Derivery_Date]
		, DATEDIFF(s, CAST(GETDATE() AS DATE), CURRENT_TIMESTAMP) AS [Derivery_Time]
		, CURRENT_TIMESTAMP AS [Timestamp_Date]
		, DATEDIFF(s, CAST(GETDATE() AS DATE), CURRENT_TIMESTAMP) AS [Timestamp_Time]
	FROM [APCSProDB].[trans].[lots]
	LEFT JOIN [APCSProDB].[trans].[surpluses] ON [lots].[lot_no] = [surpluses].[serial_no]
	INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[method].[allocat] ON [lots].[lot_no] = [allocat].[LotNo]
	LEFT JOIN [APCSProDB].[method].[allocat_temp] ON [lots].[lot_no] = [allocat_temp].[LotNo]
	OUTER APPLY (
		SELECT TOP 1 [ROHM_Model_Name]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
		FROM [APCSProDB].[method].[allocat_temp] AS [at]
		WHERE TRIM([at].[ROHM_Model_Name]) = TRIM([device_names].[name])
			AND TRIM([at].[ASSY_Model_Name]) = TRIM([device_names].[assy_name]) 
	) AS [fukuoka]
	WHERE [lots].[lot_no] = @new_lotno;

	---- # check 'H_STOCK_IF' AS [table_name]
	IF NOT EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[H_STOCK_IF] WHERE [LotNo] = @new_lotno )
	BEGIN
		DELETE FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE [HASUU_LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[H_STOCK_IF] WHERE [LotNo] = @new_lotno;

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [lot_no]
			, [command_text] )
		SELECT GETDATE() --AS [record_at]
			, 4 AS [record_class]
			, ORIGINAL_LOGIN() --AS [login_name]
			, HOST_NAME() --AS [hostname]
			, APP_NAME() --AS [appname]
			, @new_lotno --AS [lot_no]
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_data_interface]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : insert data interface error [H_STOCK_IF].'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'insert data interface error [H_STOCK_IF] !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล interface ผิดพลาด [H_STOCK_IF] !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END

	---- # 'WORK_R_DB_IF' AS [table_name]
	INSERT INTO [APCSProDWH].[dbo].[WORK_R_DB_IF]
		( [LotNo]
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
		, [SEQNO_SQL10] )
	SELECT [lots].[lot_no] AS [LotNo]
		, 1001 AS [Process_No]
		, CURRENT_TIMESTAMP AS [Process_Date]
		, DATEDIFF(s, CAST(GETDATE() AS DATE), CURRENT_TIMESTAMP) AS [Process_Time]
		, '0' AS [Back_Process_No]
		, [lots].[qty_hasuu] AS [Good_QTY]
		, '0' AS [NG_QTY]
		, '0' AS [NG_QTY1]
		, ' ' AS [Cause_Code_of_NG1]
		, '0' AS [NG_QTY2]
		, ' ' AS [Cause_Code_of_NG2]
		, '0' AS [NG_QTY3]
		, ' ' AS [Cause_Code_of_NG3]
		, '0' AS [NG_QTY4]
		, ' ' AS [Cause_Code_of_NG4]
		, '0' AS [Shipment_QTY]
		, CAST(@empnum AS INT) AS [OPNo]
		, '0' AS [TERM_ID]
		, CURRENT_TIMESTAMP AS [TimeStamp_Date]
		, DATEDIFF(s, CAST(GETDATE() AS DATE), CURRENT_TIMESTAMP) AS [TimeStamp_Time]
		, '' AS [Send_Flag]
		, '' AS [Making_Date]
		, '' AS [Making_Time]
		, '' AS [SEQNO_SQL10]
	FROM [APCSProDB].[trans].[lots]
	WHERE [lots].[lot_no] = @new_lotno;

	---- # check 'WORK_R_DB_IF' AS [table_name]
	IF NOT EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[WORK_R_DB_IF] WHERE [LotNo] = @new_lotno )
	BEGIN
		DELETE FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE [HASUU_LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[H_STOCK_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[WORK_R_DB_IF] WHERE [LotNo] = @new_lotno;

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [lot_no]
			, [command_text] )
		SELECT GETDATE() --AS [record_at]
			, 4 AS [record_class]
			, ORIGINAL_LOGIN() --AS [login_name]
			, HOST_NAME() --AS [hostname]
			, APP_NAME() --AS [appname]
			, @new_lotno --AS [lot_no]
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_data_interface]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : insert data interface error [WORK_R_DB_IF].'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'insert data interface error [WORK_R_DB_IF] !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล interface ผิดพลาด [WORK_R_DB_IF] !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END

	---- # 'PACKWORK_IF' AS [table_name]
	INSERT INTO [APCSProDWH].[dbo].[PACKWORK_IF]
		( [LotNo]
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
		, [SEQNO] )
	SELECT [lots].[lot_no] AS [LotNo]
		, [packages].[short_name] AS [Type_Name]
		, [device_names].[name] AS [ROHM_Model_Name]
		, [fukuoka].[R_Fukuoka_Model_Name] AS [R_Fukuoka_Model_Name]
		, ISNULL([device_names].[rank], '') AS [Rank]
		, ISNULL([device_names].[tp_rank], '') AS [TPRank]
		, [surpluses].[pdcd] AS [PDCD]
		, [lots].[qty_hasuu] AS [Quantity]
		, 'NO' AS [ORNo]
		, CAST(@empnum AS INT) AS [OPNo]
		, '' AS [Delete_Flag]
		, CURRENT_TIMESTAMP AS [Timestamp_Date]
		, DATEDIFF(s, CAST(GETDATE() AS DATE), CURRENT_TIMESTAMP) AS [Timestamp_time]
		, '' AS [SEQNO]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[trans].[surpluses] ON [lots].[lot_no] = [surpluses].[serial_no]
	OUTER APPLY (
		SELECT TOP 1 [ROHM_Model_Name]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
		FROM [APCSProDB].[method].[allocat_temp] AS [at]
		WHERE TRIM([at].[ROHM_Model_Name]) = TRIM([device_names].[name])
			AND TRIM([at].[ASSY_Model_Name]) = TRIM([device_names].[assy_name]) 
	) AS [fukuoka]
	WHERE [lots].[lot_no] = @new_lotno;

	---- # check 'PACKWORK_IF' AS [table_name]
	IF NOT EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[PACKWORK_IF] WHERE [LotNo] = @new_lotno )
	BEGIN
		DELETE FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE [HASUU_LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[H_STOCK_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[WORK_R_DB_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[PACKWORK_IF] WHERE [LotNo] = @new_lotno;

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [lot_no]
			, [command_text] )
		SELECT GETDATE() --AS [record_at]
			, 4 AS [record_class]
			, ORIGINAL_LOGIN() --AS [login_name]
			, HOST_NAME() --AS [hostname]
			, APP_NAME() --AS [appname]
			, @new_lotno --AS [lot_no]
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_data_interface]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : insert data interface error [PACKWORK_IF].'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'insert data interface error [PACKWORK_IF] !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล interface ผิดพลาด [PACKWORK_IF] !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END

	---- # 'WH_UKEBA_IF' AS [table_name]
	INSERT INTO [APCSProDWH].[dbo].[WH_UKEBA_IF]
		( [Record_Class]
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
		, [SEQNO] )
	SELECT '' AS [Record_Class]
		, [device_names].[name] AS [ROHM_Model_Name]
		, [lots].[lot_no] AS [LotNo]
		, CURRENT_TIMESTAMP AS [OccurDate]
		, [fukuoka].[R_Fukuoka_Model_Name] AS [R_Fukuoka_Model_Name]
		, ISNULL([device_names].[rank], '') AS [Rank]
		, ISNULL([device_names].[tp_rank], '') AS [TPRank]
		, '0' AS [RED_BLACK_Flag]
		, [lots].[qty_hasuu] AS [QTY]
		, '0' AS [StockQTY]
		, [surpluses].[pdcd] AS [Warehouse_Code]
		, 'NO' AS [ORNo]
		, CAST(@empnum AS INT) AS [OPNO]
		, '1' AS [PROC1]
		, CURRENT_TIMESTAMP AS [Making_Date_Date]
		, '' AS [Making_Date_Time]
		, '' AS [Data__send_Flag]
		, '' AS [Delete_Flag]
		, CURRENT_TIMESTAMP AS [TimeStamp_date]
		, DATEDIFF(s, CAST(GETDATE() AS DATE), CURRENT_TIMESTAMP) AS [TimeStamp_time]
		, '' AS [SEQNO]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[trans].[surpluses] ON [lots].[lot_no] = [surpluses].[serial_no]
	OUTER APPLY (
		SELECT TOP 1 [ROHM_Model_Name]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
		FROM [APCSProDB].[method].[allocat_temp] AS [at]
		WHERE TRIM([at].[ROHM_Model_Name]) = TRIM([device_names].[name])
			AND TRIM([at].[ASSY_Model_Name]) = TRIM([device_names].[assy_name]) 
	) AS [fukuoka]
	WHERE [lots].[lot_no] = @new_lotno;

	---- # check 'WH_UKEBA_IF' AS [table_name]
	IF NOT EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[WH_UKEBA_IF] WHERE [LotNo] = @new_lotno )
	BEGIN
		DELETE FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE [HASUU_LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[H_STOCK_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[WORK_R_DB_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[PACKWORK_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[WH_UKEBA_IF] WHERE [LotNo] = @new_lotno;

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [lot_no]
			, [command_text] )
		SELECT GETDATE() --AS [record_at]
			, 4 AS [record_class]
			, ORIGINAL_LOGIN() --AS [login_name]
			, HOST_NAME() --AS [hostname]
			, APP_NAME() --AS [appname]
			, @new_lotno --AS [lot_no]
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_data_interface]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : insert data interface error [WH_UKEBA_IF].'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'insert data interface error [WH_UKEBA_IF] !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล interface ผิดพลาด [WH_UKEBA_IF] !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END

	---- # check 'ALL' AS [table_name]
	IF EXISTS ( SELECT [HASUU_LotNo] FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE [HASUU_LotNo] = @new_lotno )
		AND EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WHERE [LotNo] = @new_lotno )
		AND EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[H_STOCK_IF] WHERE [LotNo] = @new_lotno )
		AND EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[WORK_R_DB_IF] WHERE [LotNo] = @new_lotno )
		AND EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[PACKWORK_IF] WHERE [LotNo] = @new_lotno )
		AND EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[WH_UKEBA_IF] WHERE [LotNo] = @new_lotno )
	BEGIN
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
	ELSE
	BEGIN
		DELETE FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE [HASUU_LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[H_STOCK_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[WORK_R_DB_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[PACKWORK_IF] WHERE [LotNo] = @new_lotno;
		DELETE FROM [APCSProDWH].[dbo].[WH_UKEBA_IF] WHERE [LotNo] = @new_lotno;

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [lot_no]
			, [command_text] )
		SELECT GETDATE() --AS [record_at]
			, 4 AS [record_class]
			, ORIGINAL_LOGIN() --AS [login_name]
			, HOST_NAME() --AS [hostname]
			, APP_NAME() --AS [appname]
			, @new_lotno --AS [lot_no]
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_data_interface]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : insert data interface error.'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'insert data interface error !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล interface ผิดพลาด !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
END

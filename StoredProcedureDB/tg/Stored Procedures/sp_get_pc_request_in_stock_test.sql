-- =============================================
-- =============================================
CREATE PROCEDURE [tg].[sp_get_pc_request_in_stock_test]
	-- Add the parameters for the stored procedure here
	   @package_name CHAR(10) = ''
	  ,@device_name CHAR(20) = ''
	  ,@rank VARCHAR(4) = NULL
	  ,@qc_instruction VARCHAR(20) = NULL
	  ,@is_action INT = NULL ---- # 0:check, 1:select
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----DECLARE @package_name CHAR(20) = 'SSOP-B20W '
	----	, @device_name CHAR(20) = 'BM67271FV-HE2       ' --'BA3166FV            '
	----	, @is_action INT = 1 ---- #0:check 1:select

	IF (@is_action = 0)
	BEGIN
		---- # check data # ----
		---- # check package not exists
		IF NOT EXISTS( SELECT TOP 1 [name] FROM [APCSProDB].[method].[packages] WHERE [short_name] = @package_name )
		BEGIN 
			SELECT 'FALSE' as Is_Pass
				, 'package not found in database !!' AS Error_Message_ENG
				, N'ไม่พบ package ในฐานข้อมูล !!' AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
			RETURN; 
		END

		---- # check device not exists
		IF NOT EXISTS( SELECT TOP 1 [name] FROM [APCSProDB].[method].[device_names] WHERE [name] = @device_name )
		BEGIN 
			SELECT 'FALSE' as Is_Pass
				, 'device not found in database !!' AS Error_Message_ENG
				, N'ไม่พบ device ในฐานข้อมูล !!' AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
			RETURN; 
		END

		---- # check device not exists in package
		IF NOT EXISTS( SELECT TOP 1 [packages].[short_name] FROM [APCSProDB].[method].[packages]
			INNER JOIN [APCSProDB].[method].[device_names] ON [packages].[id] = [device_names].[package_id]
			WHERE [packages].[short_name] = @package_name
				AND [device_names].[name] = @device_name )
		BEGIN 
			SELECT 'FALSE' as Is_Pass
				, 'device not found in package !!' AS Error_Message_ENG
				, N'ไม่พบ device นี้ใน package นี้ !!' AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
			RETURN; 
		END

		---- # check data in stcok
		IF NOT EXISTS ( SELECT TOP 1 [lots].[lot_no] AS LotNo
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[trans].[surpluses] ON [lots].[id] = [surpluses].[lot_id]
			INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
			WHERE [lots].[wip_state] IN (70,100) 
				AND [surpluses].[in_stock] = 2
				AND [surpluses].[location_id] is not null --add condition check hasuu in rack 2024/02/07 time : 11.06 by Aomsin
				AND ([packages].[short_name] LIKE @package_name)
				AND ([device_names].[name] LIKE @device_name) )
		BEGIN
			SELECT 'FALSE' as Is_Pass
				, 'data not found in stock !!' AS Error_Message_ENG
				, N'ไม่พบข้อมูลนี้ในคลังสินค้า !!' AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
			RETURN; 
		END

		----# true
		SELECT 'TRUE' as Is_Pass
			, '' AS Error_Message_ENG
			, N'' AS Error_Message_THA
			, N'' AS Handling
		RETURN;
	END
	ELSE IF (@is_action = 1)
	BEGIN
		SET @rank = IIF(@rank = '%' or @rank is null,'%',@rank);
		print @rank
		SET @qc_instruction = IIF(@qc_instruction = '%' or @qc_instruction is null,'%',@qc_instruction);
		print @qc_instruction
		---- # select data # ----
		SELECT TRIM([lots].[lot_no]) AS LotNo
			, TRIM([package_groups].[name]) AS [Packgroup_Name]
			, [packages].[short_name] AS [Type_Name]
			, [device_names].[name] AS [ASSY_Model_Name]
			, [surpluses].[pcs] AS [HASU_Stock_QTY]
			, [device_names].[pcs_per_pack] AS [Packing_Standerd_QTY]
			, ISNULL([device_names].[rank],'') AS [Rank] --Add a NULL check condition (2025/02/11) time : 16:27 by George
			, [device_names].[tp_rank] AS [TP_Rank]
			, [surpluses].[qc_instruction]
			, (CASE WHEN [surpluses].[created_at] >= (GETDATE() - 1095) THEN '' ELSE '#ff6666' END) AS [color]
			, [surpluses].[created_at] AS [Derivery_Date]
			, YEAR([surpluses].[created_at]) AS [oldyear]
			, YEAR(GETDATE()) AS [Currentyear]
			, cast(YEAR(GETDATE()) AS INT) - CAST(YEAR([surpluses].[created_at]) AS INT) AS [Overdueyear]
			, ISNULL(CAST([locations].[name] AS VARCHAR), 'NoLocation') AS [Rack_Location_name]
			, ISNULL(CAST([locations].[address] AS VARCHAR), 'NoLocation') AS [Rack_Location_address]
			, [item_labels].[label_eng] AS [status]
			, [packages].[pcs_per_tube_or_tray]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[trans].[surpluses] ON [lots].[id] = [surpluses].[lot_id]
		INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
		INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
		INNER JOIN [APCSProDB].[method].[package_groups] ON [package_groups].[id] = [packages].[package_group_id]
		INNER JOIN [APCSProDB].[trans].[locations] ON [surpluses].[location_id] = [locations].[id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] ON [surpluses].[in_stock] = CAST([item_labels].[val] AS INT)
			AND [item_labels].[name] = 'surpluse_records.in_stock'
		WHERE [lots].[wip_state] IN (70,100,20) 
			AND [surpluses].[in_stock] = 2
			AND ([packages].[short_name] LIKE @package_name)
			AND ([device_names].[name] LIKE @device_name)
			AND (ISNULL([device_names].[rank],'%') LIKE @rank)
			AND (ISNULL(TRIM([surpluses].[qc_instruction]),'%') LIKE TRIM(@qc_instruction))
		ORDER BY [lots].[lot_no] ASC;
	END
	ELSE IF (@is_action = 2)  --add condition use with list hasuu stock of pd create lot (2024/06/11) time : 10.59 by Aomsin
	BEGIN
		DECLARE @datetime DATETIME
		DECLARE @year_now int = 0
		SET @datetime = GETDATE()
		SELECT @year_now = (FORMAT(@datetime,'yy') - 3)
		---- # ---------------------------------------- # ----
		SET @rank = IIF(@rank = '%' or @rank is null,'%',@rank);
		print @rank
		SET @qc_instruction = IIF(@qc_instruction = '%' or @qc_instruction is null,'%',@qc_instruction);
		print @qc_instruction
		---- # select data # ----
		SELECT TRIM([lots].[lot_no]) AS LotNo
			, TRIM([package_groups].[name]) AS [Packgroup_Name]
			, [packages].[short_name] AS [Type_Name]
			, [device_names].[name] AS [ASSY_Model_Name]
			, [surpluses].[pcs] AS [HASU_Stock_QTY]
			, [device_names].[pcs_per_pack] AS [Packing_Standerd_QTY]
			, ISNULL([device_names].[rank],'') AS [Rank] --Add a NULL check condition (2025/02/11) time : 16:27 by George
			, [device_names].[tp_rank] AS [TP_Rank]
			, [surpluses].[qc_instruction]
			, (CASE WHEN [surpluses].[created_at] >= (GETDATE() - 1095) THEN '' ELSE '#ff6666' END) AS [color]
			, [surpluses].[created_at] AS [Derivery_Date]
			, YEAR([surpluses].[created_at]) AS [oldyear]
			, YEAR(GETDATE()) AS [Currentyear]
			, cast(YEAR(GETDATE()) AS INT) - CAST(YEAR([surpluses].[created_at]) AS INT) AS [Overdueyear]
			, ISNULL(CAST([locations].[name] AS VARCHAR), 'NoLocation') AS [Rack_Location_name]
			, ISNULL(CAST([locations].[address] AS VARCHAR), 'NoLocation') AS [Rack_Location_address]
			, [item_labels].[label_eng] AS [status]
			, [packages].[pcs_per_tube_or_tray]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[trans].[surpluses] ON [lots].[id] = [surpluses].[lot_id]
		INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
		INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
		INNER JOIN [APCSProDB].[method].[package_groups] ON [package_groups].[id] = [packages].[package_group_id]
		INNER JOIN [APCSProDB].[trans].[locations] ON [surpluses].[location_id] = [locations].[id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] ON [surpluses].[in_stock] = CAST([item_labels].[val] AS INT)
			AND [item_labels].[name] = 'surpluse_records.in_stock'
		WHERE [lots].[wip_state] IN (70,100,20) 
			AND [surpluses].[in_stock] = 2
			AND ([packages].[short_name] LIKE @package_name)
			AND ([device_names].[name] LIKE @device_name)
			AND (ISNULL([device_names].[rank],'%') LIKE @rank)
			AND (ISNULL(TRIM([surpluses].[qc_instruction]),'%') LIKE TRIM(@qc_instruction))
			--AND CAST(YEAR(GETDATE()) AS INT) - CAST(YEAR([surpluses].[created_at]) AS INT) <= 3  --add condition check hasuu over 3 year (2024/06/11) time : 09.56 by Aomsin
			AND (SUBSTRING([surpluses].[serial_no],1,2) >= @year_now or [surpluses].[is_ability] = 1)  --wait open test condition have ability test >> open 2024/06/12 time : 15.28 by Aomsin <<
		ORDER BY [lots].[lot_no] ASC;
	END
	ELSE
	BEGIN
		print '@is_action is incorrect !!'
		----# @is_action is incorrect
		SELECT 'FALSE' as Is_Pass
			, '@is_action is incorrect !!' AS Error_Message_ENG
			, N'@is_action ไม่ถูกต้อง !!' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
		RETURN; 
	END
END

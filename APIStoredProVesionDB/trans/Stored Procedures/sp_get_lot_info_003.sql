
CREATE PROCEDURE [trans].[sp_get_lot_info_003]
	@e_slip_id VARCHAR(50),
	@get_type TINYINT = 0,  -- 0: Lot info  1:Check Lot
	@mc_no VARCHAR(50) = NULL, 
	@app_name VARCHAR(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	--------------------------------------------------------------------------------------------------------------
	-- Log exec
	--------------------------------------------------------------------------------------------------------------
	INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] )
	SELECT GETDATE()
		, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [APIStoredProVersionDB].[trans].[sp_get_lot_info_003] @e_slip_id = ''' + ISNULL(CAST(@e_slip_id AS varchar),'') 
			+ ''', @get_type = ''' + ISNULL(CAST(@get_type AS varchar),'') 
			+ ''', @mc_no = ''' + ISNULL(CAST(@mc_no AS varchar),'') 
			+ ''', @app_name = ''' + ISNULL(CAST(@app_name AS varchar),'') + ''''
		, @e_slip_id;

	DECLARE @lot_no VARCHAR(10) = NULL;
	--------------------------------------------------------------------------------------------------------------
	-- @get_type = 0 Get Lot info 
	--------------------------------------------------------------------------------------------------------------
	IF (@get_type = 0)
	BEGIN
		--------------------------------------------------------------------------------------------------------------
		IF EXISTS ( SELECT 1 FROM [APCSProDB].[trans].[lots] WHERE [e_slip_id] = @e_slip_id )
		BEGIN
			--------------------------------------------------------------------------------------------------------------
			SELECT @lot_no = [lot_no] FROM [APCSProDB].[trans].[lots] WHERE [e_slip_id] = @e_slip_id;

			--------------------------------------------------------------------------------------------------------------
			-- Get QRCode
			--------------------------------------------------------------------------------------------------------------
			IF EXISTS ( SELECT 1 FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] WHERE [LOT_NO_2] = @lot_no )
			BEGIN
				--------------------------------------------------------------------------------------------------------------
				PRINT 'Denpyo';
				SELECT 'TRUE' AS [Is_Pass]
					, '' AS [Error_Message_ENG]
					, N'' AS [Error_Message_THA]
					, N'' AS [Handling]
					, CAST([denpyo].[LOT_NO_2] AS VARCHAR(10)) AS [Lot_no]
					, CAST([denpyo].[QR_CODE_2] AS CHAR(252)) AS [QR_Code]
				FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [denpyo]
				WHERE [denpyo].[LOT_NO_2] = @lot_no;
				--------------------------------------------------------------------------------------------------------------
			END
			ELSE
			BEGIN
				--------------------------------------------------------------------------------------------------------------
				PRINT 'trans.lots';
				SELECT 'TRUE' AS [Is_Pass]
					, '' AS [Error_Message_ENG]
					, N'' AS [Error_Message_THA]
					, N'' AS [Handling]
					, CAST([lots].[lot_no] AS VARCHAR(10)) AS [Lot_no]
					, CAST(ISNULL([packages].[short_name], '') AS CHAR(10)) --as package_name
						+ CAST(ISNULL([device_names].[assy_name],'') AS CHAR(20)) --as ASSY_Model_Name
						+ CAST(ISNULL([lots].[lot_no], '') AS CHAR(10)) --as LotNo
						+ SPACE(42)
						+ CAST(ISNULL([device_names].[tp_rank], '') AS CHAR(2)) --as TPRank
						+ SPACE(62)
						+ CAST(ISNULL([packages].[short_name], '') AS CHAR(20)) --as package_name
						+ CAST(ISNULL([device_names].[ft_name], '') AS CHAR(20)) --as ft_name
						+ CASE WHEN SUBSTRING(TRIM([lots].[lot_no]), 5, 1) IN ('D','F') THEN  CAST('MX' AS CHAR(12))
							ELSE CAST([surpluses].[mark_no] AS CHAR(12)) END --AS MNo
						+ CAST(FORMAT([device_names].[pcs_per_pack], '00000') AS CHAR(5)) --as packing_standard
						+ SPACE(2)
						+ CAST(ISNULL([device_names].[rank], '') AS CHAR(7)) --as Rank
						+ CAST(ISNULL([multi_labels].[user_model_name], ISNULL([device_names].[name], '')) AS CHAR(20)) --as Customer_Device
						+ CAST([device_names].[name] AS CHAR(20)) --as device_name
					AS [QR_Code]
				FROM [APCSProDB].[trans].[lots]
				INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
				INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
				LEFT JOIN [APCSProDB].[trans].[surpluses] ON [lots].[id] = [surpluses].[lot_id]
				LEFT JOIN [APCSProDB].[method].[multi_labels] ON [device_names].[name] = [multi_labels].[device_name]
				WHERE [lots].[lot_no] = @lot_no; 
				--------------------------------------------------------------------------------------------------------------
			END
			--------------------------------------------------------------------------------------------------------------
		END
		ELSE
		BEGIN
			--------------------------------------------------------------------------------------------------------------
			SELECT 'FALSE' AS [Is_Pass]
				, 'Card not found data. !!' AS [Error_Message_ENG]
				, N'ไม่พบข้อมูลการใช้งาน Card !!' AS [Error_Message_THA]
				, N'ติดต่อ System !!' AS [Handling]
				, '' AS [Lot_no]
				, '' AS [QR_Code];
			RETURN;
			--------------------------------------------------------------------------------------------------------------
		END
		--------------------------------------------------------------------------------------------------------------
	END 
	--------------------------------------------------------------------------------------------------------------
	-- @get_type = 1 Check Lot
	--------------------------------------------------------------------------------------------------------------
	ELSE IF (@get_type = 1)
	BEGIN
		--------------------------------------------------------------------------------------------------------------
		IF EXISTS ( SELECT 1 FROM [APCSProDB].[trans].[lots] WHERE [e_slip_id] = @e_slip_id )
		BEGIN
			--------------------------------------------------------------------------------------------------------------
			SELECT @lot_no = [lot_no] FROM [APCSProDB].[trans].[lots] WHERE [e_slip_id] = @e_slip_id;

			SELECT 'FALSE' AS [Is_Pass]
					, 'ESL Card using ' + CAST([lots].[lot_no] AS VARCHAR(10)) + N' !!' AS [Error_Message_ENG]
					, N'ESL Card ถูกใช้กับ ' + CAST([lots].[lot_no] AS VARCHAR(10)) + N' !!'  AS [Error_Message_THA]
					, N'ติดต่อ System !!' AS [Handling]
					, CAST([lots].[lot_no] AS VARCHAR(10)) AS [Lot_no]
					, '' AS [QR_Code]
				FROM [APCSProDB].[trans].[lots]
				WHERE [lots].[lot_no] = @lot_no;
			RETURN;
			--------------------------------------------------------------------------------------------------------------
		END
		ELSE
		BEGIN
			--------------------------------------------------------------------------------------------------------------
			SELECT 'TRUE' AS [Is_Pass]
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA]
				, N'' AS [Handling]
				, '' AS [Lot_no]
				, '' AS [QR_Code];
			RETURN;
			--------------------------------------------------------------------------------------------------------------
		END
		--------------------------------------------------------------------------------------------------------------
	END
END

-- =============================================
-- Author:		KITTITAT
-- Create date: 2022/07/06
-- =============================================
CREATE PROCEDURE [trans].[sp_get_lot_info_002]
	@e_slip_id varchar(50),
	@get_type tinyint = 0,  -- 0: Lot info  1:Check Lot
	@mc_no varchar(50) = NULL, 
	@app_name varchar(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	---------------------------------------------------------
	--- LOG
	---------------------------------------------------------
	INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history]
		([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no])
	SELECT GETDATE()
		, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [APIStoredProVersionDB].[trans].[sp_get_lot_info_002] @e_slip_id = ''' + ISNULL(CAST(@e_slip_id AS varchar),'') 
			+ ''', @get_type = ''' + ISNULL(CAST(@get_type AS varchar),'') 
			+ ''', @mc_no = ''' + ISNULL(CAST(@mc_no AS varchar),'') 
			+ ''', @app_name = ''' + ISNULL(CAST(@app_name AS varchar),'') + ''''
		, @e_slip_id
	---------------------------------------------------------
	--- Declare
	---------------------------------------------------------	
	DECLARE @lot_type tinyint = NULL;
	DECLARE @lot_no varchar(10) = NULL;
	DECLARE @wip_state int = NULL;
	--0	  || Mass Products
	--1	  ||Sample Products
	--100 ||Mass Products with Instruction
	--2	  ||Experimental Products
	--6	  ||D Lot
	--7	  ||Recall Lot
	--8	  ||Out Source Lot
	--9	  ||Special B Lot
	---------------------------------------------------------
	--- DATA
	---------------------------------------------------------
	SELECT	   @lot_type	= [device_versions].[device_type]
			, @lot_no		= [lots].[lot_no]
			, @wip_state	= [lots].[wip_state]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] 
	ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] 
	ON [device_versions].[device_id] = [device_slips].[device_id]
	WHERE [lots].[e_slip_id] = @e_slip_id
	----------------------------------------------------------------------------------------------


	IF (@lot_no IS NOT NULL)
	BEGIN

	IF(@get_type = 0)
	BEGIN 

		IF (@wip_state = 20)
		BEGIN 
			---------------------------------------------------------
			--- trans.lots wip_state = 20
			---------------------------------------------------------
			IF EXISTS (SELECT 1 FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT WHERE LOT_NO_2 = @lot_no)
			BEGIN
				SELECT 'TRUE' AS Is_Pass
					, '' AS Error_Message_ENG
					, N'' AS Error_Message_THA
					, N'' AS Handling
					, TRIM(denpyo.LOT_NO_2) AS Lot_no
					, CAST(denpyo.QR_CODE_2 AS CHAR(252)) as QR_Code
				FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo 
				WHERE denpyo.LOT_NO_2 = @lot_no
			END
			ELSE
			BEGIN
				IF (@lot_type IN (6,0))
				BEGIN
					---------------------------------------------------------
					--- D Lot
					---------------------------------------------------------
					SELECT 'TRUE'			AS Is_Pass
						, ''				AS Error_Message_ENG
						, N''				AS Error_Message_THA
						, N''				AS Handling
						, TRIM(lots_mas.lot_no) AS Lot_no
						, CAST(ISNULL(packages.short_name,'') AS CHAR(10)) --as package_name
						+ CAST(ISNULL(device_names.assy_name,'') AS CHAR(20)) --as ASSY_Model_Name
						+ CAST(ISNULL(lots_mas.lot_no,'') AS CHAR(10)) --as LotNo
						+ SPACE(42)
						+ CAST(ISNULL(device_names.tp_rank,'') AS CHAR(2)) --as TPRank
						+ SPACE(62)
						+ CAST(ISNULL(packages.short_name,'') AS CHAR(20)) --as package_name
						+ CAST(ISNULL(device_names.ft_name,'') AS CHAR(20)) --as ft_name
						+ CASE WHEN SUBSTRING(TRIM(lots_mem.lot_no),5,1) = 'D' or SUBSTRING(TRIM(lots_mem.lot_no),5,1) = 'F' THEN  CAST('MX' AS CHAR(12))
							ELSE CAST(label_issue_records.mno_hasuu AS CHAR(12)) END --AS MNo
						+ CAST(FORMAT(device_names.pcs_per_pack,'00000') AS CHAR(5)) --as packing_standard
						+ SPACE(2)
						+ CASE WHEN device_names.rank IS NULL THEN CAST('' AS CHAR(7)) 
							ELSE CAST(ISNULL(device_names.rank,'') AS CHAR(7)) END --as Rank
						+ CASE WHEN multi_labels.user_model_name IS NULL THEN CAST(ISNULL(device_names.name,'') AS CHAR(20))
							ELSE CAST(ISNULL(multi_labels.user_model_name,'') AS CHAR(20)) END --as Customer_Device
						+ CAST(device_names.name AS CHAR(20)) --as device_name
						AS QR_Code
					FROM APCSProDB.trans.lot_combine
					INNER JOIN APCSProDB.trans.lots lots_mem ON lot_combine.member_lot_id = lots_mem.id
					INNER JOIN APCSProDB.trans.lots lots_mas ON lot_combine.lot_id = lots_mas.id
					INNER JOIN APCSProDB.method.device_names ON lots_mem.act_device_name_id = device_names.id
					INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
					LEFT JOIN APCSProDB.trans.surpluses ON lot_combine.member_lot_id = surpluses.lot_id
					INNER JOIN APCSProDB.trans.label_issue_records ON label_issue_records.lot_no = lots_mas.lot_no
						and label_issue_records.type_of_label = 1
					LEFT JOIN APCSProDB.method.multi_labels ON device_names.name = multi_labels.device_name
					WHERE lots_mas.lot_no = @lot_no 
				END
				ELSE IF (@lot_type = 8)
				BEGIN
					---------------------------------------------------------
					--- Outsouse Lot
					---------------------------------------------------------
					SELECT 'TRUE' AS Is_Pass
						, '' AS Error_Message_ENG
						, N'' AS Error_Message_THA
						, N'' AS Handling
						, TRIM(lots.lot_no) AS Lot_no
						, CAST(ISNULL(packages.short_name,'') AS CHAR(10)) --as package_name
						+ CAST(ISNULL(device_names.assy_name,'') AS CHAR(20)) --as ASSY_Model_Name
						+ CAST(ISNULL(lots.lot_no,'') AS CHAR(10)) --as LotNo
						+ SPACE(42)
						+ CAST(ISNULL(device_names.tp_rank,'') AS CHAR(2)) --as TPRank
						+ SPACE(62)
						+ CAST(ISNULL(packages.short_name,'') AS CHAR(20)) --as package_name
						+ CAST(ISNULL(device_names.ft_name,'') AS CHAR(20)) --as ft_name
						+ SPACE(12) --AS MNo
						+ CAST(FORMAT(device_names.pcs_per_pack,'00000') AS CHAR(5)) --as packing_standard
						+ SPACE(2)
						+ CASE WHEN device_names.rank IS NULL THEN CAST('' AS CHAR(7)) 
							ELSE CAST(ISNULL(device_names.rank,'') AS CHAR(7)) END --as Rank
						+ CASE WHEN multi_labels.user_model_name IS NULL THEN CAST(ISNULL(device_names.name,'') AS CHAR(20))
							ELSE CAST(ISNULL(multi_labels.user_model_name,'') AS CHAR(20)) END --as Customer_Device
						+ CAST(device_names.name AS CHAR(20)) --as device_name
						AS QR_Code
					FROM APCSProDB.trans.lots
					INNER JOIN APCSProDB.method.device_names ON lots.act_device_name_id = device_names.id
					INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
					LEFT JOIN APCSProDB.method.multi_labels ON device_names.name = multi_labels.device_name
					WHERE lots.lot_no = @lot_no 
				END
				ELSE
				BEGIN
					SELECT 'FALSE' as [Is_Pass]
						, 'lot no not found in card. !!' as [Error_Message_ENG]
						, N'ไม่พบ lot no ใน card !!' as [Error_Message_THA]
						, N'ติดต่อ System !!' as [Handling]
						, '' AS Lot_no
						, '' as QR_Code
				END
			END
			---------------------------------------------------------
		END
		ELSE BEGIN
			SELECT 'FALSE' as [Is_Pass]
			, 'Card is used for lot that are no longer in production. !!' as [Error_Message_ENG]
			, N'Card นี้ถูกใช้กับ Lot ที่ไม่ได้อยู่ในกระบวนการผลิต !!' as [Error_Message_THA]
			, N'ติดต่อ System !!' as [Handling]
			, '' AS Lot_no
			, '' as QR_Code
		END


		END 
		ELSE IF(@get_type = 1)
		BEGIN  

			SELECT 'TRUE' AS Is_Pass
					, '' AS Error_Message_ENG
					, N'' AS Error_Message_THA
					, N'' AS Handling
					, TRIM([lots].[lot_no]) AS Lot_no
					, '' as QR_Code
				FROM [APCSProDB].[trans].[lots]
				WHERE [lots].[lot_no] = @lot_no

		END
		 
	END
	ELSE BEGIN
		SELECT 'FALSE' as [Is_Pass]
			, 'Card not found data. !!' as [Error_Message_ENG]
			, N'ไม่พบข้อมูลการใช้งาน Card !!' as [Error_Message_THA]
			, N'ติดต่อ System !!' as [Handling]
			, '' AS Lot_no
			, '' as QR_Code
	END

	----------------------------------------------------------------------------------------------
	 
END

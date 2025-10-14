
CREATE PROCEDURE [tg].[sp_get_link_print_label]
	-- Add the parameters for the stored procedure here
	@Print_Type INT = NULL, --#1 have ARC(All Reel), 0 no ARC(Reel by Reel)
	@Label_Type INT = NULL, --#1 reel, 0 hasuu
	@LotNo VARCHAR(20) = '',
	@ReelNo INT = NULL,
	@EmpNo VARCHAR(10) = '',
	@MachineId INT = NULL,
	@ProcessName VARCHAR(20) = '',
	@PrintVer INT = NULL --#1 New, 0 Old
AS
BEGIN
	--log on storedProcedureDB
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
	  , [record_class]
	  , [login_name]
	  , [hostname]
	  , [appname]
	  , [command_text] 
	  , [lot_no]) 
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [tg].[sp_get_link_print_label] Access Store @lotno = ''' + ISNULL(@LotNo ,'NULL')
			+ ''', @Print_Type = ''' + ISNULL(CONVERT (varchar (2), @Print_Type),'NULL')
			+ ''', @Label_Type = '''+ ISNULL(CONVERT (varchar (2), @Label_Type),'NULL') 
			+ ''', @ReelNo = ''' + ISNULL(CONVERT (varchar (3), @ReelNo) ,'NULL')
			+ ''', @EmpNo = ''' + ISNULL(@EmpNo,'NULL') 
			+ ''', @MachineId = ''' + ISNULL(CONVERT (varchar (10), @MachineId) ,'NULL')
			+ ''', @ProcessName = ''' + @ProcessName 
			+ ''', @PrintVer = ''' + ISNULL(CONVERT (varchar (2), @PrintVer),'NULL') + ''''
		, @LotNo
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @checkAluminum varchar(10) = ''
	DECLARE @checkIsIncoming int = null
	DECLARE @checkTube varchar(10) = ''
	DECLARE @checkTray varchar(10) = ''

	SELECT 
	  @checkAluminum = CASE WHEN pvt.id is null THEN ''
		WHEN pvt.ALUMINUM IS NULL THEN 'NO USE' ELSE  'USE' END --AS ALUMINUM
	, @checkIsIncoming = CASE WHEN device_names.is_incoming IS NULL THEN 0 ELSE device_names.is_incoming END --AS is_incoming
	, @checkTube = CASE WHEN pvt.id is null THEN ''
		  WHEN TUBE IS NULL THEN 'NO USE' ELSE  'USE' END --AS TUBE
	, @checkTray = CASE WHEN pvt.id is null THEN ''
		  WHEN TRAY IS NULL THEN 'NO USE' ELSE  'USE ' END --AS TRAY
	FROM APCSProDB.trans.lots INNER JOIN 
		[APCSProDB].method.device_slips ON device_slips.device_slip_id = lots.device_slip_id 
		INNER JOIN [APCSProDB].method.device_versions ON device_versions.device_id = device_slips.device_id 
		AND [APCSProDB].method.device_slips.is_released = 1 
		INNER JOIN
		[APCSProDB].method.device_names ON [APCSProDB].method.device_names.id = [APCSProDB].method.device_versions.device_name_id INNER JOIN
		[APCSProDB].method.packages ON [APCSProDB].method.device_names.package_id = [APCSProDB].method.packages.id INNER JOIN					   
		[APCSProDB].method.device_flows ON [APCSProDB].method.device_slips.device_slip_id = [APCSProDB].method.device_flows.device_slip_id
	LEFT JOIN  
		(SELECT  ms.id,ms.name,comment,details,p.name as mat_name
		 FROM	[APCSProDB].method.material_sets ms 
				INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
				[APCSProDB].material.productions p ON ml.material_group_id = p.id 
			  where (ms.process_id = 317 OR ms.process_id = 18)
			) mat
	PIVOT ( 
		max(mat_name)
		FOR details
		IN (
		[TOMSON],[AIR BUBBLE],[ALUMINUM],[INDICATOR],[SILIGA GEL],[SPACER],[TUBE],[TRAY]
		)
	) as pvt ON [APCSProDB].method.device_flows.material_set_id = pvt.id

	LEFT JOIN (SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(VARCHAR(10), CONVERT(int, use_qty)) + ' '+ il.label_eng as use_qty
						FROM  [APCSProDB].method.material_sets ms 
						   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
						   [APCSProDB].material.productions p ON ml.material_group_id = p.id LEFT JOIN
						   APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
		  where (ms.process_id = 317 OR ms.process_id = 18) and details = 'SILIGA GEL'
		) AS m_qty ON m_qty.id = pvt.id

	LEFT JOIN (SELECT ms.id,ms.name,comment,details,p.name as mat_name,tomson_code
						FROM  [APCSProDB].method.material_sets ms 
						   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
						   [APCSProDB].material.productions p ON ml.material_group_id = p.id
		  where (ms.process_id = 317 OR ms.process_id = 18) and details = 'TOMSON'
		) AS tomson_box ON tomson_box.id = pvt.id

	LEFT JOIN (SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(VARCHAR(10), CONVERT(int, use_qty)) + ' '+ il.label_eng as use_qty_tray 
	FROM [APCSProDB].method.material_sets ms 
	INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id 
	INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id 
	LEFT JOIN APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
	where (ms.process_id = 317 OR ms.process_id = 18) and details = 'TRAY'
	) AS tray_qty ON tray_qty.id = pvt.id

	LEFT JOIN StoredProcedureDB.dbo.IS_PACKING_MAT as pack_mat on device_names.name = pack_mat.ROHM_Model_Name
	LEFT JOIN [APCSProDB].[method].[jobs] AS [job] ON [job].[id] = device_flows.[job_id]
	WHERE device_flows.job_id in (317,412)
	and lot_no = @LotNo 
	ORDER BY packages.name,device_names.name

	DECLARE @PcInstructionCode INT = NULL
	    -- TP PROCESS --
		, @LinkOldAll VARCHAR(MAX) = 'http://webserv/rohmtest/Atom/LabelFormatV2/GetDataAutoPrint_TP?'  --PrintAllLabel
		, @LinkNewAll VARCHAR(MAX) = 'http://webserv/rohmtest/Atom/LabelFormatV2/GetDataAutoPrintAllReel_TP_NewFC_View?'  --PrintAllLabel
		, @LinkOldReelAndHasuu VARCHAR(MAX) = 'http://webserv.thematrix.net/rohmtest/Atom/LabelFormatV2/AutoPrintLabelTypeReelandHasuu?'   --PrintReelandHasuu
		, @LinkNewReelAndHasuu VARCHAR(MAX) = 'http://webserv.thematrix.net/rohmtest/Atom/LabelFormatV2/AutoPrintLabelTypeReelandHasuuView?'  --PrintReelandHasuu
		, @LinkPCRequest VARCHAR(MAX) = 'http://webserv.thematrix.net/rohmtest/Atom/LabelFormatV2/GetDataAutoPrintPCRequest_TP_NewFC_View?' --LabelPCRequest
		--- OGI PROCESS ---
		, @LinkIncomingLabel VARCHAR(MAX) = 'http://webserv.thematrix.net/ROHMTEST/Atom/LabelFormatV2/AutoPrintIncomingLabel_NewFC_View?'
		, @LinkTrayLabel VARCHAR(MAX) = 'http://webserv/rohmtest/atom/LabelFormatV2/AutoPrintLabelTypeTrayNewFC?'
		, @LinkShipmentAll VARCHAR(MAX) = 'http://webserv/rohmtest/atom/LabelFormatV2/ShipmentAllOGiNewFC_View?'   --PC Instruction Code is 11
		, @LinkPCRequestofTube VARCHAR(MAX) = 'http://webserv/rohmtest/atom/LabelFormatV2/AutoPrintPCRequestOGiNewFC_View?'  --PC Instruction Code is 13
		, @LinkNormal VARCHAR(MAX) = 'http://webserv/rohmtest/atom/LabelFormatV2/AutoPrintLabelNormalTypeTomson?'

	SELECT @PcInstructionCode = [pc_instruction_code] 
	FROM [APCSProDB].[trans].[lots] 
	WHERE [lot_no] = @LotNo
	-- #--------------------------------------------------------------------------------------------------------# --
	IF (@ProcessName = 'TP')
	BEGIN
		IF @PcInstructionCode = 11  --Shipment All
		BEGIN
			IF @Print_Type = 1 --have ARC will print reel all
			BEGIN
				IF @Label_Type = 1
				BEGIN
					SELECT IIF(@PrintVer = 1, @LinkNewAll, @LinkOldAll) 
							+ 'Lotno=' + @LotNo 
							+ '&Type_of_label=3' 
							+ '&No_reel='
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, IIF(@PrintVer = 1,'Shipment All New Version and have ARC (REEL)','Shipment All Old Version and have ARC (REEL)')  AS [Comment]
				END
				ELSE IF @Label_Type = 0
				BEGIN
					SELECT IIF(@PrintVer = 1, @LinkNewReelAndHasuu, @LinkOldReelAndHasuu) 
							+ 'Lotno=' + @LotNo 
							+ '&Type_of_label=2' 
							+ '&No_reel='
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, IIF(@PrintVer = 1,'Shipment All New Version and have ARC (HASUU)','Shipment All Old Version and have ARC (HASUU)') AS [Comment]
				END
			END
			ELSE IF @Print_Type = 0 --no ARC will print reel
			BEGIN
				IF @Label_Type = 1
				BEGIN
					SELECT IIF(@PrintVer = 1, @LinkNewReelAndHasuu, @LinkOldReelAndHasuu)  
							+ 'Lotno=' + @LotNo 
							+ '&Type_of_label=3' 
							+ '&No_reel=' + CAST(@ReelNo AS VARCHAR(10))
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, IIF(@PrintVer = 1,'Shipment All New Version and no have ARC (REEL)','Shipment All Old Version and no have ARC (REEL)') AS [Comment]
				END
				ELSE IF @Label_Type = 0
				BEGIN
					SELECT IIF(@PrintVer = 1, @LinkNewReelAndHasuu, @LinkOldReelAndHasuu)  
							+ 'Lotno=' + @LotNo 
							+ '&Type_of_label=2' 
							+ '&No_reel=' 
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, IIF(@PrintVer = 1,'Shipment All New Version and no have ARC (HASUU)','Shipment All Old Version and no have ARC (HASUU)') AS [Comment]
				END
			END 
		END
		ELSE IF @PcInstructionCode = 13 --Hasuu Shipment  (New link)
		BEGIN
			IF @Print_Type = 1 OR @Print_Type = 0 --have ARC will print reel all
			BEGIN
				IF @Label_Type = 1
				BEGIN
					SELECT @LinkPCRequest
							+ 'Lotno=' + @LotNo 
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, 'Hasuu Shipment new version (REEL)' AS [Comment]
				END
				ELSE IF @Label_Type = 0
				BEGIN
					SELECT IIF(@PrintVer = 1, @LinkNewReelAndHasuu, @LinkOldReelAndHasuu)
							+ 'Lotno=' + @LotNo 
							+ '&Type_of_label=2' 
							+ '&No_reel='
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, IIF(@PrintVer = 1,'Hasuu to stock in and new version','Hasuu to stock in and old version')  AS [Comment]
				END
			END
		END
		ELSE
		BEGIN
			--Normal Type Label
			IF @Print_Type = 1 --have ARC(All Reel)
			BEGIN
				SELECT IIF(@PrintVer = 1, @LinkNewAll, @LinkOldAll) 
						+ 'Lotno=' + @LotNo 
						+ '&Type_of_label=3' 
						+ '&No_reel='
						+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
					AS [Link]
					, IIF(@PrintVer = 1,'Normal new version and have ARC (All Reel)','Normal and old version no have ARC (All Reel)') AS [Comment]
			END
			ELSE IF @Print_Type = 0 --no ARC(Reel by Reel)
			BEGIN
				SELECT IIF(@PrintVer = 1, @LinkNewReelAndHasuu, @LinkOldReelAndHasuu) 
						+ 'Lotno=' + @LotNo 
						+ '&Type_of_label=3' 
						+ '&No_reel=' + CAST(@ReelNo AS VARCHAR(10))
						+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
					AS [Link]
					, IIF(@PrintVer = 1,'Normal new version and no have ARC (Reel by Reel)','Normal old version and no have ARC (Reel by Reel)') AS [Comment]
			END
		END
	END
	-- #--------------------------------------------------------------------------------------------------------# --
	ELSE IF (@ProcessName = 'OGI')
	BEGIN
		IF @PcInstructionCode = 11   --shipment all
		BEGIN
			IF @checkTray = 'USE'
			BEGIN
				IF @checkAluminum = 'USE'
				BEGIN
					SELECT @LinkTrayLabel
							+ 'Lotno=' + @LotNo 
							+ '&type_of_label=6' 
							+ '&tomson_number=' + CAST(@ReelNo AS VARCHAR(10))
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, 'Tray use and Aluminum use (type of label = 6)'  AS [Comment]
				END
				ELSE IF @checkAluminum = 'NO USE'
				BEGIN
					SELECT @LinkTrayLabel
							+ 'Lotno=' + @LotNo 
							+ '&type_of_label=5' 
							+ '&tomson_number=' + CAST(@ReelNo AS VARCHAR(10))
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, 'Tray use and Aluminum no use will print tomson only (type of label = 5)'  AS [Comment]
				END
			END
			ELSE IF @checkTray = 'NO USE'
			BEGIN
				SELECT @LinkShipmentAll
							+ 'Lotno=' + @LotNo 
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, 'Tray use and Aluminum no use (shipment all pc code is 11)'  AS [Comment]
			END
		END
		ELSE IF @PcInstructionCode = 13  -- Hasuu shipment
		BEGIN
			SELECT @LinkPCRequestofTube
					+ 'Lotno=' + @LotNo 
					+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
				AS [Link]
				, 'Hasuu sipment pc code is 13'  AS [Comment]
		END
		ELSE
		BEGIN
			--strat check type incoming work if status is 1 will is incoming type
			IF @checkIsIncoming = 1
			BEGIN
				IF @checkAluminum = 'USE'
				BEGIN
					SELECT @LinkNormal
							+ 'Lotno=' + @LotNo 
							+ '&Type_label_DryPack=4' 
							+ '&Type_label_Tomson=0' 
							+ '&Reel_num=' + CAST(@ReelNo AS VARCHAR(10))
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, 'Incoming have aluminum use (type of label = 4)'  AS [Comment]
				END
				ELSE IF @checkAluminum = 'NO USE'
				BEGIN
					SELECT @LinkIncomingLabel
							+ 'Lotno=' + @LotNo 
							+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
						AS [Link]
						, 'Incoming no have aluminum use (type of label incoming)'  AS [Comment]
				END
			END
			ELSE
			BEGIN
				--check type tray use
				IF @checkTray = 'USE'  --is tray
				BEGIN
					IF @checkAluminum = 'USE'
					BEGIN
						SELECT @LinkTrayLabel
								+ 'Lotno=' + @LotNo 
								+ '&type_of_label=6' 
								+ '&tomson_number=' + CAST(@ReelNo AS VARCHAR(10))
								+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
							AS [Link]
							, 'Tray use and Aluminum use (type of label = 6)'  AS [Comment]
					END
					ELSE IF @checkAluminum = 'NO USE'
					BEGIN
						SELECT @LinkTrayLabel
								+ 'Lotno=' + @LotNo 
								+ '&type_of_label=5' 
								+ '&tomson_number=' + CAST(@ReelNo AS VARCHAR(10))
								+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
							AS [Link]
							, 'Tray use and Aluminum no use will print tomson only (type of label = 5)'  AS [Comment]
					END
				END
				ELSE IF @checkTray = 'NO USE'  --is normal
				BEGIN
					IF @checkAluminum = 'USE'
					BEGIN
						SELECT @LinkNormal
								+ 'Lotno=' + @LotNo 
								+ '&Type_label_DryPack=4' 
								+ '&Type_label_Tomson=5' 
								+ '&Reel_num=' + CAST(@ReelNo AS VARCHAR(10))
								+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
							AS [Link]
							, 'Tray use and Aluminum use (type of label = 4 and 5)'  AS [Comment]
					END
					ELSE IF @checkAluminum = 'NO USE'
					BEGIN
						SELECT @LinkNormal
								+ 'Lotno=' + @LotNo 
								+ '&Type_label_DryPack=0' 
								+ '&Type_label_Tomson=5' 
								+ '&Reel_num=' + CAST(@ReelNo AS VARCHAR(10))
								+ '&Mcno=' + ISNULL((SELECT [name] FROM [APCSProDB].[mc].[machines] WHERE [id] = @MachineId),'')
							AS [Link]
							, 'Tray use and Aluminum no use will print tomson only (type of label = 5)'  AS [Comment]
					END
				END
			END
			--end check incoming label type
		END
	END
	-- #--------------------------------------------------------------------------------------------------------# --
END

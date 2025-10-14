-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_inventory_bylot_ver_002]
	@lot_no NVARCHAR(10) =  0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @datetime DATETIME
		, @year_now	INT = 0 
		, @lot_id INT
		, @process_state INT = 0
		, @MC NVARCHAR(100) =  ''
		, @wip INT 
		, @production_category INT 
		, @qty INT = 0

	SET @lot_id = ( SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no );
	SET @datetime = GETDATE();
	SET @year_now = ( FORMAT( @datetime, 'yy' ) - 3 );

	---- # SET @process_state, @wip
	SELECT @process_state = ( 
		CASE WHEN [lots].[is_special_flow] = 1 THEN [special_flows].[process_state]
			ELSE [lots].[process_state]   
		END ) 
		, @wip = [lots].[wip_state]   
	FROM [APCSProDB].[trans].[lots]
	LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lots].[id] = [special_flows].[lot_id]
		AND [lots].[special_flow_id] = [special_flows].[id]
		AND [lots].[is_special_flow] = 1
	WHERE [lots].[id] = @lot_id;
 
	---- # check find lot
	--EXIST TRAN LOT  
	IF NOT EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no ) 
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Data in trans.lot not found' AS [Error_Message_ENG]
			, N'ไม่พบข้อมูลใน trans.lot ' AS [Error_Message_THA] 
			, '' AS [Handling];
		RETURN;
	END

	---- # check child lot DB
	--CHILD LOT
	IF NOT EXISTS ( 
		SELECT 1 FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
		WHERE [lot_no] = @lot_no 
			AND [device_names].[is_assy_only] IN ( 0, 1 )
	)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Cannot register child lot !!' AS [Error_Message_ENG]
			, N'ไม่สามารถลงทะเบียน Lot ลูกได้  !!' AS [Error_Message_THA] 
			, N'ติดต่อ System' AS [Handling];
		RETURN;
	END

	---- # 1) get and check wip
	IF NOT EXISTS ( SELECT 'xxx' FROM [APCSProDB].[trans].[surpluses] WHERE [lot_id] = @lot_id AND [in_stock] = 2 AND [pcs] > 0 ) 
		AND @wip = 20  
	BEGIN 
		---- # ----------------------------------------------------------- # ----
		---- # 1.1) if not exists data inven wip
		IF NOT EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lot_inventory] WHERE [lot_id] = @lot_id  AND [stock_class] = '01' )
		BEGIN
			---- # ----------------------------------------------------------- # ----
			---- # don't have data inven wip
			---- # set @process_state, @production_category
			SELECT	@process_state = (
				CASE WHEN [lots].[is_special_flow] = 1 THEN [special_flows].[process_state]
					ELSE [lots].[process_state] 
				END )
				, @production_category = [lots].[production_category]
			FROM [APCSProDB].[trans].[lots]
			LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lots].[id] = [special_flows].[lot_id]
				AND [lots].[special_flow_id] = [special_flows].[id] 
				AND [lots].[is_special_flow] =  1
			WHERE [lots].[id]  = @lot_id;

			---- # IF 1 @process_state 2, 102 ON MACHINE (WIP)
			IF (@process_state  IN (2, 102)) 
			BEGIN 
				---- # ----------------------------------------------------------- # ----
				---- # return
				SELECT 'TRUE' AS [Is_Pass] 
					, '' AS [Error_Message_ENG]
					, N'' AS [Error_Message_THA] 
					, '' AS [Handling]
					, ROW_NUMBER() OVER ( ORDER BY [lots].[created_at] ) AS [No]
					, [lots].[id] AS [lot_id]
					, ISNULL([pk].[name], '') AS [pack_name]
					, ISNULL([dn].[name], '') AS [device_name]
					, ISNULL([lots].[lot_no], '') AS [lot_no]
					, ( CASE WHEN [lots].[act_job_id] = 317 THEN   
							IIF ( [pc_instruction_code] = 11
								, ISNULL([lots].[qty_out], 0) + ISNULL([lots].[qty_hasuu], 0) --# = 11
								, ( CASE WHEN ISNULL([lots].[qty_out], 0) = 0 THEN [lots].[qty_pass]
									ELSE [lots].[qty_out]
								END ) --# != 11
							)
						ELSE 
							( CASE WHEN ISNULL([lots].[qty_out], 0) <> 0  THEN [lots].[qty_out]
								ELSE [lots].[qty_pass]
							END )
					END ) AS [qty]
					, 'ON MACHINE' AS [rack_name]
					, 'WIP' AS [status_lot]
					, 1 AS [stock_class] 
				FROM [APCSProDB].[trans].[lots]  
				INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id]
				INNER JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id]
				LEFT JOIN [APCSProDB].[trans].[locations] AS [loca] ON [lots].[location_id] = [loca].[id]
				WHERE [lots].[id] = @lot_id
				ORDER BY [lots].[lot_no];
				RETURN;
				---- # ----------------------------------------------------------- # ----
			END
			---- # IF 2 don't have location rack 					
			ELSE IF  EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id AND [location_id] IS NULL )
			BEGIN
				---- # ----------------------------------------------------------- # ----
				SELECT 'FALSE' AS [Is_Pass] 
					, 'Rack is not yet registered.' AS [Error_Message_ENG]
					, N'ยังไม่ลงทะเบียน Rack' AS [Error_Message_THA] 
					, '' AS [Handling];
				RETURN;
				---- # ----------------------------------------------------------- # ----
			END
			---- # IF @production_category IN 23:D Rework, 70:D Recall
			ELSE IF (@production_category IN (23, 70))
			BEGIN 
				---- # ----------------------------------------------------------- # ----
				---- # set @qty
				IF EXISTS ( 
					SELECT TOP 1 [lots].[lot_no] 
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[lot_process_records] ON [lots].[id] = [lot_process_records].[lot_id]
						AND [lot_process_records].[record_class] = 1 --1 :LotStart
						AND [lot_process_records].[job_id] IN (93, 199, 209, 222, 236, 289, 293, 323, 332, 401, 92, 143, 287, 291, 369)
					WHERE [lots].[lot_no] = @lot_no
				)
				BEGIN
					SET @qty = ( SELECT ISNULL([qty_out], 0)  FROM [APCSProDB].[trans].[lots] WHERE [lots].[lot_no] = @lot_no );
				END
				ELSE
				BEGIN
					SET @qty = (SELECT ISNULL([qty_pass], 0) FROM [APCSProDB].[trans].[lots] WHERE [lots].[lot_no] = @lot_no );
				END

				---- # return
				SELECT 'TRUE' AS [Is_Pass] 
					, '' AS [Error_Message_ENG]
					, N'' AS [Error_Message_THA] 
					, '' AS [Handling]
					, ROW_NUMBER() OVER ( ORDER BY [lots].[created_at] ) AS [No]
					, [lots].[id] AS [lot_id]
					, ISNULL([pk].[name], '') AS [pack_name]
					, ISNULL([dn].[name], '') AS [device_name]
					, ISNULL(lots.lot_no, '') AS [lot_no]
					, ( CASE WHEN [lots].[act_job_id] = 317 THEN
							IIF ( [pc_instruction_code] = 11
								, ISNULL([lots].[qty_out], 0) + ISNULL([lots].[qty_hasuu], 0)
								, ( CASE WHEN ISNULL([lots].[qty_out], 0) = 0
									THEN [lots].[qty_pass] 
									ELSE [lots].[qty_out] 
								END ) 
							)
						ELSE @qty  
					END ) AS [qty]
					, ISNULL([loca].[name] ,'') AS [rack_name]
					, 'WIP' AS [status_lot]
					, 1 AS [stock_class] 
				FROM [APCSProDB].[trans].[lots]  
				INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id]
				INNER JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id]
				LEFT JOIN [APCSProDB].[trans].[locations] AS [loca] ON [lots].[location_id] = [loca].[id]
				WHERE [lots].[id] = @lot_id
				ORDER BY [lots].[lot_no];
				RETURN;
				---- # ----------------------------------------------------------- # ----
			END 
			---- # ELSE					
			ELSE
			BEGIN
				---- # ----------------------------------------------------------- # ----
				---- # return
				SELECT 'TRUE' AS [Is_Pass] 
					, '' AS [Error_Message_ENG]
					, N'' AS [Error_Message_THA] 
					, '' AS [Handling]
					, ROW_NUMBER() OVER ( ORDER BY [lots].[created_at] ) AS [No]
					, [lots].[id] AS [lot_id]
					, ISNULL([pk].[name], '') AS [pack_name]
					, ISNULL([dn].[name], '') AS [device_name]
					, ISNULL([lots].[lot_no], '') AS [lot_no]
					, ( CASE WHEN [lots].[act_job_id] = 317 THEN   
							IIF ( [pc_instruction_code] = 11
								, ISNULL([lots].[qty_out], 0) + ISNULL([lots].[qty_hasuu], 0) --# = 11
								, ( CASE WHEN ISNULL([lots].[qty_out], 0) = 0 THEN [lots].[qty_pass]
									ELSE [lots].[qty_out]
								END ) --# != 11
							)
						ELSE 
							( CASE WHEN ISNULL([lots].[qty_out], 0) <> 0  THEN [lots].[qty_out]
								ELSE [lots].[qty_pass]
							END )
					END ) AS [qty]
					, ISNULL([loca].[name], '') AS [rack_name]
					, 'WIP' AS [status_lot]
					, 1 AS [stock_class] 
				FROM [APCSProDB].[trans].[lots]  
				INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id]
				INNER JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id]
				LEFT JOIN [APCSProDB].[trans].[locations] AS [loca] ON [lots].[location_id] = [loca].[id]
				WHERE [lots].[id] = @lot_id
				ORDER BY [lots].[lot_no];
				RETURN;
				---- # ----------------------------------------------------------- # ----
			END
			---- # ----------------------------------------------------------- # ----
		END
		ELSE
		BEGIN
			---- # ----------------------------------------------------------- # ----
			---- # have data inven wip
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Duplicate information' AS [Error_Message_ENG]
				, N'ข้อมูลถูกลงทะเบียนใน Inventory แล้ว' AS [Error_Message_THA] 
				, '' AS [Handling];
			RETURN;
			---- # ----------------------------------------------------------- # ----
		END
		---- # ----------------------------------------------------------- # ----
	END
	
	---- # 2) get and check hasuu processing
	ELSE IF EXISTS ( 
		SELECT 'xxx' FROM [APCSProDB].[trans].[surpluses] AS [sur] 
		INNER JOIN [APCSProDB].[trans].[lots] ON [sur].[lot_id] = [lots].[id]  
		WHERE [sur].[in_stock] = 2 
			AND [sur].[lot_id] = @lot_id 
			AND [lots].[wip_state] = 20 
			AND [sur].[pcs] > 0
	)
	BEGIN 
		---- # ----------------------------------------------------------- # ----
		---- # IF 1 have data lot_inventory and have data in LotStart 
		IF NOT EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lot_inventory] WHERE [lot_id]  = @lot_id AND [stock_class] IN (02, 03) )
			AND EXISTS  ( 
				SELECT TOP 1 [lots].[lot_no] 
				FROM [APCSProDB].[trans].[lots] 
				INNER JOIN [APCSProDB].[trans].[lot_process_records] ON [lots].[id] = [lot_process_records].[lot_id]
					AND [lot_process_records].[record_class] = 1 --1 :LotStart
					AND [lot_process_records].[job_id] IN (93, 199, 209, 222, 236, 289, 293, 323, 332, 401, 92, 143, 287, 291, 369)
				WHERE [lots].[lot_no] = @lot_no
			)
		BEGIN
			---- # ----------------------------------------------------------- # ----	
			IF NOT EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lot_inventory] WHERE [lot_id]  = @lot_id AND [stock_class] IN (02,03) ) 
			BEGIN 
				---- # ----------------------------------------------------------- # ----
				SELECT 'TRUE' AS [Is_Pass] 
					, '' AS [Error_Message_ENG]
					, N'' AS [Error_Message_THA] 
					, '' AS [Handling]
					, ROW_NUMBER() OVER ( ORDER BY [sur].[created_at] ) AS [No]
					, [lots].[id] AS [lot_id]
					, ISNULL([pk].[name], '') AS [pack_name]
					, ISNULL([dn].[name], '') AS [device_name]
					, ISNULL([sur].[serial_no], '') AS [lot_no]
					, ISNULL([sur].[pcs], '') AS [qty]
					, IIF([loca ].[name] IS NULL, 'ON MACHINE', [loca].[name]) AS [rack_name]
					, ISNULL(CASE WHEN SUBSTRING([sur].[serial_no], 1, 2) >= @year_now THEN 'HASUU NOW' ELSE 'HASUU LONG' END,0) AS [status_lot]
					, ISNULL(CASE WHEN SUBSTRING([sur].[serial_no], 1, 2) >= @year_now THEN 2 ELSE 3 END, 0) AS [stock_class] 
				FROM APCSProDB.trans.surpluses AS sur
				INNER JOIN APCSProDB.trans.lots on sur.lot_id = lots.id
				INNER JOIN APCSProDB.method.packages AS pk on lots.act_package_id = pk.id
				INNER JOIN APCSProDB.method.device_names AS dn on lots.act_device_name_id = dn.id
				LEFT JOIN APCSProDB.trans.locations AS loca on sur.location_id = loca.id
				WHERE [sur].[lot_id] = @lot_id
					AND [sur].[serial_no] <> ''
				ORDER BY [sur].[serial_no]
				RETURN;
				---- # ----------------------------------------------------------- # ----
			END
			ELSE
			BEGIN 
				---- # ----------------------------------------------------------- # ----
				SELECT 'FALSE' AS [Is_Pass]
					, 'Duplicate information' AS [Error_Message_ENG]
					, N'ข้อมูลถูกลงทะเบียนใน Inventory แล้ว' AS [Error_Message_THA] 
					, '' AS [Handling];
				RETURN;
				---- # ----------------------------------------------------------- # ----
			END
			---- # ----------------------------------------------------------- # ----
		END
		---- # IF 2 inventory wip done but have husuu processing 
		ELSE IF NOT EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lot_inventory] WHERE [lot_id] = @lot_id AND [stock_class] IN (02,03) )
			AND NOT EXISTS ( 
				SELECT TOP 1 [lots].[lot_no] 
				FROM [APCSProDB].[trans].[lots] 
				INNER JOIN [APCSProDB].[trans].[lot_process_records] ON [lots].[id] = [lot_process_records].[lot_id]
					AND [lot_process_records].[record_class] = 1 --1 :LotStart
					AND [lot_process_records].[job_id] IN (93, 199, 209, 222, 236, 289, 293, 323, 332, 401, 92, 143, 287, 291, 369)
				WHERE [lots].[lot_no] = @lot_no
			)
		BEGIN 
			---- # ----------------------------------------------------------- # ----	
			IF NOT EXISTS (SELECT 'xx' FROM [APCSProDB].[trans].[lot_inventory] WHERE [lot_id] = @lot_id AND [stock_class] = 01 )
			BEGIN 
				---- # ----------------------------------------------------------- # ----
				---- # set @qty
				IF EXISTS ( 
					SELECT TOP 1 [lots].[lot_no] 
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[lot_process_records] ON [lots].[id] = [lot_process_records].[lot_id]
						AND [lot_process_records].[record_class] = 1 --1 :LotStart
						AND [lot_process_records].[job_id] IN (93, 199, 209, 222, 236, 289, 293, 323, 332, 401, 92, 143, 287, 291, 369)
					WHERE [lots].[lot_no] = @lot_no
				)
				BEGIN
					SET @qty  = ( SELECT ISNULL([qty_out], 0)  FROM [APCSProDB].[trans].[lots] WHERE [lots].[lot_no] = @lot_no )
				END
				ELSE
				BEGIN
					SET @qty  = (SELECT ISNULL([qty_pass], 0) FROM [APCSProDB].[trans].[lots] WHERE [lots].[lot_no] = @lot_no )
				END

				---- # check location_id
				IF EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id AND [location_id] IS NULL )
				BEGIN
					---- # ----------------------------------------------------------- # ----
					SELECT 'FALSE' AS [Is_Pass] 
						, 'Rack is not yet registered.' AS [Error_Message_ENG]
						, N'ยังไม่ลงทะเบียน Rack' AS [Error_Message_THA] 
						, '' AS [Handling]
					RETURN;
					---- # ----------------------------------------------------------- # ----
				END	
				ELSE
				BEGIN
					---- # ----------------------------------------------------------- # ----
					SELECT 'TRUE' AS [Is_Pass] 
						, '' AS [Error_Message_ENG]
						, N'' AS [Error_Message_THA] 
						, '' AS [Handling]
						, ROW_NUMBER() OVER ( ORDER BY [lots].[created_at] ) AS [No]
						, [lots].[id] AS [lot_id]
						, ISNULL([pk].[name], '') AS [pack_name]
						, ISNULL([dn].[name], '') AS [device_name]
						, ISNULL([lots].[lot_no],'') AS [lot_no]
						, ( CASE WHEN IIF([lots].[is_special_flow] = 1, [lsp].[job_id], [lots].[act_job_id]) = 317 THEN
								IIF ( [pc_instruction_code] = 11
									, ISNULL([lots].[qty_out], 0) + ISNULL([lots].[qty_hasuu], 0)
									, (CASE WHEN ISNULL([lots].[qty_out], 0) = 0 THEN [lots].[qty_pass] 
										ELSE [lots].[qty_out]
									END ) 
								)
							ELSE @qty  
						END ) AS [qty]
						, [loca].[name] AS [rack_name]
						, 'WIP' AS [status_lot]
						, 1 AS [stock_class]
					FROM [APCSProDB].[trans].[lots]  
					INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id]
					INNER JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id]
					LEFT JOIN [APCSProDB].[trans].[locations] AS [loca] ON [lots].[location_id] =  [loca].[id]
					LEFT JOIN [APCSProDB].[trans].[special_flows] AS [sp] ON [lots].[special_flow_id] = [sp].[id]
						AND [lots].[is_special_flow] = 1
					LEFT JOIN [APCSProDB].[trans].[lot_special_flows] AS [lsp] ON [sp].[id] = [lsp].[special_flow_id]
						AND [sp].[step_no] = [lsp].[step_no]
					WHERE [lots].[id] = @lot_id
					ORDER BY [lots].[lot_no];
					RETURN;
					---- # ----------------------------------------------------------- # ----
				END
				---- # ----------------------------------------------------------- # ----		
			END 
			ELSE
			BEGIN
				SELECT 'FALSE' AS [Is_Pass] 
					, 'Duplicate information' AS [Error_Message_ENG]
					, N'ข้อมูลถูกลงทะเบียนใน Inventory แล้ว' AS [Error_Message_THA] 
					, '' AS [Handling];
				RETURN;
			END 
			---- # ----------------------------------------------------------- # ----
		END
		---- # IF 3 inventory husuu done but have wip processing 
		ELSE IF EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lot_inventory] WHERE [lot_id] = @lot_id AND [stock_class] IN (02,03) ) 
		BEGIN 
			---- # ----------------------------------------------------------- # ----
			IF NOT EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lot_inventory] WHERE [lot_id]  = @lot_id AND stock_class =  01 )
			BEGIN
				---- # ----------------------------------------------------------- # ----
				SELECT 'TRUE' AS [Is_Pass] 
					, '' AS [Error_Message_ENG]
					, N'' AS [Error_Message_THA]
					, '' AS [Handling]
					, ROW_NUMBER() OVER ( ORDER BY [lots].[created_at] ) AS [No]
					, [lots].[id] AS [lot_id]
					, ISNULL([pk].[name], '') AS [pack_name]
					, ISNULL([dn].[name], '') AS [device_name]
					, ISNULL([lots].[lot_no], '') AS [lot_no]
					, ( CASE WHEN [lots].[act_job_id] = 317 THEN
							IIF ( pc_instruction_code = 11
								, ISNULL([lots].[qty_out], 0) + ISNULL([lots].[qty_hasuu], 0)
								, ( CASE WHEN ISNULL([lots].[qty_out], 0) = 0 THEN [lots].[qty_pass] 
									ELSE [lots].[qty_out]
								END ) 
							)
						ELSE 
							( CASE WHEN ISNULL([lots].[qty_out], 0)  <> 0 THEN [lots].[qty_out]
								ELSE [lots].[qty_pass]
							END )
					END ) AS [qty]
					, IIF([loca].[name] IS NULL, 'ON MACHINE', [loca].[name]) AS [rack_name]
					, 'WIP' AS [status_lot]
					, 1 AS [stock_class] 
				FROM APCSProDB.trans.lots  
				INNER JOIN APCSProDB.method.packages AS pk on lots.act_package_id = pk.id
				INNER JOIN APCSProDB.method.device_names AS dn on lots.act_device_name_id = dn.id
				LEFT JOIN APCSProDB.trans.locations AS loca on lots.location_id = loca.id
				WHERE [lots].[id] = @lot_id
				ORDER BY [lots].[lot_no];
				RETURN;
				---- # ----------------------------------------------------------- # ----
			END 
			ELSE
			BEGIN
				---- # ----------------------------------------------------------- # ----
				SELECT 'FALSE' AS [Is_Pass] 
					, 'Duplicate information' AS [Error_Message_ENG]
					, N'ข้อมูลถูกลงทะเบียนใน Inventory แล้ว' AS [Error_Message_THA] 
					, '' AS [Handling];
				RETURN;
				---- # ----------------------------------------------------------- # ----
			END 
			---- # ----------------------------------------------------------- # ----	
		END
		---- # ----------------------------------------------------------- # ----
	END
	
	---- # 3) get and check hasuu
	ELSE IF EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[surpluses] WHERE [lot_id] = @lot_id AND [in_stock] IN (2, 4,3) AND [pcs] > 0 ) 
		AND @wip IN (70, 100)
	BEGIN 
		---- # ----------------------------------------------------------- # ----
		---- # IF 1 
		IF NOT EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[surpluses] WHERE [lot_id] = @lot_id )
		BEGIN
			---- # ----------------------------------------------------------- # ----
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Data in trans.surpluses not found' AS [Error_Message_ENG]
				, N'ไม่พบข้อมูลใน trans.surpluses ' AS [Error_Message_THA] 
				, '' AS [Handling];
			RETURN;
			---- # ----------------------------------------------------------- # ----
		END
		---- # IF 2 have instock != 2
		--ELSE IF  EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[surpluses] WHERE [lot_id] = @lot_id AND [in_stock] <> 2 )
		ELSE IF  EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[surpluses] WHERE [lot_id] = @lot_id AND [in_stock] not in (2,3))  --#update codition 2025/03/31 by Aomsin
		BEGIN 
			---- # ----------------------------------------------------------- # ----
			IF EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[surpluses] WHERE [lot_id] = @lot_id AND [in_stock] = 4 )
			BEGIN
				---- # ----------------------------------------------------------- # ----
				SELECT 'FALSE' AS [Is_Pass] 
					, 'Duplicate information' AS [Error_Message_ENG]
					, N'ข้อมูลถูกลงทะเบียนใน Inventory แล้ว' AS [Error_Message_THA] 
					, '' AS [Handling];
				RETURN;
				---- # ----------------------------------------------------------- # ----
			END 	
			ELSE
			BEGIN
				---- # ----------------------------------------------------------- # ----
				SELECT 'FALSE' AS [Is_Pass]
					, 'This husuu has been ' + [item_labels].[label_eng] + '!!' AS [Error_Message_ENG]
					, N'Husuu นี้ถูก ' + [item_labels].[label_eng] + N'ไปแล้ว !!'  AS [Error_Message_THA] 
					, '' AS [Handling]
				FROM [APCSProDB].[trans].[surpluses]
				INNER JOIN [APCSProDB].[trans].[item_labels] ON [surpluses].[in_stock] = [item_labels].[val]
				WHERE [item_labels].[name] = 'surpluse_records.in_stock'
					AND [surpluses].[lot_id] = @lot_id;
				RETURN;
				---- # ----------------------------------------------------------- # ----
			END 
			---- # ----------------------------------------------------------- # ----
		END
		---- # IF 3 hasuu instock = 2 and don't have location rack
		ELSE IF EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[surpluses] WHERE [lot_id] = @lot_id AND [in_stock] = 2 AND [location_id] IS NULL )
		BEGIN
			---- # ----------------------------------------------------------- # ----
			SELECT 'FALSE' AS [Is_Pass]
				, 'Rack is not yet registered.' AS [Error_Message_ENG]
				, N'ยังไม่ลงทะเบียน Rack ' AS [Error_Message_THA] 
				, '' AS [Handling];
			RETURN;
			---- # ----------------------------------------------------------- # ----
		END	
		---- # ELSE
		ELSE
		BEGIN 
			---- # ----------------------------------------------------------- # ----
			SELECT 'TRUE' AS [Is_Pass] 
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA] 
				, '' AS [Handling]
				, ROW_NUMBER() OVER ( ORDER BY [sur].[created_at] ) AS [No]
				, [lots].[id] AS [lot_id]
				, ISNULL([pk].[name], '') AS [pack_name]
				, ISNULL([dn].[name], '') AS [device_name]
				, ISNULL([sur].[serial_no], '') AS [lot_no]
				, ISNULL([sur].[pcs], '') AS [qty]
				, ISNULL([loca].[name] , '') AS [rack_name]
				, ISNULL(CASE WHEN SUBSTRING([sur].[serial_no], 1, 2) >= @year_now THEN 'HASUU NOW' ELSE 'HASUU LONG' END,0) AS [status_lot]
				, ISNULL(CASE WHEN SUBSTRING([sur].[serial_no], 1, 2) >= @year_now THEN 2 ELSE 3 END, 0) AS [stock_class] 
			FROM [APCSProDB].[trans].[surpluses] AS [sur]
			INNER JOIN [APCSProDB].[trans].[lots] ON [sur].[lot_id] = [lots].[id]
			INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id]
			INNER JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id]
			LEFT JOIN [APCSProDB].[trans].[locations] AS [loca] ON [sur].[location_id] = [loca].[id]
			WHERE [sur].[lot_id] = @lot_id
				AND [sur].[in_stock] in (2,3)  --#update codition 2025/03/31 by Aomsin
				AND [serial_no] <> ''
			ORDER BY [sur].[serial_no];
			RETURN;
			---- # ----------------------------------------------------------- # ----
		END 
		---- # ----------------------------------------------------------- # ----
	END 
	
	---- # 4) @wip = 10:Dicing WIP
	ELSE IF (@wip = 10)
	BEGIN
		---- # ----------------------------------------------------------- # ----
		---- # check location rack
		IF  EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id AND [location_id] IS NULL )
		BEGIN 
			---- # ----------------------------------------------------------- # ----
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Rack is not yet registered.' AS [Error_Message_ENG]
				, N'ยังไม่ลงทะเบียน Rack' AS [Error_Message_THA]
				, '' AS [Handling];
			RETURN;
			---- # ----------------------------------------------------------- # ----
		END

		---- # return
		SELECT 'TRUE' AS [Is_Pass]
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, '' AS [Handling]
			, ROW_NUMBER() OVER ( ORDER BY [lots].[created_at] ) AS [No]
			, [lots].[id] AS [lot_id]
			, ISNULL([pk].[name], '') AS [pack_name]
			, ISNULL([dn].[name], '') AS [device_name]
			, ISNULL([lots].[lot_no], '') AS [lot_no]
			, [lots].[qty_pass] AS [qty]
			, [loca].[name] AS [rack_name]
			, 'WIP' AS [status_lot]
			, 1 AS [stock_class]  
		FROM [APCSProDB].[trans].[lots]  
		INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id]
		INNER JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id]
		LEFT JOIN [APCSProDB].[trans].[locations] AS [loca] ON [lots].[location_id] = [loca].[id]
		WHERE [lots].[id] = @lot_id
		ORDER BY [lots].[lot_no];
		RETURN;
		---- # ----------------------------------------------------------- # ----
	END	
	
	---- # 5) wip_state NOT IN (10, 20, 70, 100)
	ELSE
	BEGIN
		print 'else'
		---- # ----------------------------------------------------------- # ----
		SELECT 'FALSE' AS [Is_Pass]
			, 'This Lot has been ' + [item_labels].[label_eng] + '!!' AS [Error_Message_ENG]
			, N'Lot นี้  ' + [item_labels].[label_eng] + N'แล้ว !! '  AS [Error_Message_THA] 
			, '' AS [Handling]
		FROM [APCSProDB].[trans].[lots]
		LEFT JOIN [APCSProDB].[trans].[item_labels] ON [lots].[wip_state] = [item_labels].[val]
		WHERE [item_labels].[name] = 'lots.wip_state'
			AND [lots].[id] = @lot_id;
		RETURN;
		---- # ----------------------------------------------------------- # ----
	END 
END
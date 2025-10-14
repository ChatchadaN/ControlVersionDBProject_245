-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_input_rack_003] 
	-- Add the parameters for the stored procedure here
	@emp_id			NVARCHAR(10)
	, @App_Name		NVARCHAR(20)
	, @Item			NVARCHAR(50)
	, @Address_id	INT
	, @Status		INT
	--@Status : 0 ว่าง 1 วาง 2 จอง
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- แปลงค่า emp_id จาก VARCHAR เป็น INT
    SET @emp_id = CAST(@emp_id AS INT);
	----------------------------------------------------------------------
    -- Insert statements for procedure here
	DECLARE  
		 @CurrentItem		varchar(20)
		, @OldRackName		varchar(20)
		, @OldAddress		varchar(5)
		, @rack_crt_id		INT
		, @categories_id	INT
		, @currentstatus	INT

	
	-- ดึงข้อมูล ID ของ rack_controls, rack_addresses ,@categories_id และ Lot ปัจจุบันจาก rack_addresses
	SELECT @rack_crt_id = [rack_controls].[id]
		, @CurrentItem = [rack_addresses].[item] 
		, @categories_id = [rack_controls].[category]
		, @currentstatus = [rack_addresses].[status]
	FROM [APCSProDB].[rcs].[rack_controls]
	--INNER JOIN [APCSProDB].[trans].[location_racks] ON [rack_controls].[id] = [location_racks].[rack_control_id]
	--INNER JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
	INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
	WHERE [rack_addresses].[id] = @Address_id

	-- เช็ค location, rack_name, category, address
	IF NOT EXISTS (
		SELECT TOP 1 [rack_controls].[id]
		FROM [APCSProDB].[rcs].[rack_controls]
		--INNER JOIN [APCSProDB].[trans].[location_racks] ON [rack_controls].[id] = [location_racks].[rack_control_id]
		--INNER JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
		INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
		WHERE [rack_addresses].[id] = @Address_id
	)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
		, 'Not found location' AS [Error_Message_ENG]
		, N'ไม่พบ location' AS [Error_Message_THA] 
		, N'กรุณาติดต่อ System' AS [Handling];	
		RETURN;
	END

	DECLARE @rack_name VARCHAR(50)
	, @rack_address VARCHAR(20)

	SELECT @rack_name = [rack_controls].[name]
	, @rack_address = [address] 
	FROM APCSProDB.rcs.rack_addresses
	INNER JOIN APCSProDB.rcs.rack_controls on rack_addresses.rack_control_id = rack_controls.id
	WHERE item = @Item

	IF EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_addresses WHERE item = @Item AND [status] = 1)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
		, CONCAT('This item: ', @Item, ' was located at ', @rack_name, '-', @rack_address, ', Can''t Input Lot') AS [Error_Message_ENG]
		, CONCAT(N'Item: ', @Item, N' นี้อยู่ที่ ', @rack_name, '-', @rack_address, N', ไม่สามารถ Input Lot ได้') AS [Error_Message_THA] 
		, N'กรุณาติดต่อ System' AS [Handling];	
		RETURN;
	END

	BEGIN TRANSACTION;
	BEGIN TRY
		-------------------------------------------------------------------------------------------------------
		-- เช็ค OldRackName และ OldAddress
		IF (@categories_id = 1)
		BEGIN
			PRINT 'LOT_WIP'

			IF NOT EXISTS(SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no = @Item)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'FALSE' AS [Is_Pass] 
				,'Could not found LOTNO in trans.lots' AS [Error_Message_ENG]
				, N'ไม่พบ LOTNO ใน trans.lots' AS [Error_Message_THA] 
				, N'กรุณาติดต่อ System' AS [Handling];	
				RETURN;
			END
			ELSE
			BEGIN
				SELECT @OldRackName = [rack_controls].[name], @OldAddress = [rack_addresses].[address]
				FROM [APCSProDB].[trans].[lots]
				INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [lots].[location_id] = [rack_addresses].[id]
				INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
				WHERE [lots].[lot_no] = @Item 
				AND [rack_addresses].[status] != 2;
			END
		END
		ELSE IF (@categories_id IN (2,3))
		BEGIN
			PRINT 'LOT HASUU'

			IF NOT EXISTS(SELECT 1 FROM APCSProDB.trans.surpluses WHERE serial_no = @Item)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'FALSE' AS [Is_Pass] 
				,'Could not found LOTNO in trans.surpluses' AS [Error_Message_ENG]
				, N'ไม่พบ LOTNO ใน trans.surpluses' AS [Error_Message_THA] 
				, N'กรุณาติดต่อ System' AS [Handling];	
				RETURN;
			END
			ELSE
			BEGIN
				SELECT @OldRackName = [rack_controls].[name], @OldAddress = [rack_addresses].[address]
				FROM [APCSProDB].[trans].[surpluses]
				INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [surpluses].[location_id] = [rack_addresses].[id]
				INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
				WHERE [surpluses].[serial_no] = @Item
				AND [rack_addresses].[status] != 2;
			END
		END
		--ELSE IF (@categories_id = 5)
		--BEGIN
		--	PRINT 'Material'
		--	IF NOT EXISTS(SELECT 1 FROM APCSProDB.trans.materials WHERE barcode = @Item)
		--	BEGIN
		--		ROLLBACK TRANSACTION;
		--		SELECT 'FALSE' AS [Is_Pass] 
		--		,'Could not found Item in trans.materials' AS [Error_Message_ENG]
		--		, N'ไม่พบ Item ใน trans.materials' AS [Error_Message_THA] 
		--		, N'กรุณาติดต่อ System' AS [Handling];	
		--		RETURN;
		--	END
		--	ELSE
		--	BEGIN
		--		SELECT @OldRackName = [rack_controls].[name], @OldAddress = [rack_addresses].[address]
		--		FROM [APCSProDB].[trans].[materials]
		--		INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [materials].[location_id] = [rack_addresses].[id]
		--		INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
		--		WHERE [materials].[barcode] = @Item;
		--	END
		--END
		--bypass for test
		ELSE IF (@categories_id = 5)
		BEGIN
			print 'Materials'
				--SELECT @OldRackName = [rack_controls].[name], @OldAddress = [rack_addresses].[address]
				--FROM [APCSProDB].[trans].[materials]
				--INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [materials].[location_id] = [rack_addresses].[id]
				--INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
				--WHERE [materials].[barcode] = @Item;
		END
		ELSE IF (@categories_id = 6)
		BEGIN
			PRINT 'Jig'
			IF NOT EXISTS(SELECT 1 FROM APCSProDB.trans.jigs WHERE barcode = @Item)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'FALSE' AS [Is_Pass] 
				,'Could not found Item in trans.jigs' AS [Error_Message_ENG]
				, N'ไม่พบ Item ใน trans.jigs' AS [Error_Message_THA] 
				, N'กรุณาติดต่อ System' AS [Handling];	
				RETURN;
			END
			ELSE
			BEGIN
				SELECT @OldRackName = [rack_controls].[name], @OldAddress = [rack_addresses].[address]
				FROM [APCSProDB].[trans].[jigs]
				INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [jigs].[location_id] = [rack_addresses].[id]
				INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
				WHERE [jigs].[barcode] = @Item
				AND [rack_addresses].[status] != 2;
			END
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'FALSE' AS [Is_Pass] 
			,'Category not support' AS [Error_Message_ENG]
			, N'Category ยังไม่รองรับ' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ System' AS [Handling];	
			RETURN;
		END

		-- ตรวจสอบว่า Lotno นี้มี location อยู่แล้วหรือไม่
		IF @OldRackName IS NOT NULL AND @OldAddress IS NOT NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'FALSE' AS [Is_Pass] 
			, CONCAT('This Lot: ', @Item, ' was located at ', @OldRackName, '-', @OldAddress, ', Can''t Input Lot') AS [Error_Message_ENG]
			, CONCAT(N'Lot: ', @Item, N' นี้อยู่ที่ ', @OldRackName, '-', @OldAddress, N', ไม่สามารถ Input Lot ได้') AS [Error_Message_THA] 
			, N'กรุณาติดต่อ System' AS [Handling];	
			RETURN;
		END

		-- ตรวจสอบว่าตำแหน่งปัจจุบันมี item หรือไม่
		IF @CurrentItem IS NULL OR @currentstatus = 2
		BEGIN
			PRINT 'update rack address'
			-- อัพเดต item ใน rack_addresses
			UPDATE [APCSProDB].[rcs].[rack_addresses]
			SET [item] = @Item,
				[status] = @Status,
				[updated_at] = GETDATE(),
				[updated_by] = @emp_id
			WHERE [rack_addresses].[id] = @Address_id;

			-- อัพเดต item ใน rack_addresses_record
			INSERT INTO [APCSProDB].[rcs].[rack_address_records]
			SELECT 
				GETDATE()
				,'2'
				,[id]
				,[rack_control_id]
				,[item]
				,[status]
				,[address]
				,[x]
				,[y]
				,[z]
				,[is_enable]
				,[created_at]
				,[created_by]
				,[updated_at]
				,[updated_by]
			FROM [APCSProDB].rcs.rack_addresses
			WHERE [rack_addresses].[id] = @Address_id;

			-- อัพเดต location_id
			IF (@categories_id = 1 AND @currentstatus = 0)
			BEGIN
				print 'update location lot'
				UPDATE [APCSProDB].[trans].[lots]
				SET [location_id] = @Address_id,
					[updated_at] = GETDATE(),
					[updated_by] = @emp_id
				WHERE [lot_no] = @Item;
			END
			ELSE IF (@categories_id IN (2,3) AND @currentstatus = 0)
			BEGIN
				print 'update location surpluses'
				UPDATE [APCSProDB].[trans].[surpluses]
				SET [location_id] = @Address_id,
					[updated_at] = GETDATE(),
					[updated_by] = @emp_id
				WHERE [serial_no] = @Item;
			END
			--ELSE IF (@categories_id = 5 AND @currentstatus = 0)
			--BEGIN
			--	print 'update location materilas'
			--	UPDATE [APCSProDB].[trans].[materials]
			--	SET [location_id] = @Address_id,
			--		[updated_at] = GETDATE(),
			--		[updated_by] = @emp_id
			--	WHERE [barcode] = @Item;
			--END
			ELSE IF (@categories_id = 6 AND @currentstatus = 0)
			BEGIN
				print 'update location jigs'
				UPDATE [APCSProDB].[trans].[jigs]
				SET [location_id] = @Address_id,
					[updated_at] = GETDATE(),
					[updated_by] = @emp_id
				WHERE [barcode] = @Item;
			END

			COMMIT TRANSACTION;
			SELECT 'TRUE' AS [Is_Pass] 
				, N'Input lot Success !!' AS [Error_Message_ENG]
				, N'Input lot สำเร็จ !!' AS [Error_Message_THA] 
				, N'' AS [Handling];
			RETURN;
		END
		ELSE
		BEGIN		
			ROLLBACK TRANSACTION;
			SELECT 'FALSE' AS [Is_Pass] 
			, CONCAT('This location already have ', @CurrentItem) AS [Error_Message_ENG]
			, CONCAT(N'ตำแหน่งนี้มี item : ', @CurrentItem, N' อยู่แล้ว ') AS [Error_Message_THA]
			, N'กรุณาติดต่อ System' AS [Handling];	
			RETURN;
		END
		-------------------------------------------------------------------------------------------------------
	END TRY
	BEGIN CATCH
		-------------------------------------------------------------------------------------------------------
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
		END

		SELECT 'FALSE' AS [Is_Pass] 
		, ERROR_MESSAGE() AS [Error_Message_ENG]
		, N'ไม่สามารถ Input ได้ !!' AS [Error_Message_THA] 
		, N'กรุณาติดต่อ System' AS [Handling];
		RETURN;
		-------------------------------------------------------------------------------------------------------
	END CATCH
END

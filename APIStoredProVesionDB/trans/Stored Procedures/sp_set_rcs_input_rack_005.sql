-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_input_rack_005] 
	-- Add the parameters for the stored procedure here
	@emp_id			NVARCHAR(10)
	, @App_Name		NVARCHAR(20)
	, @Item			NVARCHAR(50)
	, @Address_id	INT
	, @Status		INT
	, @qty			INT   = 1
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
		, @rack_crt_id		INT
		, @categories_id	INT
		, @currentstatus	INT
		, @CurrentAddress	VARCHAR(20)

	-- check address_id exists
	IF NOT EXISTS (
		SELECT 1 FROM APCSProDB.rcs.rack_addresses WHERE id = @Address_id
	)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
		, 'Not found Address' AS [Error_Message_ENG]
		, N'ไม่พบ Address' AS [Error_Message_THA] 
		, N'กรุณาติดต่อ System' AS [Handling];	
		RETURN;
	END

	-- check data address_id ที่ส่งมา
	SELECT @rack_crt_id		= rack_addresses.rack_control_id
		, @CurrentItem		= rack_addresses.item
		, @categories_id	= rack_controls.category
		, @currentstatus	= rack_addresses.[status]	
		, @currentAddress	= rack_addresses.[address]
	FROM APCSProDB.rcs.rack_addresses
	INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
	WHERE rack_addresses.id = @Address_id

	DECLARE @rack_name VARCHAR(50)
	, @rack_address VARCHAR(20)

	-- Check วาง item in rack (ไม่รวมจอง)
	SELECT @rack_name	= [rack_controls].[name]
		, @rack_address = [rack_addresses].[address] 
	FROM APCSProDB.rcs.rack_addresses
	INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
	WHERE item = @Item AND [status] = 1

	IF (@rack_name IS NOT NULL OR @rack_address IS NOT NULL)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
				, CONCAT('This item: ', @Item, ' was located at ', @rack_name, '-', @rack_address, ', Can''t Input Lot') AS [Error_Message_ENG]
				, CONCAT(N'Item: ', @Item, N' นี้อยู่ที่ ', @rack_name, '-', @rack_address, N', ไม่สามารถ Input Lot ได้') AS [Error_Message_THA] 
				, N'กรุณาติดต่อ System' AS [Handling];	
		RETURN;
	END

	BEGIN TRANSACTION;
	BEGIN TRY

		-- ตรวจสอบว่าตำแหน่งปัจจุบันมี item หรือไม่
		IF @CurrentItem IS NULL OR @currentstatus = 2
		BEGIN
			PRINT 'update rack address'
			
			DECLARE @prefix NVARCHAR(1) = LEFT(@CurrentAddress, 1)
			DECLARE @startNum INT = CAST(RIGHT(@CurrentAddress, LEN(@CurrentAddress) - 1) AS INT)
			DECLARE @rack_z INT

			SELECT DISTINCT @rack_z = MAX(CAST(z AS INT)) 
			FROM APCSProDB.rcs.rack_addresses 
			WHERE rack_control_id = @rack_crt_id

			DECLARE @i INT = 0

			WHILE @i < @qty
			BEGIN
				DECLARE @NewItem NVARCHAR(50)
				DECLARE @NewAddress NVARCHAR(20)

				-- สร้างชื่อ item ใหม่
				IF @i = 0
					SET @NewItem = @Item
				ELSE
					SET @NewItem = @Item + '_' + CAST(@i + 1 AS NVARCHAR)
				
				-- สร้าง address ใหม่ตามเงื่อนไข Z
				IF @rack_z = 1
				BEGIN
					PRINT 'z = 1'
					-- กรณี Z = 1 → เปลี่ยนตัวอักษร x
					SET @NewAddress = CHAR(ASCII(@prefix) + @i) + RIGHT('0000' + CAST(@startNum AS VARCHAR), 4)
				END
				ELSE
				BEGIN
					PRINT 'z > 1'
					-- กรณี Z > 1 → เปลี่ยนเลข address
					SET @NewAddress = @prefix + RIGHT('0000' + CAST(@startNum + @i AS VARCHAR), 4)
				END

				-- แสดงผลหรือใช้ใน INSERT/UPDATE
				PRINT 'NewItem: ' + @NewItem + ' | NewAddress: ' + @NewAddress

				-- อัพเดต item ใน rack_addresses
				UPDATE APCSProDB.rcs.rack_addresses
				SET [item] = @NewItem,
				    [status] = @Status,
				    [updated_at] = GETDATE(),
				    [updated_by] = @emp_id
				WHERE rack_control_id = @rack_crt_id
				AND [address] = @NewAddress

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
				WHERE rack_control_id = @rack_crt_id
					AND [address] = @NewAddress

				SET @i = @i + 1
			END

			-- UPDATE location_id
			IF (@categories_id IN (1,4) AND @currentstatus = 0)
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

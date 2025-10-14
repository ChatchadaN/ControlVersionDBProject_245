-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_remove_rack_005] 
	-- Add the parameters for the stored procedure here
	@emp_id			NVARCHAR(10)
	, @App_Name		NVARCHAR(20)
	, @Item			NVARCHAR(20)
	, @Address_id	INT


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- แปลงค่า emp_id จาก VARCHAR เป็น INT
    SET @emp_id = CAST(@emp_id AS INT);
	----------------------------------------------------------------------
    -- Insert statements for procedure here
	DECLARE @Status		INT	
	SET @Status = 0

	DECLARE  
	 @rack_crt_id		INT
	, @CurrentLotNo		varchar(20)
	, @categories_id	INT
	, @Rackname			varchar(50)
	, @Address			varchar(50)

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

	-- ดึงข้อมูล ID ของ rack_controls, rack_addresses และ Lot ปัจจุบันจาก rack_addresses
	SELECT  @rack_crt_id = [rack_controls].[id]
		, @CurrentLotNo = [rack_addresses].[item] 
		, @categories_id = [rack_controls].[category]
		, @Rackname = [rack_controls].[name]
		, @Address = [rack_addresses].[address]
	FROM [APCSProDB].[rcs].[rack_controls]
	INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
	WHERE [rack_addresses].[id] = @Address_id

	-- rack นี้ address นี้ ไม่พบ lot
	IF @CurrentLotNo IS NULL
	BEGIN
		PRINT 'not found';
		SELECT 'FALSE' AS [Is_Pass] 
		, CONCAT('Location: ', @Rackname, '-', @Address, ' not found Lot: ', @Item) AS [Error_Message_ENG]
		, CONCAT(N'Location: ', @Rackname, '-', @Address , N' นี้ไม่พบ Lot: ', @Item) AS [Error_Message_THA] 
		, N'กรุณาติดต่อ System' AS [Handling];	
		RETURN;
	END

	BEGIN TRANSACTION;
	BEGIN TRY

		--check lotno อยู่ใน item มั้ย
		IF @Item = @CurrentLotNo
		BEGIN
			PRINT 'EXISTS';

			DECLARE @Address_TB TABLE (
				address_id INT,
				item VARCHAR(50)
			)

			INSERT INTO @Address_TB
			SELECT id,item
			FROM APCSProDB.rcs.rack_addresses
			WHERE rack_control_id =  @rack_crt_id
			AND item LIKE @Item + '%' 

			-- อัพเดต all item name like and status : NULL,0
			UPDATE APCSProDB.rcs.rack_addresses
			SET [item]	= NULL,
				[status] =  @Status,
				[updated_at] = GETDATE(),
				[updated_by] = @emp_id
			WHERE id IN (SELECT address_id FROM @Address_TB) 

			-- อัพเดต all item name like ใน rack_addresses_record
			INSERT INTO [APCSProDB].[rcs].[rack_address_records]
			SELECT 
				GETDATE()
				,'2'
				,a.[id]
				,a.[rack_control_id]
				,tb.[item]  -- ดึง item จาก @Address_TB
				,a.[status]
				,a.[address]
				,a.[x]
				,a.[y]
				,a.[z]
				,a.[is_enable]
				,a.[created_at]
				,a.[created_by]
				,a.[updated_at]
				,a.[updated_by]
			FROM [APCSProDB].rcs.rack_addresses a
			JOIN @Address_TB tb ON a.id = tb.address_id

			-- อัพเดต location
			IF (@categories_id IN (1,4))
			BEGIN		
				UPDATE APCSProDB.trans.lots
				SET location_id = NULL,
					updated_at = GETDATE(),
					updated_by = @emp_id
				WHERE lot_no = @Item
			END
			ELSE IF (@categories_id IN (2, 3))
			BEGIN
				UPDATE [APCSProDB].[trans].[surpluses]
				SET [location_id] = NULL,
					[updated_at] = GETDATE(),
					[updated_by] = @emp_id
				WHERE [serial_no] = @Item;
			END
			
			COMMIT TRANSACTION;
			SELECT 'TRUE' AS [Is_Pass] 
			, N'Remove Lot Success !!' AS [Error_Message_ENG]
			, N'Remove Lot สำเร็จ !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
			RETURN;
		END
		ELSE
		BEGIN
			PRINT 'NOT MATCH';

			ROLLBACK TRANSACTION;
			SELECT 'FALSE' AS [Is_Pass] 
			, 'The item does not match the current item on the rack. Please check data!!' AS [Error_Message_ENG] 
			, N'Item ไม่ตรงกับ Item ปัจจุบันบน Rack กรุณาตรวจสอบข้อมูล' AS [Error_Message_THA] 
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
		, N'ไม่สามารถ Remove lot ได้ !!' AS [Error_Message_THA] 
		, N'กรุณาติดต่อ System' AS [Handling];
		RETURN;
		-------------------------------------------------------------------------------------------------------
	END CATCH
END

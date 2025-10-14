-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_remove_rack_002] 
	-- Add the parameters for the stored procedure here
	@emp_id			INT
	, @App_Name		NVARCHAR(20)
	, @Item			NVARCHAR(20)
	, @Location		NVARCHAR(20) = NULL
	, @Rackname		NVARCHAR(20)
	, @Address		NVARCHAR(20)


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----------------------------------------------------------------------
    -- Insert statements for procedure here
	DECLARE @Status		INT	
	SET @Status = 0

	DECLARE  
	 @rack_crt_id		INT
	, @rack_add_id		INT
	, @CurrentLotNo		varchar(20)
	, @categories_id	INT

	-- ดึงข้อมูล ID ของ rack_controls, rack_addresses และ Lot ปัจจุบันจาก rack_addresses
	SELECT @rack_add_id = [rack_addresses].[id]
		, @rack_crt_id = [rack_controls].[id]
		, @CurrentLotNo = [rack_addresses].[item] 
		, @categories_id = [rack_controls].[category]
	FROM [APCSProDB].[rcs].[rack_controls]
	INNER JOIN [APCSProDB].[trans].[location_racks] ON [rack_controls].[id] = [location_racks].[rack_control_id]
	INNER JOIN [APCSProDB].[trans].[locations] ON [location_racks].[location_id] = [locations].[id]
	INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
	WHERE[rack_controls].[name] = @Rackname
		AND [rack_addresses].[address] = @Address
		--AND [locations].[name] = @Location

	-- เช็ค location, rack_name, category, address
	IF NOT EXISTS (
		SELECT TOP 1 [rack_controls].[id]
		FROM [APCSProDB].[rcs].[rack_controls]
		INNER JOIN [APCSProDB].[trans].[location_racks] ON [rack_controls].[id] = [location_racks].[rack_control_id]
		INNER JOIN [APCSProDB].[trans].[locations] ON [location_racks].[location_id] = [locations].[id]
		INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
		WHERE [rack_controls].[name] = @Rackname
			AND [rack_controls].[category] = @categories_id
			AND [rack_addresses].[address] = @Address
			--AND [locations].[name] = @Location
			 
	)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
		, 'Not found location' AS [Error_Message_ENG]
		, N'ไม่พบ location' AS [Error_Message_THA] 
		, N'กรุณาติดต่อ System' AS [Handling];	
		RETURN;
	END

	BEGIN TRANSACTION;
	BEGIN TRY
		-------------------------------------------------------------------------------------------------------
		-- rack นี้ address นี้ ไม่พบ lot
		IF @CurrentLotNo IS NULL
		BEGIN
			PRINT 'not found';

			ROLLBACK TRANSACTION;
			SELECT 'FALSE' AS [Is_Pass] 
			, CONCAT('Location: ', @Rackname, '-', @Address, ' not found Lot: ', @Item) AS [Error_Message_ENG]
			, CONCAT(N'Location: ', @Rackname, '-', @Address , N' นี้ไม่พบ Lot: ', @Item) AS [Error_Message_THA] 
			, N'กรุณาติดต่อ System' AS [Handling];	
			RETURN;
		END

		--check lotno อยู่ใน item มั้ย
		IF @Item = @CurrentLotNo
		BEGIN
			PRINT 'EXISTS';

			UPDATE [APCSProDB].[rcs].[rack_addresses]
			SET [item] = NULL,
				[status] =  @Status,
				[updated_at] = GETDATE(),
				[updated_by] = @emp_id
			WHERE [id] = @rack_add_id 
				AND [rack_control_id] = @rack_crt_id

			IF (@categories_id = 1)
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
			ELSE IF (@categories_id = 5)
			BEGIN
				UPDATE [APCSProDB].[trans].[materials]
				SET [location_id] = NULL,
					[updated_at] = GETDATE(),
					[updated_by] = @emp_id
				WHERE [barcode] = @Item;
			END
			ELSE IF (@categories_id = 6)
			BEGIN
				UPDATE [APCSProDB].[trans].[jigs]
				SET [location_id] = NULL,
					[updated_at] = GETDATE(),
					[updated_by] = @emp_id
				WHERE [barcode] = @Item;
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

			COMMIT TRANSACTION;
			SELECT 'TRUE' AS [Is_Pass] 
			, N'Remove Lot Success !!' AS [Error_Message_ENG]
			, N'Remove Lot สำเร็จ !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
			RETURN;
		END
		ELSE
		BEGIN
			PRINT 'not in';

			ROLLBACK TRANSACTION;
			SELECT 'FALSE' AS [Is_Pass] 
			, CONCAT('This Lot: ', @Item, ' not in ', @Rackname, '-', @Address) AS [Error_Message_ENG] 
			, CONCAT(N'Lot: ', @Item, N' นี้ไม่อยู่ที่ ', @Rackname, '-', @Address) AS [Error_Message_THA] 
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

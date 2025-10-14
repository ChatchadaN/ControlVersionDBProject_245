-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_remove_rack_test] 
	-- Add the parameters for the stored procedure here
	@OPNo			INT
	, @App_Name		NVARCHAR(20)
	, @Item			NVARCHAR(20)
	, @Location		NVARCHAR(20)
	, @Rackname		NVARCHAR(20)
	, @Address		NVARCHAR(20)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @rack_addresses TABLE
	(
		[id] int
		  ,[rack_control_id] int
		  ,[item] varchar(50)
		  ,[status] int
		  ,[address]  varchar(50)
		  ,[x] varchar(50)
		  ,[y] varchar(50)
		  ,[z] varchar(50)
		  ,[is_enable] int
		  ,[created_at] datetime
		  ,[created_by] int
		  ,[updated_at] datetime
		  ,[updated_by] int
	)
	INSERT INTO @rack_addresses
	SELECT *  FROM [APCSProDB].[rcs].[rack_addresses]

	DECLARE @trans_lot TABLE
	(
		id int
		,lot_no varchar(20)
		,location_id int
		,[updated_at] datetime
		,[updated_by] int

	)
	INSERT INTO @trans_lot
	SELECT id 
	,lot_no
	,location_id 
	,[updated_at] 
	  ,[updated_by] 
	FROM APCSProDB.trans.lots
	WHERE lot_no IN ( '1234A1234V', '2349A1194V')

	----------------------------------------------------------------------
    -- Insert statements for procedure here
	DECLARE  
		 @rack_crt_id		INT
		, @rack_add_id		INT
		, @CurrentLotNo		varchar(20)
		, @categories_id	INT

	-- ดึงข้อมูล ID ของ rack_controls, rack_addresses และ Lot ปัจจุบันจาก rack_addresses
	SELECT @rack_add_id = [rack_addresses].[id]
		, @rack_crt_id = [rack_controls].[id]
		, @CurrentLotNo = [rack_addresses].[item] 
	FROM [APCSProDB].[rcs].[rack_controls]
	INNER JOIN [APCSProDB].[trans].[location_racks] ON [rack_controls].[id] = [location_racks].[rack_control_id]
	INNER JOIN [APCSProDB].[trans].[locations] ON [location_racks].[location_id] = [locations].[id]
	INNER JOIN @rack_addresses AS [rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
	WHERE  [rack_controls].[name] = @Rackname
		AND [rack_addresses].[address] = @Address
		--AND [locations].[name] = @Location
		

	-- เช็ค location, rack_name, category, address
	IF NOT EXISTS (
		SELECT TOP 1 [rack_controls].[id]
		FROM [APCSProDB].[rcs].[rack_controls]
		INNER JOIN [APCSProDB].[trans].[location_racks] ON [rack_controls].[id] = [location_racks].[rack_control_id]
		INNER JOIN [APCSProDB].[trans].[locations] ON [location_racks].[location_id] = [locations].[id]
		INNER JOIN @rack_addresses AS [rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
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

			UPDATE @rack_addresses
			SET [item] = NULL,
				[updated_at] = GETDATE(),
				[updated_by] = @OPNo
			WHERE [id] = @rack_add_id 
				AND [rack_control_id] = @rack_crt_id

			IF (@categories_id = 1)
			BEGIN		
				UPDATE @trans_lot
				SET location_id = NULL,
					updated_at = GETDATE(),
					updated_by = @OPNo
				WHERE lot_no = @Item
			END
			ELSE IF (@categories_id IN (2, 3))
			BEGIN
				UPDATE [APCSProDB].[trans].[surpluses]
				SET [location_id] = NULL,
					[updated_at] = GETDATE(),
					[updated_by] = @OPNo
				WHERE [serial_no] = @Item;
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

			SELECT * FROM @rack_addresses

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
		, N'ไม่สามารถ Remove ได้ !!' AS [Error_Message_THA] 
		, N'กรุณาติดต่อ System' AS [Handling];
		RETURN;
		-------------------------------------------------------------------------------------------------------
	END CATCH
END


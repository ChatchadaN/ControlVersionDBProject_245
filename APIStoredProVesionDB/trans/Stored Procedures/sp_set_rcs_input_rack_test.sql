-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_input_rack_test] 
	-- Add the parameters for the stored procedure here
	@OPNo			INT
	, @App_Name		NVARCHAR(20)
	, @Item			NVARCHAR(50)
	, @Location		NVARCHAR(20) = NULL
	, @Rackname		NVARCHAR(20)
	, @Address		NVARCHAR(20)
	, @Status		INT

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
	WHERE rack_control_id = 7
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
		@CurrentLotNo		varchar(20)
		, @OldRackName		varchar(20)
		, @OldAddress		varchar(5)
		, @rack_crt_id		INT
		, @rack_add_id		INT
		, @categories_id	INT
		, @currentstatus	INT

	-- ดึงข้อมูล ID ของ rack_controls, rack_addresses ,@categories_id และ Lot ปัจจุบันจาก rack_addresses
	SELECT @rack_crt_id = [rack_controls].[id]
		, @rack_add_id = [rack_addresses].[id]
		, @CurrentLotNo = [rack_addresses].[item] 
		, @categories_id = [rack_controls].[category]
	FROM [APCSProDB].[rcs].[rack_controls]
	INNER JOIN [APCSProDB].[trans].[location_racks] ON [rack_controls].[id] = [location_racks].[rack_control_id]
	INNER JOIN [APCSProDB].[trans].[locations] ON [location_racks].[location_id] = [locations].[id]
	INNER JOIN @rack_addresses AS [rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
	WHERE [rack_controls].[name] = @Rackname
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
		-- เช็ค OldRackName และ OldAddress
		IF (@categories_id = 1)
		BEGIN
			SELECT @OldRackName = [rack_controls].[name], @OldAddress = [rack_addresses].[address]
			FROM @trans_lot as lots
			INNER JOIN @rack_addresses AS [rack_addresses] ON [lots].[location_id] = [rack_addresses].[id]
			INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
			WHERE [lots].[lot_no] = @Item;
		END
		ELSE IF (@categories_id IN (2,3))
		BEGIN
			SELECT @OldRackName = [rack_controls].[name], @OldAddress = [rack_addresses].[address]
			FROM [APCSProDB].[trans].[surpluses]
			INNER JOIN @rack_addresses AS [rack_addresses] ON [surpluses].[location_id] = [rack_addresses].[id]
			INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
			WHERE [surpluses].[serial_no] = @Item;
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

		-- ตรวจสอบว่าตำแหน่งปัจจุบันมี Lotno หรือไม่
		IF @CurrentLotNo IS NULL OR @currentstatus = 2
		BEGIN
			PRINT 'rack_addresses'
			-- อัพเดต item ใน rack_addresses
			UPDATE @rack_addresses
			SET [item] = @Item,
				[updated_at] = GETDATE(),
				[updated_by] = @OPNo
			WHERE [rack_control_id] = @rack_crt_id 
				AND [address] = @Address;

			-- อัพเดต location_id
			IF (@categories_id = 1 AND @currentstatus = 0)
			BEGIN
			print 'trans.lots'
				UPDATE @trans_lot
				SET [location_id] = @rack_add_id,
					[updated_at] = GETDATE(),
					[updated_by] = @OPNo
				WHERE [lot_no] = @Item;
			END
			ELSE IF (@categories_id IN (2,3) AND @currentstatus = 0)
			BEGIN
				UPDATE [APCSProDB].[trans].[surpluses]
				SET [location_id] = @rack_add_id,
					[updated_at] = GETDATE(),
					[updated_by] = @OPNo
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
			, CONCAT('This location already have ', @CurrentLotNo) AS [Error_Message_ENG]
			, CONCAT(N'ตำแหน่งนี้มี lot : ', @CurrentLotNo, N' อยู่แล้ว ') AS [Error_Message_THA]
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
		, N'ไม่สามารถ Input lot ได้ !!' AS [Error_Message_THA] 
		, N'กรุณาติดต่อ System' AS [Handling];
		RETURN;
		-------------------------------------------------------------------------------------------------------
	END CATCH
END

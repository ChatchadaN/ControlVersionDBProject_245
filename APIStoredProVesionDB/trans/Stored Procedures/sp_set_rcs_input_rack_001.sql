-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_input_rack_001] 
	-- Add the parameters for the stored procedure here
	@OPNo			INT
	, @App_Name		NVARCHAR(20)
	, @LotNo		NVARCHAR(20)
	, @Location		NVARCHAR(20)
	, @Rackname		NVARCHAR(20)
	, @Address		NVARCHAR(20)
	, @Categories	INT	-- 1 WIP, 2 Hasuu, 3 Hasuu long

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	----------------------------------------------------------------------
    -- Insert statements for procedure here
	DECLARE  
    @CurrentLotNo   varchar(20)
	, @OldRackName  varchar(20)
	, @OldAddress   varchar(5)
	, @rack_crt_id	INT
	, @rack_add_id	INT
	--, @emp_id       INT

	-- ดึงข้อมูล ID ของ rack_controls, rack_addresses และ emp_id
	SELECT @rack_crt_id = rack_controls.id
	FROM APCSProDB.rcs.rack_controls
	INNER JOIN APCSProDB.trans.location_racks ON rack_controls.id = location_racks.rack_control_id
	INNER JOIN APCSProDB.trans.locations ON location_racks.location_id = locations.id
	WHERE rack_controls.[name] = @Rackname AND locations.name = @Location;

	SELECT @rack_add_id = id 
	FROM APCSProDB.rcs.rack_addresses
	WHERE rack_control_id = @rack_crt_id AND [address] = @Address;

	--SELECT @emp_id = id 
	--FROM APCSProDB.man.users
	--WHERE emp_num = @OPNo;
	
	BEGIN TRY
		BEGIN TRANSACTION;

		-- ดึงข้อมูล Lot ปัจจุบันจาก rack_addresses
		SELECT @CurrentLotNo = item 
		FROM APCSProDB.rcs.rack_addresses
		WHERE rack_control_id = @rack_crt_id AND [address] = @Address;

		IF (@Categories = 1)
		BEGIN
			SELECT @OldRackName = rack_controls.name, @OldAddress = rack_addresses.address
			FROM APCSProDB.trans.lots AS lots
			INNER JOIN APCSProDB.rcs.rack_addresses AS rack_addresses ON lots.location_id = rack_addresses.id
			INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
			WHERE lots.lot_no = @LotNo;

		END
		ELSE IF (@Categories = 2 OR @Categories = 3)
		BEGIN
			SELECT @OldRackName = rack_controls.name, @OldAddress = rack_addresses.address
			FROM APCSProDB.trans.surpluses
			INNER JOIN APCSProDB.rcs.rack_addresses AS rack_addresses ON surpluses.location_id = rack_addresses.id
			INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
			WHERE surpluses.serial_no = @LotNo;
		END

		-- ตรวจสอบว่า Lotno นี้มี location อยู่แล้วหรือไม่
		IF @OldRackName IS NOT NULL AND @OldAddress IS NOT NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'FALSE' AS Is_Pass 
			,CONCAT('This Lot: ', @LotNo, ' was located at ', @OldRackName, '-', @OldAddress, ', Can''t Input Lot') AS Error_Message_ENG
			,CONCAT(N'Lot: ', @LotNo, N' นี้อยู่ที่ ', @OldRackName, '-', @OldAddress, N', ไม่สามารถ Input Lot ได้') AS Error_Message_THA 
			,N'กรุณาติดต่อ System' AS Handling	
			RETURN;
		END
	
		-- ตรวจสอบว่าตำแหน่งปัจจุบันมี Lotno หรือไม่
		IF @CurrentLotNo IS NULL
		BEGIN
		print 'rack_addresses'
			-- อัพเดต item ใน rack_addresses
			UPDATE APCSProDB.rcs.rack_addresses
			SET item = @LotNo,
				updated_at = GETDATE(),
				updated_by = @OPNo
			WHERE rack_control_id = @rack_crt_id AND [address] = @Address;

			-- อัพเดต location_id
			IF (@Categories = 1)
			BEGIN
			print 'trans.lots'
				UPDATE APCSProDB.trans.lots
				SET location_id = @rack_add_id,
					updated_at = GETDATE(),
					updated_by = @OPNo
				WHERE lot_no = @LotNo;
			END
			ELSE IF (@Categories = 2 OR @Categories = 3)
			BEGIN
				UPDATE APCSProDB.trans.surpluses
				SET location_id = @rack_add_id,
					updated_at = GETDATE(),
					updated_by = @OPNo
				WHERE serial_no = @LotNo;
			END

			COMMIT TRANSACTION;
	
			SELECT 'TRUE' AS Is_Pass 
			,N'Input lot Success !!' AS Error_Message_ENG
			,N'Input lot สำเร็จ !!' AS Error_Message_THA 
			,N'' AS Handling

		END
		ELSE
		BEGIN		
			ROLLBACK TRANSACTION;

			SELECT 'FALSE' AS Is_Pass 
			,CONCAT('This location already have ', @CurrentLotNo) AS Error_Message_ENG
			,CONCAT(N'ตำแหน่งนี้มี lot : ', @CurrentLotNo, N' อยู่แล้ว ') AS Error_Message_THA 
			,N'กรุณาติดต่อ System' AS Handling	
			RETURN;
		END
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
		END

		SELECT 'FALSE' AS Is_Pass 
		,ERROR_MESSAGE() AS Error_Message_ENG
		,N'ไม่สามารถ Input lot ได้ !!' AS Error_Message_THA 
		,N'กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH

END

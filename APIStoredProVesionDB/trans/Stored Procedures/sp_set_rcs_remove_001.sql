-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_remove_001]
	-- Add the parameters for the stored procedure here
		@emp_id				INT
	  , @app_name			VARCHAR(100) 
	  , @Item				VARCHAR(20) 
	  , @Address_id			INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @nowDateTime datetime = (SELECT GETDATE()), 
			@WHCode int, @OldRackId int, @LotId int = (SELECT id FROM APCSProDB.trans.lots WHERE lot_no = @Item),
			@Is_Pass bit, @Error_Message_ENG varchar(100), @Error_Message_THA nvarchar(100), @Handling nvarchar(100),
			@OldLotNo varchar(20)  , @Rack NVARCHAR(20) 
			, @Status  INT  =  3
  

  	-- ดึงข้อมูล ID ของ rack_controls, rack_addresses และ Lot ปัจจุบันจาก rack_addresses

		SET @Rack  = ( SELECT CASE WHEN  location_id IS NULL OR location_id =  '' THEN  1 
						ELSE 0 END 
						FROM  APCSProDB.trans.lots
						WHERE id = @LotId
					)
					  
	 
    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		--! Bring out of Rack (Master Lot)
		IF(@Rack = 0)
		BEGIN
			SELECT TOP(1) @WHCode = wh_code, @OldRackId = curr.location_id
			FROM APCSProDB.trans.locations AS loca
			INNER JOIN DBx.dbo.rcs_current_locations AS curr ON loca.id = curr.location_id
			--WHERE loca.wh_code != 2 AND curr.lot_id = @LotId
			WHERE loca.wh_code not in (2,4) AND curr.lot_id = @LotId AND [status] NOT IN (3) -- Add: [status] NOT IN (3) by Pete (2024-10-07)
			ORDER BY curr.updated_at DESC -- Add: DESC by Pete (2024-10-04)

			SET @Status = 3

			IF(@WHCode = 1 OR @WHCode = 3) --Master
			BEGIN
				UPDATE APCSProDB.trans.lots  
				SET location_id = NULL,
					updated_at = @nowDateTime,
					updated_by = @emp_id
				WHERE id = @LotId

				Goto RemoveRack;
			END
			ELSE --Shouldn't happen
			BEGIN
				SELECT @Is_Pass = 'FALSE',
					   @Error_Message_ENG = 'Please send @Rack = 1 for remove Lot from Hasuu Rack',
					   @Error_Message_THA = N'กรุณาส่ง @Rack = 1 เพื่อลบ Lot ออกจาก Hasuu Rack',
					   @Handling = N'แก้ไขค่าใน Parameter ที่ส่งมาด้วยนะจ๊ะ'
				Goto BadEnd;
			END
		END

		--! Bring out of Rack (Hasuu Lot)
		ELSE IF(@Rack = 1)
		BEGIN
			SELECT TOP(1) @WHCode = wh_code, @OldRackId = curr.location_id
			FROM APCSProDB.trans.locations AS loca
			INNER JOIN DBx.dbo.rcs_current_locations AS curr ON loca.id = curr.location_id
			WHERE loca.wh_code = 2 AND curr.lot_id = @LotId
			ORDER BY curr.updated_at

			SET @Status = 3

			IF(@WHCode = 2) --IN Surpluses
			BEGIN
				UPDATE APCSProDB.trans.surpluses 
				SET location_id = NULL,
					updated_at = @nowDateTime,
					updated_by = @emp_id
				WHERE lot_id = @LotId
				 
				Goto RemoveRack;
			END
			ELSE --Shouldn't happen
			BEGIN
				SELECT @Is_Pass = 'FALSE',
					   @Error_Message_ENG = 'Please send @Rack = 0 for remove Lot from Normal Rack',
					   @Error_Message_THA = N'กรุณาส่ง @Rack = 0 เพื่อลบ Lot ออกจาก Normal Rack',
					   @Handling = N'แก้ไขค่าใน Parameter ที่ส่งมาด้วยนะจ๊ะ'
				Goto BadEnd;
			END
		END

		--! Bring Into Rack
		ELSE
		BEGIN
			SELECT @WHCode = wh_code
			FROM APCSProDB.trans.locations
			WHERE  wh_code in (1,2,3) AND id = @Address_id

			IF(@Status = 1 OR @Status = 2)
			BEGIN
				IF NOT EXISTS(SELECT id FROM DBx.dbo.rcs_current_locations WHERE location_id = @Address_id) --Are there this location? (For first times)
				BEGIN
					IF(@WHCode = 1 OR @WHCode = 3) --Master
					BEGIN
						UPDATE APCSProDB.trans.lots  
						SET location_id = @Address_id,
							updated_at = @nowDateTime,
							updated_by = @emp_id
						WHERE id = @LotId
						GoTo InputRackForFirstTimes;
					END
					ELSE IF(@WHCode = 2) --Hasuu
					BEGIN				
						UPDATE APCSProDB.trans.surpluses  
						SET location_id = @Address_id,
							updated_at = @nowDateTime,
							updated_by = @emp_id
						WHERE lot_id = @LotId
						GoTo InputRackForFirstTimes;
					END
					ELSE
					BEGIN				
						SELECT @Is_Pass = 'FALSE', 
							   @Error_Message_ENG = CONCAT('@WHCode Error(', @WHCode, ')'), 
							   @Error_Message_THA = CONCAT(N'@WHCode ผิดพลาด(', @WHCode,')'), 
							   @Handling = N'กรุณาตรวจสอบข้อมูลที่ Rack Control System (APCSPro)'
						Goto BadEnd;
					END
				END
				ELSE --Duplicated Add or Change from Reserve to Input or Input into available address or Reinsert for QA only
				BEGIN
					DECLARE @CurrentStatus int, @CurrentLotId int, @CurrentLotNo varchar(20)
					SELECT @CurrentStatus = status, 
						   @CurrentLotId = lot_id
					FROM DBx.dbo.rcs_current_locations WHERE location_id = @Address_id
					IF((@CurrentStatus = 1) OR (@CurrentStatus = 2 AND @Status = 2))
					BEGIN
						DECLARE @OldRackName varchar(20), @OldAddress varchar(5)

						IF(@WHCode = 2)
						BEGIN
							SELECT @CurrentLotNo = serial_no
							FROM APCSProDB.trans.surpluses
							WHERE lot_id = @CurrentLotId

							SELECT @OldRackName = loca.name, @OldAddress = loca.address
							FROM APCSProDB.trans.surpluses AS surs
							INNER JOIN APCSProDB.trans.locations AS loca ON surs.location_id = loca.id
							WHERE surs.lot_id = @LotId
						END
						ELSE
						BEGIN
							SELECT @CurrentLotNo = lot_no
							FROM APCSProDB.trans.lots
							WHERE id = @CurrentLotId

							SELECT @OldRackName = loca.name, @OldAddress = loca.address
							FROM APCSProDB.trans.lots AS lots
							INNER JOIN APCSProDB.trans.locations AS loca ON lots.location_id = loca.id
							WHERE lots.id = @LotId
						END
						
						IF (@Rack like 'QA%' AND @CurrentLotNo = @Item)
						BEGIN
							GoTo ReInsert;
						END
						ELSE
						BEGIN
							SELECT @Is_Pass = 'FALSE', 
								   @Error_Message_ENG = CONCAT('This location already have ', @CurrentLotNo, ' or ', @Item, ' was already in ', @OldRackName, '-', @OldAddress, ', Can''t Input Lot'),
								   @Error_Message_THA = CONCAT(N'ตำแหน่งนี้มี ', @CurrentLotNo, N' อยู่แล้ว หรือ ', @Item, N' อยู่ ', @OldRackName, '-', @OldAddress, N', ไม่สามารถ Input Lot ได้'),
								   @Handling = N'กรุณาตรวจสอบข้อมูลที่ Rack Control System (APCSPro)'
							Goto BadEnd;
						END
					END
					ELSE IF((@CurrentStatus = 2 AND @Status = 1) OR (@CurrentStatus = 3))
					BEGIN
						IF(@WHCode = 1 OR @WHCode = 3)
						BEGIN
							UPDATE APCSProDB.trans.lots  
							SET location_id = @Address_id,
								updated_at = @nowDateTime,
								updated_by = @emp_id
							WHERE id = @LotId
							GoTo InputRack;
						END
						ELSE IF(@WHCode = 2) --Hasuu
						BEGIN
							UPDATE APCSProDB.trans.surpluses 
							SET location_id = @Address_id,
								updated_at = @nowDateTime,
								updated_by = @emp_id
							WHERE lot_id = @LotId
							GoTo InputRack;
						END
						ELSE
						BEGIN				
							SELECT @Is_Pass = 'FALSE', 
								   @Error_Message_ENG = CONCAT('@WHCode Error(', @WHCode, ')'), 
								   @Error_Message_THA = CONCAT(N'@WHCode ผิดพลาด(', @WHCode,')'), 
								   @Handling = N'กรุณาตรวจสอบข้อมูลที่ Rack Control System (APCSPro)'
							Goto BadEnd;
						END
					END
					ELSE
					BEGIN
						SELECT @Is_Pass = 'FALSE',
							   @Error_Message_ENG = CONCAT('@CurrentStatus Error(', @CurrentStatus, ')'),
							   @Error_Message_THA = CONCAT(N'@CurrentStatus ผิดพลาด(', @CurrentStatus, ')'),
							   @Handling = N'กรุณาตรวจสอบข้อมูลที่ Rack Control System (APCSPro)'
						Goto BadEnd;
					END
				END
			END
			ELSE
			BEGIN
				SELECT @Is_Pass = 'FALSE',
					   @Error_Message_ENG = 'Please send @Status = 1/2 for Input Lot',
					   @Error_Message_THA = N'กรุณาส่ง @Status = 1/2 เพื่อ Input Lot',
					   @Handling = N'แก้ไขค่าใน Parameter ที่ส่งมาด้วยนะจ๊ะ'
				Goto BadEnd;
			END
		END

		-------------------------------------------------------------------------------------------------------------------------------------------------

		ReInsert:
		BEGIN TRY
			--Don't have to update location_id on Trans.lots or Trans.Surpluses becuz of the same location_id
			SET @OldRackId = @Address_id
			SET @Status = 3

			UPDATE DBx.dbo.rcs_current_locations
			SET status = @Status, updated_at = @nowDateTime, updated_by = @emp_id
			WHERE id in (SELECT curr.id 
						 FROM DBx.dbo.rcs_current_locations AS curr
						 INNER JOIN APCSProDB.trans.locations AS loca ON curr.location_id = loca.id
						 WHERE lot_id = @LotId AND loca.wh_code = @WHCode)

			INSERT INTO DBx.dbo.rcs_process_records(lot_id, location_id, record_class, recorded_at, recorded_by)
			VALUES (@LotId, @OldRackId, @Status, @nowDateTime, @emp_id)

			SET @Status = @CurrentStatus --Should be the same of old status cuz QA System always send 1 but the old mayne still be Reserved

			UPDATE DBx.dbo.rcs_current_locations
			SET lot_id = @LotId, status = @Status, updated_at = @nowDateTime, updated_by = @emp_id
			WHERE location_id = @Address_id

			INSERT INTO DBx.dbo.rcs_process_records(lot_id, location_id, record_class, recorded_at, recorded_by)
			VALUES (@LotId, @Address_id, @Status, @nowDateTime, @emp_id)

			SELECT @Is_Pass = 'TRUE', 
				   @Error_Message_ENG = '', 
				   @Error_Message_THA = '', 
				   @Handling = ''
			Goto Finally;
		END TRY
		BEGIN CATCH
			SELECT @Is_Pass = 'FALSE', 
				   @Error_Message_ENG = 'CATCH Between REINSERT', 
				   @Error_Message_THA = N'CATCH ขณะที่กำลัง REINSERT', 
				   @Handling = N'กรุณาตรวจสอบข้อมูลที่ Rack Control System (APCSPro)'
			Goto BadEnd;
		END CATCH
		-------------------------------------------------------------------------------------------------------------------------------------------------

		RemoveRack:
		IF NOT EXISTS(SELECT id FROM DBx.dbo.rcs_current_locations WHERE location_id = @OldRackId) --Are there this location? (For first times)
		BEGIN
			INSERT INTO DBx.dbo.rcs_current_locations(lot_id, location_id, status, updated_at, updated_by)
			VALUES(@LotId, @OldRackId, @Status, @nowDateTime, @emp_id)
			GoTo SaveTransactionForRemove;
		END
		ELSE IF EXISTS(SELECT curr.id 
					   FROM DBx.dbo.rcs_current_locations AS curr
					   INNER JOIN APCSProDB.trans.locations AS loca ON curr.location_id = loca.id
					   WHERE lot_id = @LotId AND loca.wh_code = @WHCode)
		BEGIN
			UPDATE DBx.dbo.rcs_current_locations
			SET status = @Status, updated_at = @nowDateTime, updated_by = @emp_id
			WHERE id in (SELECT curr.id 
						 FROM DBx.dbo.rcs_current_locations AS curr
						 INNER JOIN APCSProDB.trans.locations AS loca ON curr.location_id = loca.id
						 WHERE lot_id = @LotId AND loca.wh_code = @WHCode)
			GoTo SaveTransactionForRemove;
		END
		ELSE --Shouldn't happen
		BEGIN
			SELECT @OldLotNo FROM DBx.dbo.rcs_current_locations WHERE location_id = @OldRackId
			SELECT @Is_Pass = 'FALSE', 
				   @Error_Message_ENG = CONCAT('This location have ''', @OldLotNo, ''' not ''', @Item, ', Can''t Remove Lot'), 
				   @Error_Message_THA = CONCAT(N'ตำแหน่งนี้มี ''', @OldLotNo, ''' อยู่ ไม่ใช่ ''', @Item, ', ไม่สามารถ Remove Lot ได้'), 
				   @Handling = N'กรุณาตรวจสอบข้อมูลที่ Rack Control System (APCSPro)'
			Goto BadEnd;
		END

		SaveTransactionForRemove:
		INSERT INTO DBx.dbo.rcs_process_records(lot_id, location_id, record_class, recorded_at, recorded_by)
		VALUES (@LotId, @OldRackId, @Status, @nowDateTime, @emp_id)
		
		SELECT @Is_Pass = 'TRUE', 
			   @Error_Message_ENG = '', 
			   @Error_Message_THA = '', 
			   @Handling = ''
		Goto Finally;

		-------------------------------------------------------------------------------------------------------------------------------------------------

		InputRackForFirstTimes:
		INSERT INTO DBx.dbo.rcs_current_locations(lot_id, location_id, status, updated_at, updated_by)
		VALUES(@LotId, @Address_id, @Status, @nowDateTime, @emp_id)
		GoTo SaveTransactionForInput;

		InputRack:
		UPDATE DBx.dbo.rcs_current_locations
		SET lot_id = @LotId, status = @Status, updated_at = @nowDateTime, updated_by = @emp_id
		WHERE location_id = @Address_id
		GoTo SaveTransactionForInput;

		SaveTransactionForInput:
		INSERT INTO DBx.dbo.rcs_process_records(lot_id, location_id, record_class, recorded_at, recorded_by)
		VALUES (@LotId, @Address_id, @Status, @nowDateTime, @emp_id)

		SELECT @Is_Pass = 'TRUE', 
			   @Error_Message_ENG = '', 
			   @Error_Message_THA = '', 
			   @Handling = ''
		Goto Finally;
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' As Is_Pass,
			   ERROR_MESSAGE() As Error_Message_ENG,
			   ERROR_MESSAGE() As Error_Message_THA,
			   N'กรุณาตรวจสอบข้อมูลที่ Rack Control System (APCSPro)' As Handling
		ROLLBACK
	END CATCH

	Finally:
		SELECT @Is_Pass As Is_Pass,
			   @Error_Message_ENG As Error_Message_ENG,
			   @Error_Message_THA As Error_Message_THA,
			   @Handling As Handling
		COMMIT
		RETURN

		-------------------------------------------------------------------------------------------------------------------------------------------------
		
	BadEnd:
		SELECT @Is_Pass As Is_Pass,
			   @Error_Message_ENG As Error_Message_ENG,
			   @Error_Message_THA As Error_Message_THA,
			   @Handling As Handling
		ROLLBACK
		RETURN
END

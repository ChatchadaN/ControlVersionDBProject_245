-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_remove_rack_001] 
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
	 @rack_crt_id		INT
	, @rack_add_id		INT
	, @emp_id			INT
	, @CurrentLotNo		varchar(20)

	SELECT @rack_add_id = rack_add.id 
		,@rack_crt_id = rack_add.rack_control_id
		,@CurrentLotNo = rack_add.item
	FROM  APCSProDB.rcs.rack_addresses  as rack_add
	INNER JOIN APCSProDB.rcs.rack_controls ON rack_add.rack_control_id = rack_controls.id
	INNER JOIN APCSProDB.trans.location_racks ON rack_controls.id = location_racks.rack_control_id
	INNER JOIN APCSProDB.trans.locations ON location_racks.location_id = locations.id
	WHERE rack_controls.[name] = @Rackname and rack_add.[address] =  @Address AND locations.name = @Location;

	--SELECT @emp_id = id 
	--FROM APCSProDB.man.users
	--WHERE emp_num = @OPNo;

	BEGIN TRY
		BEGIN TRANSACTION;

		--rack นี้ address นี้ ไม่พบ lot
		IF @CurrentLotNo IS NULL
		BEGIN
			PRINT 'not found';

			ROLLBACK TRANSACTION;
			SELECT 
			'FALSE' AS Is_Pass 
			,CONCAT('Location: ', @Rackname, '-', @Address, ' not found Lot: ', @LotNo) AS Error_Message_ENG
			,CONCAT(N'Location: ', @Rackname, '-', @Address , N' นี้ไม่พบ Lot: ', @LotNo) AS Error_Message_THA 
			,N'กรุณาติดต่อ System' AS Handling	
			RETURN;
		END;

		--check lotno อยู่ใน item มั้ย
		IF EXISTS( SELECT item FROM APCSProDB.rcs.rack_addresses WHERE item = @LotNo)
		BEGIN
			print 'EXISTS'

			UPDATE APCSProDB.rcs.rack_addresses
			SET item = NULL,
				updated_at = GETDATE(),
				updated_by = @OPNo
			WHERE id = @rack_add_id AND rack_control_id = @rack_crt_id

			IF (@Categories = 1)
			BEGIN		
				UPDATE APCSProDB.trans.lots
				SET location_id = NULL,
					updated_at = GETDATE(),
					updated_by = @OPNo
				WHERE lot_no = @LotNo
			END
			ELSE IF (@Categories = 2 OR @Categories = 3)
			BEGIN
				UPDATE APCSProDB.trans.surpluses
				SET location_id = NULL,
					updated_at = GETDATE(),
					updated_by = @OPNo
				WHERE serial_no = @LotNo;
			END

			COMMIT TRANSACTION;

			SELECT 'TRUE' AS Is_Pass 
				,N'Remove Lot Success !!' AS Error_Message_ENG
				,N'Remove Lot สำเร็จ !!' AS Error_Message_THA 
				,N'' AS Handling
		END
		ELSE
		BEGIN
			print 'not in'

			SELECT 
				'FALSE' AS Is_Pass, 
				CONCAT('This Lot: ', @LotNo, ' not in ', @Rackname, '-', @Address) AS Error_Message_ENG, 
				CONCAT(N'Lot: ', @LotNo, N' นี้ไม่อยู่ที่ ', @Rackname, '-', @Address) AS Error_Message_THA, 
				N'กรุณาติดต่อ System' AS Handling;
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
		,N'ไม่สามารถ Remove lot ได้ !!' AS Error_Message_THA 
		,N'กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH

END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_rcs_rack_update]
	-- Add the parameters for the stored procedure here
	@OPNo int, @LotNo varchar(20), @Rack varchar(20), @RackId int, @Time varchar(MAX), @Status int, @ConNo varchar(20) = '000-00-0000'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here	
	DECLARE @dateTime datetime = CONVERT(datetime, @Time, 102), @WHCode int, @OldRackId int, @OldLotNo varchar(20), @nowDateTime datetime = (SELECT GETDATE())

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[sp_set_rcs_rack_update] @OPNoId = ''' + CONVERT (varchar (5), @OPNo) + ''', @LotNo = ''' + @LotNo + ''', @Rack = ''' + @Rack + ''', @RackId = ''' + CONVERT (varchar (5), @RackId) + ''', @Status = '''+ CONVERT (varchar (255), @Status)''''

	EXEC [dbo].[sp_set_rcs_update]
		@OPNo = @OPNo,
		@LotNo = @LotNo,
		@Rack = @Rack,
		@RackId = @RackId,
		@Status = @Status

	--! Bring out of Rack (Master Lot)
	IF(@Rack = '0')
	BEGIN
		SELECT @OldRackId = location_id
		FROM [APCSProDB].[trans].[lots]
		WHERE lot_no = @LotNo

		UPDATE [APCSProDB].[trans].[lots] with (ROWLOCK)
			SET updated_by = @OPNo,
				location_id = NULL,
				updated_at = @nowDateTime
			WHERE lot_no = @LotNo

		--! Update update_at_out where by lot_no and update_at_in
		UPDATE [DBx].[dbo].[rcs_records] with (ROWLOCK)
		SET update_at_out = @nowDateTime, updated_by_out = @OPNo --!, status = @Status
		--WHERE lot_no = @LotNo AND update_at_in = @dateTime
		WHERE lot_no = @LotNo AND update_at_out IS NULL AND location_id = @OldRackId

		SELECT 1
	END

	--! Bring out of Rack (Hasuu Lot)
	ELSE IF(@Rack = '1')
	BEGIN
		SELECT @OldRackId = (SELECT location_id 
						     FROM [APCSProDB].[trans].[surpluses]
						     WHERE serial_no = @LotNo)

		--IN Surpluses
		UPDATE [APCSProDB].[trans].[surpluses] with (ROWLOCK)
		SET --updated_by = @OPNo,
			location_id = NULL,
			updated_at = @nowDateTime
		WHERE serial_no = @LotNo

		--! Update update_at_out where by lot_no and update_at_in
		UPDATE [DBx].[dbo].[rcs_records] with (ROWLOCK)
		SET update_at_out = @nowDateTime, updated_by_out = @OPNo --!, status = @Status
		--WHERE lot_no = @LotNo AND update_at_in = @dateTime
		WHERE lot_no = @LotNo AND update_at_out IS NULL AND location_id = @OldRackId

		SELECT 1
	END

	--! Bring Into Rack
    ELSE
	BEGIN -- Insert Correct Location -> Insert location_id with Data from calling and status is history is 1 / 2

		SELECT @WHCode = wh_code
			FROM [APCSProDB].[trans].[locations]
			WHERE wh_code in (1,2,3) AND id = @RackId
			 

		IF(SELECT SUM (id) 
		   FROM (SELECT COUNT (A.id) AS id
		   	     FROM [APCSProDB].[trans].[locations]	AS A with (NOLOCK)
		   	     LEFT JOIN [APCSProDB].[trans].[lots]	AS B with (NOLOCK) ON A.id = B.location_id
		   	     WHERE (B.location_id IS NOT NULL)
		   	       AND (B.location_id = @RackId)
				   AND (B.lot_no = @LotNo)
		   	     
		   	     UNION ALL
	  	   	     
		   	     SELECT COUNT (A.id) AS id
		   	     FROM [APCSProDB].[trans].[locations]		AS A with (NOLOCK)
		   	     LEFT JOIN [APCSProDB].[trans].[surpluses]	AS B with (NOLOCK) ON A.id = B.location_id
		   	     WHERE (B.location_id IS NOT NULL)
		   	       AND (B.location_id = @RackId)
				   AND (B.serial_no = @LotNo)) x) = 0

		BEGIN

			--Hasuu Lot
			IF(@WHCode = 2)
			BEGIN				
				UPDATE [APCSProDB].[trans].[surpluses] with (ROWLOCK)
				SET --updated_by = @OPNo,
					location_id = @RackId,
					updated_at = @nowDateTime
				WHERE serial_no = @LotNo
			END
			ELSE
			BEGIN				
				UPDATE [APCSProDB].[trans].[lots] with (ROWLOCK)
				SET updated_by = @OPNo,
					location_id = @RackId,
					updated_at = @nowDateTime
				WHERE lot_no = @LotNo
			END
		
			--! Insert into dbx.dbo.rcs_records with lot_no, location_id and update_at_in
			INSERT INTO [DBx].[dbo].[rcs_records] (lot_no, location_id, update_at_in, status, updated_by_in)
			VALUES (@LotNo, @RackId, @nowDateTime, @Status, @OPNo)

			SELECT 1
		END

		ELSE -- Insert Same Location -> Insert location_id that there is some Lot is on that Location
		BEGIN 

			IF(@WHCode = 2)
			BEGIN				
				SELECT @OldLotNo = @LotNo --Always pass for many lots in 1 slot

				SELECT @OldRackId = (SELECT location_id 
									 FROM [APCSProDB].[trans].[surpluses]
									 WHERE serial_no = @LotNo)
			END
	
			--Master Lot
			ELSE
			BEGIN --Should be just 1 Lot				
				SELECT @OldLotNo = (SELECT lot_no 
									FROM [APCSProDB].[trans].[lots]
									WHERE location_id = @RackId)

				SELECT @OldRackId = (SELECT location_id 
									 FROM [APCSProDB].[trans].[lots]
									 WHERE lot_no = @LotNo)				
			END
			SELECT @OldRackId, @RackId
			IF (@OldLotNo = @LotNo AND @OldRackId = @RackId) --Reinsert
			BEGIN
				--! Update update_at_out where by lot_no and update_at_in
				UPDATE [DBx].[dbo].[rcs_records] with (ROWLOCK)
				SET update_at_out = @nowDateTime, updated_by_out = @OPNo --!, status = @Status
				WHERE lot_no = @LotNo AND update_at_in = @DateTime

				----! Insert into dbx.dbo.rcs_records with lot_no, location_id and update_at_in
				INSERT INTO [DBx].[dbo].[rcs_records] (lot_no, location_id, update_at_in, status, updated_by_in)
				VALUES (@LotNo, @RackId, @nowDateTime, @Status, @OPNo)			

				SELECT 1
			END
			ELSE
			BEGIN
				SELECT 0
			END
		END
	END
END

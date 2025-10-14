------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2024/08/05
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_rack]
(		
	  @LotNo			VARCHAR(20)
	, @OPNoId			INT
	, @categories		INT
	, @isCurrentStepNo	BIT = 0
)
-- @categories : rcs.rack_categories						
AS
BEGIN	 
	--ไม่ใช้แล้ว
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	
	DECLARE @LotId INT, @DevId INT, @JobId INT
	DECLARE @oldName VARCHAR(20), @oldAddress VARCHAR(20)
	DECLARE @get_rack_id INT
	DECLARE @newName VARCHAR(20), @newAddress VARCHAR(20), @newLocation VARCHAR(20)
	DECLARE @ErrorRackName VARCHAR(20)

	-- Retrieve Lot ID
	SET @LotId = (SELECT id FROM APCSProDB.trans.lots WHERE lot_no = @LotNo)

	-----------------------------------------------------------------
	-- Retrieve Device and Job IDs
	SELECT 
		@DevId = act_device_name_id
		, @JobId = CASE 
			WHEN @isCurrentStepNo = 1 --current_flow
				THEN IIF(lots.is_special_flow = 1 ,[lot_special_flows].job_id,currentDevFlow.job_id) 
			WHEN @isCurrentStepNo = 0 --next_flow
				THEN IIF(lots.is_special_flow = 1 ,[lot_special_flows].job_id,nextDevFlow.job_id) 
		   END
	FROM APCSProDB.trans.lots AS lots
	INNER JOIN APCSProDB.method.device_flows AS currentDevFlow 
		ON currentDevFlow.device_slip_id = lots.device_slip_id AND currentDevFlow.step_no = lots.step_no
	INNER JOIN APCSProDB.method.device_flows AS nextDevFlow 
		ON nextDevFlow.device_slip_id = lots.device_slip_id AND nextDevFlow.step_no = currentDevFlow.next_step_no	
	--Special_flow
	LEFT JOIN [APCSProDB].[trans].[special_flows] 
	ON [lots].[is_special_flow] = 1                                    
	AND [lots].[special_flow_id] = [special_flows].[id]                                                            
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
	ON [special_flows].[id] = [lot_special_flows].[special_flow_id] 
	AND [special_flows].[step_no] = [lot_special_flows].[step_no] 
	WHERE lots.id = @LotId

	BEGIN TRANSACTION;
	BEGIN TRY
		-- Common Steps
		SELECT 
			@oldAddress = rack_addresses.[address],
			@oldName = rack_controls.name 
		FROM APCSProDB.rcs.rack_addresses
		INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
		WHERE item = @LotNo


		IF EXISTS (	SELECT 1 FROM APCSProDB.rcs.rack_addresses
		INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id WHERE item = @LotNo)
		BEGIN
			ROLLBACK TRANSACTION;
			-- Lot already on a Rack in the same process
			SELECT '5000' AS code
			, 'CommonCellController' AS app_name
			, CONCAT(N'lot นี้อยู่ยน Rack ', @oldName, '-', @OldAddress) AS message
			, '' AS handling
			, '' AS new_name
			, '' AS new_address
			, ISNULL(@oldName, '') AS old_name
			, ISNULL(@oldAddress, '') AS old_address 

			RETURN;
		END

		IF NOT EXISTS (SELECT 1 FROM APCSProDB.rcs.rack_controls
						INNER JOIN APCSProDB.rcs.rack_devices ON rack_controls.id = rack_devices.rack_control_id
						INNER JOIN APCSProDB.rcs.rack_jobs ON rack_controls.id = rack_jobs.rack_control_id
						WHERE device_id = @DevId AND job_id = @JobId)
		BEGIN
			ROLLBACK TRANSACTION;
			-- Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
			SELECT '5001' AS code
				, app_name
				, message
				, handling
				, '' AS new_name
				, '' AS new_address
				, ISNULL(@oldName, '') AS old_name
				, ISNULL(@oldAddress, '') AS old_address
			FROM APCSProDB.mdm.errors
			WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha'
			
			RETURN;
		END
		ELSE
		BEGIN
			-- Step 1 หา Rack จาก device, job และ priority
			SET @get_rack_id = (SELECT TOP 1 rc.id
								FROM APCSProDB.rcs.rack_controls rc
								INNER JOIN APCSProDB.rcs.rack_devices  rd ON rc.id = rd.rack_control_id
								INNER JOIN APCSProDB.rcs.rack_jobs rj ON rc.id = rj.rack_control_id
								WHERE rd.device_id = @DevId AND rj.job_id = @JobId AND rc.category = @categories
								ORDER BY rd.priority ASC)
        
			-- Check Rack Space
			IF NOT EXISTS (SELECT 1 FROM APCSProDB.rcs.rack_addresses WHERE rack_addresses.rack_control_id = @get_rack_id AND rack_addresses.item IS NULL)
			BEGIN
				ROLLBACK TRANSACTION;
				--ชั้นวางเต็มแล้ว
				SET @ErrorRackName = (SELECT [name] FROM APCSProDB.rcs.rack_controls WHERE id = @get_rack_id)
				SELECT '5000' AS code
					, app_name
					, CONCAT(message, (N' Please check the Rack : ')
					, @ErrorRackName) AS message
					, handling
					, ISNULL(@newName, '') AS new_name
					, ISNULL(@newAddress, '') AS new_address
					, ISNULL(@oldName, '') AS old_name
					, ISNULL(@oldAddress, '') AS old_address
				FROM APCSProDB.mdm.errors 
				WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha'
				
				RETURN;
			END
			ELSE
			BEGIN
				-- Retrieve New Rack Address
				SELECT TOP 1 @newName = rack_controls.name, @newAddress = rack_addresses.address, @newLocation = locations.name
				FROM APCSProDB.rcs.rack_addresses
				INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
				--INNER JOIN APCSProDB.trans.location_racks ON location_racks.rack_control_id = rack_controls.id
				INNER JOIN APCSProDB.trans.locations ON rack_controls.location_id = locations.id
				WHERE rack_addresses.rack_control_id = @get_rack_id AND rack_addresses.item IS NULL
				ORDER BY rack_addresses.address ASC

				COMMIT TRANSACTION;

				SELECT '0' AS code
				, 'CommonCellController' AS app_name
				, '' AS message, '' AS handling
				, ISNULL(@newName, '') AS new_name
				, ISNULL(@newAddress, '') AS new_address
				, ISNULL(@oldName, '') AS old_name
				, ISNULL(@oldAddress, '') AS old_address

				RETURN;
			END
		END
		IF (@categories NOT IN (1, 2, 3))
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT '5000' AS code
			, 'CommonCellController' AS app_name
			, 'Categories not support' AS message
			, 'Please contact SYSTEM' AS handling
			, '' AS new_name
			, '' AS new_address
			, ISNULL(@oldName, '') AS old_name
			, ISNULL(@oldAddress, '') AS old_address 

			RETURN;
		END
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
		END

		SELECT '5002' AS code
			, app_name
			, CONCAT(message, (N' Please check the Rack : ')
			, @ErrorRackName) AS message
			, handling
			, ISNULL(@newName, '') AS new_name
			, ISNULL(@newAddress, '') AS new_address
			, ISNULL(@oldName, '') AS old_name
			, ISNULL(@oldAddress, '') AS old_address
		FROM APCSProDB.mdm.errors 
		WHERE code = '5002' AND app_name = 'CommonCellController' AND lang = 'Eng'

		RETURN;
	END CATCH

END

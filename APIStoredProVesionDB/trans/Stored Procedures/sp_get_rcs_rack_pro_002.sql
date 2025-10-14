-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_rcs_rack_pro_002]
	-- Add the parameters for the stored procedure here
	  @lot_no				VARCHAR(20)
	, @emp_id				INT
	, @categories			INT			
	, @isCurrentStepNo		BIT			= 0 -- 0 = next step(cellcon) || 1 = current step(lsms)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @LotId INT
	DECLARE @PkgId INT, @DevId INT, @JobId INT
	DECLARE @oldRackName VARCHAR(20), @oldAddress VARCHAR(20), @oldAddressID INT  = 0
	DECLARE @get_rack_id INT
	DECLARE @newRackName VARCHAR(20), @newAddress VARCHAR(20), @newAddressID INT  = 0
	DECLARE @ErrorRackName VARCHAR(20)

	-- Retrieve Lot ID
	SET @LotId = (SELECT id FROM APCSProDB.trans.lots WHERE lot_no = @lot_no)
	
	-- Retrieve Package Device and Job IDs
	SELECT 
		@PkgId = act_package_id,
		@DevId = act_device_name_id,		
		@JobId = CASE 
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
		ON [lots].[is_special_flow] = 1 AND [lots].[special_flow_id] = [special_flows].[id]                                                            
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
		ON [special_flows].[id] = [lot_special_flows].[special_flow_id] AND [special_flows].[step_no] = [lot_special_flows].[step_no]

	WHERE lots.id = @LotId

	BEGIN TRANSACTION
	BEGIN TRY
		
		-- Check categories
		IF (@categories NOT IN (1, 2, 3))
		BEGIN
			SELECT 'FALSE'						AS Is_Pass
				, ERROR_MESSAGE()				AS Error_Message_ENG
				, N'ไม่ support categories นี้'	AS Error_Message_THA
				, 'Please Contact SYSTEM'		AS Handling
				, ISNULL(@newRackName, '')		AS new_name 
				, ISNULL(@newRackName, '')		AS new_address 
				, @newAddressID					AS new_address_id
				, ISNULL(@oldRackName, '')		AS old_name
				, ISNULL(@oldAddress, '')		AS old_address	
				, @oldAddressID					AS old_address_id  

				COMMIT TRANSACTION
			RETURN;
		END

		-- Find Old Rack 
		SELECT 
			@oldAddressID	= [rack_addresses].[id],
			@oldAddress		= [rack_addresses].[address],
			@oldRackName	= [rack_controls].[name] 
		FROM APCSProDB.rcs.rack_addresses
		INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
		WHERE item = @lot_no
		
		-- Lot have old location 
		IF(@oldAddress != '' OR @oldRackName != '')
		BEGIN
			SELECT	'TRUE'															AS Is_Pass 
				, N'Lot is stay on Rack'											AS Error_Message_ENG
				, 'Lot '+ N'นี้ยังอยู่บน Rack'											AS Error_Message_THA
				, N'Please remove from Rack first'									AS Handling
				, CASE WHEN @oldRackName IS NULL THEN ''  ELSE @oldRackName	END		AS new_name 
				, CASE WHEN @oldAddress IS NULL THEN ''  ELSE @oldAddress END		AS new_address
				, @newAddressID														AS new_address_id
				, CASE WHEN @oldRackName IS NULL THEN ''  ELSE @oldRackName	END		AS old_name  
				, CASE WHEN @oldAddress IS NULL THEN ''  ELSE @oldAddress	END		AS old_address	
				, @oldAddressID														AS old_address_id
				
				COMMIT TRANSACTION
			RETURN;
		END
		ELSE
		BEGIN
			-- GET rack data with rack set
			DECLARE @RackSetList_TB TABLE
			(
				rack_id INT
				, rack_set_id INT
				, job_id VARCHAR(100) 
				, package_id INT
				, device_id INT
				, priority_rack INT
			)

			;WITH RackSetListData AS (
				SELECT rack_settings.rack_id
				,rack_set_lists.rack_set_id
				,STRING_AGG(CASE WHEN value_type = 2 THEN rack_set_lists.value END,',') AS job_id
				,rack_settings.[priority]
				FROM APCSProDB.rcs.rack_set_lists
				INNER JOIN APCSProDB.rcs.rack_settings on rack_settings.rack_set_id = rack_set_lists.rack_set_id
				INNER JOIN APCSProDB.rcs.rack_controls ON rack_settings.rack_id = rack_controls.id
				WHERE rack_controls.category = @categories
				GROUP BY rack_settings.rack_id ,rack_set_lists.rack_set_id,rack_settings.[priority]
			),
			DeviceData AS (
				SELECT rack_set_id
				,value as device_id
				FROM APCSProDB.rcs.rack_set_lists
				WHERE value_type = 1
			)
	
			INSERT INTO @RackSetList_TB
			SELECT rsl.rack_id
				,rsl.rack_set_id
				,rsl.job_id
				,packages.id as package_id
				,d.device_id
				,rsl.[priority]
			FROM RackSetListData rsl
			CROSS JOIN DeviceData d
			INNER JOIN APCSProDB.method.device_names ON device_names.id = d.device_id
			INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
			WHERE rsl.rack_set_id = d.rack_set_id
			ORDER BY rack_set_id

			IF NOT EXISTS (SELECT 1 FROM @RackSetList_TB)
			BEGIN
				SELECT 'FALSE'					AS Is_Pass
					, 'Rack not found. Please Check the data'		AS Error_Message_ENG
					, N'ไม่พบข้อมูล Rack Setting กรุณาตรวจสอบข้อมูล'				AS Error_Message_THA
					, 'Please Contact SYSTEM'		AS Handling
					, ISNULL(@newRackName, '')		AS new_name 
					, ISNULL(@newRackName, '')		AS new_address 
					, ISNULL(@newAddressID, '')		AS new_address_id
					, ISNULL(@oldRackName, '')		AS old_name
					, ISNULL(@oldAddress, '')		AS old_address	
					, ISNULL(@oldAddressID, '')	AS old_address_id 
					COMMIT TRANSACTION
				RETURN;
			END

			------------------------------------------------------------------------------------------------
			--GET Rack follow Condition
			DECLARE @RackSetCondition_TB TABLE
			(
				rack_id INT
				, rack_name VARCHAR(100)
				, job_id VARCHAR(100) 
				, package_id INT
				, device_id INT
				, priority_rack INT
			)

			INSERT INTO @RackSetCondition_TB
			SELECT rack_id, rack_controls.[name] as rack,[value] as job_id , device_id, package_id, priority_rack
			FROM @RackSetList_TB rsl
			INNER JOIN APCSProDB.rcs.rack_controls ON rsl.rack_id = rack_controls.id
			CROSS APPLY string_split(rsl.job_id, ',')
			WHERE [value] = @JobId
			AND package_id = @PkgId
			AND device_id = @DevId
			AND rack_controls.is_enable != 0
			GROUP BY rack_id,rack_controls.[name], [value] , device_id, package_id, priority_rack
			ORDER BY priority_rack,rack_controls.[name] ASC

			DECLARE @rack_name VARCHAR(50)
			SELECT TOP 1 @rack_name = rack_name FROM @RackSetCondition_TB ORDER BY priority_rack,rack_name ASC


			IF EXISTS(SELECT 1  FROM @RackSetCondition_TB)
			BEGIN
				-- GET rack address
				DECLARE @RackAuto_TB TABLE
				(
					rack_id INT
					, rack_name VARCHAR(100)
					, job_id VARCHAR(100) 
					, package_id INT
					, device_id INT
					, priority_rack INT
					, rack_address_id INT
					, rack_address varchar(50)
					, item varchar(50)
				)

				INSERT INTO @RackAuto_TB
				SELECT rack_id, rack_controls.[name] as rack,[value] as job_id , device_id, package_id, priority_rack
				,rack_addresses.id,rack_addresses.address , rack_addresses.item
				FROM @RackSetList_TB rsl
				INNER JOIN APCSProDB.rcs.rack_controls ON rsl.rack_id = rack_controls.id
				INNER JOIN APCSProDB.rcs.rack_addresses ON rack_controls.id = rack_addresses.rack_control_id
				CROSS APPLY string_split(rsl.job_id, ',')
				WHERE [value] = @JobId
				AND package_id = @PkgId
				AND device_id = @DevId
				AND rack_controls.is_enable != 0
				AND rack_addresses.item IS NULL
				AND rack_addresses.is_enable != 0
				ORDER BY priority_rack,rack_controls.[name] ASC

				-- GET ADDRESS
				SELECT TOP 1 @newAddressID = rack_address_id 
					, @newAddress = rack_address
					, @newRackName = rack_name
				FROM @RackAuto_TB ORDER BY priority_rack , rack_name , rack_address ASC

				IF @newAddressID IS NULL OR @newAddressID = 0
				BEGIN
			
					SELECT 'FALSE'						AS Is_Pass
						, 'Rack No Space '				AS Error_Message_ENG
						, CONCAT(N'Rack : ', @rack_name , N' เต็ม กรุณาตรวจสอบข้อมูล')		AS Error_Message_THA
						, 'Please Contact SYSTEM'		AS Handling
	 					, ISNULL(@newRackName, '')		AS new_name 
						, ISNULL(@newRackName, '')		AS new_address 
						, @newAddressID					AS new_address_id
						, ISNULL(@oldRackName, '')		AS old_name
						, ISNULL(@oldAddress, '')		AS old_address	
						, @oldAddressID					AS old_address_id 

						COMMIT TRANSACTION 
					RETURN;
				END
				ELSE
				BEGIN
					SELECT 'TRUE'					AS Is_Pass
						, 'Get Rack Success!!'		AS Error_Message_ENG
						, 'Get Rack Success!!'		AS Error_Message_THA
						, ''						AS Handling
						, ISNULL(@newRackName, '')	AS new_name 
						, ISNULL(@newAddress, '')	AS new_address 
						, @newAddressID				AS new_address_id
						, ISNULL(@oldRackName, '')	AS old_name
						, ISNULL(@oldAddress, '')	AS old_address	
						, @oldAddressID				AS old_address_id 

						COMMIT TRANSACTION 
					 RETURN;
				END

			END
			ELSE
			BEGIN
				SELECT 'TRUE'						AS Is_Pass
					, 'Next Process has not register Rack Setting'			AS Error_Message_ENG
					, N'Process ถัดไปยังไม่ได้ลงทะเบียน Rack Setting'				AS Error_Message_THA
					, 'Please Contact SYSTEM'		AS Handling
	 				, ISNULL(@newRackName, '')		AS new_name 
					, ISNULL(@newRackName, '')		AS new_address 
					, @newAddressID					AS new_address_id
					, ISNULL(@oldRackName, '')		AS old_name
					, ISNULL(@oldAddress, '')		AS old_address	
					, @oldAddressID					AS old_address_id 

					COMMIT TRANSACTION 
				RETURN;
			END

		END

	END TRY
	BEGIN CATCH
		SELECT 'FALSE'						AS Is_Pass
			, ERROR_MESSAGE()				AS Error_Message_ENG
			, N'ไม่สามารถ get rack auto ได้'	AS Error_Message_THA
			, 'Please Contact SYSTEM'		AS Handling
			, ISNULL(@newRackName, '')		AS new_name 
			, ISNULL(@newRackName, '')		AS new_address 
			, @newAddressID					AS new_address_id
			, ISNULL(@oldRackName, '')		AS old_name
			, ISNULL(@oldAddress, '')		AS old_address	
			, @oldAddressID					AS old_address_id 

			COMMIT TRANSACTION 
		RETURN;
		 
	END CATCH
END

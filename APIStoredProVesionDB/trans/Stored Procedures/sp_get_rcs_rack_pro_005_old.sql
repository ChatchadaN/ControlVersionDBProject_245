-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_rcs_rack_pro_005_old]
	-- Add the parameters for the stored procedure here
	  @lot_no				VARCHAR(20)
	, @emp_id				INT
	, @categories			INT			
	, @isCurrentStepNo		BIT	 =  0 -- 0 = next step(cellcon) || 1 = current step(lsms)
	, @qty					INT  =  1
	, @location				INT  =  0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @cate_name VARCHAR(50)
	DECLARE @oldRackID INT  = 0, @oldRackName VARCHAR(20), @oldAddress VARCHAR(20), @oldAddressID INT  = 0
	DECLARE @newRackID INT  = 0, @newRackName VARCHAR(20), @newAddress VARCHAR(20), @newAddressID INT  = 0
	DECLARE @rackCount INT, @addressCount INT

	DECLARE @TempResult_Address TABLE
	(
		rack_id INT
		, rack_name VARCHAR(100)
		, rack_set_id INT
		, priority_rack INT		
		, rack_address_id INT
		, rack_address varchar(50)
		, item varchar(50)
	)

	--categories
	SET @categories = IIF(@categories = 0 ,1,@categories)

	-- Retrieve Categories Name
	SELECT @cate_name = rack_categories.[name] 
	FROM APCSProDB.rcs.rack_categories
	WHERE id = @categories

	BEGIN TRY
		-------------------------------------------------------------------------------------------------------------------
		-- ! Rack Setting DATA base : Get Rack Setting ! --
		-- Step 0: ประกาศตัวแปร
		DECLARE @value_type_tb TABLE (value_type NVARCHAR(MAX));
		DECLARE @value_type NVARCHAR(MAX);
		DECLARE @columns NVARCHAR(MAX) = '';
		DECLARE @fill_columns NVARCHAR(MAX) = '';
		DECLARE @sql NVARCHAR(MAX);

		-- Step 1: ดึง value_type จาก item_labels
		INSERT INTO @value_type_tb (value_type)
		SELECT DISTINCT item_labels.label_eng
		FROM APCSProDB.rcs.rack_set_lists rsl
		INNER JOIN APCSProDB.rcs.item_labels 
			ON item_labels.val = rsl.value_type
			AND item_labels.name = 'rack_settings.value_type'

		-- Step 2: Loop เพื่อสร้าง column expression สำหรับ pivot
		WHILE EXISTS (SELECT TOP 1 value_type FROM @value_type_tb)
		BEGIN
			SELECT TOP 1 @value_type = value_type FROM @value_type_tb;

			SET @columns = @columns + 
				'MAX(CASE WHEN value_type = ''' + @value_type + ''' THEN value END) AS [' + @value_type + '], ';

			SET @fill_columns = @fill_columns +
				'' + @value_type + ' AS [' + @value_type + '], ';

			DELETE FROM @value_type_tb WHERE value_type = @value_type;
		END

		-- Step 3: ลบ comma สุดท้าย
		SET @columns = LEFT(@columns, LEN(@columns) - 1);
		SET @fill_columns = LEFT(@fill_columns, LEN(@fill_columns) - 1);

		-- Step 4: สร้าง dynamic SQL พร้อม DROP TABLE ถ้ามีอยู่แล้ว
		SET @sql = '
		IF OBJECT_ID(''tempdb..##TempResult_RackSetting'') IS NOT NULL
			DROP TABLE ##TempResult_RackSetting;

		WITH OriginalResult AS (
			SELECT 
				rack_id,
				rack_set_id,
				priority,
				rn,
				' + @columns + '
			FROM (
				SELECT 
					rs.rack_id,
					rs.rack_set_id,
					rs.priority,
					item_labels.label_eng AS value_type,
					rsl.value,
					ROW_NUMBER() OVER (
						PARTITION BY rs.rack_id, rs.rack_set_id, item_labels.label_eng 
						ORDER BY rsl.value
					) AS rn
				FROM APCSProDB.rcs.rack_set_lists rsl
				INNER JOIN APCSProDB.rcs.rack_settings rs ON rs.rack_set_id = rsl.rack_set_id
				INNER JOIN APCSProDB.rcs.rack_controls rc ON rs.rack_id = rc.id
				INNER JOIN APCSProDB.rcs.item_labels ON item_labels.val = rsl.value_type
					AND item_labels.name = ''rack_settings.value_type''
				WHERE rc.is_enable != 0
				  AND rc.category = @categories
			) AS pivoted
			GROUP BY rack_id, rack_set_id, priority, rn
		)

		SELECT 
			rack_id,
			rack_set_id,
			priority,
			rn,
			' + @fill_columns + '
		INTO ##TempResult_RackSetting
		FROM OriginalResult
		ORDER BY rack_id, rack_set_id, rn;
		';

		-- Step 5: Execute dynamic SQL
		EXEC sp_executesql 
			@sql, 
			N'@categories INT', 
			@categories = @categories;
		
		---------------------------------------------------------------------------------------------------------------------
		-- LOTS
		IF(@categories IN (1,2,3))
		BEGIN
			PRINT 'Condition AUTO RACK for LOTS'
			
			-- ! ITEM DATA ! --
			DECLARE @LotId INT
			DECLARE @PkgId INT, @DevId INT, @JobId INT

			DECLARE @TempResult_Rack TABLE
			(
				rack_id INT
				, rack_name VARCHAR(100)
				, rack_set_id INT
				, job_id VARCHAR(100) 
				, device_id INT
				, package_id INT	
				, priority_rack INT
			)

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
								THEN IIF(special_flows.id IS NULL , nextDevFlow.job_id , 
									CASE 
										WHEN lots.is_special_flow = 0 
											THEN IIF( lot_special_flows.step_no > currentDevFlow.next_step_no,nextDevFlow.job_id,  lot_special_flows.job_id)
										WHEN lots.is_special_flow = 1 
											THEN IIF( lot_special_flows.step_no != lot_special_flows.next_step_no , nextSPFlow.job_id , nextDevFlow.job_id)
									END)
							END 
			FROM APCSProDB.trans.lots AS lots
			INNER JOIN APCSProDB.method.device_flows AS currentDevFlow 
				ON currentDevFlow.device_slip_id = lots.device_slip_id AND currentDevFlow.step_no = lots.step_no
			INNER JOIN APCSProDB.method.device_flows AS nextDevFlow
				ON nextDevFlow.device_slip_id = lots.device_slip_id AND nextDevFlow.step_no = currentDevFlow.next_step_no
			--Special_flow
			LEFT JOIN APCSProDB.trans.special_flows 
				ON lots.special_flow_id = special_flows.id
			LEFT JOIN APCSProDB.trans.lot_special_flows 
				ON [lot_special_flows].special_flow_id = lots.special_flow_id
				AND lot_special_flows.step_no = special_flows.step_no
			LEFT JOIN APCSProDB.trans.lot_special_flows AS nextSPFlow 
				ON nextSPFlow.special_flow_id = lots.special_flow_id
				AND lot_special_flows.next_step_no = nextSPFlow.step_no

			WHERE lots.id = @LotId

			--------------------------------------------------------------------------------------
			-- ! GET RACK OLD ! --

			SELECT 
				@oldAddressID	= [rack_addresses].[id],
				@oldAddress		= [rack_addresses].[address],
				@oldRackID		= [rack_controls].[id],
				@oldRackName	= [rack_controls].[name] 
			FROM APCSProDB.rcs.rack_addresses
			INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
			WHERE item = @lot_no

			---------------------------------------------------------------------------------------
			-- ! GET RACK AUTO ! --
			-- RACK WIP Condition || check location
			IF (@categories = 1)
			BEGIN
				-- Lot have old location 
				IF(@oldAddress != '' OR @oldRackName != '')
				BEGIN
					SELECT	'TRUE'							AS Is_Pass 
						, N'Lot is stay on Rack'			AS Error_Message_ENG
						, 'Lot '+ N'นี้ยังอยู่บน Rack'			AS Error_Message_THA
						, N'Please remove from Rack first'	AS Handling
				
						, ISNULL(@newRackName, '')		AS new_name 
						, ISNULL(@newRackID, 0)			AS new_rack_id
						, ISNULL(@newAddress, '')		AS new_address 
						, ISNULL(@newAddressID, 0)		AS new_address_id
 
						, ISNULL(@oldRackName, '')		AS old_name
						, ISNULL(@oldRackID, 0)			AS old_rack_id
						, ISNULL(@oldAddress, '')		AS old_address	
						, ISNULL(@oldAddressID, 0)		AS old_address_id

					RETURN;
				END
				ELSE
				BEGIN
					PRINT 'CONDITION AUTO RACK WIP'

					---------------------------------------------------------------------------------------------------------
					-- GET RACK --		
					;WITH JobList AS (
						SELECT 
							rack_id,
							rack_set_id,
							STRING_AGG(CAST(Job AS NVARCHAR), ',') AS job_id
						FROM ##TempResult_RackSetting
						WHERE Job IS NOT NULL
						GROUP BY rack_id, rack_set_id
					)

					INSERT INTO @TempResult_Rack
					SELECT 
						rst.rack_id AS rack_id,
						rack_controls.name AS rack_name,
						rst.rack_set_id AS rack_set_id,			
						jl.job_id AS job_id,		
						rst.Device AS device_id,
						packages.id AS package_id,
						rst.[priority] AS [priority]
					FROM ##TempResult_RackSetting AS rst
					INNER JOIN APCSProDB.method.device_names ON device_names.id = rst.Device
					INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
					INNER JOIN APCSProDB.rcs.rack_controls ON rst.rack_id = rack_controls.id
					INNER JOIN JobList jl ON jl.rack_id = rst.rack_id AND jl.rack_set_id = rst.rack_set_id
					CROSS APPLY string_split(jl.job_id, ',')
					WHERE 
						[value] = @JobId
						AND rst.Device = @DevId
						AND packages.id = @PkgId
						AND rack_controls.is_enable != 0
					GROUP BY rst.rack_id , rack_controls.name, rst.rack_set_id, jl.job_id, rst.Device, packages.id ,rst.[priority] 
					ORDER BY rst.[priority],rack_controls.name ASC

				END
			END

			-- RACK Hassu/Hasuu Long Condition || not check location
			ELSE IF (@categories = 2 OR @categories = 3)
			BEGIN
				PRINT 'CONDITION AUTO RACK HASUU'
				---------------------------------------------------------------------------------------------------------
				-- GET RACK --	

				;WITH JobList AS (
					SELECT 
						rack_id,
						rack_set_id,
						STRING_AGG(CAST(Job AS NVARCHAR), ',') AS job_id
					FROM ##TempResult_RackSetting
					WHERE Job IS NOT NULL
					GROUP BY rack_id, rack_set_id
				)

				INSERT INTO @TempResult_Rack
				SELECT 
					rst.rack_id AS rack_id,
					rack_controls.name AS rack_name,
					rst.rack_set_id AS rack_set_id,			
					jl.job_id AS job_id,		
					rst.Device AS device_id,
					packages.id AS package_id,
					rst.[priority] AS [priority]
				FROM ##TempResult_RackSetting AS rst
				INNER JOIN APCSProDB.method.device_names ON device_names.id = rst.Device
				INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
				INNER JOIN APCSProDB.rcs.rack_controls ON rst.rack_id = rack_controls.id
				INNER JOIN JobList jl ON jl.rack_id = rst.rack_id AND jl.rack_set_id = rst.rack_set_id
				CROSS APPLY string_split(jl.job_id, ',')
				WHERE 
					rst.Device = @DevId
					AND packages.id = @PkgId
					AND rack_controls.is_enable != 0	
				GROUP BY rst.rack_id , rack_controls.name, rst.rack_set_id, jl.job_id, rst.Device, packages.id ,rst.[priority] 
				ORDER BY rst.[priority],rack_controls.name ASC
			END

			---------------------------------------------------------------------------------------------------------
			-- ! GET RACK ADDRESS AUTO ! --

			--HAVE RACK SETTING
			IF EXISTS(SELECT 1 FROM @TempResult_Rack)
			BEGIN
				PRINT 'HAVE RACK SETTING'

				INSERT INTO @TempResult_Address
				SELECT TOP (@qty) 
				rack_id
				, rack_name
				, rack_set_id
				, [priority_rack]
				, rack_addresses.id AS address_id
				, rack_addresses.address
				, rack_addresses.item
				FROM @TempResult_Rack AS rack_controls
				INNER JOIN APCSProDB.rcs.rack_addresses ON rack_controls.rack_id = rack_addresses.rack_control_id
				WHERE 
					rack_addresses.item IS NULL
					AND rack_addresses.is_enable != 0
				ORDER BY [priority_rack],rack_name ASC, rack_addresses.address ASC

				--CHECK RACK HAVE ADDRESS
				IF EXISTS(SELECT 1 FROM @TempResult_Address)
				BEGIN
					SELECT TOP 1 @newAddressID = rack_address_id 
					, @newAddress = rack_address
					, @newRackID = rack_id
					, @newRackName = rack_name
					FROM @TempResult_Address 
					ORDER BY [priority_rack] , rack_name , rack_address ASC

					SELECT 'TRUE'					AS Is_Pass
						, 'Get Rack Success!!'		AS Error_Message_ENG
						, 'Get Rack Success!!'		AS Error_Message_THA
						, ''						AS Handling

						, ISNULL(@newRackName, '')		AS new_name 
						, ISNULL(@newRackID, 0)			AS new_rack_id
						, ISNULL(@newAddress, '')		AS new_address 
						, ISNULL(@newAddressID, 0)		AS new_address_id
 
						, ISNULL(@oldRackName, '')		AS old_name
						, ISNULL(@oldRackID, 0)			AS old_rack_id
						, ISNULL(@oldAddress, '')		AS old_address	
						, ISNULL(@oldAddressID, 0)		AS old_address_id

					RETURN;
				END
				ELSE
				BEGIN
					PRINT 'RACK DONT HAVE ADDRESS'

					SELECT 'FALSE'						AS Is_Pass
						, 'Rack No Space '				AS Error_Message_ENG
						, N'Rack เต็ม กรุณาตรวจสอบข้อมูล'	AS Error_Message_THA
						, 'Please Contact SYSTEM'		AS Handling

						, ISNULL(@newRackName, '')		AS new_name 
						, ISNULL(@newRackID, 0)			AS new_rack_id
						, ISNULL(@newAddress, '')		AS new_address 
						, ISNULL(@newAddressID, 0)		AS new_address_id
 
						, ISNULL(@oldRackName, '')		AS old_name
						, ISNULL(@oldRackID, 0)			AS old_rack_id
						, ISNULL(@oldAddress, '')		AS old_address	
						, ISNULL(@oldAddressID, 0)		AS old_address_id
					RETURN;
				END
			END
			--DON'T HAVE RACK SETTING
			ELSE
			BEGIN
				PRINT 'DONT HAVE RACK SETTING'

				SELECT 'TRUE'						AS Is_Pass
					, 'Next Process has not register Rack Setting'			AS Error_Message_ENG
					, N'Process ถัดไปยังไม่ได้ลงทะเบียน Rack Setting'				AS Error_Message_THA
					, 'Please Contact SYSTEM'		AS Handling

					, ISNULL(@newRackName, '')		AS new_name 
					, ISNULL(@newRackID, 0)			AS new_rack_id
					, ISNULL(@newAddress, '')		AS new_address 
					, ISNULL(@newAddressID, 0)		AS new_address_id
 
					, ISNULL(@oldRackName, '')		AS old_name
					, ISNULL(@oldRackID, 0)			AS old_rack_id
					, ISNULL(@oldAddress, '')		AS old_address	
					, ISNULL(@oldAddressID, 0)		AS old_address_id
				RETURN;
			END

		END

		-- GET OLD RACK ALL CATEGORIES
		ELSE 
		BEGIN
			-- Find item in Rack Address
			IF EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_addresses WHERE item = @lot_no )
			BEGIN
				SELECT @oldRackID	= [rack_controls].[id]
					, @oldRackName	= [rack_controls].[name]
					, @oldAddressID = [rack_addresses].[id]
					, @oldAddress	= [rack_addresses].[address]
				FROM APCSProDB.rcs.rack_addresses
				INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
				WHERE item = @lot_no

				SELECT 'TRUE' AS Is_Pass
					, 'Get Rack Success!!' AS Error_Message_ENG
					, 'Get Rack Success!!' AS Error_Message_THA
					, '' AS Handling

					, ISNULL(@newRackName, '')		AS new_name 
					, ISNULL(@newRackID, 0)			AS new_rack_id
					, ISNULL(@newAddress, '')		AS new_address 
					, ISNULL(@newAddressID, 0)		AS new_address_id
 
					, ISNULL(@oldRackName, '')		AS old_name
					, ISNULL(@oldRackID, 0)			AS old_rack_id
					, ISNULL(@oldAddress, '')		AS old_address	
					, ISNULL(@oldAddressID, 0)		AS old_address_id
				RETURN;
			END
			ELSE
			BEGIN					

				SELECT 'FALSE' AS Is_Pass
    				, 'Item not found on rack.!!' AS Error_Message_ENG
    				, N'ไม่พบ item บน Rack!!' AS Error_Message_THA
    				, 'Please Contact SYSTEM' AS Handling

    				, ISNULL(@newRackName, '')		AS new_name 
					, ISNULL(@newRackID, 0)			AS new_rack_id
					, ISNULL(@newAddress, '')		AS new_address 
					, ISNULL(@newAddressID, 0)		AS new_address_id
 
					, ISNULL(@oldRackName, '')		AS old_name
					, ISNULL(@oldRackID, 0)			AS old_rack_id
					, ISNULL(@oldAddress, '')		AS old_address	
					, ISNULL(@oldAddressID, 0)		AS old_address_id
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
			, ISNULL(@newRackID, 0)			AS new_rack_id
			, ISNULL(@newAddress, '')		AS new_address 
			, ISNULL(@newAddressID, 0)		AS new_address_id
 
			, ISNULL(@oldRackName, '')		AS old_name
			, ISNULL(@oldRackID, 0)			AS old_rack_id
			, ISNULL(@oldAddress, '')		AS old_address	
			, ISNULL(@oldAddressID, 0)		AS old_address_id
		RETURN;
	END CATCH
END
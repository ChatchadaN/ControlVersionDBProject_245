-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_rack_flow_v1]
	-- Add the parameters for the stored procedure here
	@LotNo varchar(20), @OPNoId int, @lotStatus varchar(1) = 0, @isCurrentStepNo bit = 0 --False
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @PkgId int, @DevId int, @JobId int, @ErrorName varchar(255)
	DECLARE @newName varchar(20), @newAddress varchar(20), @oldName varchar(20), @oldAddress varchar(20)
	DECLARE @LotId INT = (SELECT id FROM APCSProDB.trans.lots WHERE lot_no =  @LotNo)

    -- Insert statements for procedure here

	SELECT @PkgId = act_package_id
	     , @DevId = act_device_name_id
	     , @JobId = CASE WHEN @isCurrentStepNo = 1 THEN currentDevFlow.job_id 
	   											   ELSE nextDevFlow.job_id END 

	FROM APCSProDB.trans.lots AS lots
	INNER JOIN APCSProDB.method.device_flows AS currentDevFlow ON currentDevFlow.device_slip_id = lots.device_slip_id 
															  AND currentDevFlow.step_no		= lots.step_no
	INNER JOIN APCSProDB.method.device_flows AS nextDevFlow	   ON nextDevFlow.device_slip_id	= lots.device_slip_id 
															  AND nextDevFlow.step_no			= currentDevFlow.next_step_no
	WHERE lots.id  = @LotId
	
	DECLARE @WHCode int, @OldRackId int, @Status int, @nowDateTime datetime = (SELECT GETDATE()), @OPNo int = (SELECT @OPNoId)

	--IN Surpluses or lot_status = 1 (HASUU LOT)
	IF (@lotStatus = 1) 
	BEGIN
		SELECT @oldAddress = address
			 , @oldName = name
		FROM DBx.dbo.rcs_current_locations   AS curr with (NOLOCK)
		INNER JOIN APCSProDB.trans.locations AS loca with (NOLOCK) ON curr.location_id = loca.id
		WHERE curr.status != 3 AND loca.wh_code = 2 AND curr.lot_id = @LotID

		--IF(@oldName IS NOT NULL OR @oldAddress IS NOT NULL)
		--BEGIN
		--	SELECT TOP(1) @WHCode = wh_code, @OldRackId = curr.location_id
		--	FROM APCSProDB.trans.locations AS loca
		--	INNER JOIN DBx.dbo.rcs_current_locations AS curr ON loca.id = curr.location_id
		--	WHERE curr.lot_id = @LotId
		--	ORDER BY curr.updated_at

		--	SET @Status = 3

		--	IF(@WHCode = 2) --IN Surpluses
		--	BEGIN
		--		UPDATE APCSProDB.trans.surpluses with (ROWLOCK)
		--		SET location_id = NULL,
		--			updated_at = @nowDateTime,
		--			updated_by = @OPNo
		--		WHERE lot_id = @LotId

		--		IF NOT EXISTS(SELECT id FROM DBx.dbo.rcs_current_locations WHERE location_id = @OldRackId) --Are there this location? (For first times)
		--		BEGIN
		--			INSERT INTO DBx.dbo.rcs_current_locations(lot_id, location_id, status, updated_at, updated_by)
		--			VALUES(@LotId, @OldRackId, @Status, @nowDateTime, @OPNo)
					
		--			INSERT INTO DBx.dbo.rcs_process_records(lot_id, location_id, record_class, recorded_at, recorded_by)
		--			VALUES (@LotId, @OldRackId, @Status, @nowDateTime, @OPNo)
		--		END
		--		ELSE IF EXISTS(SELECT id FROM DBx.dbo.rcs_current_locations WHERE lot_id = @LotId)
		--		BEGIN
		--			UPDATE DBx.dbo.rcs_current_locations
		--			SET status = @Status, updated_at = @nowDateTime, updated_by = @OPNo
		--			WHERE lot_id = @LotId
					
		--			INSERT INTO DBx.dbo.rcs_process_records(lot_id, location_id, record_class, recorded_at, recorded_by)
		--			VALUES (@LotId, @OldRackId, @Status, @nowDateTime, @OPNo)	
		--		END
		--		ELSE
		--		BEGIN
		--			SELECT '5003' AS code 
		--				 , app_name 
		--				 , message --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
		--				 , handling
		--				 , '' AS new_name 
		--				 , '' AS new_address 
		--				 , CASE WHEN @oldName IS NULL    THEN '' 
		--												 ELSE @oldName	  END AS old_name --Is this LotNo IS ON Any Rack?
		--				 , CASE WHEN @oldAddress IS NULL THEN '' 
		--												 ELSE @oldAddress END AS old_address	
		--			FROM APCSProDB.mdm.errors
		--			WHERE code = '5003' AND app_name = 'CommonCellController' AND lang = 'Tha'
		--		END
		--	END
		--	ELSE
		--	BEGIN
		--		SELECT '5003' AS code 
		--			 , app_name 
		--			 , message --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
		--			 , handling
		--			 , '' AS new_name 
		--			 , '' AS new_address 
		--			 , CASE WHEN @oldName IS NULL    THEN '' 
		--											 ELSE @oldName	  END AS old_name --Is this LotNo IS ON Any Rack?
		--			 , CASE WHEN @oldAddress IS NULL THEN '' 
		--											 ELSE @oldAddress END AS old_address	
		--		FROM APCSProDB.mdm.errors
		--		WHERE code = '5003' AND app_name = 'CommonCellController' AND lang = 'Tha'
		--	END
		--END

		-- NOT in control
		IF NOT EXISTS (SELECT 1 --count row that empty and correct rack
				       FROM APCSProDB.trans.locations  AS loca with (NOLOCK)
				       INNER JOIN DBx.dbo.rcs_controls AS con  with (NOLOCK) ON loca.name = con.name
				       WHERE con.package_id = @PkgId AND con.device_id = @DevId AND loca.wh_code = 2)  
		BEGIN 
			SELECT '0' AS code 
			     , app_name 
			     , message --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
			     , handling
			     , '' AS new_name 
			     , '' AS new_address 
			     , CASE WHEN @oldName IS NULL    THEN '' 
												 ELSE @oldName	  END AS old_name --Is this LotNo IS ON Any Rack?
			     , CASE WHEN @oldAddress IS NULL THEN '' 
												 ELSE @oldAddress END AS old_address	
			FROM APCSProDB.mdm.errors
			WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha'
		END
	
		--IN control
		ELSE 
		BEGIN

			SELECT TOP(1) @newName = loca.name
					    , @newAddress = loca.address
			FROM APCSProDB.trans.locations		     AS loca with (NOLOCK)
			INNER JOIN DBx.dbo.rcs_controls		     AS con  with (NOLOCK) ON loca.name = con.name
			LEFT  JOIN DBx.dbo.rcs_current_locations AS curr with (NOLOCK) ON loca.id	= curr.location_id
			WHERE con.package_id = @PkgId AND con.device_id = @DevId AND loca.wh_code = 2 AND (curr.status = 3 OR curr.status IS NULL)
			ORDER BY con.priorities, loca.name, loca.address

			--NO SPACE IN THAT RACK (unavailable)
			IF(@newName IS NULL AND @newAddress IS NULL)
			BEGIN	
				SELECT @ErrorName = COALESCE(@ErrorName + ', ', '') + loca.name
				FROM APCSProDB.trans.locations  AS loca with (NOLOCK)
				INNER JOIN DBx.dbo.rcs_controls AS con  with (NOLOCK) ON loca.name = con.name
				WHERE con.package_id = @PkgId AND con.device_id = @DevId AND loca.wh_code = 2
				GROUP BY loca.name
	
				SELECT '5000' AS code
					 , app_name 
					 , CONCAT(message,(N' Please check the Rack : '), @ErrorName) AS message --ชั้นวางเต็มแล้ว
					 , handling
					 , CASE WHEN @newName IS NULL    THEN '' 
												     ELSE @newName    END AS new_name
					 , CASE WHEN @newAddress IS NULL THEN '' 
													 ELSE @newAddress END AS new_address 
					 , CASE WHEN @oldName IS NULL    THEN '' 
													 ELSE @oldName    END AS old_name
					 , CASE WHEN @oldAddress IS NULL THEN '' 
													 ELSE @oldAddress END AS old_address	
				FROM APCSProDB.mdm.errors 
				WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha'
			END
	
			--HAVE SPACE IN THAT RACK (available)
			ELSE
			BEGIN
				SELECT '0' AS code
					 , app_name 
					 , '' AS message 
					 , '' AS handling 
					 , CASE WHEN @newName IS NULL	 THEN '' 
													 ELSE @newName	  END AS new_name 
					 , CASE WHEN @newAddress IS NULL THEN '' 
													 ELSE @newAddress END AS new_address 
					 , CASE WHEN @oldName IS NULL    THEN '' 
													 ELSE @oldName    END AS old_name
					 , CASE WHEN @oldAddress IS NULL THEN '' 
												     ELSE @oldAddress END AS old_address	
				FROM APCSProDB.mdm.errors 
				WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha'
			END
		END
	END

	--NOT Surpluses or lot_status = 0 (MASTER LOT)
	ELSE
	BEGIN 
		SELECT @oldAddress = address
			 , @oldName    = name
		FROM DBx.dbo.rcs_current_locations   AS curr with (NOLOCK)
		INNER JOIN APCSProDB.trans.locations AS loca with (NOLOCK) ON curr.location_id = loca.id
		WHERE curr.status != 3 AND loca.wh_code in (1,3) AND curr.lot_id = @LotID
		--WHERE curr.status != 3 AND loca.wh_code != 2 AND curr.lot_id = @LotID

		--IF(@oldName IS NOT NULL OR @oldAddress IS NOT NULL)
		--BEGIN
		--	SELECT TOP(1) @WHCode = wh_code, @OldRackId = curr.location_id
		--	FROM APCSProDB.trans.locations AS loca
		--	INNER JOIN DBx.dbo.rcs_current_locations AS curr ON loca.id = curr.location_id
		--	WHERE curr.lot_id = @LotId
		--	ORDER BY curr.updated_at

		--	SET @Status = 3

		--	IF(@WHCode = 1 OR @WHCode = 3) --Master
		--	BEGIN
		--		UPDATE APCSProDB.trans.lots with (ROWLOCK)
		--		SET location_id = NULL,
		--			updated_at = @nowDateTime,
		--			updated_by = @OPNo
		--		WHERE id = @LotId

		--		IF NOT EXISTS(SELECT id FROM DBx.dbo.rcs_current_locations WHERE location_id = @OldRackId) --Are there this location? (For first times)
		--		BEGIN
		--			INSERT INTO DBx.dbo.rcs_current_locations(lot_id, location_id, status, updated_at, updated_by)
		--			VALUES(@LotId, @OldRackId, @Status, @nowDateTime, @OPNo)
					
		--			INSERT INTO DBx.dbo.rcs_process_records(lot_id, location_id, record_class, recorded_at, recorded_by)
		--			VALUES (@LotId, @OldRackId, @Status, @nowDateTime, @OPNo)
		--		END
		--		ELSE IF EXISTS(SELECT id FROM DBx.dbo.rcs_current_locations WHERE lot_id = @LotId)
		--		BEGIN
		--			UPDATE DBx.dbo.rcs_current_locations
		--			SET status = @Status, updated_at = @nowDateTime, updated_by = @OPNo
		--			WHERE lot_id = @LotId
					
		--			INSERT INTO DBx.dbo.rcs_process_records(lot_id, location_id, record_class, recorded_at, recorded_by)
		--			VALUES (@LotId, @OldRackId, @Status, @nowDateTime, @OPNo)
		--		END
		--		ELSE
		--		BEGIN
		--			SELECT '5003' AS code 
		--			 , app_name 
		--			 , message --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
		--			 , handling
		--			 , '' AS new_name 
		--			 , '' AS new_address 
		--			 , CASE WHEN @oldName IS NULL    THEN '' 
		--											 ELSE @oldName	  END AS old_name --Is this LotNo IS ON Any Rack?
		--			 , CASE WHEN @oldAddress IS NULL THEN '' 
		--											 ELSE @oldAddress END AS old_address	
		--			FROM APCSProDB.mdm.errors
		--			WHERE code = '5003' AND app_name = 'CommonCellController' AND lang = 'Tha'
		--		END
		--	END
		--	ELSE
		--	BEGIN
		--		SELECT '5003' AS code 
		--			 , app_name 
		--			 , message --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
		--			 , handling
		--			 , '' AS new_name 
		--			 , '' AS new_address 
		--			 , CASE WHEN @oldName IS NULL    THEN '' 
		--											 ELSE @oldName	  END AS old_name --Is this LotNo IS ON Any Rack?
		--			 , CASE WHEN @oldAddress IS NULL THEN '' 
		--											 ELSE @oldAddress END AS old_address	
		--		FROM APCSProDB.mdm.errors
		--		WHERE code = '5003' AND app_name = 'CommonCellController' AND lang = 'Tha'
		--	END
		--END

		-- NOT in control
		IF NOT EXISTS (SELECT 1 
					   FROM APCSProDB.trans.locations AS loca with (NOLOCK)
					   INNER JOIN DBx.dbo.rcs_controls AS con with (NOLOCK) ON loca.name = con.name
					   CROSS APPLY string_split(con.job_id, ',')
					   WHERE con.package_id = @PkgId AND con.device_id = @DevId AND loca.wh_code = 1 AND value = @JobId)

		BEGIN 
			SELECT '0' AS code 
				 , app_name 
				 , message --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
				 , handling
				 , '' AS new_name 
				 , '' AS new_address
				 , CASE WHEN @oldName IS NULL	 THEN '' 
												 ELSE @oldName	  END AS old_name  
				 , CASE WHEN @oldAddress IS NULL THEN '' 
												 ELSE @oldAddress END AS old_address	
			FROM APCSProDB.mdm.errors 
			WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha'	

		END
	
		--IN control
		ELSE 
		BEGIN 
			SELECT TOP(1) @newName	  = loca.name
			            , @newAddress = loca.address
			FROM APCSProDB.trans.locations			AS loca with (NOLOCK)
			INNER JOIN DBx.dbo.rcs_controls			AS con  with (NOLOCK) ON loca.name = con.name
			LEFT JOIN DBx.dbo.rcs_current_locations AS curr with (NOLOCK) ON loca.id = curr.location_id -- For some location_id still no lot get in before this will be null
			CROSS APPLY string_split(con.job_id, ',')
			WHERE con.package_id = @PkgId AND con.device_id = @DevId AND loca.wh_code = 1 AND value = @JobId AND (curr.status = 3 OR curr.status IS NULL)
			ORDER BY con.priorities, loca.name, loca.address

			--NO SPACE IN THAT RACK (unavailable)
			IF(@newName IS NULL AND @newAddress IS NULL)
			BEGIN	
				SELECT @ErrorName = COALESCE(@ErrorName + ', ', '') + loca.name
				FROM APCSProDB.trans.locations  AS loca with (NOLOCK)
				INNER JOIN DBx.dbo.rcs_controls AS con with (NOLOCK) ON loca.name = con.name
				CROSS APPLY string_split(con.job_id, ',')
				WHERE con.package_id = @PkgId AND con.device_id = @DevId AND loca.wh_code = 1 AND value = @JobId
				GROUP BY loca.name
	
				SELECT '5000' AS code  
					 , app_name 
					 , CONCAT(message , (N' โปรดตรวจสอบชั้นวาง : '), @ErrorName ) AS message --ชั้นวางเต็มแล้ว
					 , handling
					 , CASE WHEN @newName IS NULL	 THEN ''  
													 ELSE @newName	  END AS new_name
					 , CASE WHEN @newAddress IS NULL THEN '' 
													 ELSE @newAddress END AS new_address
					 , CASE WHEN @oldName IS NULL	 THEN '' 
													 ELSE @oldName	  END AS old_name 
					 , CASE WHEN @oldAddress IS NULL THEN '' 
													 ELSE @oldAddress END AS old_address
				FROM APCSProDB.mdm.errors 
				WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha'

			END
	
			--HAVE SPACE IN THAT RACK (available)
			ELSE
			BEGIN
				SELECT '0' AS code 
					 , 'CommonCellController' AS app_name 
					 , '' AS message
					 , '' AS handling 
					 , CASE WHEN @newName IS NULL	 THEN '' 
													 ELSE @newName	 END AS new_name 
					 , CASE WHEN @newAddress IS NULL THEN '' 
													 ELSE @newAddress END AS new_address 
					 , CASE WHEN @oldName IS NULL	 THEN '' 
													 ELSE @oldName	 END AS old_name 
					 , CASE WHEN @oldAddress IS NULL THEN '' 
													 ELSE @oldAddress END AS old_address
			END
		END
	END
END

--USE [StoredProcedureDB]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_get_rcs_rack_flow]    Script Date: 22/11/03 08:23:38 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
---- =============================================
---- Author:		<Author,,Name>
---- Create date: <Create Date,,>
---- Description:	<Description,,>
---- =============================================
--ALTER PROCEDURE [dbo].[sp_get_rcs_rack_flow]
--	-- Add the parameters for the stored procedure here
--	@LotNo varchar(20), @OPNoId int, @lotStatus varchar(1) = 0, @isCurrentStepNo bit = 0 --False
--AS
--BEGIN
--	-- SET NOCOUNT ON added to prevent extra result sets from
--	-- interfering with SELECT statements.
--	SET NOCOUNT ON;
--	DECLARE @device_slip_id int, @NextStepNo int, @CurrentStepNo int, @UsingStepNo int, @JobId int, @PkgId int, @DevId int, @ErrorName varchar(255)
--	DECLARE @newName varchar(20), @newAddress varchar(20), @oldName varchar(20), @oldAddress varchar(20)
--    -- Insert statements for procedure here

--	SELECT -- Find Next Step No and Device Slip Id for find Next Job Id
--	@device_slip_id = (SELECT device_slip_id
--					   FROM [APCSProDB].[method].[device_flows] with (NOLOCK)
--					   WHERE device_slip_id = (SELECT device_slip_id
--					   					       FROM APCSProDB.trans.lots with (NOLOCK)
--					   					       WHERE lot_no = @LotNo) 
--					     AND step_no = (SELECT step_no
--					   			        FROM APCSProDB.trans.lots with (NOLOCK)
--					   			        WHERE lot_no = @LotNo)), 

--	@NextStepNo = next_step_no, @CurrentStepNo = step_no
--	                   FROM [APCSProDB].[method].[device_flows] with (NOLOCK)
--	                   WHERE device_slip_id = (SELECT device_slip_id
--	                    					   FROM APCSProDB.trans.lots with (NOLOCK)
--	                    					   WHERE lot_no = @LotNo) 
--	                     AND step_no = (SELECT step_no
--	                    			    FROM APCSProDB.trans.lots with (NOLOCK)
--	                    			    WHERE lot_no = @LotNo)

--	IF(@isCurrentStepNo = 1) --Current StepNo
--	BEGIN
--		SET @UsingStepNo = @CurrentStepNo
--	END
--	ELSE --Next StepNo
--	BEGIN
--		SET @UsingStepNo = @NextStepNo
--	END

--	SELECT --New Select cause @NextStepNo Still NULL in same Select
--	@JobId = 
--		(SELECT job_id
--		 FROM [APCSProDB].[method].[device_flows] with (NOLOCK)
--		 WHERE device_slip_id = @device_slip_id
--		   AND step_no = @UsingStepNo
--		   AND is_skipped = 0),

--	@PkgId =
--		(SELECT pkg.id
--		 FROM [APCSProDB].[trans].[lots] AS lot with (NOLOCK)
--		 INNER JOIN [APCSProDB].[method].[packages] AS pkg with (NOLOCK) ON lot.act_package_id = pkg.id
--		 WHERE lot_no = @LotNo),

--	@DevId =
--		(SELECT dev.id
--		 FROM [APCSProDB].[trans].[lots] with (NOLOCK)
--		 INNER JOIN APCSProDB.method.device_names AS dev with (NOLOCK) ON dev.id = act_device_name_id
--		 WHERE lot_no = @LotNo)

--	--IN Surpluses or lot_status = 1 (HASUU LOT)
--	IF((SELECT COUNT(serial_no)
--	   FROM [APCSProDB].[trans].[surpluses]
--	   WHERE serial_no = @LotNo AND in_stock != 0) != 0 AND @lotStatus = 1)
--	BEGIN 

--		SELECT @oldName = name 
--		FROM [APCSProDB].[trans].[locations] with (NOLOCK)
--		WHERE id = (SELECT location_id
--					FROM [APCSProDB].[trans].[surpluses] AS lot with (NOLOCK)
--					JOIN [APCSProDB].[trans].[locations] AS loca with (NOLOCK) ON loca.id = lot.location_id
--					WHERE lot.location_id IS NOT NULL 
--					  AND lot.serial_no = @LotNo)		
	
--		SELECT @oldAddress = address 
--		FROM [APCSProDB].[trans].[locations] with (NOLOCK)
--		WHERE id = (SELECT location_id
--					FROM [APCSProDB].[trans].[surpluses] AS lot with (NOLOCK)
--					JOIN [APCSProDB].[trans].[locations] AS loca with (NOLOCK) ON loca.id = lot.location_id
--					WHERE lot.location_id IS NOT NULL 
--					  AND lot.serial_no = @LotNo)

--		-- NOT in control
--		IF((SELECT COUNT(A.name) --count row that empty and correct rack
--		     FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
--			 INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
--			 WHERE B.package_id = @PkgId AND B.device_id = @DevId AND A.wh_code = 2 --Hasuu Rack --(A.name like 'HS%' OR A.name like 'OG%' OR A.name like 'TT%')
--			) = 0)
--		BEGIN 
--			SELECT 
--			('0') AS code ,
	
--			('CommonCellController') AS app_name ,
	
--			(SELECT message 
--			 FROM [APCSProDB].[mdm].[errors] 
--			 WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha') AS message , --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
	
--			(SELECT handling 
--			 FROM [APCSProDB].[mdm].[errors] 
--			 WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha') AS handling , --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
	
--			(SELECT '') AS new_name ,
	
--			(SELECT '') AS new_address ,
	
--			--Is this LotNo IS ON Any Rack?
--			(SELECT CASE WHEN @oldName IS NULL THEN ''
--						 ELSE @oldName END
--			) AS old_name ,
	
--			(SELECT CASE WHEN @oldAddress IS NULL THEN ''
--						 ELSE @oldAddress END
--			) AS old_address		
--		END
	
--		--IN control
--		ELSE 
--		BEGIN
		
--			SELECT TOP(1) @newName = A.name, @newAddress = A.address
--			FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
--			INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
--			WHERE B.package_id = @PkgId AND B.device_id = @DevId AND A.wh_code = 2 --Hasuu Rack --(A.name like 'HS%' OR A.name like 'OG%'OR A.name like 'TT%')
--			AND A.id NOT IN (SELECT loca.id --LotNo NOT IN (ON Rack and wip_state = 20)
--							 FROM [APCSProDB].[trans].[locations] AS loca with (NOLOCK)
--							 JOIN [APCSProDB].[trans].[surpluses] AS lot with (NOLOCK) ON loca.id = lot.location_id
--							 WHERE lot.location_id IS NOT NULL)
--			ORDER BY B.priorities, A.name, A.address

--			--NO SPACE IN THAT RACK (unavailable)
--			IF(@newName IS NULL AND @newAddress IS NULL)
--			BEGIN	
--				SELECT @ErrorName = COALESCE(@ErrorName + ', ', '') + A.name
--				FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
--				INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
--				WHERE B.package_id = @PkgId AND B.device_id = @DevId AND A.wh_code = 2 --Hasuu Rack --(A.name like 'HS%' OR A.name like 'OG%'OR A.name like 'TT%')
--				GROUP BY A.name
	
--				SELECT
--				('5000') AS code , --ชั้นวางเต็มแล้ว
	
--				('CommonCellController') AS app_name ,
	
--				(SELECT CONCAT(
--					(SELECT message 
--					 FROM [APCSProDB].[mdm].[errors] 
--					 WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha'),
--					(N' โปรดตรวจสอบชั้นวาง : '),
--					@ErrorName
--				)) AS message ,
			 
--				(SELECT handling 
--				 FROM [APCSProDB].[mdm].[errors] 
--				 WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha') AS handling ,
	
--				(SELECT CASE WHEN @newName IS NULL THEN ''
--							 ELSE @newName END
--				) AS new_name ,

--				(SELECT CASE WHEN @newAddress IS NULL THEN ''
--							 ELSE @newAddress END
--				) AS new_address ,
	
--				--Is this LotNo IS ON Any Rack?
--				(SELECT CASE WHEN @oldName IS NULL THEN ''
--							 ELSE @oldName END
--				) AS old_name ,
	
--				(SELECT CASE WHEN @oldAddress IS NULL THEN ''
--							 ELSE @oldAddress END
--				) AS old_address		
--			END
	
--			--HAVE SPACE IN THAT RACK (available)
--			ELSE
--			BEGIN
--				SELECT
--				('0') AS code ,
	
--				('CommonCellController') AS app_name ,
	
--				('') AS message ,
	
--				('') AS handling,
	
--				(SELECT CASE WHEN @newName IS NULL THEN ''
--							 ELSE @newName END
--				) AS new_name ,

--				(SELECT CASE WHEN @newAddress IS NULL THEN ''
--							 ELSE @newAddress END
--				) AS new_address ,
	
--				--Is this LotNo IS ON Any Rack?
--				(SELECT CASE WHEN @oldName IS NULL THEN ''
--							 ELSE @oldName END
--				) AS old_name ,
	
--				(SELECT CASE WHEN @oldAddress IS NULL THEN ''
--							 ELSE @oldAddress END
--				) AS old_address						
--			END
--		END
--	END

--	--NOT Surpluses or lot_status = 0 (MASTER LOT)
--	ELSE
--	BEGIN 

--		SELECT @oldName = name 
--		FROM [APCSProDB].[trans].[locations]
--		WHERE id = (SELECT location_id
--					FROM [APCSProDB].[trans].[lots] AS lot with (NOLOCK)
--					JOIN [APCSProDB].[trans].[locations] AS loca with (NOLOCK) ON loca.id = lot.location_id
--					WHERE lot.location_id IS NOT NULL 
--					  AND lot.lot_no = @LotNo)
	
--		SELECT @oldAddress = address 
--		FROM [APCSProDB].[trans].[locations] with (NOLOCK)
--		WHERE id = (SELECT location_id
--						 FROM [APCSProDB].[trans].[lots] AS lot with (NOLOCK)
--						 JOIN [APCSProDB].[trans].[locations] AS loca with (NOLOCK) ON loca.id = lot.location_id
--						 WHERE lot.location_id IS NOT NULL 
--					   AND lot.lot_no = @LotNo)

--		-- NOT in control
--		IF((SELECT COUNT(A.name) --count row that empty and correct rack
--		     FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
--			 INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
--			 CROSS APPLY string_split(B.job_id, ',')
--			 WHERE B.package_id = @PkgId AND B.device_id = @DevId AND A.wh_code = 1 --Normal Rack --(A.name not like 'HS%' OR A.name not like 'OG%' OR A.name not like 'TT%')
--			 AND value = @JobId
--			) = 0)
--		BEGIN 
--			SELECT 
--			('0') AS code ,
	
--			('CommonCellController') AS app_name ,
	
--			(SELECT message 
--			 FROM [APCSProDB].[mdm].[errors] 
--			 WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha') AS message , --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
	
--			(SELECT handling 
--			 FROM [APCSProDB].[mdm].[errors] 
--			 WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha') AS handling , --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
	
--			(SELECT '') AS new_name ,
	
--			(SELECT '') AS new_address ,
	
--			--Is this LotNo IS ON Any Rack?
--			(SELECT CASE WHEN @oldName IS NULL THEN ''
--						 ELSE @oldName END
--			) AS old_name ,
	
--			(SELECT CASE WHEN @oldAddress IS NULL THEN ''
--						 ELSE @oldAddress END
--			) AS old_address		
--		END
	
--		--IN control
--		ELSE 
--		BEGIN 

--			SELECT TOP(1) @newName = A.name, @newAddress = A.address
--			FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
--			INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
--			CROSS APPLY string_split(B.job_id, ',')
--			WHERE B.package_id = @PkgId AND B.device_id = @DevId AND A.wh_code = 1 --Normal Rack --(A.name not like 'HS%' OR A.name not like 'OG%' OR A.name not like 'TT%')
--			AND value = @JobId
--			AND A.id NOT IN (SELECT loca.id --LotNo NOT IN (ON Rack and wip_state = 20)
--							 FROM [APCSProDB].[trans].[locations] AS loca with (NOLOCK)
--							 JOIN [APCSProDB].[trans].[lots] AS lot with (NOLOCK) ON loca.id = lot.location_id
--							 WHERE lot.location_id IS NOT NULL)
--			ORDER BY B.priorities, A.name, A.address

--			--NO SPACE IN THAT RACK (unavailable)
--			IF(@newName IS NULL AND @newAddress IS NULL)
--			BEGIN	
--				SELECT @ErrorName = COALESCE(@ErrorName + ', ', '') + A.name
--				FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
--				INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
--				CROSS APPLY string_split(B.job_id, ',')
--				WHERE B.package_id = @PkgId AND B.device_id = @DevId AND A.wh_code = 1 --Normal Rack --(A.name not like 'HS%' OR A.name not like 'OG%' OR A.name not like 'TT%')
--				AND value = @JobId
--				GROUP BY A.name
	
--				SELECT
--				('5000') AS code , --ชั้นวางเต็มแล้ว
	
--				('CommonCellController') AS app_name ,
	
--				(SELECT CONCAT(
--					(SELECT message 
--					 FROM [APCSProDB].[mdm].[errors] 
--					 WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha'),
--					(N' โปรดตรวจสอบชั้นวาง : '),
--					@ErrorName
--				)) AS message ,
			 
--				(SELECT handling 
--				 FROM [APCSProDB].[mdm].[errors] 
--				 WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha') AS handling ,
	
--				(SELECT CASE WHEN @newName IS NULL THEN ''
--							 ELSE @newName END
--				) AS new_name ,
	
--				(SELECT CASE WHEN @newAddress IS NULL THEN ''
--							 ELSE @newAddress END
--				) AS new_address ,
	
--				--Is this LotNo IS ON Any Rack?
--				(SELECT CASE WHEN @oldName IS NULL THEN ''
--							 ELSE @oldName END
--				) AS old_name ,
	
--				(SELECT CASE WHEN @oldAddress IS NULL THEN ''
--							 ELSE @oldAddress END
--				) AS old_address
--			END
	
--			--HAVE SPACE IN THAT RACK (available)
--			ELSE
--			BEGIN
--				SELECT
--				('0') AS code ,
	
--				('CommonCellController') AS app_name ,
	
--				('') AS message ,
	
--				('') AS handling,
	
--				(SELECT CASE WHEN @newName IS NULL THEN ''
--							 ELSE @newName END
--				) AS new_name ,
	
--				(SELECT CASE WHEN @newAddress IS NULL THEN ''
--							 ELSE @newAddress END
--				) AS new_address ,
	
--				--Is this LotNo IS ON Any Rack?
--				(SELECT CASE WHEN @oldName IS NULL THEN ''
--							 ELSE @oldName END
--				) AS old_name ,
	
--				(SELECT CASE WHEN @oldAddress IS NULL THEN ''
--							 ELSE @oldAddress END
--				) AS old_address
--			END
--		END
--	END
--END
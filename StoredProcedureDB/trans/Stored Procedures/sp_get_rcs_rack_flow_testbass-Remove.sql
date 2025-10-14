-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_rcs_rack_flow_testbass-Remove]
	-- Add the parameters for the stored procedure here
	@LotNo varchar(20), @OPNoId int, @lotStatus varchar(1) = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @device_slip_id int, @NextStep int, @JobId int, @PkgId int, @DevId int, @ErrorName varchar(255)
	DECLARE @newName varchar(20), @newAddress varchar(20), @oldName varchar(20), @oldAddress varchar(20)
    -- Insert statements for procedure here

	SELECT -- Find Next Step No and Device Slip Id for find Next Job Id
	@device_slip_id =
		(SELECT device_slip_id
		 FROM [APCSProDB].[method].[device_flows] with (NOLOCK)
		 WHERE device_slip_id = (SELECT device_slip_id
								 FROM APCSProDB.trans.lots with (NOLOCK)
								 WHERE lot_no = @LotNo) 
		   AND step_no = (SELECT step_no
						  FROM APCSProDB.trans.lots with (NOLOCK)
						  WHERE lot_no = @LotNo)), 

	@NextStep =
		(SELECT next_step_no
		 FROM [APCSProDB].[method].[device_flows] with (NOLOCK)
		 WHERE device_slip_id = (SELECT device_slip_id
	 							 FROM APCSProDB.trans.lots with (NOLOCK)
	 							 WHERE lot_no = @LotNo) 
		   AND step_no = (SELECT step_no
	 					  FROM APCSProDB.trans.lots with (NOLOCK)
	 					  WHERE lot_no = @LotNo))
	SELECT --New Select cause @NextStepNo Still NULL in same Select
	@JobId = 
		(SELECT job_id
		 FROM [APCSProDB].[method].[device_flows] with (NOLOCK)
		 WHERE device_slip_id = @device_slip_id
		   AND step_no = @NextStep
		   AND is_skipped = 0),

	@PkgId =
		(SELECT pkg.id
		 FROM [APCSProDB].[trans].[lots] AS lot with (NOLOCK)
		 INNER JOIN [APCSProDB].[method].[packages] AS pkg with (NOLOCK) ON lot.act_package_id = pkg.id
		 WHERE lot_no = @LotNo),

	@DevId =
		(SELECT dev.id
		 FROM [APCSProDB].[trans].[lots] with (NOLOCK)
		 INNER JOIN APCSProDB.method.device_names AS dev with (NOLOCK) ON dev.id = act_device_name_id
		 WHERE lot_no = @LotNo)



	--IN Surpluses or lot_status = 1 (HASUU LOT)
	IF((SELECT COUNT(serial_no)
	   FROM [APCSProDB].[trans].[surpluses]
	   WHERE serial_no = @LotNo AND in_stock != 0) != 0 AND @lotStatus = 1)
	BEGIN 

		SELECT @oldName = name 
		FROM [APCSProDB].[trans].[locations] with (NOLOCK)
		WHERE id = (SELECT location_id
					FROM [APCSProDB].[trans].[surpluses] AS lot with (NOLOCK)
					JOIN [APCSProDB].[trans].[locations] AS loca with (NOLOCK) ON loca.id = lot.location_id
					WHERE lot.location_id IS NOT NULL 
					  AND lot.serial_no = @LotNo)		
	
		SELECT @oldAddress = address 
		FROM [APCSProDB].[trans].[locations] with (NOLOCK)
		WHERE id = (SELECT location_id
					FROM [APCSProDB].[trans].[surpluses] AS lot with (NOLOCK)
					JOIN [APCSProDB].[trans].[locations] AS loca with (NOLOCK) ON loca.id = lot.location_id
					WHERE lot.location_id IS NOT NULL 
					  AND lot.serial_no = @LotNo)

		-- NOT in control
		IF(not exists (SELECT COUNT(A.name) --count row that empty and correct rack
		     FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
			 INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
			 WHERE B.package_id = @PkgId AND B.device_id = @DevId AND A.wh_code = 2 --AND (substring(A.name,0,3) = 'HS' or substring(A.name,0,3) = 'OG' or substring(A.name,0,3) = 'TT')
		))
		BEGIN  
			SELECT 
			('0') AS code ,
	
			('CommonCellController') AS app_name ,
	
			(SELECT message 
			 FROM [APCSProDB].[mdm].[errors] 
			 WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha') AS message , --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
	
			(SELECT handling 
			 FROM [APCSProDB].[mdm].[errors] 
			 WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha') AS handling , --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
	
			(SELECT '') AS new_name ,
	
			(SELECT '') AS new_address ,
	
			--Is this LotNo IS ON Any Rack?
			(SELECT CASE WHEN @oldName IS NULL THEN ''
						 ELSE @oldName END
			) AS old_name ,
	
			(SELECT CASE WHEN @oldAddress IS NULL THEN ''
						 ELSE @oldAddress END
			) AS old_address		
		END
	
		--IN control
		ELSE 
		BEGIN
		

			SELECT top 1 @newName = A.name, @newAddress = A.address
			FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
			INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
				AND B.package_id = @PkgId 
				AND B.device_id = @DevId 
				AND A.wh_code = 2
				--AND (substring(A.name,0,3) = 'HS' or substring(A.name,0,3) = 'OG' or substring(A.name,0,3) = 'TT')
			LEFT JOIN (
				SELECT loca.id --LotNo NOT IN (ON Rack and wip_state = 20)
				FROM [APCSProDB].[trans].[locations] AS loca
				INNER JOIN [APCSProDB].[trans].[lots] AS lot ON loca.id = lot.location_id
					AND lot.location_id IS NOT NULL
			) as locations on A.id = locations.id
			WHERE locations.id IS NULL
			ORDER BY B.priorities, A.name, A.address

			--NO SPACE IN THAT RACK (unavailable)
			IF(@newName IS NULL AND @newAddress IS NULL)
			BEGIN	
				SELECT @ErrorName = COALESCE(@ErrorName + ', ', '') + A.name
				FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
				INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
				WHERE B.package_id = @PkgId AND B.device_id = @DevId AND A.wh_code = 2 --AND (substring(A.name,0,3) = 'HS' or substring(A.name,0,3) = 'OG' or substring(A.name,0,3) = 'TT')
				GROUP BY A.name
	
				SELECT
				('5000') AS code , --ชั้นวางเต็มแล้ว
	
				('CommonCellController') AS app_name ,
	
				(SELECT CONCAT(
					(SELECT message 
					 FROM [APCSProDB].[mdm].[errors] 
					 WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha'),
					(N' โปรดตรวจสอบชั้นวาง : '),
					@ErrorName
				)) AS message ,
			 
				(SELECT handling 
				 FROM [APCSProDB].[mdm].[errors] 
				 WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha') AS handling ,
	
				(SELECT CASE WHEN @newName IS NULL THEN ''
							 ELSE @newName END
				) AS new_name ,

				(SELECT CASE WHEN @newAddress IS NULL THEN ''
							 ELSE @newAddress END
				) AS new_address ,
	
				--Is this LotNo IS ON Any Rack?
				(SELECT CASE WHEN @oldName IS NULL THEN ''
							 ELSE @oldName END
				) AS old_name ,
	
				(SELECT CASE WHEN @oldAddress IS NULL THEN ''
							 ELSE @oldAddress END
				) AS old_address		
			END
	
			--HAVE SPACE IN THAT RACK (available)
			ELSE
			BEGIN
			
				SELECT
				('0') AS code ,
	
				('CommonCellController') AS app_name ,
	
				('') AS message ,
	
				('') AS handling,
	
				(SELECT CASE WHEN @newName IS NULL THEN ''
							 ELSE @newName END
				) AS new_name ,

				(SELECT CASE WHEN @newAddress IS NULL THEN ''
							 ELSE @newAddress END
				) AS new_address ,
	
				--Is this LotNo IS ON Any Rack?
				(SELECT CASE WHEN @oldName IS NULL THEN ''
							 ELSE @oldName END
				) AS old_name ,
	
				(SELECT CASE WHEN @oldAddress IS NULL THEN ''
							 ELSE @oldAddress END
				) AS old_address						
			END
		END
	END

	--NOT Surpluses or lot_status = 0 (MASTER LOT)
	ELSE
	BEGIN 
	
		SELECT @oldName = name 
		FROM [APCSProDB].[trans].[locations]
		WHERE id = (SELECT location_id
					FROM [APCSProDB].[trans].[lots] AS lot with (NOLOCK)
					JOIN [APCSProDB].[trans].[locations] AS loca with (NOLOCK) ON loca.id = lot.location_id
					WHERE lot.location_id IS NOT NULL 
					  AND lot.lot_no = @LotNo)
	
		SELECT @oldAddress = address 
		FROM [APCSProDB].[trans].[locations] with (NOLOCK)
		WHERE id = (SELECT location_id
						 FROM [APCSProDB].[trans].[lots] AS lot with (NOLOCK)
						 JOIN [APCSProDB].[trans].[locations] AS loca with (NOLOCK) ON loca.id = lot.location_id
						 WHERE lot.location_id IS NOT NULL 
					   AND lot.lot_no = @LotNo)




		-- NOT in control
		IF(not exists (SELECT A.name --count row that empty and correct rack
		     FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
			 INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
			 CROSS APPLY string_split(B.job_id, ',')
			 WHERE B.package_id = @PkgId AND B.device_id = @DevId AND A.wh_code = 1 --AND (substring(A.name,0,3) != 'HS' or substring(A.name,0,3) != 'OG' or substring(A.name,0,3) != 'TT')
			 AND value = @JobId
		))
		BEGIN 
			
			SELECT 
			('0') AS code ,
	
			('CommonCellController') AS app_name ,
	
			(SELECT message 
			 FROM [APCSProDB].[mdm].[errors] 
			 WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha') AS message , --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
	
			(SELECT handling 
			 FROM [APCSProDB].[mdm].[errors] 
			 WHERE code = '5001' AND app_name = 'CommonCellController' AND lang = 'Tha') AS handling , --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
	
			(SELECT '') AS new_name ,
	
			(SELECT '') AS new_address ,
	
			--Is this LotNo IS ON Any Rack?
			(SELECT CASE WHEN @oldName IS NULL THEN ''
						 ELSE @oldName END
			) AS old_name ,
	
			(SELECT CASE WHEN @oldAddress IS NULL THEN ''
						 ELSE @oldAddress END
			) AS old_address		
		END
	
		--IN control
		ELSE 
		BEGIN 
			
			
			SELECT top 1 @newName = A.name, @newAddress = A.address
			FROM [APCSProDB].[trans].[locations] AS A
			INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
				AND B.package_id = @PkgId 
				AND B.device_id = @DevId
				AND A.wh_code = 1
				--AND (substring(A.name,0,3) = 'HS' or substring(A.name,0,3) = 'OG' or substring(A.name,0,3) = 'TT')
			LEFT JOIN (
					SELECT loca.id --LotNo NOT IN (ON Rack and wip_state = 20)
					FROM [APCSProDB].[trans].[locations] AS loca
					INNER JOIN [APCSProDB].[trans].[lots] AS lot ON loca.id = lot.location_id
						AND lot.location_id IS NOT NULL
			) as locations on A.id = locations.id
			CROSS APPLY string_split(B.job_id, ',')
			WHERE locations.id IS NULL
				and value = @JobId
			ORDER BY B.priorities, A.name, A.address
			

			--NO SPACE IN THAT RACK (unavailable)
			IF(@newName IS NULL AND @newAddress IS NULL)
			BEGIN	
				SELECT @ErrorName = COALESCE(@ErrorName + ', ', '') + A.name
				FROM [APCSProDB].[trans].[locations] AS A with (NOLOCK)
				INNER JOIN [DBx].[dbo].[rcs_controls] AS B ON A.name = B.name
				CROSS APPLY string_split(B.job_id, ',')
				WHERE B.package_id = @PkgId AND B.device_id = @DevId AND A.wh_code = 1 --AND (substring(A.name,0,3) != 'HS' or substring(A.name,0,3) != 'OG' or substring(A.name,0,3) != 'TT')
				AND value = @JobId
				GROUP BY A.name
	
				SELECT
				('5000') AS code , --ชั้นวางเต็มแล้ว
	
				('CommonCellController') AS app_name ,
	
				(SELECT CONCAT(
					(SELECT message 
					 FROM [APCSProDB].[mdm].[errors] 
					 WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha'),
					(N' โปรดตรวจสอบชั้นวาง : '),
					@ErrorName
				)) AS message ,
			 
				(SELECT handling 
				 FROM [APCSProDB].[mdm].[errors] 
				 WHERE code = '5000' AND app_name = 'CommonCellController' AND lang = 'Tha') AS handling ,
	
				(SELECT CASE WHEN @newName IS NULL THEN ''
							 ELSE @newName END
				) AS new_name ,
	
				(SELECT CASE WHEN @newAddress IS NULL THEN ''
							 ELSE @newAddress END
				) AS new_address ,
	
				--Is this LotNo IS ON Any Rack?
				(SELECT CASE WHEN @oldName IS NULL THEN ''
							 ELSE @oldName END
				) AS old_name ,
	
				(SELECT CASE WHEN @oldAddress IS NULL THEN ''
							 ELSE @oldAddress END
				) AS old_address
			END
	
			--HAVE SPACE IN THAT RACK (available)
			ELSE
			BEGIN
				SELECT
				('0') AS code ,
	
				('CommonCellController') AS app_name ,
	
				('') AS message ,
	
				('') AS handling,
	
				(SELECT CASE WHEN @newName IS NULL THEN ''
							 ELSE @newName END
				) AS new_name ,
	
				(SELECT CASE WHEN @newAddress IS NULL THEN ''
							 ELSE @newAddress END
				) AS new_address ,
	
				--Is this LotNo IS ON Any Rack?
				(SELECT CASE WHEN @oldName IS NULL THEN ''
							 ELSE @oldName END
				) AS old_name ,
	
				(SELECT CASE WHEN @oldAddress IS NULL THEN ''
							 ELSE @oldAddress END
				) AS old_address
			END
		
		END



	END
END
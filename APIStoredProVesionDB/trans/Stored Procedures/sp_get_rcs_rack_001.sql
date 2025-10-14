-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_rcs_rack_001]
	-- Add the parameters for the stored procedure here
	  @lot_no				VARCHAR(20)
	, @emp_id				INT
	, @categories			INT			= 0
	, @isCurrentStepNo		BIT			= 0 --False --0 : next_flow 1: current_flow
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  
	DECLARE	  @PkgId			INT
			, @DevId			INT
			, @JobId			INT
			, @ErrorName		VARCHAR(255)
	DECLARE   @newName			VARCHAR(20)
			, @newAddress		VARCHAR(20)
			, @newAddress_id	INT				= 0
			, @oldName			VARCHAR(20)
			, @oldAddress		VARCHAR(20)
			, @oldAddress_id	INT				= 0
	DECLARE @LotId INT = (SELECT id FROM APCSProDB.trans.lots WHERE lot_no =  @lot_no)

    -- Insert statements for procedure here

	SELECT @PkgId = act_package_id
	     , @DevId = act_device_name_id
		 , @JobId = CASE WHEN @isCurrentStepNo = 1 THEN currentDevFlow.job_id 
	   											   ELSE nextDevFlow.job_id END 
	FROM APCSProDB.trans.lots AS lots
	INNER JOIN APCSProDB.method.device_flows AS currentDevFlow 
		ON currentDevFlow.device_slip_id = lots.device_slip_id 
		AND currentDevFlow.step_no		= lots.step_no
	INNER JOIN APCSProDB.method.device_flows AS nextDevFlow	   
		ON nextDevFlow.device_slip_id	= lots.device_slip_id 
		AND nextDevFlow.step_no			= currentDevFlow.next_step_no
	--Special_flow
	LEFT JOIN [APCSProDB].[trans].[special_flows] 
		ON [lots].[is_special_flow] = 1                                    
		AND [lots].[special_flow_id] = [special_flows].[id]                                                            
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
		ON [special_flows].[id] = [lot_special_flows].[special_flow_id] 
		AND [special_flows].[step_no] = [lot_special_flows].[step_no] 
	WHERE lots.id  = @LotId
	
	DECLARE	  @WHCode		INT
			, @OldRackId	INT
			, @Status		INT
			, @nowDateTime DATETIME = (SELECT GETDATE())
			, @OPNo			INT		= (SELECT @emp_id)

	--IN Surpluses or lot_status = 1 (HASUU LOT)
	IF (@categories = 1) 
	BEGIN
		SELECT @oldAddress		= [address]
			 , @oldName			= [name]
			 , @oldAddress_id	= loca.id
		FROM DBx.dbo.rcs_current_locations   AS curr with (NOLOCK)
		INNER JOIN APCSProDB.trans.locations AS loca with (NOLOCK) ON curr.location_id = loca.id
		WHERE curr.status != 3 AND loca.wh_code = 2 AND curr.lot_id = @LotID

		-- NOT in control
		IF NOT EXISTS (SELECT 1 --count row that empty and correct rack
				       FROM APCSProDB.trans.locations  AS loca with (NOLOCK)
				       INNER JOIN DBx.dbo.rcs_controls AS con  with (NOLOCK) ON loca.name = con.name
				       WHERE con.package_id = @PkgId AND con.device_id = @DevId AND loca.wh_code = 2)  
		BEGIN 

			SELECT 'FALSE'														AS Is_Pass
			     , N'Next Process has not registered the Rack'					AS Error_Message_ENG
			     , 'Process'+N' ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง'							AS Error_Message_THA --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
			     , N'Please contact SYSTEM'										AS Handling
			     , ''															AS new_name 
			     , ''															AS new_address 
				 , 0															AS new_address_id
			     , CASE WHEN @oldName IS NULL    THEN '' ELSE @oldName	  END	AS old_name --Is this LotNo IS ON Any Rack?
			     , CASE WHEN @oldAddress IS NULL THEN '' ELSE @oldAddress END	AS old_address	
				 , @oldAddress_id										AS old_address_id 
		END
	
		--IN control
		ELSE 
		BEGIN

			SELECT TOP(1) @newName = loca.[name]
					    , @newAddress = loca.[address]
						, @newAddress_id = loca.id
			FROM APCSProDB.trans.locations		     AS loca with (NOLOCK)
			INNER JOIN DBx.dbo.rcs_controls		     AS con  with (NOLOCK) ON loca.[name] = con.[name]
			LEFT  JOIN DBx.dbo.rcs_current_locations AS curr with (NOLOCK) ON loca.id	= curr.location_id
			WHERE con.package_id = @PkgId AND con.device_id = @DevId AND loca.wh_code = 2 AND (curr.status = 3 OR curr.status IS NULL)
			ORDER BY con.priorities, loca.[name], loca.[address]

			--NO SPACE IN THAT RACK (unavailable)
			IF(@newName IS NULL AND @newAddress IS NULL)
			BEGIN	
				SELECT @ErrorName = COALESCE(@ErrorName + ', ', '') + loca.name
				FROM APCSProDB.trans.locations  AS loca with (NOLOCK)
				INNER JOIN DBx.dbo.rcs_controls AS con  with (NOLOCK) ON loca.name = con.name
				WHERE con.package_id = @PkgId AND con.device_id = @DevId AND loca.wh_code = 2
				GROUP BY loca.name
	
				SELECT 'FALSE'														AS Is_Pass 
					 , N'Rack No Space Please check the Rack : '+ @ErrorName				AS Error_Message_ENG
					 , N'Rack เต็ม กรุณาตรวจสอบ Rack  : '+ @ErrorName							AS Error_Message_THA 
					 , ''															AS Handling 
					 , CASE WHEN @newName IS NULL    THEN ''  ELSE @newName    END	AS new_name
					 , CASE WHEN @newAddress IS NULL THEN ''  ELSE @newAddress END	AS new_address 
					 , @newAddress_id												AS new_address_id
					 , CASE WHEN @oldName IS NULL    THEN ''  ELSE @oldName    END	AS old_name
					 , CASE WHEN @oldAddress IS NULL THEN ''  ELSE @oldAddress END	AS old_address	
					 , @oldAddress_id												AS old_address_id
			 
			END
	
			--HAVE SPACE IN THAT RACK (available)
			ELSE
			BEGIN
				SELECT 'TRUE'														AS Is_Pass
					 , ''															AS Error_Message_ENG
					 , ''															AS Error_Message_THA --Process ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง
					 , ''															AS Handling
					 , CASE WHEN @newName IS NULL	 THEN '' ELSE @newName	  END	AS new_name 
					 , CASE WHEN @newAddress IS NULL THEN '' ELSE @newAddress END	AS new_address 
					 , @newAddress_id												AS new_address_id
					 , CASE WHEN @oldName IS NULL    THEN '' ELSE @oldName    END	AS old_name
					 , CASE WHEN @oldAddress IS NULL THEN '' ELSE @oldAddress END	AS old_address	
					 , @oldAddress_id												AS old_address_id
	
			END
		END
	END

	--NOT Surpluses or lot_status = 0 (MASTER LOT)
	ELSE
	BEGIN 
		SELECT @oldAddress		= address
			 , @oldName			= name
			 , @oldAddress_id   = loca.id
		FROM DBx.dbo.rcs_current_locations   AS curr with (NOLOCK)
		INNER JOIN APCSProDB.trans.locations AS loca with (NOLOCK) ON curr.location_id = loca.id
		WHERE curr.status != 3 AND loca.wh_code in (1,3) AND curr.lot_id = @LotID

		-- Lot have old location (2024-08-21)
		IF(@oldAddress != '' OR @oldName != '')
			BEGIN

				SELECT	  'TRUE'															AS Is_Pass 
						, N'Lot is stay on Rack'											AS Error_Message_ENG
						, 'Lot '+N'นี้ยังอยู่บน Rack'												AS Error_Message_THA
						, N'Please remove from Rack first'									AS Handling
						, CASE WHEN @oldName IS NULL THEN ''  ELSE @oldName	END				AS new_name 
						, CASE WHEN @oldAddress IS NULL THEN ''  ELSE @oldAddress END		AS new_address
						, @newAddress_id													AS new_address_id
						, CASE WHEN @oldName IS NULL THEN ''  ELSE @oldName	END				AS old_name  
						, CASE WHEN @oldAddress IS NULL THEN ''  ELSE @oldAddress	END		AS old_address	
						, @oldAddress_id													AS old_address_id
			  
			END
		ELSE
			BEGIN

			-- NOT in control
			IF NOT EXISTS (SELECT 1 
						   FROM APCSProDB.trans.locations AS loca with (NOLOCK)
						   INNER JOIN DBx.dbo.rcs_controls AS con with (NOLOCK) ON loca.name = con.name
						   CROSS APPLY string_split(con.job_id, ',')
						   WHERE con.package_id = @PkgId AND con.device_id = @DevId AND loca.wh_code = 1 AND value = @JobId)

			BEGIN 
				SELECT	  'TRUE'															AS Is_Pass 
						, N'Next Process has not registered the Rack'						AS Error_Message_ENG
						, N'Process'+N' ถัดไปยังไม่ได้ลงทะเบียนชั้นวาง'									AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ Rack control system'							AS Handling
						, ''																AS new_name 
						, ''																AS new_address
						, @newAddress_id													AS new_address_id
						, CASE WHEN @oldName IS NULL THEN '' ELSE @oldName END				AS old_name  
						, CASE WHEN @oldAddress IS NULL THEN '' ELSE @oldAddress END		AS old_address	
						, @oldAddress_id													AS old_address_id
			 
			END
	
			--IN control
			ELSE 
			BEGIN 
				SELECT TOP(1) @newName	  = loca.name
							, @newAddress = loca.address
							, @newAddress_id	= loca.id
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
	
				SELECT	  'FALSE'														AS Is_Pass 
						 , N'Please check the Rack : '+ @ErrorName						AS Error_Message_ENG
						 , N'กรุณาตรวจสอบ Rack  : '+ @ErrorName							AS Error_Message_THA 
						 , ''															AS Handling 
						 , CASE WHEN @newName IS NULL THEN '' ELSE @newName	  END		AS new_name
						 , CASE WHEN @newAddress IS NULL THEN '' ELSE @newAddress END	AS new_address
						 , @newAddress_id												AS new_address_id 
						 , CASE WHEN @oldName IS NULL THEN '' ELSE @oldName	  END		AS old_name 
						 , CASE WHEN @oldAddress IS NULL THEN ''  ELSE @oldAddress END	AS old_address
						 , @oldAddress_id												AS old_address_id
						  
				END
	
				--HAVE SPACE IN THAT RACK (available)
				ELSE
				BEGIN


				SELECT	  'TRUE'															AS Is_Pass 
						, ''																AS Error_Message_ENG
						, ''																AS Error_Message_THA
						, ''																AS Handling
						 , CASE WHEN @newName IS NULL THEN '' ELSE @newName	END				AS new_name 
						 , CASE WHEN @newAddress IS NULL THEN '' ELSE @newAddress END		AS new_address 
						 , @newAddress_id													AS new_address_id
						 , CASE WHEN @oldName IS NULL THEN '' ELSE @oldName	 END			AS old_name 
						 , CASE WHEN @oldAddress IS NULL THEN '' ELSE @oldAddress END		AS old_address
						 , @oldAddress_id													AS old_address_id
				END
			END
		END
	END
END

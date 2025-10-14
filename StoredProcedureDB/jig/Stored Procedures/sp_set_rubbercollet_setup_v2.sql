-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_rubbercollet_setup_v2]
	-- Add the parameters for the stored procedure here
	@QRCode AS VARCHAR(100),
	@MCNo AS VARCHAR(10),
	@OPNo AS Varchar(10) 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	DECLARE @STDLifeTime AS INT,
			@LifeTime AS INT,
			@Safety AS INT,
			@Accu AS INT,
			@Period AS INT 

	DECLARE @RubberNO AS VARCHAR(10),
			@X AS VARCHAR(10),
			@Y AS VARCHAR(10),
			@Status AS VARCHAR(50),
			@MCId AS INT,
			@Idx AS INT,
			@JIGIdOld AS INT,
			@JIGIdNew AS INT,
			@OPID AS INT

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
	SET @Status = (SELECT jigs.status FROM APCSProDB.trans.jigs WHERE jigs.barcode = @QRCode)

	
	SET @STDLifeTime = (SELECT APCSProDB.jig.production_counters.alarm_value / 1000
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id AND production_counters.counter_no = 1
						where barcode = @QRCode)

	SET @LifeTime = (SELECT (APCSProDB.trans.jig_conditions.value / 1000) 
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
						where barcode = @QRCode)

	--//////////////Check JIG Register
	IF NOT EXISTS(SELECT jigs.id FROM APCSProDB.trans.jigs WHERE jigs.barcode = @QRCode) 
	BEGIN
		SELECT 'FALSE' AS Is_Pass,N'This JIG ('+ @QRCode + ') Is not register !!' AS Error_Message_ENG,
		N'JIG นี้ ('+ @QRCode + N') ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
		,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
		RETURN
	END

	--//////////////Check JIG Yes/No RubberCollet
	IF (SELECT categories.name FROM APCSProDB.trans.jigs INNER JOIN 
		APCSProDB.jig.productions ON jigs.jig_production_id = productions.id INNER JOIN
		APCSProDB.jig.categories ON productions.category_id = categories.id
		WHERE jigs.barcode = @QRCode) <> 'RubberCollet' 
	BEGIN

			SELECT 'FALSE' AS Is_Pass,N'This JIG ('+ @QRCode + N') Is not rubbercollet !!' AS Error_Message_ENG,
			N'JIG นี้ ('+ @QRCode + N') ไม่ใช่ rubbercollet !!' AS Error_Message_THA
			,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
		RETURN
	END

	--//////////////Check JIG Status
	IF (@Status) <> 'To Machine' AND (@Status) <> 'On Machine' BEGIN			
			SELECT 'FALSE' AS Is_Pass,N'This JIG ('+ @QRCode + N') Is not scan out of stock !!' AS Error_Message_ENG,
			N'JIG นี้ ('+ @QRCode + N') ไม่ใช่ยังไม่ถูกสแกนออกจาก stock !!' AS Error_Message_THA
			,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
		RETURN
	END

	--//////////////Check JIG Status Onmachine and Check MC New / MC Old
	IF (@Status) = 'On Machine' BEGIN
		DECLARE @MCOld AS VARCHAR(50)
		SET @MCOld = (SELECT machines.name FROM APCSProDB.trans.jigs LEFT JOIN
            APCSProDB.trans.machine_jigs ON machine_jigs.jig_id = jigs.id LEFT JOIN 
			APCSProDB.mc.machines ON machines.id = machine_jigs.machine_id WHERE jigs.barcode = @QRCode )
		IF @MCOld <> @MCNo BEGIN

			SELECT 'FALSE' AS Is_Pass,N'This JIG ('+ @QRCode + N') Is use on another Machine !! ('+ @MCOld + ')' AS Error_Message_ENG,
			N'JIG นี้ ('+ @QRCode + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น !! ('+ @MCOld + ')'  AS Error_Message_THA
			,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
		RETURN
		END

		IF  @MCOld IS NULL BEGIN
				SELECT 'FALSE' AS Is_Pass,N'Can not found JIG on this Machine !!' AS Error_Message_ENG,
				N'ไม่พบ JIG Machine เครื่องนี้ !!' AS Error_Message_THA
				,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
			RETURN
		END
	END


	--IF @LifeTime >= @STDLifeTime  
	--BEGIN
	--	SELECT 'FALSE' AS Is_Pass, 
	--	'('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG,
	--	'('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
	-- ,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
	--	FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
	--	RETURN
	--END

	BEGIN TRANSACTION
	BEGIN TRY
	IF @Status  = 'To Machine' BEGIN
		
			--//////////Found MCId by MCNo
			IF EXISTS(SELECT TOP(1) machines.id from APCSProDB.mc.machines where machines.name = @MCNo) 
			BEGIN
				SET @MCId = (SELECT TOP(1) machines.id from APCSProDB.mc.machines where machines.name = @MCNo)
				SET @JIGIdNew = (SELECT id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)
				
				--//////////Check JIG RubberCollet OLD on MC
				IF EXISTS(SELECT TOP(1) machine_id from APCSProDB.trans.jigs
		            LEFT JOIN APCSProDB.trans.machine_jigs on machine_jigs.jig_id = jigs.id
		            LEFT JOIN APCSProDB.mc.machines on machines.id = machine_jigs.machine_id

		            INNER JOIN APCSProDB.jig.productions on productions.id = jigs.jig_production_id 
		            INNER JOIN APCSProDB.jig.categories on categories.id = productions.category_id  

                    WHERE machine_id = @MCId  AND categories.name = 'RubberCollet') 
				BEGIN
						SET @JIGIdOld = (SELECT TOP(1) jig_id from APCSProDB.trans.jigs
						LEFT JOIN APCSProDB.trans.machine_jigs on machine_jigs.jig_id = jigs.id
						LEFT JOIN APCSProDB.mc.machines on machines.id = machine_jigs.machine_id

						INNER JOIN APCSProDB.jig.productions on productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.categories on categories.id = productions.category_id  

						WHERE machine_id = @MCId  AND categories.name = 'RubberCollet')

						--//////////UPDATE JIG OLD
						UPDATE APCSProDB.trans.jigs set status = 'To Stock',[jig_state] = 3,updated_at = GETDATE(),updated_by = @OPID where id = @JIGIdOld
						INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type) 
					    values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@JIGIdOld,
					    (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIGIdOld), GETDATE(),@OPID,@OPNo,'To Stock')

						--//////////UPDATE JIG NEW
						UPDATE APCSProDB.trans.jigs set location_id = NULL,status = 'On Machine',[jig_state] = 12,updated_at = GETDATE(),updated_by = @OPID where barcode = @QRCode
						UPDATE APCSProDB.trans.machine_jigs SET jig_id = @JIGIdNew , updated_at = GETDATE(), updated_by = @OPID
							   WHERE machine_id = @MCId AND jig_id = @JIGIdOld						
				END
				ELSE BEGIN
					--//////////UPDATE JIG NEW
					SET @Idx = (SELECT COUNT(idx) FROM APCSProDB.trans.machine_jigs WHERE machine_jigs.machine_id = @MCId AND idx = 1)
					update APCSProDB.trans.jigs set location_id = NULL,status = 'On Machine',[jig_state] = 12,updated_at = GETDATE(),updated_by = @OPID where id = @JIGIdNew
					--/////////Count Check idx On This MC
					IF @Idx = 0 BEGIN 
							INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_group_id,jig_id,created_at,created_by) 
							VALUES (@MCId,1,1,@JIGIdNew,GETDATE(),@OPID)
					END
					ELSE BEGIN
							INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_group_id,jig_id,created_at,created_by) 
							VALUES (@MCId,2,1,@JIGIdNew,GETDATE(),@OPID)
					END
				END
			END
			ELSE BEGIN
				SELECT 'FALSE' AS Is_Pass,N'Machine number is invalid. !!' AS Error_Message_ENG,
					N'Machine number ไม่ถูกต้อง กรุณาตรวจสอบข้อมูล !!' AS Error_Message_THA
					,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
				RETURN
			END

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no) 
					    values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@JIGIdNew,
					    (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIGIdNew), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo)
	
		
		SELECT DISTINCT 'TRUE' AS Is_Pass,''AS Error_Message_ENG,'' AS Error_Message_THA,''AS Handling,
		smallcode AS SmallCode, productions.name AS Type_Name, collet_no AS RubberNo  
		FROM APCSProDB.trans.jigs 
			INNER JOIN APCSProDB.jig.productions ON jigs.jig_production_id = productions.id 
			INNER JOIN APCSProDB.jig.collet_recipes ON collet_recipes.production_id = productions.id
		WHERE jigs.id = @JIGIdNew

	END
	ELSE IF @Status  = 'On Machine' BEGIN
		SELECT DISTINCT 'TRUE' AS Is_Pass,''AS Error_Message_ENG,'' AS Error_Message_THA,''AS Handling,
		smallcode AS SmallCode, productions.name AS Type_Name, collet_no AS RubberNo  
		FROM APCSProDB.trans.jigs 
			INNER JOIN APCSProDB.jig.productions ON jigs.jig_production_id = productions.id 
			INNER JOIN APCSProDB.jig.collet_recipes ON collet_recipes.production_id = productions.id
		WHERE jigs.barcode = @QRCode		
		
		
	END
	COMMIT;
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass,N'Update data failed !! (JIG Rubber Service)' AS Error_Message_ENG,
				N'การอัพเดทข้อมูลผิดพลาด !! (JIG Rubber Service) ' AS Error_Message_THA
				,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
		ROLLBACK;
		RETURN
	END CATCH
	
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_tsukiage_setup]
	-- Add the parameters for the stored procedure here
	@LotNo AS VARCHAR(20),
	@QRCode AS VARCHAR(100),
	@MCNo AS VARCHAR(10),
	@MCType AS VARCHAR(20),
	@OPNo AS Varchar(10) ,
	@DataInput AS INT = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
 
	SET NOCOUNT ON;
 
	DECLARE		  @STDLifeTime		AS INT 
				, @LifeTime			AS INT 
				, @Safety			AS INT 
				, @Accu				AS INT 
				, @Period			AS INT 
				, @TsukiageNo		AS VARCHAR(10) 
				, @X				AS VARCHAR(10) 
				, @Y				AS VARCHAR(10) 
				, @Status			AS VARCHAR(50) 
				, @MCId				AS INT 
				, @Idx				AS INT 
				, @JIGIdOld			AS INT 
				, @JIGIdNew			AS INT 
				, @XYMIN			VARCHAR(10) 
				--, @LOT_ID as INT 
				--, @LOT_Process as INT 
				--, @JIG_Record_ID as INT			
				, @OPID				AS INT

	SET @JIGIdNew = (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)

	 INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history_jig]
	(	
			  [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, lot_no
			, jig_id
			, barcode
	)
	SELECT    GETDATE()
			, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'EXEC [jig].[sp_set_tsukiage_setup] @QRCode = '''  + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''',@OPNo = ''' 
				+ ISNULL(CAST(@OPNo AS nvarchar(MAX)),'') +  ''',@MCNo = ''' + ISNULL(CAST(@MCNo AS nvarchar(MAX)),'') + ''',@MCType = ''' + ISNULL(CAST(@MCType AS nvarchar(MAX)),'') + ''',@DataInput = ''' + ISNULL(CAST(@DataInput AS nvarchar(MAX)),'') + ''''
			, @LotNo
			, @JIGIdNew
			, @QRCode
	 
	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
	SET @Status = (SELECT jigs.status FROM APCSProDB.trans.jigs WHERE jigs.barcode = @QRCode)
	SET @MCType = (SELECT (CASE WHEN UPPER(@MCType) in ('AD8312','AD833','AD8312PLUS') THEN 'ASM' 
					WHEN UPPER(@MCType) in ('IDBR','IDBW','CANON-D02','CANON-D10','IDBR-P','IDBR-S','IDBW-2','IDBW-3','BESTEM-D02','BESTEM-D10R') THEN 'ROHM'
					WHEN UPPER(@MCType) in ('2009SSI','ESEC2009 SSI','SD832D') THEN 'ESECS'
					WHEN UPPER(@MCType) in ('2100HS','2100XP','ESEC2100 HS','ESEC2100 XP') THEN 'ESECP'
					ELSE @MCType END))	

  

	SET @STDLifeTime = (SELECT APCSProDB.jig.production_counters.alarm_value / 1000
						FROM APCSProDB.trans.jigs INNER JOIN
						--APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode   AND counter_name  <> 'Stock')
 
	SET @LifeTime = (SELECT (APCSProDB.trans.jig_conditions.value / 1000) + (@DataInput / 1000)
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)

	



	--//////////////Check JIG Register
	IF NOT EXISTS(SELECT jigs.id FROM APCSProDB.trans.jigs WHERE jigs.barcode = @QRCode) 
	BEGIN

		SELECT    'FALSE'											AS Is_Pass
				, N'This JIG ('+ @QRCode + ') Is not register !!'	AS Error_Message_ENG
				, N'JIG นี้ ('+ @QRCode + N') ยังไม่ถูกลงทะเบียน !!'		AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'			AS Handling
		RETURN

	END

 
	--//////////////Check JIG Yes/No Tsukiage
	IF (SELECT categories.name FROM APCSProDB.trans.jigs 
			INNER JOIN APCSProDB.jig.productions 
			ON jigs.jig_production_id = productions.id
			INNER JOIN	APCSProDB.jig.categories 
			ON productions.category_id = categories.id
			WHERE jigs.barcode = @QRCode) <> 'Tsukiage' 
	BEGIN

			SELECT   'FALSE'											AS Is_Pass
					, N'This JIG ('+ @QRCode + N') Is not Tsukiage !!'	AS Error_Message_ENG
					, N'JIG นี้ ('+ @QRCode + N') ไม่ใช่ Tsukiage !!'		AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'			AS Handling
			RETURN
	END

	--//////////////Check JIG Status
	IF @Status <> 'To Machine' AND (@Status) <> 'On Machine' 
	BEGIN			
			
			SELECT    'FALSE'													AS Is_Pass
					, N'This JIG ('+ @QRCode + N') Is not scan out of stock !!' AS Error_Message_ENG
					, N'JIG นี้ ('+ @QRCode + N') ไม่ใช่ยังไม่ถูกสแกนออกจาก stock !!'	AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'					AS Handling
		RETURN
	END

	--//////////////Check JIG Status Onmachine and Check MC New / MC Old
	IF @Status = 'On Machine' 
	BEGIN
		DECLARE @MCOld AS VARCHAR(50)
		 
		SET @MCOld = ( SELECT machines.name FROM APCSProDB.trans.jigs
					   LEFT JOIN APCSProDB.trans.machine_jigs ON machine_jigs.jig_id = jigs.id
					   LEFT JOIN APCSProDB.mc.machines ON machines.id = machine_jigs.machine_id 
					   WHERE jigs.barcode = @QRCode
					 )

		IF @MCOld IS NULL OR @MCOld <> @MCNo 
		BEGIN
				SELECT	  'FALSE'														AS Is_Pass
						, N'This JIG ('+ @QRCode + N') Is use on another Machine !!'	AS Error_Message_ENG
						, N'JIG นี้ ('+ @QRCode + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น !!'		AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'						AS Handling
			RETURN
		END
	END

	--///////////////Found Data in DENPYO_PRINT BY LotNo
	IF NOT EXISTS (SELECT RUBBER_NO From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo) 
	BEGIN
			SELECT   'FALSE'																							AS Is_Pass
					, N'This LotNo ('+ @LotNo + N') is not found in DENPYO_PRINT. Plase contract System Dept. !!'		AS Error_Message_ENG
					, N'ไม่พบข้อมูล LotNo นี้ ('+ @LotNo + N') ในตาราง DENPYO_PRINT. กรุณาติดต่อแผนก System !!'					AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'															AS Handling
			RETURN
	END
	ELSE
	BEGIN

		SET @X = (SELECT MANU_COND_CHIP_SIZE_1 From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
		SET @Y = (SELECT MANU_COND_CHIP_SIZE_2 From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
 
	END


	--IF @LifeTime  >= @STDLifeTime
	--BEGIN
	--	SELECT 'FALSE' AS Is_Pass, 
	--	'('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG,
	--	'('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
	--	,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
	--	FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
	--	RETURN
	--END

	--///////////////Found TsukiageNo By MCType
	IF @MCType IN ( 'ESECS') 
	BEGIN
		IF EXISTS (SELECT TOP 1 tsukiage_no FROM APCSProDB.jig.tsukiage_chipsize_recipes
					INNER JOIN	 APCSProDB.jig.tsukiage_chipsizes 
					ON tsukiage_chipsize_recipes.tsukiage_chipsize_id = tsukiage_chipsizes.id
					WHERE (@X BETWEEN xmin AND xmax) AND tsukiage_no like '%PIN%') 
		BEGIN
				SET @TsukiageNo = ( SELECT TOP 1 tsukiage_no FROM APCSProDB.jig.tsukiage_chipsize_recipes
								    INNER JOIN APCSProDB.jig.tsukiage_chipsizes 
									ON tsukiage_chipsize_recipes.tsukiage_chipsize_id = tsukiage_chipsizes.id
								    WHERE (IIF(@X >@Y ,@Y , @X ) BETWEEN xmin AND xmax) AND tsukiage_no like '%PIN%' 
								  )
		 
		END
		ELSE 
		BEGIN

			SELECT    'FALSE' AS Is_Pass
					, N'ChipSize is not support. Plase check Tsukiage or register Chipsize to correct !!' AS Error_Message_ENG
					, N'ขนาด ChipSize ไม่ตรงกับข้อมูลในระบบ กรุณาตรวจสอบ Tsukiage หรือ ลงทะเบียน ChipSize ให้ถูกต้อง !!' AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
			
			RETURN
		END
	END
	ELSE IF @MCType = 'ASM' 
	BEGIN
 
		IF EXISTS (SELECT TOP 1  tsukiage_no FROM APCSProDB.jig.tsukiage_chipsize_recipes INNER JOIN
							APCSProDB.jig.tsukiage_chipsizes ON tsukiage_chipsize_recipes.tsukiage_chipsize_id = tsukiage_chipsizes.id
							WHERE (@X BETWEEN xmin AND xmax) AND (@Y BETWEEN ymin AND ymax) AND tsukiage_no like '%A%') 
		BEGIN
			--MCType ASM GET TsukiageNo From tsukiage_chipsize_recipes BY X,Y
			SET @TsukiageNo = (SELECT TOP 1 tsukiage_no FROM APCSProDB.jig.tsukiage_chipsize_recipes INNER JOIN
							   APCSProDB.jig.tsukiage_chipsizes ON tsukiage_chipsize_recipes.tsukiage_chipsize_id = tsukiage_chipsizes.id
							   WHERE (@X BETWEEN xmin AND xmax) AND (@Y BETWEEN ymin AND ymax) AND tsukiage_no like '%A%')
		END
		ELSE BEGIN

			SELECT	  'FALSE' AS Is_Pass
					, N'ChipSize is not support. Plase check Tsukiager or register Chipsize to correct !!' AS Error_Message_ENG
					, N'ขนาด ChipSize ไม่ตรงกับข้อมูลในระบบ กรุณาตรวจสอบ Tsukiage หรือ ลงทะเบียน ChipSize ให้ถูกต้อง !!' AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
			RETURN

		END
	END
	ELSE 
	BEGIN
	 
		--Another MCType GET TsukiageNo From DENPYO_PRINT BY LotNo
		SET @TsukiageNo = (SELECT PIN_NO From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
	END

	--///////////Check Match Data Form JIG.tsukiage_recipes by SubtypeId,RubberNo,MachineType
	IF NOT EXISTS ( SELECT TOP 1 1 from APCSProDB.jig.tsukiage_recipes 
				    WHERE production_id = (SELECT TOP 1 jig_production_id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode )
				    AND tsukiage_no = @TsukiageNo AND machine_type = @MCType 
				  ) 
	BEGIN
 
 
			SELECT    'FALSE'			AS Is_Pass
					, N'Miss match TsukiageNo ('+ @TsukiageNo +') is not register or This Machine Type ('+ @MCType +') registration is invalid. !!'			AS Error_Message_ENG
					, N'ข้อมูล TsukiageNo ไม่ตรงกัน หรือ TsukiageNo นี้ ('+ @TsukiageNo +N') ยังไม่ได้ลงทะเบียน หรือ Machine Type นี้ ('+ @MCType +N') ลงทะเบียนไม่ถูกต้อง !!'	AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling

		RETURN
	END

	BEGIN TRANSACTION
		BEGIN TRY 

			IF @Status  = 'To Machine' 
			BEGIN
	  
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
                    WHERE machine_id = @MCId  AND categories.name = 'Tsukiage') 

				BEGIN
				 
						SET @JIGIdOld = (SELECT TOP(1) jig_id from APCSProDB.trans.jigs
										 LEFT JOIN APCSProDB.trans.machine_jigs on machine_jigs.jig_id = jigs.id
										 LEFT JOIN APCSProDB.mc.machines on machines.id = machine_jigs.machine_id
										 INNER JOIN APCSProDB.jig.productions on productions.id = jigs.jig_production_id 
										 INNER JOIN APCSProDB.jig.categories on categories.id = productions.category_id  
										 WHERE machine_id = @MCId  AND categories.name = 'Tsukiage')

						--//////////UPDATE JIG OLD
							UPDATE APCSProDB.trans.jigs 
							SET		  [status]		= 'To Stock'
									, [jig_state]	= 3
									, updated_at	= GETDATE()
									, updated_by	= @OPID 
							WHERE	id	= @JIGIdOld

							INSERT INTO APCSProDB.trans.jig_records 
							(	  [day_id]
								, [record_at]
								, [jig_id]
								, [jig_production_id]
								, [created_at]
								, [created_by]
								, [operated_by]
								, transaction_type
							) 
							VALUES
							(	  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
								, GETDATE()
								, @JIGIdOld
								, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIGIdOld)
								, GETDATE()
								, @OPID
								, @OPNo
								, 'To Stock'
							)

						--//////////UPDATE JIG NEW
							UPDATE APCSProDB.trans.jigs 
							SET		  location_id	= NULL
									, status		= 'On Machine'
									, [jig_state]	= 12
									, updated_at	= GETDATE()
									, updated_by	= @OPID 
							WHERE barcode = @QRCode

							UPDATE APCSProDB.trans.machine_jigs 
							SET		jig_id			= @JIGIdNew 
									, updated_at	= GETDATE()
									, updated_by	= @OPID
							WHERE machine_id = @MCId 
							AND jig_id = @JIGIdOld						
				END
				ELSE BEGIN
					--//////////UPDATE JIG NEW
					SET @Idx = (SELECT COUNT(idx)FROM APCSProDB.trans.machine_jigs WHERE machine_jigs.machine_id = @MCId AND idx = 1)	
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
					ELSE 
					BEGIN
						SELECT    'FALSE'										AS Is_Pass
								, N'Machine number is invalid. !!'				AS Error_Message_ENG
								, N'Machine number ไม่ถูกต้อง กรุณาตรวจสอบข้อมูล !!'	AS Error_Message_THA
								, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'		AS Handling
						RETURN
					END

					INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no) 
							    values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@JIGIdNew,
							    (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIGIdNew), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo)

					SELECT    'TRUE' AS Is_Pass
							, (SELECT smallcode FROM APCSProDB.trans.jigs WHERE id = @JIGIdNew ) AS SmallCode
							, @X AS X
							, @Y AS Y
							, @TsukiageNo AS TsukiageNo	
			COMMIT;
			RETURN 
			 
			END

 
			--Lot JIG
			--SET @LOT_ID = (SELECT id FROM APCSProDB.trans.lots where lot_no = @LOTNO)
			--SET @LOT_Process = (SELECT TOP(1) id FROM APCSProDB.trans.lot_process_records WHERE lot_id = @LOT_ID order by id desc)

			--INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no) 
			--			    values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@JIGIdNew,
			--			    (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIGIdNew), GETDATE(),@UserNo,@UserNo,'On Machine',@MCNo)

			--SET @JIG_Record_ID = (SELECT TOP(1) id FROM APCSProDB.trans.jig_records WHERE jig_id = @JIGIdNew ORDER BY id DESC)
			--INSERT INTO APCSProDB.trans.lot_jigs VALUES (@LOT_Process,@JIGIdNew,@JIG_Record_ID)

			--SELECT 'TRUE' AS Is_Pass,(SELECT smallcode FROM APCSProDB.trans.jigs WHERE id = @JIGIdNew) AS SmallCode,@X AS X,@Y AS Y,@TsukiageNo AS TsukiageNo				
			--RETURN 
		
			ELSE IF @Status  = 'On Machine' 
			BEGIN
			
					SELECT    'TRUE' AS Is_Pass
							, (SELECT smallcode FROM APCSProDB.trans.jigs WHERE id = @JIGIdNew ) AS SmallCode
							, @X AS X
							, @Y AS Y
							, @TsukiageNo AS TsukiageNo			
				COMMIT
				RETURN 
		 
			END
		
		END TRY
		BEGIN CATCH
				
				ROLLBACK;

			SELECT	  'FALSE' AS Is_Pass
					, N'Update data failed !! (JIG Tsukiage Service)' AS Error_Message_ENG
					, N'การอัพเดทข้อมูลผิดพลาด !! (JIG Tsukiage Service) ' AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
			
			RETURN
		END CATCH
	
END


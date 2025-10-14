-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_rubbercollet_setup]
	-- Add the parameters for the stored procedure here
	--@LotNo AS VARCHAR(20),
	@QRCode AS VARCHAR(100),
	@MCNo AS VARCHAR(10),
	@DataInput		AS INT		= 0
	--@MCType AS VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	DECLARE @RubberNO AS VARCHAR(10),
			--@X AS VARCHAR(10),
			--@Y AS VARCHAR(10),
			@Status AS VARCHAR(50)
	DECLARE @STDLifeTime	AS INT,
			@LifeTime		AS INT,
			@Safety			AS INT,
			@Accu			AS INT,
			@Period			AS INT 


	SET @Status = (SELECT jigs.status FROM APCSProDB.trans.jigs WHERE jigs.barcode = @QRCode)
	--SET  @MCType = (SELECT (CASE WHEN UPPER(@MCType) in('AD8312','AD8312PLUS','AD833','ROHM','2100HS','ESEC2100 HS','2100XP',
	--				'ESEC2100 XP','IDBR','IDBR-S','IDBR-P','IDBW','IDBW-2','IDBW-3','CANON-D02','BESTEM-D02','CANON-D10R','BESTEM-D10R') 
	--				THEN 'ROHM/ASM' 
	--				WHEN UPPER(@MCType) in ('2009SSI','ESEC2009 SSI') 
	--				THEN 'ESECS' 
	--				ELSE @MCType END))
	
	SET @STDLifeTime = (SELECT TOP 1 APCSProDB.jig.production_counters.alarm_value / 1000
						FROM APCSProDB.trans.jigs INNER JOIN
						--APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode )

	SET @LifeTime = (SELECT (APCSProDB.trans.jig_conditions.value / 1000) + (@DataInput / 1000)
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)
	IF (@LifeTime > @STDLifeTime  )
			BEGIN 
			SELECT    'FALSE' AS Is_Pass
					, '('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG
					, '('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
					,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
			FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
			RETURN

	END 


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
			APCSProDB.mc.machines ON machines.id = machine_jigs.machine_id WHERE jigs.barcode = @QRCode)
		IF  @MCOld <> @MCNo BEGIN
				SELECT 'FALSE' AS Is_Pass,N'This JIG ('+ @QRCode + N') Is use on another Machine ('+ @MCOld+') !!' AS Error_Message_ENG,
				N'JIG นี้ ('+ @QRCode + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น ('+ @MCOld+') !!' AS Error_Message_THA
				,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
			RETURN
		END

		--IF  @MCOld IS NULL BEGIN
		--		SELECT 'FALSE' AS Is_Pass,N'Can not found JIG on this Machine !!' AS Error_Message_ENG,
		--		N'ไม่พบ JIG Machine เครื่องนี้ !!' AS Error_Message_THA
		--		,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
		--	RETURN
		--END

	END

		SELECT 'TRUE' AS Is_Pass,(SELECT smallcode FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) AS SmallCode,
		(SELECT productions.name FROM APCSProDB.trans.jigs INNER JOIN 
		APCSProDB.jig.productions ON jigs.jig_production_id = productions.id 
		WHERE jigs.barcode = @QRCode) AS Rubber_Type
		--@X AS X,@Y AS Y,@RubberNO AS RubberNo				
	RETURN 
		
END
	--///////////////Found Data in DENPYO_PRINT BY LotNo
	--IF NOT EXISTS (SELECT RUBBER_NO From [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo) 
	--BEGIN
	--		SELECT 'FALSE' AS Is_Pass,N'This LotNo ('+ @LotNo + N') is not found in DENPYO_PRINT. Plase contract System Dept. !!' AS Error_Message_ENG,
	--		N'ไม่พบข้อมูล LotNo นี้ ('+ @LotNo + N') ในตาราง DENPYO_PRINT. กรุณาติดต่อแผนก System !!' AS Error_Message_THA
	--	RETURN
	--END
	--ELSE BEGIN
	--	SET @X = (SELECT MANU_COND_CHIP_SIZE_1 From [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
	--	SET @Y = (SELECT MANU_COND_CHIP_SIZE_2 From [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
	--END

	----///////////////Found RubberNo By MCType
	--IF @MCType = 'ESECS' BEGIN
	--	IF EXISTS (SELECT rubber_no as RubberNo FROM APCSProDB.jig.collet_chipsize_recipes INNER JOIN
	--		APCSProDB.jig.chipsizes ON chipsize_id = chipsizes.id
	--		WHERE (@X BETWEEN xmin AND xmax) AND (@Y BETWEEN ymin AND ymax)) 
	--	BEGIN
	--		--MCType ESECS GET RubberNo From collet_chipsize_recipes BY X,Y
	--		SET @RubberNO = (SELECT TOP 1 rubber_no as RubberNo FROM APCSProDB.jig.collet_chipsize_recipes INNER JOIN
	--						APCSProDB.jig.chipsizes ON chipsize_id = chipsizes.id
	--						WHERE (@X BETWEEN xmin AND xmax) AND (@Y BETWEEN ymin AND ymax))
	--	END
	--	ELSE BEGIN
	--		SELECT 'FALSE' AS Is_Pass,N'ChipSize is not support. Plase check RubberNo or register Chipsize to correct !!' AS Error_Message_ENG,
	--		N'ขนาด ChipSize ไม่ตรงกับข้อมูลในระบบ กรุณาตรวจสอบ Rubber หรือ ลงทะเบียน ChipSize ให้ถูกต้อง !!' AS Error_Message_THA
	--		RETURN
	--	END
	--END
	--ELSE BEGIN
	--	--Another MCType GET RubberNo From DENPYO_PRINT BY LotNo
	--	SET @RubberNO = (SELECT RUBBER_NO From [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
	--END

	----///////////Check Match Data Form JIG.ColletRecipe by SubtypeId,RubberNo,MachineType
	--IF NOT EXISTS (select 1 from APCSProDB.jig.collet_recipes 
	--			WHERE production_id = (SELECT jig_production_id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)
	--			AND collet_no = @RubberNO AND machine_type = @MCType ) 
	--BEGIN
	--		SELECT 'FALSE' AS Is_Pass,N'Miss match RubberNo ('+ @RubberNO +') is not register or This Machine Type ('+ @MCType +') registration is invalid. !!' AS Error_Message_ENG,
	--		N'ข้อมูล RubberNo ไม่ตรงกัน หรือ RubberNo นี้ ('+ @RubberNO +N') ยังไม่ได้ลงทะเบียน หรือ Machine Type นี้ ('+ @MCType +N') ลงทะเบียนไม่ถูกต้อง !!' AS Error_Message_THA
	--	RETURN
	--END



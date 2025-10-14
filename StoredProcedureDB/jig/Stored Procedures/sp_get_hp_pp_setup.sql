-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_hp_pp_setup]
	-- Add the parameters for the stored procedure here
		@HPPP VARCHAR(255),
		@MCNo AS VARCHAR(50),
		@OPNo AS VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @HPPP_ID AS VARCHAR(10),
			@HPPP_SM AS VARCHAR(4),
			@HP_PP AS VARCHAR(10),
			@HPPP_Status AS VARCHAR(50)

 SELECT @HPPP_ID =  jigs.id, @HPPP_SM = jigs.smallcode, @HPPP_Status = jigs.status FROM APCSProDB.trans.jigs 	  
	  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
	  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
	  WHERE (qrcodebyuser = @HPPP OR smallcode = @HPPP) AND categories.lsi_process_id = 3

	--Check HP/PP is null
	IF @HPPP_ID IS NULL BEGIN 		
	SELECT 'FALSE' AS Is_Pass,'This ('+ @HPPP +') is not register !!' AS Error_Message_ENG
		,'('+ @HPPP + N') ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
		,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
		RETURN
	END
	--//////////////Check JIG Status Onmachine and Check MC New / MC Old
	IF @HPPP_Status = 'On Machine' BEGIN
		DECLARE @MCOld AS VARCHAR(50)

		SET @MCOld = (SELECT machines.name FROM APCSProDB.trans.jigs LEFT JOIN
				APCSProDB.trans.machine_jigs ON machine_jigs.jig_id = jigs.id LEFT JOIN 
				APCSProDB.mc.machines ON machines.id = machine_jigs.machine_id WHERE jigs.id = @HPPP_ID)
		IF @MCOld <> @MCNo BEGIN
			SELECT 'FALSE' AS Is_Pass,N'This JIG ('+ @HPPP_SM + N') Is use on another Machine !!' AS Error_Message_ENG,
				N'JIG นี้ ('+ @HPPP_SM + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น !!' AS Error_Message_THA,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
			RETURN
		END
		ELSE BEGIN
			SELECT 'TRUE' AS Is_Pass ,'Success !!' AS Error_Message_ENG,N'บันทึกเรียบร้อย !!' AS Error_Message_THA, '' AS Handling
				,@HPPP_ID AS HPPP_ID,@HPPP_SM AS HPPP_SmallCode
			RETURN
		END
	END
	SET @HP_PP = (SELECT APCSProDB.jig.categories.name FROM APCSProDB.trans.jigs 
	  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
	  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
	  WHERE APCSProDB.trans.jigs.id = @HPPP_ID)

	--Check HP /////////////////////////////////////////////////////

	IF @HP_PP = 'HP' 
	BEGIN
		--Check Status HP
		IF (SELECT status FROM APCSProDB.trans.jigs WHERE id = @HPPP_ID) <> 'To Machine'
		BEGIN
			SELECT 'FALSE' AS Is_Pass,@HPPP_SM + ' is not scan out of stock !!' AS Error_Message_ENG
			,@HPPP_SM + N' นี้ยังไม่ถูกเบิกออกจาก Stock !!' AS Error_Message_THA
			,N'กรุณาเบิก หรือตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
			RETURN
		END

		--Check HP To machine and BM request machine
		IF @MCNo <> (SELECT TOP 1 mc_no FROM APCSProDB.trans.jig_records WHERE jig_records.jig_id = @HPPP_ID AND transaction_type = 'To Machine' ORDER BY id DESC)
		BEGIN
			SELECT 'FALSE' AS Is_Pass,'HP ('+ @HPPP_SM +') request MCNo not match between BM Online and JIG !!' AS Error_Message_ENG
			,N'HP ('+ @HPPP_SM +N') นี้ร้องขอ Machine ไม่ตรงกันระหว่าง BM Online และ JIG !!' AS Error_Message_THA
			,N'กรุณาตรวจสอบ MCNo ของ HP ที่เว็บ JIG System' AS Handling
			RETURN
		END

		--Check Frame Type
		--IF (SELECT FrameNo From [DBx].[dbo].[TransactionData] where LotNo = @LotNo ) <> 
		--	(SELECT DISTINCT APCSProDB.jig.productions.name FROM APCSProDB.trans.jigs 
		--	  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
		--	  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
		--	  WHERE APCSProDB.trans.jigs.id = @HPPP_ID)
		--BEGIN
		--	SELECT 'FALSE' AS Is_Pass,'Frame Type HP and Frame Type LotNo not match !!' AS Error_Message_ENG
		--	,N'Frame Type ของ HP และ Frame Type ของ LotNo นี้ไม่ตรงกัน !! กรุณาตรวจสอบ Frame Type ของ HP ที่เว็บ JIG System' AS Error_Message_THA
		--	,N'กรุณาตรวจสอบ Frame Type ของ HP ที่เว็บ JIG System' AS Handling
		--	RETURN
		--END

	-- Return Success
		SELECT 'TRUE' AS Is_Pass ,'Success !!' AS Error_Message_ENG,N'บันทึกเรียบร้อย !!' AS Error_Message_THA, '' AS Handling
		,@HPPP_ID AS HPPP_ID,@HPPP_SM AS HPPP_SmallCode
		RETURN
	END


	--Check PP /////////////////////////////////////////////////////

	ELSE IF @HP_PP = 'PP'
	BEGIN
		--Check Status PP
		IF (SELECT status FROM APCSProDB.trans.jigs WHERE id = @HPPP_ID) <> 'To Machine'
		BEGIN
			SELECT 'FALSE' AS Is_Pass,@HPPP_SM + ' is not scan out of stock !!' AS Error_Message_ENG
			,@HPPP_SM + N' นี้ยังไม่ถูกเบิกออกจาก Stock !!' AS Error_Message_THA
			,N'กรุณาเบิก หรือตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
			RETURN
		END

		--Check PP To machine and BM request machine
		IF @MCNo <> (SELECT TOP 1 mc_no FROM APCSProDB.trans.jig_records WHERE jig_records.jig_id = @HPPP_ID AND transaction_type = 'To Machine' ORDER BY id DESC)
		BEGIN
			SELECT 'FALSE' AS Is_Pass,'PP ('+ @HPPP_SM +') request MCNo not match between BM Online and JIG !!' AS Error_Message_ENG
			,N'PP ('+ @HPPP_SM +N') นี้ร้องขอ Machine ไม่ตรงกันระหว่าง BM Online และ JIG !!' AS Error_Message_THA
			,N'กรุณาตรวจสอบ MCNo ของ PP ที่เว็บ JIG System' AS Handling
			RETURN
		END

		--Check Frame Type
		--IF (SELECT FrameNo From [DBx].[dbo].[TransactionData] where LotNo = @LotNo ) <> 
		--	(SELECT DISTINCT APCSProDB.jig.productions.name FROM APCSProDB.trans.jigs 
		--	  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
		--	  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
		--	  WHERE APCSProDB.trans.jigs.id = @HPPP_ID)
		--BEGIN
		--	SELECT 'FALSE' AS Is_Pass,'Frame Type PP and Frame Type LotNo not match !!' AS Error_Message_ENG
		--	,N'Frame Type ของ PP และ Frame Type ของ LotNo นี้ไม่ตรงกัน !! กรุณาตรวจสอบ Frame Type ของ PP ที่เว็บ JIG System' AS Error_Message_THA
		--	,N'กรุณาตรวจสอบ Frame Type ของ PP ที่เว็บ JIG System' AS Handling
		--	RETURN
		--END

	-- Return Success	
		SELECT 'TRUE' AS Is_Pass ,'Success !!' AS Error_Message_ENG,N'บันทึกเรียบร้อย !!' AS Error_Message_THA, '' AS Handling
		,@HPPP_ID AS HPPP_ID,@HPPP_SM AS HPPP_SmallCode
		RETURN		
	END

	ELSE BEGIN
		SELECT 'FALSE' AS Is_Pass,'This '+@HPPP_SM+' is not HP/PP !!' AS Error_Message_ENG
		,@HPPP_SM + N' ไม่ใช่ HP/PP !!' AS Error_Message_THA
		,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
		RETURN
	END

END

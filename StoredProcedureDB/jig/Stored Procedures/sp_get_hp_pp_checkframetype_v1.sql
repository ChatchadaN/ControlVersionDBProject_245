-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_hp_pp_checkframetype_v1]
	-- Add the parameters for the stored procedure here
	@LotNo as varchar(10),
	@MCNo as varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	--Check MCNo
	IF NOT EXISTS(SELECT * FROM APCSProDB.mc.machines WHERE name = @MCNo)
	BEGIN
		SELECT 'FALSE' AS Is_Pass,'MCNo is wrong !!' AS Error_Message_ENG,N'MCNo ไม่ถูกต้อง !!' AS Error_Message_THA
		,N'กรุณากรอก MCNo ให้ถูกต้อง หรือ ตรวจสอบ MCNo' AS Handling
		RETURN
	END

	--Check HP/PP OnMachine
	IF (SELECT count(idx) FROM [APCSProDB].[trans].[machine_jigs] 
		INNER JOIN APCSProDB.mc.machines on machine_id = APCSProDB.mc.machines.id
		INNER JOIN APCSProDB.trans.jigs on jigs.id = APCSProDB.trans.machine_jigs.jig_id
		INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
		INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id 
		WHERE APCSProDB.mc.machines.name = @MCNo AND APCSProDB.jig.categories.name in ('HP','PP') AND idx <= 2 ) = 2 
	BEGIN
		--Find HP/PP OnMachine
		IF NOT EXISTS (SELECT jigs.barcode FROM APCSProDB.trans.jigs 
		  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
		  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
		  WHERE APCSProDB.trans.jigs.id = (SELECT [jig_id]
											FROM [APCSProDB].[trans].[machine_jigs]
											INNER JOIN APCSProDB.mc.machines on APCSProDB.trans.machine_jigs.machine_id = APCSProDB.mc.machines.id
											where name = @MCNo AND idx = 1) 
		  AND APCSProDB.jig.categories.name = 'HP') BEGIN
			SELECT 'FALSE' AS Is_Pass,'HP is not found on machine '+ @MCNo +'. ' AS Error_Message_ENG
			,N'ไม่พบข้อมูล HP ที่ Machine '+ @MCNo +N' นี้กรุณาร้องขอ HP ที่ BM Online !!' AS Error_Message_THA
			,N' นี้กรุณาร้องขอ HP ที่ BM Online !!' AS Handling
			RETURN
		END

		IF NOT EXISTS (SELECT jigs.barcode FROM APCSProDB.trans.jigs 
		  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
		  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
		  WHERE APCSProDB.trans.jigs.id = (SELECT [jig_id]
											FROM [APCSProDB].[trans].[machine_jigs]
											INNER JOIN APCSProDB.mc.machines on APCSProDB.trans.machine_jigs.machine_id = APCSProDB.mc.machines.id
											where name = @MCNo AND idx = 2) 
		  AND APCSProDB.jig.categories.name = 'PP') BEGIN
			SELECT 'FALSE' AS Is_Pass,'PP is not found on machine '+ @MCNo  AS Error_Message_ENG
			,N'ไม่พบข้อมูล PP ที่ Machine '+ @MCNo AS Error_Message_THA
			,N' นี้กรุณาร้องขอ PP ที่ BM Online !!' AS Handling
			RETURN
		END

		DECLARE @FrameLot AS VARCHAR(50),
				@FrameHP AS VARCHAR(50),
				@FramePP AS VARChAR(50)
		SET @FrameLot = (SELECT DISTINCT FrameNo From [DBx].[dbo].[TransactionData] where LotNo = @LotNo)
		SET @FrameHP = (SELECT DISTINCT APCSProDB.jig.productions.name FROM APCSProDB.trans.jigs 
		  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
		  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
		  WHERE APCSProDB.trans.jigs.id = (SELECT [jig_id]
											FROM [APCSProDB].[trans].[machine_jigs]
											INNER JOIN APCSProDB.mc.machines on APCSProDB.trans.machine_jigs.machine_id = APCSProDB.mc.machines.id
											where name = @MCNo AND idx = 1) AND APCSProDB.jig.categories.name = 'HP')

		SET @FramePP = (SELECT DISTINCT APCSProDB.jig.productions.name FROM APCSProDB.trans.jigs 
		  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
		  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
		  WHERE APCSProDB.trans.jigs.id = (SELECT [jig_id]
											FROM [APCSProDB].[trans].[machine_jigs]
											INNER JOIN APCSProDB.mc.machines on APCSProDB.trans.machine_jigs.machine_id = APCSProDB.mc.machines.id
											where name = @MCNo AND idx = 2) AND APCSProDB.jig.categories.name = 'PP')

		--Check Frame type
		IF NOT EXISTS(SELECT 1 FROM APCSProDB.jig.common_frametypes 
		WHERE APCSProDB.jig.common_frametypes.frametype = @FrameHP AND APCSProDB.jig.common_frametypes.common_frametype = @FrameLot)
		BEGIN
			SELECT 'FALSE' AS Is_Pass
			,'Frame Type HP and Frame Type LotNo not match !!' AS Error_Message_ENG
			,N'Frame Type ของ HP และ Frame Type ของ LotNo นี้ไม่ตรงกัน !!' AS Error_Message_THA
			,N'กรุณาตรวจสอบ Frame Type ของ HP ที่เว็บ JIG System' AS Handling
			,@FrameLot AS FrameType_Lot,@FrameHP AS FrameType_HP
			RETURN
		END

		IF NOT EXISTS(SELECT 1 FROM APCSProDB.jig.common_frametypes 
		WHERE APCSProDB.jig.common_frametypes.frametype = @FramePP AND APCSProDB.jig.common_frametypes.common_frametype = @FrameLot	)	
		BEGIN
			SELECT 'FALSE' AS Is_Pass,'Frame Type PP and Frame Type LotNo not match !!' AS Error_Message_ENG
			,N'Frame Type ของ PP และ Frame Type ของ LotNo นี้ไม่ตรงกัน !!' AS Error_Message_THA
			,N'กรุณาตรวจสอบ Frame Type ของ PP ที่เว็บ JIG System' AS Handling
			,@FrameLot AS FrameType_Lot,@FramePP AS FrameType_PP
			RETURN
		END

		--//////////////////////////////////////Check HP/PP Into Stock////////////////////////////////////
		IF EXISTS(SELECT 1 FROM (
					  SELECT jigs.[id]
						  ,jigs.[barcode]
						  ,[smallcode]
						  ,[qrcodebyuser]
						  ,[status],jigs.jig_state
						  ,jr.mc_no
					  FROM [APCSProDB].[trans].[jigs] 
					  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id  
					  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id 
					  LEFT JOIN (SELECT MAX(id) as max_id,jig_id,mc_no,record_class FROM APCSProDB.trans.jig_records  GROUP BY jig_id,mc_no,record_class) AS jr 
					  on jr.jig_id = jigs.id and jr.record_class = jigs.jig_state 
					  
					  WHERE  jigs.jig_state = 3 AND qrcodebyuser IS NOT NULL AND categories.name in ('HP','PP')
				) AS TB WHERE mc_no = @MCNo)
		BEGIN
			SELECT 'FALSE' AS Is_Pass,'This HP/PP ( '+ smallcode +' ) has not been put into Stock !!' AS Error_Message_ENG
			,N'HP/PP ( '+ smallcode +N' ) ยังไม่ถูกนำเข้า Stock !!' AS Error_Message_THA
			,N'กรุณาแจ้ง PM ให้นำ HP/PP ( '+ smallcode +N' ) เข้า Stock !!' AS Handling			
			   FROM (SELECT jigs.[id]
						  ,jigs.[barcode]
						  ,[smallcode]
						  ,[qrcodebyuser]
						  ,[status],jigs.jig_state 
						  ,jr.mc_no
					  FROM [APCSProDB].[trans].[jigs] 
					  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id  
					  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id 
					  LEFT JOIN (SELECT MAX(id) as max_id,jig_id,mc_no,record_class FROM APCSProDB.trans.jig_records  GROUP BY jig_id,mc_no,record_class) AS jr 
					  on jr.jig_id = jigs.id and jr.record_class = jigs.jig_state 
					  
					  WHERE  jigs.jig_state = 3 AND qrcodebyuser IS NOT NULL AND categories.name in ('HP','PP')
				) AS TB WHERE mc_no = @MCNo
		END

		SELECT 'TRUE' AS Is_Pass,'Frame Type match !!' AS Error_Message_ENG
			,N'Frame Type ตรงกัน !!' AS Error_Message_THA, '' AS Handling
			,@FrameLot AS FrameType
		RETURN
	END

	ELSE BEGIN
		SELECT 'FALSE' AS Is_Pass
		,'HP/PP is not found on machine '+ @MCNo +' !!' AS Error_Message_ENG
		,N'ไม่พบข้อมูล HP/PP ที่ Machine '+ @MCNo AS Error_Message_THA
		,N'กรุณาร้องขอ HP/PP ที่ BM Online !!' AS Handling
		RETURN
	END

END

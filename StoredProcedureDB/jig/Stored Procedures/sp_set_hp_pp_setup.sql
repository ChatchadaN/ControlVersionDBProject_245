-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_hp_pp_setup]
	-- Add the parameters for the stored procedure here
	@HPPP VARCHAR(255),
	@MCNo AS VARCHAR(50),
	@OPNo AS VARCHAR(6)	
	--@LOTNo AS VARCHAR(10),
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @HPPP_ID AS VARCHAR(10),
			@HPPP_SM AS VARCHAR(10),
			@HPPP_Status AS VARCHAR(50),
			@Type AS VARCHAR(10),
			@mcid AS int,
			@OldHPPP AS int,
			@OPID AS INT
	
	  SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
	
	  SELECT @HPPP_ID =  jigs.id, @HPPP_SM = jigs.smallcode, @HPPP_Status = jigs.status FROM APCSProDB.trans.jigs 	  
	  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
	  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
	  WHERE (qrcodebyuser = @HPPP OR smallcode = @HPPP) AND categories.lsi_process_id = 3

	--SET @HPPP_SM = (SELECT smallcode FROM APCSProDB.trans.jigs 
	--  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
	--  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
	--  WHERE (qrcodebyuser = @HPPP OR smallcode = @HPPP) AND categories.lsi_process_id = 3)

	--Check HP/PP is null
	IF @HPPP_ID IS NULL BEGIN 		
	SELECT 'FALSE' AS Is_Pass,'This ('+@HPPP+') is not register !!' AS Error_Message_ENG
		,'('+@HPPP + N') ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
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

	SET @Type = (SELECT APCSProDB.jig.categories.name FROM APCSProDB.trans.jigs 
	  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
	  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
	  WHERE APCSProDB.trans.jigs.id = @HPPP_ID)

	--Check Type /////////////////////////////////////////////////////
	IF @Type = 'HP' 
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

		----Check Frame Type
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

	--update HP on machine
	BEGIN TRY 

		--SET @MCNo = (SELECT TOP 1 MachineID FROM [DBx].[dbo].[BMMaintenance] WHERE  ProcessID = 'WB' AND LotNo = @LOTNo ORDER BY id DESC)
		SET @mcid = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)

		--HP idx1
		IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 1)
		BEGIN
			SET @OldHPPP = (SELECT jig_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 1)
			--update old
			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'To Stock'
				   ,[jig_state] = 3
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @OldHPPP

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
					    values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@OldHPPP,
					    (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @OldHPPP), GETDATE(),@OPID,@OPNo,'To Stock',@MCNo,3)

			--update new
			UPDATE[APCSProDB].[trans].[machine_jigs]
			   SET [jig_id] = @HPPP_ID     
				  ,[updated_at] = GETDATE()
				  ,[updated_by] = @OPID
			 WHERE machine_id = @mcid and idx = 1

			 UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
					WHERE id = @HPPP_ID

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@HPPP_ID,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @HPPP_ID), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END
		 ELSE BEGIN
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_group_id,jig_id,created_at,created_by) 
			VALUES (@mcid,1,1,@HPPP_ID,GETDATE(),@OPID)

			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @HPPP_ID

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@HPPP_ID,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @HPPP_ID), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END

			SELECT 'TRUE' AS Is_Pass ,'Success !!' AS Error_Message_ENG,N'บันทึกเรียบร้อย !!' AS Error_Message_THA, '' AS Handling
			,@HPPP_ID AS HPPP_ID,@HPPP_SM AS HPPP_SmallCode
			RETURN
		END TRY
		BEGIN CATCH 
			SELECT 'FALSE' AS Is_Pass ,'Update error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
			,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH

	END

	--Check Type /////////////////////////////////////////////////////
	ELSE IF @Type = 'PP'
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

	--update PP on machine
		BEGIN TRY 

		--SET @MCNo = (SELECT TOP 1 MachineID FROM [DBx].[dbo].[BMMaintenance] WHERE  ProcessID = 'WB' AND LotNo = @LOTNo ORDER BY id DESC)
		SET @mcid = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)

		--PP idx1
		IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 2)
		BEGIN
			SET @OldHPPP = (SELECT jig_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 2)
			--update old
			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'To Stock'
				   ,[jig_state] = 3
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @OldHPPP

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
					    values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@OldHPPP,
					    (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @OldHPPP), GETDATE(),@OPID,@OPNo,'To Stock',@MCNo,12)

			--update new
			UPDATE[APCSProDB].[trans].[machine_jigs]
			   SET [jig_id] = @HPPP_ID     
				  ,[updated_at] = GETDATE()
				  ,[updated_by] = @OPID
			 WHERE machine_id = @mcid and idx = 2

			 UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
					WHERE id = @HPPP_ID

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@HPPP_ID,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @HPPP_ID), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END
		 ELSE BEGIN
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_group_id,jig_id,created_at,created_by) 
			VALUES (@mcid,2,1,@HPPP_ID,GETDATE(),@OPID)

			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @HPPP_ID

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@HPPP_ID,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @HPPP_ID), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END

			SELECT 'TRUE' AS Is_Pass ,'Success !!' AS Error_Message_ENG,N'บันทึกเรียบร้อย !!' AS Error_Message_THA, '' AS Handling
			,@HPPP_ID AS HPPP_ID,@HPPP_SM AS HPPP_SmallCode
			RETURN
		END TRY
		BEGIN CATCH 
			SELECT 'FALSE' AS Is_Pass ,'Update error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
			,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH

	END

	ELSE BEGIN
		SELECT 'FALSE' AS Is_Pass,'This '+@HPPP_SM+' is not HP/PP !!' AS Error_Message_ENG
		,@HPPP_SM + N' ไม่ใช่ HP/PP !!' AS Error_Message_THA
		,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
		RETURN
	END

END

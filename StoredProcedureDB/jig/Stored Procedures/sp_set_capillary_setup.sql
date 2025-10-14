-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_capillary_setup]
	-- Add the parameters for the stored procedure here
	@CAPQR AS VARCHAR(100),
	@MCNo AS VARCHAR(50),
	@OPNo AS VARCHAR(6)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE 
			@CAP_ID AS VARCHAR(10),
			@CAP_SM AS VARCHAR(10),
			@MCId AS int,
			@OldCAP AS int,
			@Type AS VARCHAR(250),
			@OPID AS INT

		
		SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
		SET @MCId = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)
		SET @Type = (SELECT categories.name FROM APCSProDB.trans.jigs INNER JOIN 
					APCSProDB.jig.productions ON jig_production_id = productions.id INNER JOIN 
					APCSProDB.jig.categories ON category_id = categories.id WHERE barcode = @CAPQR)
		SET @CAP_ID = (SELECT id FROM APCSProDB.trans.jigs WHERE barcode = @CAPQR)
		SET @CAP_SM = (SELECT smallcode FROM APCSProDB.trans.jigs WHERE barcode = @CAPQR)

		IF (@Type) <> 'Capillary' BEGIN
			SELECT 'FALSE' AS Is_Pass ,'This QRCode ('+ (@CAPQR) +') is not Capillary !!' AS Error_Message_ENG,N'QRCode นี้ ('+@CAPQR+') ไม่ใช่ Capillary !!' AS Error_Message_THA
			,N' กรุณาตรวจสอบ หรือติดต่อ System' AS Handling
			
			RETURN
		END

		IF NOT EXISTS(SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo) BEGIN 
			SELECT 'FALSE' AS Is_Pass ,'Machine Number is invalid !!' AS Error_Message_ENG,N'MCno ไม่ถูกต้อง !!' AS Error_Message_THA
			,N' กรุณาตรวจสอบ หรือติดต่อ System' AS Handling

			RETURN
		END

		IF (SELECT status FROM APCSProDB.trans.jigs WHERE barcode = @CAPQR) = 'On Machine' BEGIN
			IF (SELECT machines.name FROM APCSProDB.trans.jigs LEFT JOIN
					APCSProDB.trans.machine_jigs ON machine_jigs.jig_id = jigs.id LEFT JOIN 
					APCSProDB.mc.machines ON machines.id = machine_jigs.machine_id WHERE jigs.barcode = @CAPQR) = @MCNo BEGIN

				SELECT   'TRUE' AS Is_Pass 
						,'Success !!' AS Error_Message_ENG
						,N'บันทึกเรียบร้อย !!' AS Error_Message_THA
						,'' AS Handling
						,@CAP_ID AS id,@CAP_SM AS smallCode
				RETURN
			END	
			ELSE BEGIN
				SELECT   'FALSE' AS Is_Pass 
						,'Capillary is on another Machine !!' AS Error_Message_ENG
						,N'Capillary นี้ถูกใช้อยู่ที่เครื่องจักรอื่น !!' AS Error_Message_THA
						,N' กรุณาตรวจสอบข้อมูลบนเว็บไซต์ JIG หรือติดต่อ System' AS Handling
			END
		END

		IF (SELECT status FROM APCSProDB.trans.jigs WHERE barcode = @CAPQR) <> 'To Machine' BEGIN
			SELECT  'FALSE' AS Is_Pass 
					,'Capillary is in stock !!' AS Error_Message_ENG
					,N'Capillary นี้อยู่ใน Stock !!' AS Error_Message_THA
					,N' กรุณาสแกนออกจาก Stock หรือติดต่อ System' AS Handling

			RETURN
		END

	BEGIN TRY 
	
		IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 3)
		BEGIN
			SET @OldCAP = (SELECT jig_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 3)
			--update old
			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'To Stock'
				   ,[jig_state] = 3
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @OldCAP

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
					    values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@OldCAP,
					    (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @OldCAP), GETDATE(),@OPID,@OPNo,'To Stock',@MCNo,3)

			--update new
			UPDATE[APCSProDB].[trans].[machine_jigs]
			   SET [jig_id] = @CAP_ID     
				  ,[updated_at] = GETDATE()
				  ,[updated_by] = @OPID
			 WHERE machine_id = @MCId and idx = 3

			 UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
					WHERE id = @CAP_ID

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@CAP_ID,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @CAP_ID), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)

			SELECT   'TRUE' AS Is_Pass 
					, 'Success !!' AS Error_Message_ENG
					, N'บันทึกเรียบร้อย !!' AS Error_Message_THA
					, '' AS Handling
					, @CAP_ID AS id
					, @CAP_SM AS smallCode
			RETURN			
		 END
		 ELSE BEGIN
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_group_id,jig_id,created_at,created_by) 
			VALUES (@MCId,3,1,@CAP_ID,GETDATE(),@OPID)

			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @CAP_ID

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@CAP_ID,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @CAP_ID), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END

			SELECT  'TRUE' AS Is_Pass 
					,'Success !!' AS Error_Message_ENG
					,N'บันทึกเรียบร้อย !!' AS Error_Message_THA
					, '' AS Handling
					,@CAP_ID AS id
					,@CAP_SM AS smallCode
			RETURN
	END TRY
	BEGIN CATCH 
		SELECT 'FALSE' AS Is_Pass ,'Update error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
		,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH
END

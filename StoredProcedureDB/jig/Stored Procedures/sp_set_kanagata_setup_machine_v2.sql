-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_kanagata_setup_machine_v2] 
	-- Add the parameters for the stored procedure here
		@MCNo as varchar(50),		
		@UserID as varchar(50),
		@KanagataName as varchar(50) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @JIG_ID as varchar(50)
	,@MC_ID as INT
	,@Status as varchar(50)

	SET @JIG_ID = (SELECT jigs.id FROM APCSProDB.trans.jigs INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
				  INNER JOIN APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id WHERE qrcodebyuser = @KanagataName AND categories.name = 'Kanagata Base')
	SET @MC_ID = (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo)

	SET @Status = (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID)

	DECLARE @MCOld AS VARCHAR(50)

	SET @MCOld = (SELECT machines.name FROM APCSProDB.trans.jigs LEFT JOIN
            APCSProDB.trans.machine_jigs ON machine_jigs.jig_id = jigs.id LEFT JOIN 
			APCSProDB.mc.machines ON machines.id = machine_jigs.machine_id WHERE jigs.qrcodebyuser = @KanagataName)


		--Check Status On Machine
	IF @Status = 'On Machine' AND @MCNo = @MCOld BEGIN
	--/////////////// RETURN DATA
						  SELECT 'TRUE' AS Is_Pass,jigs.id,@KanagataName AS Kanagata_Name,jigs.status,productions.name AS subtype FROM APCSProDB.trans.jigs 
						  INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
						  INNER JOIN APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id 
						  WHERE qrcodebyuser = @KanagataName AND categories.name = 'Kanagata Base'
		RETURN
	END

	IF @Status = 'On Machine' AND @MCNo <> @MCOld BEGIN
			SELECT 'FALSE' AS Is_Pass,N'This JIG ('+ @KanagataName + N') Is use on another Machine ('+@MCOld+') !!' AS Error_Message_ENG,
				N'JIG นี้ ('+ @KanagataName + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น ('+@MCOld+') !!' AS Error_Message_THA
				,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
		RETURN
	END

	BEGIN TRY
		IF @Status = 'To Machine' BEGIN
			IF SUBSTRING(@MCNo,1,2) <> 'MP' BEGIN
				IF EXISTS (SELECT machine_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID and idx = 1) BEGIN
					DECLARE @JIG_OLD as INT
					SET @JIG_OLD =	(SELECT jig_id as Detail FROM APCSProDB.trans.machine_jigs where machine_id = @MC_ID and idx = 1 )
					IF @JIG_ID <> @JIG_OLD BEGIN
								--/////////Check JIG On Machine Old //OR// JIG NEW
						IF NOT EXISTS( SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE jig_id = @JIG_ID AND machine_id = @MC_ID) BEGIN
							--//////////UPDATE JIG OLD
							UPDATE APCSProDB.trans.jigs set status = 'To Machine',[jig_state] = 11,updated_at = GETDATE(),updated_by = @UserID where id = @JIG_OLD OR root_jig_id = @JIG_OLD

							--//////////UPDATE JIG NEW
							UPDATE APCSProDB.trans.jigs set location_id = NULL,status = 'On Machine',[jig_state] = 12,updated_at = GETDATE(),updated_by = @UserID where id = @JIG_ID OR root_jig_id = @JIG_ID
							UPDATE APCSProDB.trans.machine_jigs SET  jig_id = @JIG_ID,updated_at = GETDATE(),updated_by = @UserID WHERE machine_id = @MC_ID

							--//////////Insert JIG Record On Machine
							INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,mc_no,record_class) 
										 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_ID,
										 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID),NULL, GETDATE(), @UserID, @UserID,'On Machine',@MCNo,12)

							--//////////Insert JIG Record Out Machine
							INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,record_class) 
										 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_OLD,
										 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_OLD),NULL, GETDATE(), @UserID, @UserID,'To Machine',11)
						END
					END
				END
				ELSE  BEGIN
					--//////////UPDATE JIG NEW
					UPDATE APCSProDB.trans.jigs set location_id = NULL,status = 'On Machine',[jig_state] = 12,updated_at = GETDATE(),updated_by = @UserID where id = @JIG_ID OR root_jig_id = @JIG_ID
					INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_id,created_at,created_by) VALUES (@MC_ID,1,@JIG_ID,GETDATE(),@UserID)

					--//////////Insert JIG Record On Machine
					INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,mc_no,record_class) 
								 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_ID,
								 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID),NULL, GETDATE(), @UserID, @UserID,'On Machine',@MCNo,12)
				END
			END
			ELSE BEGIN
			--/////////////////// Mold Setup Kanagata On machine
				DECLARE @idx AS INT = 1

				WHILE @idx <= 4 BEGIN
					IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID AND idx = @idx) BEGIN
						--//////////UPDATE JIG NEW
						UPDATE APCSProDB.trans.jigs set location_id = NULL,status = 'On Machine',[jig_state] = 12,updated_at = GETDATE(),updated_by = @UserID where id = @JIG_ID
						INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_id,created_at,created_by) VALUES (@MC_ID,@idx,@JIG_ID,GETDATE(),@UserID)

						--//////////Insert JIG Record On Machine
						INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,mc_no,record_class) 
									 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_ID,
									 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID),NULL, GETDATE(), @UserID, @UserID,'On Machine',@MCNo,12)

						--/////////////// RETURN DATA
						  SELECT 'TRUE' AS Is_Pass,jigs.id,@KanagataName AS Kanagata_Name,jigs.status,productions.name AS subtype FROM APCSProDB.trans.jigs 
						  INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
						  INNER JOIN APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id 
						  WHERE qrcodebyuser = @KanagataName AND categories.name = 'Kanagata Base'
						RETURN
					END

					SET	@idx = @idx + 1
				END

				IF NOT EXISTS(SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE jig_id = @JIG_ID) BEGIN
					SELECT 'FALSE' AS Is_Pass,'Update Failed. Can not update Kanagata to machine !!' AS Error_Message_ENG
						,N'อัพเดทผิดพลาด Kanagata ยังไม่ถูกนำเข้าในเครื่องจักร !!' AS Error_Message_THA
						,N'กรุณาเบิก หรือตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
					RETURN
				END
			--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
			END
		END
		ELSE BEGIN
			SELECT 'FALSE' AS Is_Pass,@KanagataName + ' is not scan out of stock. !!' AS Error_Message_ENG
					,@KanagataName + N' นี้ยังไม่ถูกเบิกออกจาก Stock. !!' AS Error_Message_THA
					,N'กรุณาเบิก หรือตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
					RETURN
		END

		--///////////////Return Data
		SELECT 'TRUE' AS Is_Pass,jigs.id,@KanagataName AS Kanagata_Name,jigs.status,productions.name AS subtype FROM APCSProDB.trans.jigs 
				  INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
				  INNER JOIN APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id 
				  WHERE qrcodebyuser = @KanagataName AND categories.name = 'Kanagata Base'
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass,'Setup Error. !!' AS Error_Message_ENG
					,N'การติดตั้ง Kanagata ผิดพลาด !!' AS Error_Message_THA
					,N'กรุณาติดต่อ System' AS Handling
	END CATCH
END
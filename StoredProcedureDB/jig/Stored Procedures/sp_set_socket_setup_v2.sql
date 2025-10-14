-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_socket_setup_v2]
	-- Add the parameters for the stored procedure here
	@QRCodeIn AS VARCHAR(15),
	@QRCodeOut AS VARCHAR(15) = NULL,
	@MCNo AS VARCHAR(50),
	@OPNo AS VARCHAR(6) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		DECLARE @JIG_ID_IN AS INT,
		@JIG_ID_OUT AS INT,
		@MC_ID AS INT ,
		@Status_JIG_IN AS varchar(50),
		@Status_JIG_OUT AS varchar(50),
		@STDLifeTime AS INT,
		@LifeTime AS INT,
		@Safety AS INT,
		@Accu AS INT,
		@OPID AS INT

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

	SET @MC_ID = (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo)

	SET @JIG_ID_IN = (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn)
	SET @Status_JIG_IN = (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID_IN)
	
	SET @JIG_ID_OUT = (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeOut)	
	SET @Status_JIG_OUT = (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID_OUT)
	
	--/////////////////////Check Socket Regist
	IF NOT EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn) BEGIN
		SELECT 'FALSE' AS Is_Pass,'This socket is not registered !!' AS Error_Message_ENG
		,N'Socket นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
		RETURN
	END

	--//////////////////// CHECK MACHINE NUMBER
	IF NOT EXISTS (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo) BEGIN
		SELECT 'FALSE' AS Is_Pass,'Machine Number is invalid !!' AS Error_Message_ENG
		,N'หมายเลขเครื่องจักรไม่ถูกต้อง !!' AS Error_Message_THA
		RETURN
	END

	IF @Status_JIG_IN = 'On Machine' BEGIN
		SELECT 'FALSE' AS Is_Pass,'Socket status is use on machine !!' AS Error_Message_ENG
			,N'Socket นี้อยู่สถานะถูกใช้อยู่ในเครื่องจักร !!' AS Error_Message_THA
		RETURN
	END

	--//////////////////// CHECK SOCKET SAME
	IF @JIG_ID_OUT = @JIG_ID_IN BEGIN
		SELECT 'FALSE' AS Is_Pass,'Socket-IN and Socket-OUT are the same !!' AS Error_Message_ENG
		,N'Socket ที่นำเข้า และ Socket ที่นำออกซ้ำกัน !!' AS Error_Message_THA
		RETURN
	END

	--////////////////////Check LifeTime
	SET @STDLifeTime = (SELECT APCSProDB.jig.productions.expiration_value / 1000
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCodeIn)

	SET @LifeTime = (SELECT (APCSProDB.trans.jig_conditions.value / 1000)
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where barcode = @QRCodeIn)

	SET @Accu = (SELECT (APCSProDB.trans.jig_conditions.accumulate_lifetime / 1000)
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where barcode = @QRCodeIn)

	SET @Safety = (SELECT (APCSProDB.jig.production_counters.warn_value / 1000)
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCodeIn)
	
	IF (@LifeTime + @Accu) >= (@STDLifeTime + (@STDLifeTime - @Safety)) BEGIN
		SELECT 'FALSE' AS Is_Pass, 
		'('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG,
		'('+(smallcode)+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA
		FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn

		RETURN
	END

		
	--//////////////// SOCKET IN
	IF @Status_JIG_IN = 'To Machine' BEGIN
		BEGIN TRY 
		--//////////// SOCKET NULL
		IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID AND idx between 2 and 17) BEGIN
			--//////////UPDATE JIG NEW
			UPDATE APCSProDB.trans.jigs set location_id = NULL,status = 'On Machine',[jig_state] = 12,updated_at = GETDATE(),updated_by = @OPID where id = @JIG_ID_IN
			INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_id,created_at,created_by) VALUES (@MC_ID,2,@JIG_ID_IN,GETDATE(),@OPID)

			--//////////Insert JIG Record On Machine
			INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,mc_no,record_class) 
						 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_ID_IN,
						 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID_IN),NULL, GETDATE(), @OPID, @OPNo,'On Machine',@MCNo,12)			
		END

		--////////////SOCKET OUT - IN
		ELSE IF EXISTS(SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeOut) BEGIN
			--/////////////////// SOCKET OUT
			IF  @Status_JIG_OUT <> 'On Machine' BEGIN
				SELECT 'FALSE' AS Is_Pass,'Socket ('+ (smallcode) + ') is not On Machine.' AS Error_Message_ENG
				,N'Socket ('+ (smallcode ) + N') ไม่ได้อยู่ในเครื่องจักร !!' AS Error_Message_THA
				FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn

				RETURN
			END
			ELSE IF @Status_JIG_OUT = 'On Machine' BEGIN				
				--//////////UPDATE JIG NEW
				UPDATE APCSProDB.trans.jigs SET location_id = NULL,status = 'On Machine',[jig_state] = 12,updated_at = GETDATE(),updated_by = @OPID where id = @JIG_ID_IN
				UPDATE APCSProDB.trans.machine_jigs SET jig_id = @JIG_ID_IN,updated_at = GETDATE(),updated_by = @OPID WHERE machine_id = @MC_ID AND jig_id = @JIG_ID_OUT

				--//////////Insert JIG Record On Machine
				INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,mc_no,record_class) 
							 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_ID_IN,
							 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID_IN),NULL, GETDATE(), @OPID, @OPNo,'On Machine',@MCNo,12)

				--//////////UPDATE JIG OLD
				UPDATE APCSProDB.trans.jigs set location_id = NULL,status = 'To Machine',[jig_state] = 11,updated_at = GETDATE(),updated_by = @OPID where id = @JIG_ID_OUT

				INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,mc_no,record_class) 
								 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_ID_OUT,
								 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID_OUT),NULL, GETDATE(), @OPID, @OPNo,'To Machine',NULL,11)			
			END
		END

		--///////////SOCKET NEW IDX
		ELSE BEGIN
			DECLARE @idx AS INT = 2

			WHILE @idx <= 17 BEGIN
				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID AND idx = @idx) BEGIN
					--//////////UPDATE JIG NEW
					UPDATE APCSProDB.trans.jigs set location_id = NULL,status = 'On Machine',[jig_state] = 12,updated_at = GETDATE(),updated_by = @OPID where id = @JIG_ID_IN
					INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_id,created_at,created_by) VALUES (@MC_ID,@idx,@JIG_ID_IN,GETDATE(),@OPID)

					--//////////Insert JIG Record On Machine
					INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,mc_no,record_class) 
								 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_ID_IN,
								 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID_IN),NULL, GETDATE(), @OPID, @OPNo,'On Machine',@MCNo,12)

					--/////////////// RETURN DATA
					SELECT 'TRUE' AS Is_Pass,@QRCodeIn AS QRCode,
						smallcode  AS Smallcode,
						p.name  AS SocketType,
						CONVERT(int,((jc.value + jc.accumulate_lifetime) / 1000)) AS Life_Time,
						CONVERT(int,(p.expiration_value / 1000)) AS STD_Life_Time,
						CONVERT(int,(jc.accumulate_lifetime / 1000)) AS Acc,
						CONVERT(int,(p.expiration_value - pc.warn_value) / 1000) AS Safety,
						j.id AS jig_id
		
					FROM APCSProDB.trans.jigs j 
					INNER JOIN APCSProDB.jig.productions p ON jig_production_id = p.id 
					INNER JOIN [APCSProDB].[jig].[production_counters] pc ON pc.production_id = p.id 
					INNER JOIN APCSProDB.trans.jig_conditions jc ON jc.id = j.id
					WHERE barcode = @QRCodeIn
					RETURN
				END

				SET	@idx = @idx + 1
			END
		END

		IF NOT EXISTS(SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE jig_id = @JIG_ID_IN) BEGIN
			SELECT 'FALSE' AS Is_Pass,'Update Failed. Can not update Socket to machine !!' AS Error_Message_ENG
				,N'อัพเดทผิดพลาด Socket ยังไม่ถูกนำเข้าในเครื่องจักร !!' AS Error_Message_THA
			RETURN
		END
		
		--/////////////// RETURN DATA
					SELECT 'TRUE' AS Is_Pass,@QRCodeIn AS QRCode,
						smallcode  AS Smallcode,
						p.name  AS SocketType,
						CONVERT(int,((jc.value + jc.accumulate_lifetime) / 1000)) AS Life_Time,
						CONVERT(int,(p.expiration_value / 1000)) AS STD_Life_Time,
						CONVERT(int,(jc.accumulate_lifetime / 1000)) AS Acc,
						CONVERT(int,(p.expiration_value - pc.warn_value) / 1000) AS Safety,
						j.id AS jig_id
		
					FROM APCSProDB.trans.jigs j 
					INNER JOIN APCSProDB.jig.productions p ON jig_production_id = p.id 
					INNER JOIN [APCSProDB].[jig].[production_counters] pc ON pc.production_id = p.id 
					INNER JOIN APCSProDB.trans.jig_conditions jc ON jc.id = j.id
					WHERE barcode = @QRCodeIn
		
		END TRY
		BEGIN CATCH
			SELECT 'FALSE' AS Is_Pass,'Update Failed !!' AS Error_Message_ENG
			,N'การติดตั้ง Socket ผิดพลาด !!' AS Error_Message_THA
		END CATCH

	END
	ELSE BEGIN
		SELECT 'FALSE' AS Is_Pass,'Socket ('+ (smallcode ) + ') status is not scan out of stock.' AS Error_Message_ENG
		,'Socket ('+ (smallcode) + N') ยังไม่ถูกสแกนออกจาก Stock !!' AS Error_Message_THA
		FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn
		RETURN
	END
END

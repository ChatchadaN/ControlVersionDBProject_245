------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Author Name              : Sadanun  B.
-- Written Date             : 2022/01/07
-- Procedure Name 	 		: jig.sp_set_jig_setup
-- Filename					: jig.sp_set_jig_setup.sql
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.mc.machines
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_set_arc_setup]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
	@QRCode AS VARCHAR(100),
	@MCNo AS VARCHAR(50),
	@OPNo AS VARCHAR(6) 
)
AS
BEGIN
	-- SET NOCOUNT ON ADDED TO PREVENT EXTRA RESULT SETS FROM
	-- INTERFERING WITH SELECT STATEMENTS.
	SET NOCOUNT ON;

    -- INSERT STATEMENTS FOR PROCEDURE HERE
		DECLARE @JIG_ID  AS INT,
		@MC_ID AS INT ,
		@Status_JIG  AS varchar(50),
		@STDLifeTime AS INT,
		@LifeTime AS INT,
		@Safety AS INT,
		@Accu AS INT,
		@OPID AS INT

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

	SET @MC_ID = (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo)

	SET @JIG_ID = (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)
	SET @Status_JIG = (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID)
	
 
	-- CHECK SOCKET REGIST
	IF NOT EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) BEGIN
		SELECT 'FALSE' AS Is_Pass,'This socket is not registered !!' AS Error_Message_ENG
		,N'Socket นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
		RETURN
	END

	-- CHECK MACHINE NUMBER
	IF NOT EXISTS (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo) BEGIN
		SELECT 'FALSE' AS Is_Pass,'Machine Number is invalid !!' AS Error_Message_ENG
		,N'หมายเลขเครื่องจักรไม่ถูกต้อง !!' AS Error_Message_THA
		RETURN
	END

	IF @Status_JIG = 'On Machine' BEGIN
		SELECT 'FALSE' AS Is_Pass,'Socket status is use on machine !!' AS Error_Message_ENG
			,N'Socket นี้อยู่สถานะถูกใช้อยู่ในเครื่องจักร !!' AS Error_Message_THA
		RETURN
	END
 
	--  SOCKET IN
	IF @Status_JIG  = 'To Machine' BEGIN
		BEGIN TRY 
		-- SOCKET NULL
		IF NOT EXISTS (SELECT 'xxx' FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID ) BEGIN
			
			--UPDATE JIG STATUS
			UPDATE APCSProDB.trans.jigs 
			set location_id = NULL
			,status = 'On Machine'
			,[jig_state] = 12
			,updated_at = GETDATE()
			,updated_by = @OPID 
			where id = @JIG_ID

			INSERT INTO APCSProDB.trans.machine_jigs 
			(	machine_id
				,idx
				,jig_id
				,jig_group_id
				,created_at
				,created_by
			) 
			VALUES 
			(
				@MC_ID
				,1
				,@JIG_ID
				,1
				,GETDATE()
				,@OPID
			)

			-- INSERT JIG Record On Machine
			INSERT INTO APCSProDB.trans.jig_records 
			(
				day_id
				,record_at
				,jig_id
				,jig_production_id
				,location_id
				,created_at
				,created_by
				,operated_by
				,transaction_type
				,mc_no
				,record_class
			) 
			VALUES
			(
				(SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
				,GETDATE()
				,@JIG_ID
				,(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID)
				,NULL
				, GETDATE()
				, @OPID
				, @OPNo
				,'On Machine'
				,@MCNo
				,12
			)			
		END


		IF NOT EXISTS(SELECT 'xxx' FROM APCSProDB.trans.machine_jigs WHERE jig_id = @JIG_ID) BEGIN
			SELECT 'FALSE' AS Is_Pass,'Update Failed. Can not update Socket to machine !!' AS Error_Message_ENG
				,N'อัพเดทผิดพลาด Socket ยังไม่ถูกนำเข้าในเครื่องจักร !!' AS Error_Message_THA
			RETURN
		END
		
		--  RETURN DATA
		SELECT 'TRUE' AS Is_Pass , @QRCode AS QRCode,
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
		WHERE barcode = @QRCode
		
		END TRY
		BEGIN CATCH
			SELECT 'FALSE' AS Is_Pass,'Update Failed !!' AS Error_Message_ENG
			,N'การติดตั้ง Socket ผิดพลาด !!' AS Error_Message_THA
		END CATCH

	END
	ELSE BEGIN
		SELECT 'FALSE' AS Is_Pass,'Socket ('+ (smallcode ) + ') status is not scan out of stock.' AS Error_Message_ENG
		,'Socket ('+ (smallcode) + N') ยังไม่ถูกสแกนออกจาก Stock !!' AS Error_Message_THA
		FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
		RETURN
	END
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_blade_setup]
	 
	@BLADE VARCHAR(255),
	@MCNo AS VARCHAR(50),
	@OPNo AS VARCHAR(6)	
	--@LOTNo AS VARCHAR(10),
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	 	DECLARE   @JIG_ID			AS VARCHAR(10)
				, @SMALLCODE		AS VARCHAR(4)
				, @STATUS			AS VARCHAR(50)
				, @Type				AS VARCHAR(10)
				, @mcid				AS int
				, @Old_blade		AS int
				, @OPID				AS INT
				, @Production_id	AS INT
			-------------------------------------------
			--, @BLADE			VARCHAR(255)		= 'WH2211128040XGXAA'
			--, @MCNo				AS VARCHAR(50)		= 'DC-S-01'
			--, @OPNo				AS VARCHAR(6)		= '010452'


	
		SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
	
		SELECT	  @JIG_ID			= jigs.id
				, @SMALLCODE		= jigs.smallcode
				, @STATUS			= jigs.status 
				, @Production_id	= jig_production_id
		FROM APCSProDB.trans.jigs 	  
		INNER JOIN APCSProDB.jig.productions 
		ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
		INNER JOIN APCSProDB.jig.categories 
		ON APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
		WHERE (qrcodebyuser = @BLADE OR barcode = @BLADE) 
		AND categories.short_name = 'Dicer Blade'

 
		--CHECK BLADE IS NULL
		IF @JIG_ID IS NULL BEGIN 	
		
			SELECT	  'FALSE'										AS Is_Pass
					, 'This ('+@BLADE+') is not register !!'		AS Error_Message_ENG
					, '('+@BLADE + N') ยังไม่ถูกลงทะเบียน !!'				AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'		AS Handling
			RETURN
		END

		--CHECK JIG STATUS ONMACHINE AND CHECK MC NEW / MC OLD
		IF @STATUS = 'On Machine' 
		BEGIN
			DECLARE @MC_Old AS VARCHAR(50)

			SET @MC_Old = (	SELECT machines.name 
							FROM APCSProDB.trans.jigs 
							LEFT JOIN APCSProDB.trans.machine_jigs 
							ON machine_jigs.jig_id = jigs.id 
							LEFT JOIN APCSProDB.mc.machines 
							ON machines.id	= machine_jigs.machine_id 
							WHERE jigs.id	= @JIG_ID
						  )

			IF @MC_Old <> @MCNo 
			BEGIN

				SELECT	  'FALSE'														AS Is_Pass
						, N'This JIG ('+ @SMALLCODE + N') Is use on another Machine !!' AS Error_Message_ENG
						, N'JIG นี้ ('+ @SMALLCODE + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น !!'		AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'						AS Handling
				RETURN

			END
			ELSE 
			BEGIN

				SELECT	  'TRUE'				AS Is_Pass 
						, 'Success !!'			AS Error_Message_ENG
						, N'บันทึกเรียบร้อย !!'		AS Error_Message_THA
						, ''					AS Handling
						, @JIG_ID				AS JIG_ID
						, @SMALLCODE			AS SMALLCODE
				RETURN
			END
		END

		--CHECK STATUS BLADE
		IF (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID) <> 'To Machine'
		BEGIN
			SELECT	  'FALSE' AS Is_Pass
					, @SMALLCODE + ' is not scan out of stock !!'	AS Error_Message_ENG
					, @SMALLCODE + N' นี้ยังไม่ถูกเบิกออกจาก Stock !!'		AS Error_Message_THA
					, N'กรุณาเบิก หรือตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
			RETURN
		END

		BEGIN TRY 

		SET @mcid = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)

		IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 1)
		BEGIN
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs 
			(		  machine_id
					, idx
					, jig_group_id
					, jig_id
					, created_at
					, created_by
			) 
			VALUES 
			(		  @mcid
					, 1
					, 1
					, @JIG_ID
					, GETDATE()
					, @OPID
			)

			UPDATE	  [APCSProDB].[trans].[jigs]
			SET		  [status]		= 'On Machine'
					, [jig_state]	= 12
					, [updated_at]	= GETDATE()
					, [updated_by]	= @OPID
			WHERE	  id			= @JIG_ID

			INSERT INTO APCSProDB.trans.jig_records 
			(		  [day_id]
					, [record_at]
					, [jig_id]
					, [jig_production_id]
					, [created_at]
					, [created_by]
					, [operated_by]
					, transaction_type
					, mc_no
					, record_class
			) 
			VALUES
			(
					  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
					, GETDATE()
					, @JIG_ID
					, @Production_id
					, GETDATE()
					, @OPID
					, @OPNo
					, 'On Machine'
					, @MCNo
					, 12
			)

			SELECT	  'TRUE'			AS Is_Pass 
					, 'Success !!'		AS Error_Message_ENG
					, N'บันทึกเรียบร้อย !!'	AS Error_Message_THA
					, ''				AS Handling
					, @JIG_ID			AS JIG_ID
					, @SMALLCODE		AS SMALLCODE
					, @BLADE			AS BLADE
			RETURN

		END

		IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 2)
		BEGIN
		
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs 
			(		  machine_id
					, idx
					, jig_group_id
					, jig_id
					, created_at
					, created_by
			) 
			VALUES 
			(		  @mcid
					, 2
					, 1
					, @JIG_ID
					, GETDATE()
					, @OPID
			)

			UPDATE	  [APCSProDB].[trans].[jigs]
			SET		  [status]		= 'On Machine'
					, [jig_state]	= 12
					, [updated_at]	= GETDATE()
					, [updated_by]	= @OPID
			WHERE id = @JIG_ID

			INSERT INTO APCSProDB.trans.jig_records 
			(		  [day_id]
					, [record_at]
					, [jig_id]
					, [jig_production_id]
					, [created_at]
					, [created_by]
					, [operated_by]
					, transaction_type
					, mc_no
					, record_class
			) 
			values
			(		  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
					, GETDATE()
					, @JIG_ID
					, @Production_id
					, GETDATE()
					, @OPID
					, @OPNo
					, 'On Machine'
					, @MCNo
					, 12
			)

			SELECT	  'TRUE'			AS Is_Pass 
					, 'Success !!'		AS Error_Message_ENG
					, N'บันทึกเรียบร้อย !!'	AS Error_Message_THA
					, ''				AS Handling
					, @JIG_ID			AS JIG_ID	
					, @SMALLCODE		AS SMALLCODE
					, @BLADE			AS BLADE	
			RETURN

		 END
 		END TRY
		BEGIN CATCH 

			SELECT	  'FALSE'				AS Is_Pass 
					, 'Update error !!'		AS Error_Message_ENG
					, N'บันทึกข้อมูลผิดพลาด !!'	AS Error_Message_THA
					, N'กรุณาติดต่อ System'	AS Handling
			RETURN

		END CATCH
END

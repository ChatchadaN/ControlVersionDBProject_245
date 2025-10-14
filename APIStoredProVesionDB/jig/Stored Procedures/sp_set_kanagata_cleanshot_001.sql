-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE  [jig].[sp_set_kanagata_cleanshot_001]
	-- Add the parameters for the stored procedure here
		@kanagataNo			VARCHAR(50)
	 ,  @OPNo				INT		
	 ,  @MCNO				VARCHAR(50)	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	
	DECLARE   @jig_id				INT
			, @OPID					INT
			, @MCId					INT
			, @State				INT
     		, @Smallcode			VARCHAR(4)
			, @OldJIG				INT
			, @Type					VARCHAR(250)
			, @Shot_name			NVARCHAR(50)
			, @idx					INT  
			, @jig_production_id	INT 
			, @MCOld				VARCHAR(50)
	
	SET @jig_id = (SELECT TOP(1) id FROM APCSProDB.trans.jigs WHERE qrcodebyuser = @kanagataNo )
	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
	SET @MCId = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)


		SELECT	  @JIG_ID				= jigs.id 
				, @State				= jig_state 
				, @Smallcode			= jigs.smallcode  
				, @Type					= categories.name
				, @Shot_name			= categories.short_name
				, @jig_production_id	=jig_production_id
		FROM APCSProDB.trans.jigs
		INNER JOIN APCSProDB.jig.productions 
		ON jig_production_id = productions.id 
		INNER JOIN APCSProDB.jig.categories 
		ON category_id = categories.id 
		WHERE (qrcodebyuser = @kanagataNo)

		 
	--- LOG
	---------------------------------------------------------
	INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history_jig]
		([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		 
		, barcode
		, jig_id
		)
	SELECT GETDATE()
		, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [APIStoredProVersionDB].[jig].[sp_set_kanagata_cleanshot] @lot_no = '''  
			+ ''', @kanagataNo = ''' + ISNULL(CAST(@kanagataNo AS varchar),'') 
			+ ''', @OPNo = ''' + ISNULL(CAST(@OPNo AS varchar),'')  
			+ ''', @MCNO = ''' + ISNULL(CAST(@MCNO AS varchar),'')  + ''''
		 
		 , @kanagataNo
		 , @JIG_ID

	IF NOT EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE (qrcodebyuser = @kanagataNo)) 
		BEGIN
			SELECT	 'FALSE'							AS Is_Pass
					, 'This JIG is not registered !!'	AS Error_Message_ENG
					, N'JIG นี้ยังไม่ถูกลงทะเบียน !!'			AS Error_Message_THA
					, N' กรุณาตรวจสอบ หรือติดต่อ System'		AS Handling
			RETURN
		END
		-- CHECK MACHINE NUMBER
		IF NOT EXISTS(SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo) 
		BEGIN 
			SELECT    'FALSE' AS Is_Pass 
					, 'Machine Number is invalid !!' AS Error_Message_ENG
					, N'Machine Number ไม่ถูกต้อง !!' AS Error_Message_THA
					, N' กรุณาตรวจสอบ หรือติดต่อ System' AS Handling

			RETURN
		END


	IF ( @State =  12) --On Machine
	BEGIN
 
		BEGIN TRANSACTION
		BEGIN TRY
	
	 			UPDATE    APCSProDB.trans.jig_conditions
				SET		  periodcheck_value			= 0
						, reseted_at				= GETDATE()
						, reseted_by				= @OPNo
				WHERE id = @JIG_ID

				INSERT INTO  [APCSProDB].[trans].[jig_condition_records]
	           (
							  [day_id]
							, [recorded_at]
							, [jig_id]
							, [control_no]
							, [val]
							, [reseted_at]
							, [reseted_by]
							, [periodcheck_value]
							, accumulate_lifetime
			   )
			   	SELECT        (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
							, GETDATE()
							, id
							, control_no
							, [value]
							, GETDATE()
							, @OPNo
							, periodcheck_value 
							, accumulate_lifetime
			   FROM  APCSProDB.trans.jig_conditions
			   WHERE id = @JIG_ID
		  
		   		SELECT    'TRUE' AS Is_Pass
						, N'This jig ('+ @kanagataNo + ') Clean Shot done!!' AS Error_Message_ENG
						, N'jig นี้ ('+ @kanagataNo + N') Clean Shot แล้ว !!' AS Error_Message_THA
						, '' AS Handling
					  


		COMMIT TRANSACTION
		END TRY
		BEGIN CATCH

			SELECT	  'FALSE'						AS Is_Pass 
					, ERROR_MESSAGE()				AS Error_Message_ENG
					, N'ไม่สามารถ Clean shot ได้ !!' AS Error_Message_THA
					, N' กรุณาติดต่อ System'			AS Handling


		ROLLBACK TRANSACTION 
		END CATCH
	END
END
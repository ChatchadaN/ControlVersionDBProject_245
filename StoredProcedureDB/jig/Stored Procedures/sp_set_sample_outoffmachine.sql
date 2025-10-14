-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_sample_outoffmachine]
	-- Add the parameters for the stored procedure here
		  @QRCode		AS VARCHAR(100)
		, @MCNo			AS VARCHAR(50)
		, @OPNo			AS VARCHAR(6) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE   @JIG_ID_OUT		AS INT
			, @MC_ID			AS INT 
			, @Status_JIG_OUT	AS VARCHAR(50)
			, @OPID				AS INT
			, @app_name			AS NVARCHAR(100) = 'API'

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

	SET @MC_ID = (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo)
	
	SET @JIG_ID_OUT = (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)	
	SET @Status_JIG_OUT = (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID_OUT)
	

INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history_jig]
		   ([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , jig_id
		  , barcode
		   )
SELECT GETDATE()
			,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			, 'EXEC [jig].[sp_set_sample_outoffmachine] @MCNo  = ''' + ISNULL(CAST(@MCNo AS nvarchar(MAX)),'') 
			 +  ''',@OPNo = ''' + ISNULL(CAST(@OPNo AS nvarchar(MAX)),'') + ''''
			, @JIG_ID_OUT
			, @QRCode



	--//////////////////// CHECK MACHINE NUMBER
	IF NOT EXISTS (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo) BEGIN
		--SELECT    'FALSE'							AS Is_Pass
		--		, 'Machine Number is invalid !!'	AS Error_Message_ENG
		--		, N'หมายเลขเครื่องจักรไม่ถูกต้อง !!'			AS Error_Message_THA

				SELECT	  'FALSE'		AS Is_Pass
						  , 2			AS code
						  , @app_name	AS [app_name]
						  , '' 			AS comment

		RETURN
	END

	--///////////////////  OUT
	IF EXISTS(SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) AND @Status_JIG_OUT <> 'On Machine' BEGIN
		
		--SELECT    'FALSE' AS Is_Pass
		--		, 'JIG ('+ @QRCode + ') is not On Machine.' AS Error_Message_ENG
		--		,  N'JIG นี้ ('+ @QRCode + N') ไม่ได้อยู่ในเครื่องจักร !!' AS Error_Message_THA

				SELECT	 'FALSE'		AS Is_Pass
						 , 10			AS code
						 , @app_name	AS [app_name]
						 , '' 			AS comment

		RETURN
	END
	ELSE BEGIN
		BEGIN TRY 

			UPDATE APCSProDB.trans.jigs 
			SET   location_id	= NULL
				, status		= 'To Machine'
				, [jig_state]	= 11
				, updated_at	= GETDATE()
				, updated_by	= @OPID 
			where id = @JIG_ID_OUT

			DELETE FROM APCSProDB.trans.machine_jigs 
			WHERE machine_id	= @MC_ID 
			AND jig_id			= @JIG_ID_OUT

			INSERT INTO APCSProDB.trans.jig_records 
			(			
					  [day_id]
					, [record_at]
					, [jig_id]
					, [jig_production_id]
					, [location_id]
					, [created_at]
					, [created_by]
					, [operated_by]
					, transaction_type
					, mc_no
					, record_class
			) 
			VALUES 
			(
					  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
					, GETDATE()
					, @JIG_ID_OUT,(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID_OUT)
					, NULL
					, GETDATE()
					, @OPID
					, @OPNo
					, 'To Machine'
					, NULL
					, 11
			)

					SELECT	  'TRUE'		AS Is_Pass
							 , 12			AS code
							 , @app_name	AS [app_name]
							 , '' 			AS comment

		END TRY
		BEGIN CATCH

			--SELECT	  'FALSE' AS Is_Pass
			--		, 'Update Failed !!' AS Error_Message_ENG
			--		, N'การถอด JIG ออกจากเครื่องจักรผิดพลาด !!' AS Error_Message_THA

					SELECT	  'FALSE'		AS Is_Pass
							  , 8			AS code
							  , @app_name	AS [app_name]
							  , '' 			AS comment

		END CATCH
	END
END

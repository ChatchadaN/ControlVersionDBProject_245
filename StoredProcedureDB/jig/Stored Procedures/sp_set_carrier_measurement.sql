-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE  [jig].[sp_set_carrier_measurement]
	-- Add the parameters for the stored procedure here
		@QRCode					VARCHAR(50)
	 ,  @process_id				INT		
	 ,  @Updated_by				INT 
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	 
     	DECLARE   @JIG_ID				VARCHAR(10)
			, @Smallcode			VARCHAR(4)
			, @MCId					INT
			, @OldJIG				INT
			, @Type					VARCHAR(250)
			, @OPID					INT
			, @State				INT 
			, @Shot_name			NVARCHAR(50)
			, @idx					INT  
			, @jig_production_id	INT 
			, @MCOld				VARCHAR(50)

	 
	SET @JIG_ID = (SELECT TOP(1) id FROM APCSProDB.trans.jigs WHERE qrcodebyuser = @QRCode )

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
	WHERE (barcode = @QRCode OR qrcodebyuser =@QRCode)


	--- LOG
	---------------------------------------------------------
	INSERT INTO StoredProcedureDB.[dbo].[exec_sp_history_jig]
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
		, 'EXEC [APIStoredProVersionDB].[jig].[sp_set_carrier_measurement] @lot_no = '''  
			+ ''', @kanagataNo = ''' + ISNULL(CAST(@QRCode AS NVARCHAR),'') 
			+ ''', @OPNo = ''' + ISNULL(CAST(@Updated_by AS varchar(6)),'') + ''''
		 , @QRCode
		 , @JIG_ID


 
	BEGIN TRANSACTION
	BEGIN TRY
	
	 		UPDATE    APCSProDB.trans.jigs
			SET		  jig_state					= 10
					, [status]					= 'Measurement'
					, updated_at				= GETDATE()
					, updated_by				= @Updated_by
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
					, jig_state
					, record_class
			) 
			VALUES
			(
					  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
					, GETDATE()
					, @JIG_ID
					, @jig_production_id
					, GETDATE()
					, @OPID
					, @Updated_by
					, 'Measurement'
					, 10
					, 10
			)



		   	SELECT    'TRUE' AS Is_Pass
					, N'This jig ('+ @QRCode + ') Measurement done!!' AS Error_Message_ENG
					, N'jig นี้ ('+ @QRCode + N') Measurement แล้ว !!' AS Error_Message_THA
					, '' AS Handling
					  
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH

		SELECT	  'FALSE'						AS Is_Pass 
				, ERROR_MESSAGE()				AS Error_Message_ENG
				, N'ไม่สามารถ Measurement ได้ !!' AS Error_Message_THA
				, N' กรุณาติดต่อ System'			AS Handling


	ROLLBACK TRANSACTION 
	END CATCH

END
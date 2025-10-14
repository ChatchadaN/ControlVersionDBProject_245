-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_sample_endlot] 
	-- Add the parameters for the stored procedure here
	@QRCode			AS VARCHAR(100),
	@LotNo			AS VARCHAR(10),
	@MCNo			AS VARcHAR(50),
	@OPNo			AS VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE   @JIG_ID			AS INT 
				, @LOT_ID			AS INT 
				, @LOT_Process		AS INT
				, @Record_ID		AS INT
				, @OPID				AS INT
				, @STDLifeTime		AS DATETIME
				, @LifeTime			AS DATETIME
				, @Safety			AS DATETIME
				, @app_name			AS NVARCHAR(100) = 'API'

	SET @JIG_ID = (SELECT id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)
	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history_jig]
		   ([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , [lot_no]
		  , jig_id
		  , barcode
		  )
		SELECT GETDATE()
			,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			, 'EXEC [jig].[sp_set_sample_endlot] @LotNo  = ''' + ISNULL(CAST(@LotNo AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''',@OpNO = ''' 
				+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@McNo = ''' + ISNULL(CAST(@McNo AS nvarchar(MAX)),'') + ''''
			, @LotNo
			, @JIG_ID
			, @QRCode


	BEGIN TRANSACTION

	BEGIN TRY

		


		-- Insert statements for procedure here
	

		--/////////////////Lot Jig//////////////
		SET @LOT_ID = (SELECT id FROM APCSProDB.trans.lots where lot_no = @LotNo)
		SET @LOT_Process = (SELECT TOP(1) id 
							FROM APCSProDB.trans.lot_process_records 
							WHERE lot_id = @LOT_ID 
							ORDER BY id DESC
							)

		INSERT INTO APCSProDB.trans.jig_records 
		(
					  [day_id]
					, [record_at]
					, [jig_id]
					, [jig_production_id]
					, [created_at]
					, [created_by]
					, [operated_by]
					, transaction_type
					, mc_no
					, lot_no
					, record_class
		) 
		VALUES
		(
					  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
					, GETDATE()
					, @JIG_ID,(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID)
					,  GETDATE()
					, @OPID
					, @OPNo
					, 'End Lot'
					, @MCNo
					, @LOTNo
					, 15
		)

		SET @Record_ID = (SELECT TOP(1) id FROM APCSProDB.trans.jig_records WHERE jig_id = @JIG_ID ORDER BY id DESC)
		

		INSERT INTO APCSProDB.trans.lot_jigs 
		VALUES 
		(
					  @LOT_Process
					, @JIG_ID
					, @Record_ID
		)

		--////////////////////Check LifeTime
		SET @STDLifeTime =  (SELECT DATEADD(YEAR, productions.expiration_base, APCSProDB.jig.productions.created_at )
							FROM APCSProDB.trans.jigs 
							INNER JOIN APCSProDB.jig.productions 
							ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
							INNER JOIN APCSProDB.jig.production_counters 
							ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
							WHERE barcode = @QRCode)

		SET @LifeTime	=  (SELECT GETDATE())

		SET @Safety		= (SELECT (DATEADD(month, -1, @STDLifeTime))
							FROM APCSProDB.trans.jigs 
							INNER JOIN APCSProDB.jig.productions 
							ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
							INNER JOIN APCSProDB.jig.production_counters 
							ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
							WHERE barcode = @QRCode)

		--/////////////// RETURN DATA
		SELECT	  'TRUE'			AS Is_Pass
				, 12				AS code
				, @app_name			AS [app_name]
				, ''				AS comment
				, @QRCode			AS QRCode
				, smallcode			AS Smallcode
				, p.name			AS [Type] 
				, FORMAT(GETDATE(),'yyyy-MM-dd hh:mm:ss tt')  AS Life_Time
				, FORMAT(DATEADD(YEAR,p.expiration_base, p.created_at ),'yyyy-MM-dd hh:mm:ss tt') AS STD_Life_Time
				, FORMAT(DATEADD(month, -1, DATEADD(YEAR, p.expiration_base, p.created_at )), 'yyyy-MM-dd hh:mm:ss tt') AS Safety
				, j.id		AS jig_id 
		FROM APCSProDB.trans.jigs j 
		INNER JOIN APCSProDB.jig.productions p ON jig_production_id = p.id 
		INNER JOIN [APCSProDB].[jig].[production_counters] pc ON pc.production_id = p.id 
		INNER JOIN APCSProDB.trans.jig_conditions jc ON jc.id = j.id
		WHERE barcode = @QRCode



	COMMIT TRANSACTION 

	END TRY
	BEGIN CATCH

		--SELECT   'FALSE'						AS Is_Pass 
		--		, 'End Lot Fail !!'				AS Error_Message_ENG
		--		, N'การบันทึกการจบการผลิตผิดพลาด !!' AS Error_Message_THA 
		--		, ''							AS Handling
			SELECT	 'FALSE'		AS Is_Pass
					, 9				AS code
					, @app_name		AS [app_name]
					, '' 			AS comment

			ROLLBACK TRANSACTION
	END CATCH	

	

END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_jig_endlot]
	-- Add the parameters for the stored procedure here
		  @QRCode			AS NVARCHAR(100) 
		, @LOTNO			AS NVARCHAR(10)
		, @OPNo				AS NVARCHAR(6)
		, @MCNo				AS NVARCHAR(50)
		, @INPUT_QTY		AS INT			= 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	 
	SET NOCOUNT ON;
	 
		DECLARE   @JIG_ID			AS INT 
				, @LOT_ID			AS INT
				, @LOT_Process		AS INT
				, @record_id		AS INT
				, @OPID				AS INT


		SELECT    @JIG_ID			=  jigs.id
		FROM APCSProDB.trans.jigs 
		WHERE (barcode = @QRCode OR qrcodebyuser = @QRCode )

		SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
		SET @LOT_ID = (SELECT id FROM APCSProDB.trans.lots where lot_no = @LOTNO)
		SET @LOT_Process = (SELECT TOP(1) id FROM APCSProDB.trans.lot_process_records WHERE lot_id = @LOT_ID ORDER BY id DESC)

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history_jig]
		(	
				  [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
				, jig_id
				, barcode
		)
		SELECT    GETDATE()
				, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'EXEC [jig].[sp_set_jig_endlot] @INPUT_QTY  = ''' + ISNULL(CAST(@INPUT_QTY AS nvarchar(MAX)),'') + ''', @JIG_ID = ''' + ISNULL(CAST(@JIG_ID AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''',@OpNO = ''' 
					+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@McNo = ''' + ISNULL(CAST(@McNo AS nvarchar(MAX)),'') + ''''
				, @LOTNO
				, @JIG_ID
				, @QRCode


	BEGIN TRANSACTION
    -- Insert statements for procedure here
	BEGIN TRY

		 
			UPDATE APCSProDB.trans.jig_conditions
			SET [value]			= value + @INPUT_QTY
				, reseted_at	= GETDATE()
				, reseted_by	= @OPID
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
						, @OPID
						, periodcheck_value 
						, accumulate_lifetime
		   FROM  APCSProDB.trans.jig_conditions
		   WHERE id = @JIG_ID


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
						, @JIG_ID
						, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID)
						, GETDATE()
						, @OPID
						, @OPNo
						, 'End Lot'
						, @MCNo
						, @LOTNo
						, 15
			)
 
			SET @record_id = (SELECT TOP(1) id FROM APCSProDB.trans.jig_records WHERE jig_id = @JIG_ID ORDER BY id DESC)
		
			INSERT INTO APCSProDB.trans.lot_jigs 
			VALUES 
			(			  @LOT_Process
						, @JIG_ID
						, @record_id
			)

			SELECT		  'TRUE'					AS Is_Pass 
						, 'Success !!'				AS Error_Message_ENG
						, N'บันทึกข้อมูลเรียบร้อย !!'		AS Error_Message_THA
						, ''						AS Handling



	COMMIT TRANSACTION 
	END TRY
	BEGIN CATCH

		SELECT		  'FALSE'						AS Is_Pass 
					, ERROR_MESSAGE()				AS Error_Message_ENG
					, N'การบันทึกการจบการผลิตผิดพลาด !!' AS Error_Message_THA
					, N' กรุณาติดต่อ System'			AS Handling


		ROLLBACK TRANSACTION
	END CATCH	
END

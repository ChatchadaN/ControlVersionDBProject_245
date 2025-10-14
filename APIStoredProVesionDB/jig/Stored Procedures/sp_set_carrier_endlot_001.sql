-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_carrier_endlot_001]
	-- Add the parameters for the stored procedure here
		  @QRCode	AS VARCHAR(50) 
		, @MCNo		AS NVARCHAR(50) 
		, @OPNo		AS NVARCHAR(6) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 
	DECLARE   @JIG_ID				AS INT 
			, @MC_ID				AS INT 
			, @Status_JIG			AS varchar(50) 
			, @OPID					AS INT
			, @jig_state			AS INT 
			, @barcode				AS NVARCHAR(100)

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

	SET @MC_ID = (select top(1) id from APCSProDB.mc.machines WHERE machines.name = @MCNo)
	
 
	SELECT    @JIG_ID			=  jigs.id
			, @Status_JIG		=  [status]
			, @jig_state		=  jigs.jig_state
			, @barcode			= jigs.barcode
	FROM APCSProDB.trans.jigs 
	WHERE ( barcode = @QRCode OR qrcodebyuser = @QRCode)
 
	INSERT INTO APIStoredProDB.[dbo].[exec_sp_history_jig]
	(	
				  [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, jig_id
				, barcode
	)
	SELECT		  GETDATE()
				, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'EXEC [jig].[sp_set_carrier_endlot] @JIG_ID = ''' + ISNULL(CAST(@JIG_ID AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''',@OpNO = ''' 
					+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@McNo = ''' + ISNULL(CAST(@McNo AS nvarchar(MAX)),'') + ''''
				, @JIG_ID
				, @barcode 


	--//////////////////// CHECK MACHINE NUMBER
	IF NOT EXISTS (select top (1) id from APCSProDB.mc.machines where machines.name = @MCNo) 
	BEGIN
		SELECT    'FALSE'										AS Is_Pass
				, 'Machine Number is invalid !!'				AS Error_Message_ENG
				, N'หมายเลขเครื่องจักรไม่ถูกต้อง !!'						AS Error_Message_THA 
				, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'		AS Handling
		RETURN
	END
 
	ELSE BEGIN
		BEGIN TRY 

			UPDATE APCSProDB.trans.jigs 
			SET	   location_id		= NULL
				 , status			= 'Measurement'
				 , [jig_state]		= 10
				 , updated_at		= GETDATE()
				 , updated_by		= @OPID 
			WHERE id				= @JIG_ID

 
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
					, jig_state
			) 
			VALUES 
			(
					 (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
					, GETDATE()
					, @JIG_ID
					, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID)
					, NULL
					, GETDATE()
					, @OPID
					, @OPNo
					, 'Measurement'
					, NULL
					, 10
					, 10
			)

			SELECT	  'TRUE'							AS Is_Pass
					, 'Success !!'						AS Error_Message_ENG
					, N'สำเร็จ !!'							AS Error_Message_THA
					, N''								AS Handling

		END TRY
		BEGIN CATCH

			SELECT   'FALSE'										AS Is_Pass
					, ERROR_MESSAGE()							    AS Error_Message_ENG
					, N'การถอด Carrier ออกจากเครื่องจักรผิดพลาด !!'		AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'		AS Handling

		END CATCH
	END
END

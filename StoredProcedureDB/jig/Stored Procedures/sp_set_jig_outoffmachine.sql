-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_jig_outoffmachine]
	-- Add the parameters for the stored procedure here
	  @QRCode	AS NVARCHAR(100) 
	, @MCNo		AS NVARCHAR(50) 
	, @OPNo		AS NVARCHAR(6) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE   @JIG_ID				AS INT 
			, @MC_ID				AS INT 
			, @Status_JIG			AS varchar(50) 
			, @OPID					AS INT
			, @jig_state			AS INT 

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

	SET @MC_ID = (select top(1) id from APCSProDB.mc.machines WHERE machines.name = @MCNo)
	
 
		SELECT    @JIG_ID			=  jigs.id
				, @Status_JIG		=  status
				, @jig_state		=  jigs.jig_state
		FROM APCSProDB.trans.jigs 
		WHERE ( barcode = @QRCode OR qrcodebyuser = @QRCode)
		 
 	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history_jig]
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
	SELECT    GETDATE()
			, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'EXEC [jig].[sp_set_jig_outoffmachine]  @JIG_ID = ''' + ISNULL(CAST(@JIG_ID AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''',@OPNo = ''' 
				+ ISNULL(CAST(@OPNo AS nvarchar(MAX)),'') +  ''',@MCNo = ''' + ISNULL(CAST(@MCNo AS nvarchar(MAX)),'') + ''''
			, @JIG_ID
			, @QRCode


	--//////////////////// CHECK MACHINE NUMBER
	IF NOT EXISTS (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo) 
	BEGIN
		SELECT    'FALSE'										AS Is_Pass
				, 'Machine Number is invalid !!'				AS Error_Message_ENG
				, N'หมายเลขเครื่องจักรไม่ถูกต้อง !!'						AS Error_Message_THA 
				, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'		AS Handling
		RETURN
	END

	--///////////////////  OUT
	IF EXISTS(SELECT jigs.id FROM APCSProDB.trans.jigs WHERE ( barcode = @QRCode OR qrcodebyuser = @QRCode)) AND @jig_state <> 12 --On Machine
	BEGIN

		SELECT	  'FALSE'										 AS Is_Pass
				, 'JIG ('+ @QRCode + ') is not On Machine.'		 AS Error_Message_ENG
				, N'JIG นี้ ('+ @QRCode + N') ไม่ได้อยู่ในเครื่องจักร !!'  AS Error_Message_THA 
				, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'		 AS Handling
		RETURN

	END
	ELSE BEGIN
		BEGIN TRY 

			UPDATE APCSProDB.trans.jigs 
			SET	   location_id		= NULL
				 , status			= 'To Machine'
				 , [jig_state]		= 11
				 , updated_at		= GETDATE()
				 , updated_by		= @OPID 
			WHERE id				= @JIG_ID

			DELETE FROM APCSProDB.trans.machine_jigs 
			WHERE machine_id	= @MC_ID 
			AND jig_id			= @JIG_ID

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
					, @JIG_ID
					, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID)
					, NULL
					, GETDATE()
					, @OPID
					, @OPNo
					, 'To Machine'
					, NULL
					, 11
			)

			SELECT	  'TRUE'							AS Is_Pass
					, 'Success !!'						AS Error_Message_ENG
					, N'ถอด JIG ออกจากเครื่องจักรเรียบร้อย !!'	AS Error_Message_THA
					, N''								AS Handling

		END TRY
		BEGIN CATCH

			SELECT   'FALSE'										AS Is_Pass
					, ERROR_MESSAGE()							    AS Error_Message_ENG
					, N'การถอด JIG ออกจากเครื่องจักรผิดพลาด !!'			AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'		AS Handling

		END CATCH
	END
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_blade_outoffmachine]
	-- Add the parameters for the stored procedure here
	@BLADE		AS VARCHAR(100),
	@MCNo		AS VARCHAR(50),
	@OPNo		AS VARCHAR(6) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @JIG_ID_OUT		AS INT,
			@MC_ID			AS INT ,
			@Status_JIG_OUT AS varchar(50),
			@OPID			AS INT

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

	SET @MC_ID = (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo)
	
 

		SELECT    @JIG_ID_OUT		= jigs.id  
				, @Status_JIG_OUT	= jigs.status
		FROM APCSProDB.trans.jigs 
		WHERE ( barcode	= @BLADE 
		OR qrcodebyuser = @BLADE
		)

	 
	--//////////////////// CHECK MACHINE NUMBER
	IF NOT EXISTS (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo) 
	BEGIN
			SELECT	  'FALSE'							AS Is_Pass
					, 'Machine Number is invalid !!'	AS Error_Message_ENG
					,  N'หมายเลขเครื่องจักรไม่ถูกต้อง !!'		AS Error_Message_THA 
					, ''								AS Handling
			RETURN
	END

	--/////////////////// BLADE OUT
	IF EXISTS(SELECT jigs.id FROM APCSProDB.trans.jigs WHERE id = @JIG_ID_OUT) AND @Status_JIG_OUT <> 'On Machine' 
	BEGIN
			SELECT    'FALSE'											AS Is_Pass
					, N'Blade ('+ (@BLADE) + ') is not On Machine.'		AS Error_Message_ENG
					, N'Blade ('+ (@BLADE) + N') ไม่ได้อยู่ในเครื่องจักร !!'		AS Error_Message_THA 
					, ''												AS Handling
			FROM APCSProDB.trans.jigs 
			WHERE id = @JIG_ID_OUT

			RETURN
	END

	--/////////////////// BLADE : M/C
	IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID AND jig_id = @JIG_ID_OUT) 
	BEGIN
			SELECT	 'FALSE'																AS Is_Pass
					,'Blade ('+ (@BLADE) + ') is not on this Machine. ('+ @MCNo +') !!'		AS Error_Message_ENG
					, N'Blade ('+ (@BLADE) + N') ไม่ได้อยู่ในเครื่องจักร ('+ @MCNo +') !!'			AS Error_Message_THA 
					,''																		AS Handling
			FROM APCSProDB.trans.jigs 
			WHERE id = @JIG_ID_OUT
		
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
				WHERE id = @JIG_ID_OUT

				DELETE FROM APCSProDB.trans.machine_jigs 
				WHERE	machine_id = @MC_ID 
				AND		jig_id	   = @JIG_ID_OUT

				INSERT INTO APCSProDB.trans.jig_records 
				(	  [day_id]
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
				values 
				(	  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
					, GETDATE()
					, @JIG_ID_OUT
					, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID_OUT)
					, NULL
					, GETDATE()
					, @OPID
					, @OPNo
					, 'To Machine'
					, NULL
					, 11
				)
			
				SELECT   'TRUE'										AS Is_Pass
						,'Success !!'								AS Error_Message_ENG
						, N'ถอด Blade ออกจากเครื่องจักรเรียบร้อย !!'		AS Error_Message_THA 
						,''											AS Handling
		END TRY
		BEGIN CATCH

				SELECT  'FALSE'										AS Is_Pass
						,'Update Failed !!'							AS Error_Message_ENG
						, N'การถอด Blade ออกจากเครื่องจักรผิดพลาด !!'		AS Error_Message_THA 
						,''											AS Handling
		END CATCH
	END
END

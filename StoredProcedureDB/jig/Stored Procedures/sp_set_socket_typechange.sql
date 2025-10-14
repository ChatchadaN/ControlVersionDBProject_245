-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_socket_typechange]
	-- Add the parameters for the stored procedure here
	--@QRCodeIn AS VARCHAR(15),
	@QRCode AS VARCHAR(100),
	@DataInput AS INT,
	@LotNo AS VARCHAR(10),
	@MCNo AS VARCHAR(50),
	@OPNo AS VARCHAR(6) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRY
		DECLARE @JIG_ID AS INT,
				@MC_ID AS INT ,
				@Status_JIG AS varchar(50),
				--@LOT_ID as INT,
				--@LOT_Process as INT,
				--@Record_ID as INT
				
				@OPID AS INT

		SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
		-- Insert statements for procedure here
		SET @JIG_ID = (SELECT id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)
		SET @MC_ID = (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo)		
		SET @Status_JIG = (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID)

			--//////////////////// CHECK MACHINE NUMBER
		IF NOT EXISTS (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo) BEGIN
			SELECT 'FALSE' AS Is_Pass,'Machine Number is invalid !!' AS Error_Message_ENG, N'หมายเลขเครื่องจักรไม่ถูกต้อง !!' AS Error_Message_THA ,'' AS Handling
			RETURN
		END

		--/////////////////// SOCKET OUT
		IF EXISTS(SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) AND @Status_JIG <> 'On Machine' BEGIN
			SELECT 'FALSE' AS Is_Pass,'Socket ('+ (smallcode) + ') is not On Machine.' AS Error_Message_ENG
			, N'Socket นี้ ('+ (smallcode) + ') ไม่ได้อยู่ในเครื่องจักร !!' AS Error_Message_THA ,'' AS Handling
			FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
			RETURN
		END
		ELSE BEGIN
		
			UPDATE APCSProDB.trans.jigs set location_id = NULL,status = 'To Machine',[jig_state] = 11,updated_at = GETDATE(),updated_by = @OPID where id = @JIG_ID
			DELETE FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID AND jig_id = @JIG_ID

			UPDATE APCSProDB.trans.jig_conditions
			SET [value] = [value] + @DataInput
			WHERE id = @JIG_ID

			--/////////////////Lot Jig//////////////
			--SET @LOT_ID = (SELECT id FROM APCSProDB.trans.lots where lot_no = @LotNo)
			--SET @LOT_Process = (SELECT TOP(1) id FROM APCSProDB.trans.lot_process_records WHERE lot_id = @LOT_ID order by id desc)

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,lot_no,record_class) 
					values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@JIG_ID,
					(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID), GETDATE(),@OPID,@OPNo,'Type Change',@MCNo,@LOTNo,17)

			--SET @Record_ID = (SELECT TOP(1) id FROM APCSProDB.trans.jig_records WHERE jig_id = @JIG_ID ORDER BY id DESC)
			--INSERT INTO APCSProDB.trans.lot_jigs VALUES (@LOT_Process,@JIG_ID,@Record_ID)

			SELECT	 'TRUE' AS Is_Pass 
					, '' AS Error_Message_ENG
					, '' AS Error_Message_THA 
					, '' AS Handling , @QRCode AS QRCode 
					, smallcode AS Smallcode
					, productions.name AS SocketType
					, CONVERT(int, ((jig_conditions.value + jig_conditions.accumulate_lifetime) / 1000)) AS Life_Time
					, CONVERT(int, productions.expiration_value / 1000)  AS STD_Life_Time
					, CONVERT(int,(jig_conditions.accumulate_lifetime / 1000)) AS Acc
					, CONVERT(int,(productions.expiration_value - [production_counters].warn_value) / 1000) AS Safety
			FROM APCSProDB.trans.jigs 
			INNER JOIN APCSProDB.trans.jig_conditions ON jig_conditions.id = jigs.id
			INNER JOIN APCSProDB.jig.productions ON jig_production_id = productions.id 
			INNER JOIN [APCSProDB].[jig].[production_counters] ON production_counters.production_id = productions.id WHERE barcode = @QRCode

		END
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass ,'Type Change Socket Fail !!' AS Error_Message_ENG,N'การบันทึกการเปลี่ยน Socket ผิดพลาด !!' AS Error_Message_THA ,'' AS Handling
	END CATCH
END

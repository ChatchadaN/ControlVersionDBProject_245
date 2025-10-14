-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_socket_endlot_v3] 
	-- Add the parameters for the stored procedure here
	@QRCode AS VARCHAR(15),
	@DataInput AS INT,
	@LotNo AS VARCHAR(10),
	@MCNo AS VARcHAR(50),
	@OPNo AS VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @JIG_ID AS INT,
				@LOT_ID as INT,
				@LOT_Process as INT,
				@Record_ID as INT,
				@OPID AS INT,
				@STDLifeTime AS INT,
				@LifeTime AS INT,
				@Safety AS INT,
				@Accu AS INT

	    SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

		-- Insert statements for procedure here
		SET @JIG_ID = (SELECT id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)

		UPDATE APCSProDB.trans.jig_conditions
		SET [value] = [value] + @DataInput
		WHERE id = @JIG_ID

		--/////////////////Lot Jig//////////////
		SET @LOT_ID = (SELECT id FROM APCSProDB.trans.lots where lot_no = @LotNo)
		SET @LOT_Process = (SELECT TOP(1) id FROM APCSProDB.trans.lot_process_records WHERE lot_id = @LOT_ID order by id desc)

		INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,lot_no,record_class) 
					values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@JIG_ID,
					(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID), GETDATE(),@OPID,@OPNo,'End Lot',@MCNo,@LOTNo,15)

		SET @Record_ID = (SELECT TOP(1) id FROM APCSProDB.trans.jig_records WHERE jig_id = @JIG_ID ORDER BY id DESC)
		INSERT INTO APCSProDB.trans.lot_jigs VALUES (@LOT_Process,@JIG_ID,@Record_ID)

		--////////////////////Check LifeTime
		SET @STDLifeTime = (SELECT APCSProDB.jig.productions.expiration_value / 1000
							FROM APCSProDB.trans.jigs INNER JOIN
							APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
							APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
							where barcode = @QRCode)

		SET @LifeTime = (SELECT (APCSProDB.trans.jig_conditions.value / 1000)
							FROM APCSProDB.trans.jigs INNER JOIN
							APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
							APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
							where barcode = @QRCode)

		SET @Accu = (SELECT (APCSProDB.trans.jig_conditions.accumulate_lifetime / 1000)
							FROM APCSProDB.trans.jigs INNER JOIN
							APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
							APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
							where barcode = @QRCode)

		SET @Safety = (SELECT (APCSProDB.jig.production_counters.warn_value / 1000)
							FROM APCSProDB.trans.jigs INNER JOIN
							APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
							APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
							where barcode = @QRCode)

		--/////////////// RETURN DATA
		SELECT 'TRUE' AS Is_Pass,@QRCode AS QRCode,
			smallcode  AS Smallcode,
			p.name  AS SocketType,
			CONVERT(int,((jc.value + jc.accumulate_lifetime) / 1000)) AS Life_Time,
			CONVERT(int,(p.expiration_value / 1000)) AS STD_Life_Time,
			CONVERT(int,(jc.accumulate_lifetime / 1000)) AS Acc,
			CONVERT(int,(p.expiration_value - pc.warn_value) / 1000) AS Safety,
			j.id AS jig_id

		FROM APCSProDB.trans.jigs j 
		INNER JOIN APCSProDB.jig.productions p ON jig_production_id = p.id 
		INNER JOIN [APCSProDB].[jig].[production_counters] pc ON pc.production_id = p.id 
		INNER JOIN APCSProDB.trans.jig_conditions jc ON jc.id = j.id
		WHERE barcode = @QRCode

	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass ,'End Lot Fail !!' AS Error_Message_ENG,N'การบันทึกการจบการผลิตผิดพลาด !!' AS Error_Message_THA
	END CATCH
END

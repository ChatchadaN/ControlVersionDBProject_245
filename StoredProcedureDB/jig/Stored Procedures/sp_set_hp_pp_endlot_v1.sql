-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [jig].[sp_set_hp_pp_endlot_v1]
	-- Add the parameters for the stored procedure here
		@HPPP_ID AS INT,
		@LOTNo AS VARCHAR(10),
		@OPNo AS VARCHAR(6),
		@MCNo AS VARCHAR(50) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRY
		UPDATE APCSProDB.trans.jig_conditions
			SET [value] = [value] + 1,
				[periodcheck_value] = [periodcheck_value] + 1
		WHERE id in (@HPPP_ID)

		--/////////////////Lot Jig//////////////
		DECLARE @LOT_ID as INT
			,@LOT_Process as INT
			,@HPPP_Record_ID as INT
			,@OPID AS INT

		SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
		SET @LOT_ID = (SELECT id FROM APCSProDB.trans.lots where lot_no = @LOTNO)
		SET @LOT_Process = (SELECT TOP(1) id FROM APCSProDB.trans.lot_process_records WHERE lot_id = @LOT_ID order by id desc)

		INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,lot_no,record_class) 
					values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@HPPP_ID,
					(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @HPPP_ID), GETDATE(),@OPID,@OPNo,'End Lot',@MCNo,@LOTNo,15)

		--INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,lot_no,record_class) 
		--			values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@PP_ID,
		--			(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @PP_ID), GETDATE(),@OPNo,@OPNo,'End Lot',@MCNo,@LOTNo,15)

		SET @HPPP_Record_ID = (SELECT TOP(1) id FROM APCSProDB.trans.jig_records WHERE jig_id = @HPPP_ID ORDER BY id DESC)
		INSERT INTO APCSProDB.trans.lot_jigs VALUES (@LOT_Process,@HPPP_ID,@HPPP_Record_ID)

		--SET @PP_Record_ID = (SELECT TOP(1) id FROM APCSProDB.trans.jig_records WHERE jig_id = @PP_ID ORDER BY id DESC)
		--INSERT INTO APCSProDB.trans.lot_jigs VALUES (@LOT_Process,@PP_ID,@PP_Record_ID)

		SELECT 'TRUE' AS Is_Pass ,'Success !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA, '' AS Handling
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass ,'End Lot Fail !!' AS Error_Message_ENG,N'การบันทึกการจบการผลิตผิดพลาด !!' AS Error_Message_THA
			,N' กรุณาติดต่อ System' AS Handling
	END CATCH

END

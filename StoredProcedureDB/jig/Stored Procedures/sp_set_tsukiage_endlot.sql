-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_tsukiage_endlot] 
	-- Add the parameters for the stored procedure here
		@JIGQRCode AS VARCHAR(100),
		@LOTNo AS VARCHAR(20),
		@OPNo AS VARCHAR(6),
		@MCNo AS VARCHAR(50),
		@LTValue INT =  0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--/////////////////Lot Jig//////////////
	BEGIN TRY
		DECLARE   @LOT_ID			AS INT
				, @LOT_Process		AS INT
				, @JIG_ID			AS INT
				, @JIG_Record_ID	AS INT
				, @OPID				AS INT

		SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
		SET @LOT_ID = (SELECT id FROM APCSProDB.trans.lots where lot_no = @LOTNO)
		SET @LOT_Process = (SELECT TOP(1) id FROM APCSProDB.trans.lot_process_records WHERE lot_id = @LOT_ID order by id desc)
		SET @JIG_ID = (SELECT id FROM APCSProDB.trans.jigs where barcode = @JIGQRCode)


		UPDATE APCSProDB.trans.jig_conditions
		SET   [value]		= [value] + @LTValue
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
		)

		SET @JIG_Record_ID = (SELECT TOP(1) id FROM APCSProDB.trans.jig_records WHERE jig_id = @JIG_ID ORDER BY id DESC)
		INSERT INTO APCSProDB.trans.lot_jigs 
		VALUES (@LOT_Process,@JIG_ID,@JIG_Record_ID)


		SELECT 'TRUE' AS Is_Pass ,'Success !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA ,N'' AS Handling
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass ,'End Lot Fail !!' AS Error_Message_ENG,N'การบันทึกการจบการผลิตผิดพลาด !!' AS Error_Message_THA
			,N' กรุณาติดต่อ System' AS Handling
	END CATCH
END

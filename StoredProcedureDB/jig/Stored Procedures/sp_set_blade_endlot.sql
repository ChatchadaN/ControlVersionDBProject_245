-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_blade_endlot]
	-- Add the parameters for the stored procedure here
		  @JIG_ID			AS INT
		, @LOTNo			AS VARCHAR(10)
		, @OPNo				AS VARCHAR(6)
		, @MCNo				AS VARCHAR(50)
		, @INPUT_QTY		AS INT			= 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	 
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRY

			UPDATE  APCSProDB.trans.jig_conditions
			SET		[value]		= jigs.quantity - @INPUT_QTY
			FROM APCSProDB.trans.jigs
			WHERE jig_conditions.id =  @JIG_ID 

			 
			DECLARE   @LOT_ID			AS INT
					, @LOT_Process		AS INT
					, @Blade_record_id	AS INT
					, @OPID				AS INT

			SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
			SET @LOT_ID = (SELECT id FROM APCSProDB.trans.lots where lot_no = @LOTNO)
			SET @LOT_Process = (SELECT TOP(1) id FROM APCSProDB.trans.lot_process_records WHERE lot_id = @LOT_ID order by id desc)

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
			values
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
 
			SET @Blade_record_id = (SELECT TOP(1) id FROM APCSProDB.trans.jig_records WHERE jig_id = @JIG_ID ORDER BY id DESC)
		
			INSERT INTO APCSProDB.trans.lot_jigs 
			VALUES 
			(			  @LOT_Process
						, @JIG_ID
						, @Blade_record_id
			)
	 
			SELECT		  'TRUE' AS Is_Pass 
						, 'Success !!' AS Error_Message_ENG
						, N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA
						, '' AS Handling

	END TRY
	BEGIN CATCH

		SELECT		  'FALSE' AS Is_Pass 
					, 'End Lot Fail !!' AS Error_Message_ENG
					, N'การบันทึกการจบการผลิตผิดพลาด !!' AS Error_Message_THA
					, N' กรุณาติดต่อ System' AS Handling

	END CATCH
END

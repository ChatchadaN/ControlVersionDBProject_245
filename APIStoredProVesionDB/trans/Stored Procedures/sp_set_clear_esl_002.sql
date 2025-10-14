-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_clear_esl_002] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10),
	@e_slip_id AS VARCHAR(20), 
	@op_no AS VARCHAR(6),
	@mc_no AS VARCHAR(50) = NULL,
	@app_name AS VARCHAR(255)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

  
		BEGIN TRY 
			IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no = @lot_no )
			BEGIN
				--update data
				UPDATE APCSProDB.trans.lots 
				SET		e_slip_id = NULL,
						updated_at = GETDATE(),
						updated_by = (SELECT id FROM APCSProDB.man.users WHERE emp_num =  @op_no)
				WHERE lot_no = @lot_no

				SELECT 'TRUE'				as Is_Pass,
					'Update Successed. !!' AS Error_Message_ENG,
					N'อัพเดทข้อมูลเรียบร้อย !!' AS Error_Message_THA,
					N'อัพเดทข้อมูลเรียบร้อย !!' AS Handling 
				RETURN 

			END
			ELSE
			BEGIN
				SELECT 'FALSE' as Is_Pass,
					'No data found for Lot ' AS Error_Message_ENG,
					N'ไม่พบข้อมูล Lot ' AS Error_Message_THA,
					N'กรุณาติดต่อ System !!' AS Handling 
				RETURN
			END
		END TRY
		BEGIN CATCH
			SELECT 'FALSE' as Is_Pass,
				'Update Faild. !!' AS Error_Message_ENG,
				N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA,
				N'กรุณาติดต่อ System !!' AS Handling 
			RETURN 
		END CATCH
	END
 
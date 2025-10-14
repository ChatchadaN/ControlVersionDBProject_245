-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_clear_e_slip_001] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10),
	@e_slip_id AS VARCHAR(20),
	@carrier_no AS VARCHAR(20) = NULL,
	@op_no AS VARCHAR(6),
	@mc_no AS VARCHAR(50) = NULL,
	@app_name AS VARCHAR(255)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE e_slip_id = @e_slip_id) BEGIN
		SELECT 'FALSE' as Is_Pass,
			'Can not found card. !! ('+ TRIM([lots].[lot_no]) +')' AS Error_Message_ENG,
			N'ไม่พบข้อมูลการใช้งาน card นี้ !! ('+ TRIM([lots].[lot_no]) +')' AS Error_Message_THA,
			N'กรุณาตรวจสอบข้อมูลบนเว็บ ATOM !!' AS Handling 
		FROM APCSProDB.trans.lots WHERE lot_no = @lot_no	
		RETURN 
	END
	ELSE BEGIN
		BEGIN TRY 
			IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no = @lot_no and e_slip_id = @e_slip_id)
			BEGIN
				--update data
				update APCSProDB.trans.lots 
					set carrier_no = NULL,
						e_slip_id = NULL,
						updated_at = GETDATE(),
						updated_by = (SELECT id FROM APCSProDB.man.users WHERE emp_num =  @op_no)
				where lot_no = @lot_no and e_slip_id = @e_slip_id

				SELECT 'TRUE' as Is_Pass,
					'Unlink Successed. !!' AS Error_Message_ENG,
					N'Unlink ข้อมูลเรียบร้อย !!' AS Error_Message_THA,
					N'Unlink ข้อมูลเรียบร้อย !!' AS Handling 
				--FROM APCSProDB.trans.lots WHERE e_slip_id = @e_slip_id	
				RETURN 
			END
			ELSE
			BEGIN
				SELECT 'FALSE' as Is_Pass,
					'Card and Lot data do not match. !!' AS Error_Message_ENG,
					N'ข้อมูล card กับ Lot ไม่ตรงกัน !!' AS Error_Message_THA,
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

END 

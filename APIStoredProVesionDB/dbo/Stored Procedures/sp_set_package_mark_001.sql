
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_package_mark_001]	-- Add the parameters for the stored procedure here	
	@id INT
	, @is_enable INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	UPDATE APCSProDB.trans.lot_marking_verify_condition
	SET condition_value = @is_enable
	WHERE id = @id;
		
	SELECT 'TRUE' AS Is_Pass 
		, 'Update Success !!' AS Error_Message_ENG
		, N'บันทึกข้อมูลสำเร็จ !!' AS Error_Message_THA 
		, N'' AS Handling;

END

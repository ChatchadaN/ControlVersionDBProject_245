-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_rack_set_delete]
	-- Add the parameters for the stored procedure here
	@rack_set_id INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY	
		IF EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_sets WHERE id = @rack_set_id)
		BEGIN
			DELETE APCSProDB.rcs.rack_set_lists
			WHERE rack_set_id = @rack_set_id

			DELETE APCSProDB.rcs.rack_sets
			WHERE id = @rack_set_id

			SELECT 'TRUE' AS Is_Pass 
				,'Remove Successfully !!' AS Error_Message_ENG
				,N'	การลบข้อมูลสำเร็จ !!' AS Error_Message_THA	
				,N'' AS Headlind
			COMMIT; 
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Is_Pass 
				,'Remove fail. Not found data !!' AS Error_Message_ENG
				,N'การลบข้อมูลผิดพลาด ไม่พบข้อมูล!!' AS Error_Message_THA
				,N'Please check the data !!' AS Headlind
			RETURN;
		END
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
		,ERROR_MESSAGE() AS Error_Message_ENG
		,N'Please check the data !!' AS Error_Message_THA
		,N'' AS Headlind
	END CATCH
END
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_rack_controls]
	-- Add the parameters for the stored procedure here
	 @rack_id INT
	, @rack_name VARCHAR(50)
	, @is_enable INT
	, @updated_by INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY		
		IF EXISTS( SELECT 1 FROM APCSProDB.rcs.rack_controls WHERE id = @rack_id)
		BEGIN
			UPDATE APCSProDB.rcs.rack_controls
				SET rack_controls.name = @rack_name
				,is_enable = @is_enable
				,updated_at = GETDATE()
				,updated_by = @updated_by
			WHERE id = @rack_id

			SELECT 'TRUE' AS Is_Pass 
				,'Update Data Successfully !!' AS Error_Message_ENG
				,N'	การอัพเดทข้อมูลสำเร็จ !!' AS Error_Message_THA	
				,N'' AS Headlind
			COMMIT;
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Is_Pass 
				,'Not found data !!' AS Error_Message_ENG
				,N'ไม่พบข้อมูล!!' AS Error_Message_THA
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

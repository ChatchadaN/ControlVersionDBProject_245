-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_rack_set]
	-- Add the parameters for the stored procedure here
	@rack_set_id INT
	,@set_name VARCHAR(50)
	,@updated_by INT

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
			IF EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_sets WHERE name = @set_name)
			BEGIN
				SELECT 'FALSE' AS Is_Pass 
				,'Register fail. Set Name Already Exists!!' AS Error_Message_ENG
				,N'การลงทะเบียนผิดพลาด Set Name นี้มีอยู่แล้ว !!' AS Error_Message_THA
				,N'Please check the data !!' AS Headlind
			RETURN;
			END
			ELSE
			BEGIN		
				UPDATE APCSProDB.rcs.rack_sets
					SET name = @set_name
					,updated_at = GETDATE()
					,updated_by = @updated_by
				WHERE id = @rack_set_id

				SELECT 'TRUE' AS Is_Pass 
					,'Update Data Successfully !!' AS Error_Message_ENG
					,N'	การอัพเดทข้อมูลสำเร็จ !!' AS Error_Message_THA	
					,N'' AS Headlind
				COMMIT;
			END
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
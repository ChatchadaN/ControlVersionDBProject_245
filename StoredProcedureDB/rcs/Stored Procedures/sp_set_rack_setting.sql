-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_rack_setting]
	-- Add the parameters for the stored procedure here
	@rack_id INT
	, @rack_set_id INT
	, @priority INT = 0
	, @emp_id INT
	, @filter INT
	--(1: Delete 2: Edit priority)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		IF(@filter = 1)
		BEGIN
			--1: Delete
			IF NOT EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_settings WHERE rack_id = @rack_id and rack_set_id = @rack_set_id)
			BEGIN
				SELECT 'FALSE' AS Is_Pass 
					,'Data not found!!' AS Error_Message_ENG
					, N'ไม่พบข้อมูล !!' AS Error_Message_THA
					,N'Please check the data !!' AS Headlind
				RETURN;
			END
			ELSE
			BEGIN		
				DELETE APCSProDB.rcs.rack_settings
				WHERE rack_id = @rack_id
				and rack_set_id = @rack_set_id
	
				SELECT 'TRUE' AS Is_Pass 
					,'Remove Data Successfully !!' AS Error_Message_ENG
					,N'การลบข้อมูลสำเร็จ !!' AS Error_Message_THA	
					,N'' AS Headlind
				COMMIT;
			END
		END
		ELSE IF (@filter = 2)
		BEGIN
			-- 2: Edit priority
			IF NOT EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_settings WHERE rack_id = @rack_id and rack_set_id = @rack_set_id)
			BEGIN
				SELECT 'FALSE' AS Is_Pass 
					,'Data not found!!' AS Error_Message_ENG
					, N'ไม่พบข้อมูล !!' AS Error_Message_THA
					,N'Please check the data !!' AS Headlind
				RETURN;
			END
			ELSE
			BEGIN
				UPDATE APCSProDB.rcs.rack_settings
				SET [priority] = @priority
				 , updated_at = GETDATE()
				 , updated_by = @emp_id
				WHERE rack_id = @rack_id 
				AND rack_set_id = @rack_set_id

				SELECT 'TRUE' AS Is_Pass 
					,'Update Data Successfully !!' AS Error_Message_ENG
					,N'การอัพเดทข้อมูลสำเร็จ !!' AS Error_Message_THA	
					,N'' AS Headlind
				COMMIT;
			END
		END
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
		,ERROR_MESSAGE() AS Error_Message_ENG
		,N'กรุณาตรวจสอบข้อมูล !!' AS Error_Message_THA
		,N'Please check the data !!' AS Headlind
	END CATCH
END
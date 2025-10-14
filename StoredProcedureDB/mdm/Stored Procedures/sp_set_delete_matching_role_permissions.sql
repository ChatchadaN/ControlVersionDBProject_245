


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_delete_matching_role_permissions]
	-- Add the parameters for the stored procedure here
	  @roleID INT
	, @permissionID INT
	
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
BEGIN TRANSACTION;

	BEGIN TRY
		IF NOT EXISTS (SELECT 'xxx' FROM [APCSProDB].[man].[role_permissions] WHERE role_id = @roleID and permission_id = @permissionID)
		BEGIN
			SELECT 'FALSE' AS Is_Pass,
					'5'    AS code,
				   'Data Not Found' AS Error_Message_ENG,
				   N'ไม่พบข้อมูลการลงทะเบียน' AS Error_Message_THA,
				   '' AS Handling;
			ROLLBACK TRANSACTION;
			RETURN;
		END
		
		ELSE
		BEGIN
			DELETE FROM [APCSProDB].[man].[role_permissions] WHERE role_id = @roleID and permission_id = @permissionID;
			
			SELECT	  'TRUE'				AS Is_Pass
					, 'Successed !!'		AS Error_Message_ENG
					, N'บันทึกข้อมูลเรียบร้อย.'	AS Error_Message_THA	
					, ''					AS Handling

			COMMIT; 

			RETURN
	END 
	END TRY

	BEGIN CATCH
			ROLLBACK;
			SELECT	  'FALSE'				AS Is_Pass
					, 'Update Faild !!'		AS Error_Message_ENG
					, N'บันทึกข้อมูลผิดพลาด !!'	AS Error_Message_THA
					, ''					AS Handling
		END CATCH
	END




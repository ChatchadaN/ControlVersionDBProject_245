-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_user_roles]
	-- Add the parameters for the stored procedure here
	@user_id		AS INT,
	@role_id		AS INT,
	@updated_by		AS INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		  
		  IF EXISTS (SELECT 'xxx' FROM  [APCSProDB].[man].[user_roles]  WHERE  [user_id] =   @user_id AND role_id	=   @role_id)
		  BEGIN 


			 DELETE FROM [APCSProDB].[man].[user_roles] 
			 WHERE [user_id] =   @user_id   
			 AND role_id	 =   @role_id

			INSERT INTO	[APCSProDB].[man_hist].[user_roles_hist]  
			(
					  [category]
					, [user_id]
					, [role_id]
					, [expired_on]
					, [created_at]
					, [created_by] 
			)  
			VALUES( 
					  3  
					, @user_id  
					, @role_id   
					, '9999-12-31'
					, GETDATE()
					, @updated_by 
			)


		COMMIT; 

			SELECT    'TRUE' AS Is_Pass
					, 'Successed !!' AS Error_Message_ENG
					, N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA	
		END
		ELSE
		BEGIN

			SELECT    'FALSE' AS Is_Pass
					, 'Data not found' AS Error_Message_ENG
					, N'ไม่พบข้อมูล' AS Error_Message_THA

		END 
	END TRY

	BEGIN CATCH
		ROLLBACK;

		SELECT    'FALSE' AS Is_Pass
				, 'Update Faild !!' AS Error_Message_ENG
				, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA

	END CATCH
END

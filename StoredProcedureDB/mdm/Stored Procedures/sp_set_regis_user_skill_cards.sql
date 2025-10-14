

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_regis_user_skill_cards]
	-- Add the parameters for the stored procedure here
	  @userID		INT
	, @emp_code	VARCHAR(10)
	, @comment	VARCHAR(200)
	, @created_by	INT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
    BEGIN TRY

		IF EXISTS (SELECT  'xx' FROM  [APCSProDB].[man].[user_skill_cards] WHERE [user_id] = @userID )
		BEGIN  

					SELECT	  'FALSE'		AS Is_Pass
					, 'Data Duplicate'		AS Error_Message_ENG
					, N'ข้อมูลนี้ลงทะเบียนแล้ว'		AS Error_Message_THA	
					, ''					AS Handling

					RETURN

		END 
		ELSE
		BEGIN 

			INSERT INTO [APCSProDB].[man].[user_skill_cards]
					   ([user_id]
					   ,[emp_code]
					   ,[comment]
					   ,[expired_on]
					   ,[created_at]
					   ,[created_by])
				
			VALUES 
						(
						 @userID
						,@emp_code
						,@comment
						,'9999-12-31'
						,GETDATE ()
						,@created_by
			)

				 --SELECT	  'TRUE'		AS Is_Pass
					--	, 1				AS code
					--	, @role_name	AS parameter

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


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_regis_user_roles]
	-- Add the parameters for the stored procedure here
	  @UserID INT
	, @roleID INT
	, @created_by INT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
 	BEGIN TRANSACTION
	BEGIN TRY

	IF EXISTS (SELECT  'xx' FROM  [APCSProDB].[man].[user_roles] WHERE [user_id] = @UserID AND [role_id] = @roleID   )
	BEGIN  

				SELECT	  'FALSE'		AS Is_Pass
				, 'Data Duplicate'		AS Error_Message_ENG
				, N'ข้อมูลนี้ลงทะเบียนแล้ว'		AS Error_Message_THA	
				, ''					AS Handling

				RETURN

	END 
	ELSE

		BEGIN
		INSERT INTO [APCSProDB].[man].[user_roles] 
				  ([user_id]
				  ,[role_id]
				  ,[expired_on]
				  ,[created_at]
				  ,[created_by])
				VALUES (
				  @UserID
				 ,@roleID 
				 ,'9999-12-31'
				 ,GETDATE()
				 ,@created_by
				)

		INSERT INTO [APCSProDB].[man_hist].[user_roles_hist] 
					 ([category]
					,[user_id]
					,[role_id]
					,[expired_on]
					,[created_at]
					,[created_by])
			VALUES( 
					 '1'
					 ,@UserID
					 ,@roleID
					 ,'9999-12-31'
					 ,GETDATE()
					 ,@created_by)

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
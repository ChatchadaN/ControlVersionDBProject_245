
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_regis_roles]
	-- Add the parameters for the stored procedure here
	  @role_name VARCHAR(15)
	, @descriptions NVARCHAR(50)
	, @created_by INT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @num_id INT;

    -- Insert statements for procedure here
 	BEGIN TRANSACTION
	BEGIN TRY

	IF EXISTS (SELECT  'xx' FROM  [APCSProDB].[man].[roles] WHERE [name] = @role_name )
	BEGIN  

				SELECT	  'FALSE'		AS Is_Pass
				, 'Data Duplicate'		AS Error_Message_ENG
				, N'ข้อมูลนี้ลงทะเบียนแล้ว'		AS Error_Message_THA	
				, ''					AS Handling

				RETURN

	END 
	ELSE

		BEGIN
			
			  SET @num_id = (SELECT ISNULL(MAX([id]), 0) + 1
			  FROM [APCSProDB].[man].[numbers]
			  WHERE [name] = 'roles.id');

				INSERT INTO [APCSProDB].[man].[roles]
				   ([id]
				   ,[name]
				   ,[descriptions]
				   ,[validity_period]
				   ,[created_at]
				   ,[created_by])
				VALUES (
				  @num_id
				 ,@role_name
				,@descriptions
				,0
				,GETDATE()
				,@created_by
				)

UPDATE [APCSProDB].[man].[numbers] SET [ID] = @num_id WHERE [name] = 'roles.id'


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
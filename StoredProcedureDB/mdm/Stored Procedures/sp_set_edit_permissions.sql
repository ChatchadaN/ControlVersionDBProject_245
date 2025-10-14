


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_edit_permissions]
	-- Add the parameters for the stored procedure here
	 @id AS INT
   , @permiss_name VARCHAR(20)
   , @descriptions NVARCHAR(50)
   , @updated_by  INT
	
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		
	IF NOT EXISTS (SELECT  'xx' FROM  [APCSProDB].[man].[permissions] WHERE [name] = @permiss_name  AND descriptions = @descriptions)
	
		BEGIN  

				SELECT	  'FALSE'			AS Is_Pass
				, 'Data Not fund'			AS Error_Message_ENG
				, N'ไม่พบข้อมูลการลงทะเบียน'		AS Error_Message_THA	
				, ''						AS Handling

				RETURN

		END 
		ELSE
		BEGIN
	
			UPDATE [APCSProDB].[man].[permissions]
			SET [name]= @permiss_name  ,[descriptions] = @descriptions , [updated_at] = GETDATE(), 
			[updated_by] = @updated_by 
			WHERE [id] = @id

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
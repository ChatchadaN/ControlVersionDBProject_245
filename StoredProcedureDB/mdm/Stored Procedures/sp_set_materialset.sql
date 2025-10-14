-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_materialset]
	-- Add the parameters for the stored procedure here
	@name AS VARCHAR(250),
	@processid AS INT,
	@comment AS VARCHAR(MAX),
	@is_checking AS INT,
	@created_by AS INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	--Check Material Set Exists
	IF EXISTS(SELECT 1 FROM [APCSProDB].[method].[material_sets] WHERE name = @name AND process_id = @processid AND comment = @comment)BEGIN
		SELECT 'FALSE' AS Is_Pass,'Material Set is duplicate. !!' AS Error_Message_ENG,N'Material Set ไม่สามารถลงทะเบียนซ้ำกันได้ !!' AS Error_Message_THA
		RETURN
	END

	DECLARE @lastest_id_num AS INT = 0
	SET @lastest_id_num = (SELECT id + 1 FROM [APCSProDB].[method].[numbers] WHERE [name] = 'material_sets.id')
	
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [APCSProDB].[method].[material_sets]
			   ([id]
			   ,[name]
			   ,[process_id]
			   ,[comment]
			   ,[is_checking]
			   ,[created_at]
			   ,[created_by])		   
		 VALUES
			   (@lastest_id_num
			   ,@name
			   ,@processid
			   ,UPPER(@comment)
			   ,@is_checking
			   ,GETDATE()
			   ,@created_by)

		DECLARE @r AS INT
				set @r = @@ROWCOUNT
				UPDATE [APCSProDB].[method].[numbers]
				SET  id = id + @r
				WHERE name = 'material_sets.id'

		SELECT 'TRUE' AS Is_Pass ,'Success' AS Error_Message_ENG,N'บันทึกสำเร็จ' AS Error_Message_THA		
		,(SELECT id FROM [APCSProDB].[method].[numbers] WHERE name = 'material_sets.id') AS mat_id,@name AS set_name
		,(SELECT name  FROM [APCSProDB].[method].processes WHERE id = @processid) AS process_name
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Register fail. !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
	END CATCH
END


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_update_combine]
	-- Add the parameters for the stored procedure here
	@name				AS VARCHAR(250),
	@process_id			AS INT,
	@comment			AS VARCHAR(MAX),
	@is_checking		AS INT,
	@created_by			AS INT
	,@code				AS NVARCHAR(100) =  NULL

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	--Check Material Set Exists
	IF EXISTS(SELECT 1 FROM [APCSProDB].[method].jig_sets 
				WHERE name		 = @name 
				AND process_id	 = @process_id 
				AND comment		 = @comment 
				AND code		 = @code 
				AND [is_disable] = 0
				)
	BEGIN
		SELECT 'FALSE' AS Is_Pass,'Jig Set is duplicate. !!' AS Error_Message_ENG,N'Jig Set ไม่สามารถลงทะเบียนซ้ำกันได้ !!' AS Error_Message_THA
		RETURN
	END

	DECLARE @lastest_id_num AS INT = 0
	SET @lastest_id_num = (SELECT MAX([id]) + 1 as id FROM [APCSProDB].[method].[jig_sets])
	
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [APCSProDB].[method].jig_sets
			   ([id]
			   ,[name]
			   ,[process_id]
			   ,[product_family_id]
			   ,[code]
			   ,[comment]
			   ,[is_disable]
			   ,[created_at]
			   ,[created_by])		   
		 VALUES
			   (@lastest_id_num
			   ,@name
			   ,@process_id
			   , 1
			   ,@code
			   ,UPPER(@comment)
			   ,@is_checking
			   ,GETDATE()
			   ,@created_by)



		DECLARE @r AS INT
				set @r = @lastest_id_num
				UPDATE [APCSProDB].[method].[numbers]
				SET  id =   @r
				WHERE name =  'jig_sets.id'

		SELECT    'TRUE'				AS Is_Pass 
				, 'Success'				AS Error_Message_ENG
				, N'บันทึกสำเร็จ'			AS Error_Message_THA		
				, (SELECT id FROM [APCSProDB].[method].[numbers] WHERE name = 'jig_sets.id') AS jig_id
				,  @name				AS set_name
				, (SELECT name  FROM [APCSProDB].[method].processes WHERE id = @process_id) AS process_name
				, @process_id			AS process_id
				, code  
				, comment
				FROM [APCSProDB].[method].jig_sets
				WHERE id  = @lastest_id_num

		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Register fail. !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
	END CATCH
END

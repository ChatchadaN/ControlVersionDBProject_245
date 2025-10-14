-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_add_recipe_bm_case]
	-- Add the parameters for the stored procedure here
	 @recipe_name varchar(20)
	,@machine_model_id int
	,@bm_case_id int
	,@pm_no varchar(10)
	,@mc_no varchar(20)
	,@app_name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT EXISTS (SELECT 1 FROM APCSProDB.method.recipe_names 
				WHERE recipe_names.name = @recipe_name and recipe_names.machine_model_id = @machine_model_id) BEGIN
		SELECT 'FALSE' AS Is_Pass ,'Recipe Name is not found. !!' AS Error_Message_ENG,N'ไม่พบข้อมูล Recipe Name นี้ !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ MDM' AS Handling
		RETURN
	END

	IF EXISTS (SELECT 1 FROM DBx.dbo.recipe_bm_case WHERE bm_case_id = @bm_case_id) BEGIN
	    SELECT 'FALSE' AS Is_Pass ,'BM case is duplicate data. !!' AS Error_Message_ENG,N'BM case นี้ถูกบันทึกแล้ว !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ MDM' AS Handling
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM APCSProDB.mc.machines WHERE name = @mc_no) BEGIN
		SELECT 'FALSE' AS Is_Pass ,'Machine Name is not found. !!' AS Error_Message_ENG,N'ไม่พบข้อมูล machine เครื่องนี้ !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ MDM' AS Handling
		RETURN
	END
	
	BEGIN TRANSACTION
	BEGIN TRY
		   DECLARE @recipe_name_id as int = (SELECT recipe_names.id FROM APCSProDB.method.recipe_names 
											WHERE recipe_names.name = @recipe_name and recipe_names.machine_model_id = @machine_model_id);

		   INSERT INTO [DBX].[dbo].[recipe_bm_case]
			   ([bm_case_id]
			   ,[pm_id]
			   ,[recipe_name_id]
			   ,[created_at]
			   ,[created_by]
			   ,[machine_id])
			VALUES
			   (@bm_case_id 
			   ,(SELECT id FROM APCSProDB.man.users WHERE emp_num =  @pm_no )
			   ,@recipe_name_id 
			   ,GETDATE() 
			   ,1
			   ,(SELECT id FROM APCSProDB.mc.machines WHERE name = @mc_no))

			INSERT INTO [DBX].[dbo].[recipe_bm_case_records]
			   ([recipe_bm_case_id]
			   ,[bm_case_id]
			   ,[pm_id]
			   ,[recipe_name_id]
			   ,[status]
			   ,[created_at]
			   ,[created_by]
			   ,[machine_id])
				
			SELECT TOP 1 id 
				,bm_case_id
				,pm_id
			    ,recipe_name_id
				,status
			    ,created_at
			    ,created_by
				,machine_id
				FROM DBx.dbo.recipe_bm_case WHERE bm_case_id = @bm_case_id and recipe_name_id = @recipe_name_id 
				


		   SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA, N'' AS Handling,id as recipe_bm_case_id
		   FROM DBx.dbo.recipe_bm_case WHERE bm_case_id = @bm_case_id and recipe_name_id = @recipe_name_id
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Update fail. !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA, N'กรุณาติดต่อ System' AS Handling--, ERROR_MESSAGE() AS System_error
	END CATCH

END

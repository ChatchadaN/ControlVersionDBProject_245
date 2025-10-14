-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_cancel_recipe_bm_case]
	-- Add the parameters for the stored procedure here
	 @bm_case_id INT
	,@recipe_name varchar(20)
	,@machine_model_id INT 
	,@cancel_by varchar(10)
	,@mc_no varchar(20)
	,@app_name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT EXISTS (SELECT 1 FROM APCSProDB.method.recipe_names rn	
				WHERE rn.name = @recipe_name  and rn.machine_model_id = @machine_model_id) BEGIN
		SELECT 'FALSE' AS Is_Pass ,'Recipe Name is not found. !!' AS Error_Message_ENG,N'ไม่พบข้อมูล Recipe Name นี้ !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ MDM' AS Handling
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM DBx.dbo.recipe_bm_case rbc 				
			INNER JOIN APCSProDB.method.recipe_names rn ON rbc.recipe_name_id = rn.id
			WHERE rbc.bm_case_id = @bm_case_id AND rn.name = @recipe_name and rn.machine_model_id = @machine_model_id) BEGIN
	    SELECT 'FALSE' AS Is_Pass ,'Data recipe BM case is not found. !!' AS Error_Message_ENG,N'ไม่พบข้อมูล recipe BM case นี้ !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ MDM' AS Handling
		RETURN
	END
	
	BEGIN TRANSACTION
	BEGIN TRY
		   DECLARE @recipe_bm_case_id as int = (SELECT rbc.id FROM DBx.dbo.recipe_bm_case rbc 
				INNER JOIN APCSProDB.method.recipe_names rn ON rbc.recipe_name_id = rn.id
			WHERE rbc.bm_case_id = @bm_case_id AND rn.name = @recipe_name and rn.machine_model_id = @machine_model_id);


		UPDATE [DBx].[dbo].[recipe_bm_case]
			SET status = 2
				,[updated_at] = GETDATE()
				,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @cancel_by)
		WHERE recipe_bm_case.id = @recipe_bm_case_id

		
    	INSERT INTO [DBX].[dbo].[recipe_bm_case_records]
    	   ([recipe_bm_case_id]
    	   ,[bm_case_id]
    	   ,[pm_id]
    	   ,[recipe_name_id]
		   ,[status]
    	   ,[created_at]
    	   ,[created_by])
    		
    	SELECT TOP 1 id 
    		,bm_case_id
    		,pm_id
    	    ,recipe_name_id
			,status
    	    ,created_at
    	    ,created_by
    		FROM DBx.dbo.recipe_bm_case WHERE recipe_bm_case.id = @recipe_bm_case_id

		   SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA, N'' AS Handling
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Update fail. !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA, N'กรุณาติดต่อ System' AS Handling
	END CATCH

END

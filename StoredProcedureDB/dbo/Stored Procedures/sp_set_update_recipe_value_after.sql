-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_update_recipe_value_after]
	-- Add the parameters for the stored procedure here
	 @bm_case_id INT
	,@recipe_name varchar(20)
	,@recipe_item_no  INT
	,@machine_model_id INT 
	,@act_value_after DECIMAL(18,6)
	,@pm_no varchar(10)
	,@mc_no varchar(20)
	,@app_name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT EXISTS (SELECT 1 FROM APCSProDB.method.recipe_names rn
					INNER JOIN APCSProDB.method.recipe_name_items rni ON rn.id = rni.recipe_name_id
					INNER JOIN APCSProDB.method.recipe_items ri ON rni.recipe_item_id = ri.id
				WHERE rn.name = @recipe_name and ri.item_no = @recipe_item_no and rn.machine_model_id = @machine_model_id) BEGIN
		SELECT 'FALSE' AS Is_Pass ,'Recipe Name is not found. !!' AS Error_Message_ENG,N'ไม่พบข้อมูล Recipe Name นี้ !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ MDM' AS Handling
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM DBx.dbo.recipe_bm_case rbc WHERE bm_case_id = @bm_case_id) BEGIN
	    SELECT 'FALSE' AS Is_Pass ,'Data recipe BM case is not found. !!' AS Error_Message_ENG,N'ไม่พบข้อมูล recipe BM case นี้ !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ MDM' AS Handling
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM DBx.dbo.recipe_bm_case rbc 
				INNER JOIN DBx.dbo.recipe_bm_case_details rbcd ON rbc.id = rbcd.recipe_bm_case_id
				INNER JOIN APCSProDB.method.recipe_names rn ON rbcd.recipe_name_id = rn.id
				INNER JOIN APCSProDB.method.recipe_items ri ON rbcd.recipe_item_id = ri.id
			WHERE rbc.bm_case_id = @bm_case_id AND rn.name = @recipe_name AND ri.item_no = @recipe_item_no) BEGIN
	    SELECT 'FALSE' AS Is_Pass ,'Item number is not found. !!' AS Error_Message_ENG,N'ไม่พบข้อมูล Item number นี้ !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ MDM' AS Handling
		RETURN
	END
	
	BEGIN TRANSACTION
	BEGIN TRY
		   DECLARE @recipe_bm_case_detail_id as int = (SELECT rbcd.id FROM DBx.dbo.recipe_bm_case rbc 
				INNER JOIN DBx.dbo.recipe_bm_case_details rbcd ON rbc.id = rbcd.recipe_bm_case_id
				INNER JOIN APCSProDB.method.recipe_names rn ON rbcd.recipe_name_id = rn.id
				INNER JOIN APCSProDB.method.recipe_items ri ON rbcd.recipe_item_id = ri.id
			WHERE rbc.bm_case_id = @bm_case_id AND rn.name = @recipe_name AND ri.item_no = @recipe_item_no AND rn.machine_model_id = @machine_model_id);
		
			DECLARE @emp_id as int = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @pm_no)

		UPDATE [DBx].[dbo].[recipe_bm_case_details]
			SET act_value_after = @act_value_after
				,[updated_at] = GETDATE()
				,[updated_by] = @emp_id
		WHERE recipe_bm_case_details.id = @recipe_bm_case_detail_id

		
		INSERT INTO [DBx].[dbo].[recipe_bm_case_detail_records]
           (detail_id
		   ,[recipe_bm_case_id]
           ,[recipe_name_id]
           ,[recipe_item_id]
           ,[act_value_before]
           ,[act_value_after]
           ,[min_value]
           ,[max_value]
           ,[target_value]
		   ,[is_confirm]
           ,[confirm_by]
           ,[remark]
           ,[created_at]
           ,[created_by]
		   ,[updated_at]
		   ,[updated_by]
		   )

		SELECT TOP 1 rbcd.id
		   ,rbcd.recipe_bm_case_id
           ,rbcd.recipe_name_id
           ,rbcd.recipe_item_id
           ,rbcd.act_value_before
           ,rbcd.act_value_after
           ,rbcd.min_value
           ,rbcd.max_value
           ,rbcd.target_value
		   ,rbcd.is_confirm
           ,rbcd.confirm_by
           ,rbcd.remark
           ,rbcd.created_at
           ,rbcd.created_by
		   ,rbcd.updated_at
		   ,rbcd.updated_by
		FROM DBx.dbo.recipe_bm_case_details rbcd 
		WHERE rbcd.id = @recipe_bm_case_detail_id


		   SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA, N'' AS Handling
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Update fail. !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA, N'กรุณาติดต่อ System' AS Handling
	END CATCH

END

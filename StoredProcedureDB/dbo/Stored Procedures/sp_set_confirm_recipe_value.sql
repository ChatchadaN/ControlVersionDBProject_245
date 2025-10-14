-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_confirm_recipe_value]
	-- Add the parameters for the stored procedure here
	 @recipe_bm_case_id INT
	,@recipe_bm_case_detail_id INT
	,@confirm_by varchar(10)
	,@remark varchar(255) = NULL
	,@mc_no varchar(20)
	,@app_name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	IF NOT EXISTS (SELECT 1 FROM DBx.dbo.recipe_bm_case_details  WHERE id = @recipe_bm_case_detail_id) BEGIN
	    SELECT 'FALSE' AS Is_Pass ,'Data recipe BM case is not found. !!' AS Error_Message_ENG,N'ไม่พบข้อมูล recipe BM case นี้ !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ MDM' AS Handling
		RETURN
	END
	
	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @emp_id as int = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @confirm_by)

		UPDATE [DBx].[dbo].[recipe_bm_case_details]
			SET is_confirm = 1
				,remark = @remark
				,[confirm_by] = @emp_id
				,[updated_at] = GETDATE()
				,[updated_by] = @emp_id
		WHERE recipe_bm_case_details.recipe_bm_case_id = @recipe_bm_case_id AND recipe_bm_case_details.id = @recipe_bm_case_detail_id

		
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
		WHERE rbcd.recipe_bm_case_id = @recipe_bm_case_id AND rbcd.id = @recipe_bm_case_detail_id 


--//////////////// update status = success  when confirm all item_no /////////////////////
		IF NOT EXISTS (SELECT 1 FROM DBx.dbo.recipe_bm_case_details rbcd WHERE rbcd.recipe_bm_case_id = @recipe_bm_case_id AND is_confirm = 0) BEGIN
			UPDATE [DBx].[dbo].[recipe_bm_case]
			SET status = 1
				,[updated_at] = GETDATE()
				,[updated_by] = @emp_id
			WHERE id = @recipe_bm_case_id

			INSERT INTO [DBX].[dbo].[recipe_bm_case_records]
			   ([recipe_bm_case_id]
			   ,[bm_case_id]
			   ,[pm_id]
			   --,[tp_code]
			   ,[recipe_name_id]
			   ,[created_at]
			   ,[created_by])	
			   
			SELECT TOP 1 id 
				,bm_case_id
				,pm_id
				--,tp_code
			    ,recipe_name_id
			    ,created_at
			    ,created_by
			FROM DBx.dbo.recipe_bm_case WHERE id = @recipe_bm_case_id
		END

		   SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA, N'' AS Handling
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Update fail. !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA, N'กรุณาติดต่อ System' AS Handling
	END CATCH

END

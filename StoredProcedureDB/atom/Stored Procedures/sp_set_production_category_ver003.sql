-- =============================================
-- Author:		<Author,,Name: Vanatjaya P. 009131>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_production_category_ver003]
	-- Add the parameters for the stored procedure here
	 @lot_id varchar(10)
	,@update_by varchar(20)
	,@is_clear tinyint = 0  --0 : save , 1 : clear
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	BEGIN TRANSACTION
	BEGIN TRY

		DECLARE @update_at varchar(50);
		DECLARE @r INT = 0;
		DECLARE @lot_type VARCHAR(10);
		DECLARE @result VARCHAR(10);
		DECLARE @production_category TINYINT = NULL;

		-- หาค่า lot_type จาก table lots และ item_labels
		SELECT 
			 @lot_type = (SUBSTRING(lot_no, PATINDEX('%[A-Z]%', lot_no), 1))
			,@production_category = production_category
		FROM APCSProDB.trans.lots
		WHERE id = @lot_id;

		IF @lot_type = 'D'
		BEGIN
			--Add condition 2024/12/20 Time : 11.06 By Aomsin (Support งาน ที่รัน Hasuu เพื่อเก็บเข้า Stock)
			IF @production_category = 23  
			BEGIN
				UPDATE [APCSProDB].[trans].[lots] 
				SET [production_category] = 22
				WHERE id = @lot_id
				COMMIT TRANSACTION;

				SELECT 'TRUE' AS Is_Pass 
				  ,'Change production_category is 22 Successfully !!' AS Error_Message_ENG
				  ,N'เปลี่ยน production_category เป็น 22 สำเร็จ !!' AS Error_Message_THA 
				  ,'' AS Handling	
				RETURN
			END
			ELSE
			BEGIN
				COMMIT TRANSACTION;
				SELECT 'FALSE' AS Is_Pass 
				  ,'Cannot change production_category : D !!' AS Error_Message_ENG
				  ,N'ไม่สามารถเปลี่ยน production_category : D ได้ !!' AS Error_Message_THA 
				  ,'' AS Handling	
				RETURN
			END
		END
	
		IF @is_clear = 0
		BEGIN
			SET @result = '31'
		END
		ELSE
		BEGIN
			SELECT @result = val 
			FROM APCSProDB.trans.item_labels
			WHERE [name] = 'lots.production_category'
			AND label_eng = @lot_type
		END

		--IF @is_clear = 0 BEGIN
		set @update_at = GETDATE();

		-- Insert statements for procedure here
		update [APCSProDB].[trans].[lots] 
		--set [lots].production_category = (CASE WHEN @is_clear = 0 THEN 30 ELSE 0 END)--@ProCate
		SET [lots].production_category = @result
		where [lots].id = @lot_id;

		--Insert log at trans.lots_process_record by lots.id
		INSERT INTO [APCSProDB].[trans].[lot_process_records](
		[id]
		  ,[day_id]
		  ,[recorded_at]
		  ,[operated_by]
		  ,[record_class]
		  ,[lot_id]
		  ,[process_id]
		  ,[job_id]
		  ,[step_no]
		  ,[qty_in]
		  ,[qty_pass]
		  ,[qty_fail]
		  ,[qty_last_pass]
		  ,[qty_last_fail]
		  ,[qty_pass_step_sum]
		  ,[qty_fail_step_sum]
		  ,[qty_divided]
		  ,[qty_hasuu]
		  ,[qty_out]
		  ,[recipe]
		  ,[recipe_version]
		  ,[machine_id]
		  ,[position_id]
		  ,[process_job_id]
		  ,[is_onlined]
		  ,[dbx_id]
		  ,[wip_state]
		  ,[process_state]
		  ,[quality_state]
		  ,[first_ins_state]
		  ,[final_ins_state]
		  ,[is_special_flow]
		  ,[special_flow_id]
		  ,[is_temp_devided]
		  ,[temp_devided_count]
		  ,[container_no]
		  ,[extend_data]
		  ,[std_time_sum]
		  ,[pass_plan_time]
		  ,[pass_plan_time_up]
		  ,[origin_material_id]
		  ,[treatment_time]
		  ,[wait_time]
		  ,[qc_comment_id]
		  ,[qc_memo_id]
		  ,[created_at]
		  ,[created_by]
		  ,[updated_at]
		  ,[updated_by]
		  ,production_category
		  )
			SELECT [nu].[id] + row_number() over (order by [lots].[id])
			, [days].[id] [day_id]
			, @update_at as [recorded_at]
			, @update_by as [operated_by]
			, 120 as [record_class]
			, [lots].[id] as [lot_id]
			, [act_process_id] as [process_id]
			, [act_job_id] as [job_id]
			, [step_no] as [step_no]
			, [qty_in]
			, [qty_pass]
			, [qty_fail]
			, [qty_last_pass]
			, [qty_last_fail]
			, [qty_pass_step_sum]
			, [qty_fail_step_sum]
			, [qty_divided]
			, [qty_hasuu]
			, [qty_out]
			, NULL as [recipe]
			, 1 as [recipe_version]
			, [machine_id]
			, NULL as [position_id]
			, [process_job_id]
			, 0 as [is_onlined]
			, 0 as [dbx_id]
			, [wip_state]
			, [process_state]
			, [quality_state]
			, [first_ins_state]
			, [final_ins_state]
			, [is_special_flow]
			, [special_flow_id]
			, [is_temp_devided]
			, [temp_devided_count]
			, [container_no]
			, NULL as [extend_data]
			, [std_time_sum]
			, [pass_plan_time]
			, [pass_plan_time_up]
			, [origin_material_id]
			, NULL as [treatment_time]
			, NULL as [wait_time]
			, [qc_comment_id]
			, [qc_memo_id]
			, [created_at]
			, [created_by]
			, @update_at as [updated_at]
			, @update_by as [updated_by]
			--, (CASE WHEN @is_clear = 0 THEN 30 ELSE 0 END)
			, @result
			FROM [APCSProDB].[trans].[lots] 
			INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
			INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
			WHERE [lots].[id] = @lot_id
	

		SET @r = @@ROWCOUNT
		 UPDATE [APCSProDB].[trans].[numbers]
		 SET [id] = [id] + @r
		 WHERE [name] = 'lot_process_records.id'

		SELECT 'TRUE' AS Is_Pass ,'Register Successfully !!' AS Error_Message_ENG,N'การลงทะเบียนสำเร็จ !!' AS Error_Message_THA	,'' AS Handling	
		COMMIT;

	END TRY
	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Register fail. !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA ,'' AS Handling	
	END CATCH
END
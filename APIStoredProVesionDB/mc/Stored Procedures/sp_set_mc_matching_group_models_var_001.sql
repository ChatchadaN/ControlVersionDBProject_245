

-- =============================================
-- Author:		<Nutchanat K.>
-- Create date: <11/08/2025>
-- Description:	<mc_matching_group_models>
-- =============================================
CREATE PROCEDURE [mc].[sp_set_mc_matching_group_models_var_001]
	-- Add the parameters for the stored procedure here
	  @machine_group_id INT
	, @machine_model_id INT
	, @created_by INT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
			
		IF NOT EXISTS (SELECT  'xx' FROM  [DWH].[mc].[group_models] WHERE machine_group_id = @machine_group_id  AND machine_group_id = @machine_group_id)
		BEGIN  

					SELECT	  'FALSE'			AS Is_Pass
					, 'Data Not fund'			AS Error_Message_ENG
					, N'ไม่พบข้อมูลการลงทะเบียน'		AS Error_Message_THA	
					, ''						AS Handling

					RETURN

		END 
		ELSE

		BEGIN 
				INSERT INTO [DWH].[mc].[group_models]
						([machine_group_id]
						,[machine_model_id]
						,[created_at]
						,[created_by])
				VALUES (
					 @machine_group_id
					,@machine_model_id
					,GETDATE()
					,@created_by
					)

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

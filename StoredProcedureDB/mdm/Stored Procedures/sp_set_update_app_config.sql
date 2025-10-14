-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_update_app_config]
	-- Add the parameters for the stored procedure here
	@id AS INT,
	@app_name_e AS  VARCHAR(max),
	@comment_e AS VARCHAR(max),
	@function_name_e AS VARCHAR(max),
	@is_use_e AS VARCHAR(max),
	@factory_code AS VARCHAR(max),
	@config_path_e AS VARCHAR(max),
	@updated_by AS INT,
	@is_disable_e AS INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		UPDATE [APCSProDB].[cellcon].[config_functions]
		SET [app_name] = @app_name_e, [comment] = @comment_e, [function_name] = @function_name_e,
		[is_use] = @is_use_e, [factory_code] = @factory_code, [value] = @config_path_e,
		[updated_at] = GETDATE(), [updated_by] = @updated_by ,[is_disabled] = @is_disable_e
		WHERE [id] = @id

		COMMIT; 
		SELECT 'TRUE' AS Is_Pass, 'Successed !!' AS Error_Message_ENG, N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA		
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass, 'Update Faild !!' AS Error_Message_ENG, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
	END CATCH
END
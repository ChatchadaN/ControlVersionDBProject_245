-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_update_error_alarm]
	-- Add the parameters for the stored procedure here
	@app_name_e AS VARCHAR(max),
	@code_e AS INT,
	@language_e AS NVARCHAR(max),
	@message_e AS NVARCHAR(max),
	@cause_e AS NVARCHAR(max),
	@handling_e AS NVARCHAR(max),
	@information_code_e AS VARCHAR(max),
	@comment_e AS NVARCHAR(max)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		UPDATE [APCSProDB].[mdm].[errors] SET [message] = @message_e ,[cause] = @cause_e,[handling] = @handling_e
        ,[information_code] = @information_code_e,[comment] = @comment_e,[created_at] = GETDATE()
        WHERE [app_name] = @app_name_e and [code] = @code_e and [lang] = @language_e

		COMMIT; 
		SELECT 'TRUE' AS Is_Pass, 'Successed !!' AS Error_Message_ENG, N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA		
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass, 'Update Faild !!' AS Error_Message_ENG, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
	END CATCH
END
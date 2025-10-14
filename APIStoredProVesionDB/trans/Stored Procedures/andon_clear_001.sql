-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[andon_clear_001] 
		@id				INT,
		@comment_id		INT = NULL,
		@gl_emp_code	VARCHAR(6)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE	@emp_id INT;
	
	SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @gl_emp_code

	IF @id IS NULL
	BEGIN 
					SELECT    'FALSE'				AS Is_Pass 
							, 'No Andon ID !!'		AS Error_Message_ENG
							, N'ไม่มี Andon ID !!'	AS Error_Message_THA
							, ''					AS Handling
			RETURN
	END
	ELSE 
		BEGIN TRANSACTION
		BEGIN TRY

					UPDATE  [APCSProDB].[trans].[andon_controls]  
					SET 	[is_solved] = 1,
							[comment_id_at_finding] = CASE WHEN @comment_id IS NOT NULL THEN @comment_id ELSE [comment_id_at_finding] END, 
							[updated_at] = GETDATE(), 
							[updated_by] = @emp_id
					WHERE [id] = @id

					SELECT    'TRUE'		 AS Is_Pass 
							, 'Success'		 AS Error_Message_ENG
							, N'บันทึกสำเร็จ'    AS Error_Message_THA	
							, ''			 AS Handling

			COMMIT; 
			RETURN

		END TRY
		BEGIN CATCH
			ROLLBACK;

					SELECT    'FALSE'					AS Is_Pass 
							, 'Recording fail. !!'		AS Error_Message_ENG
							, N'การบันทึกผิดพลาด !!'		AS Error_Message_THA
							,  ''						AS Handling
		END CATCH
		   		 
END
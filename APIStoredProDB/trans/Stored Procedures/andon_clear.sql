-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[andon_clear]  
	@id INT,
	@comment_id INT = NULL,
	@gl_emp_code VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    EXEC [APIStoredProVersionDB].[trans].[andon_clear_001]
		@id = @id,
		@comment_id = @comment_id,
		@gl_emp_code = @gl_emp_code

END

-- =============================================
-- Author:		<Author, Yutida P.>
-- Create date: <Create Date, 16 July 2025>
-- Description:	<Description, Get flow patterns>
-- =============================================
CREATE PROCEDURE [material].[sp_get_productions]
	@id INT = 0, @category_id INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_productions_ver_001]
			@id = @id,
			@category_id = @category_id

END

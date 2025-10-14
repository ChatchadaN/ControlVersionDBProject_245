-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_product_families_ver_001]
	@factory_id INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(255);

	SET @SQL = 'SELECT [id],[name], * 
				FROM [APCSProDB].[man].[product_families]
				WHERE 1 = 1 ';
	IF (ISNULL(@factory_id,'') <> '')
	BEGIN
		SET @SQL += ' AND factory_id = ' + CONVERT(nvarchar, @factory_id);
	END

	EXEC sp_executesql @SQL; 

END

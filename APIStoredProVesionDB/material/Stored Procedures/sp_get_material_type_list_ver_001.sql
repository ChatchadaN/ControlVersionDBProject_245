-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_material_type_list_ver_001]
	@product_family_id INT = NULL,
	@category_id INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT  Id , name , product_family_id, category_id
	FROM [APCSProDB_lsi_110].[material].[productions]
	WHERE (category_id = @category_id OR ISNULL(@category_id,0) = 0)
	AND (product_family_id = @product_family_id OR ISNULL(@product_family_id,0) = 0)

	/* 
	DECLARE @SQL NVARCHAR(255);

	SET @SQL = N'SELECT  Id , name , product_family_id, category_id
			FROM [APCSProDB_lsi_110].[material].[productions]
			WHERE 1=1';

	IF (ISNULL(@product_family_id,'') <> '' AND @product_family_id <> 0)
	BEGIN
		SET @SQL += ' AND product_family_id = ' + CONVERT(NVARCHAR, @product_family_id);
	END

	IF (ISNULL(@category_id,'') <> '' AND @category_id <> 0)
	BEGIN
		SET @SQL += ' AND category_id = ' + CONVERT(NVARCHAR, @category_id);
	END

	EXEC sp_executesql @SQL;
	*/

END

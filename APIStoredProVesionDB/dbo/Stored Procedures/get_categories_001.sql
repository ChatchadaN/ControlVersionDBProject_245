-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[get_categories_001] 
	@category_id INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF @category_id IS NULL
		SELECT  [id], [name], ISNULL( [description] ,'') AS [description] 
		FROM [AppDB_app_244].[dbo].[categories]
		WHERE [is_disable] = 0
	ELSE 
		SELECT	  sub_cat.[id]			 
				, sub_cat.[name]		 
				, ISNULL(sub_cat.[description] ,'') AS [description]
		FROM [AppDB_app_244].[dbo].[categories]		cat
		JOIN [AppDB_app_244].[dbo].[sub_categories] sub_cat 
		ON cat.id = sub_cat.category_id
		WHERE cat.id = @category_id 
		OR  @category_id IS NULL
		AND sub_cat.[is_disable] = 0

END
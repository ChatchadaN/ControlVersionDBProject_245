-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_categories_ver_001]
	@id INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [id],[name] , short_name
	FROM [APCSProDB].[material].[categories]
	WHERE ([id] =  @id OR ISNULL(@id, 0) = 0);

	/*
	IF (ISNULL(@id,'') <> '' AND @id <> 0)
	BEGIN
		SELECT [id],[name]
		FROM [APCSProDB_lsi_110].[material].[categories]
		WHERE [id] = @id;
	END
	ELSE
	BEGIN
		SELECT [id],[name]
		FROM [APCSProDB_lsi_110].[material].[categories];
	END

    */

END

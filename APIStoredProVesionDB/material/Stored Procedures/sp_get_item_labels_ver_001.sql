-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_item_labels_ver_001]
	@name varchar(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SELECT [name]
		  ,[val]
		  ,[label_eng]
		  ,[label_jpn]
		  ,[label_sub]
		  ,[color_code]
	FROM [APCSProDB].[material].[item_labels]  
	WHERE ([name] = @name OR @name IS NULL)


END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_capillary_data] 
	-- Add the parameters for the stored procedure here
	@id int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET @id = CASE WHEN  @id = 0 THEN NULL ELSE @id  END  
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [capillary_recipes].[id]
      ,[production_id]
	  ,productions.name as production_name
      ,[wb_code]
      ,[capillary_recipes].[created_at]
      ,[capillary_recipes].[created_by]
      ,[capillary_recipes].[updated_at]
      ,[capillary_recipes].[updated_by]
  FROM [APCSProDB].[jig].[capillary_recipes]
  INNER JOIN APCSProDB.jig.productions ON capillary_recipes.production_id = productions.id
  WHERE [capillary_recipes].[id] =  @id  OR  @id  IS NULL 
END

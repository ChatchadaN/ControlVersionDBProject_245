

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_productions]
	-- Add the parameters for the stored procedure here
	@id AS INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT productions.id
		,productions.name AS production 
		,suppliers.name AS supplier 
		,code  
		,categories.name  AS categories
		,productions.updated_by
		,productions.created_by
		FROM [APCSProDB].[material].[productions]  
		inner join [APCSProDB].[material].[categories] on productions.category_id = categories.id
		inner join [APCSProDB].[material].[suppliers] on productions.supplier_cd = suppliers.supplier_cd 
		WHERE (productions.id LIKE '%' AND @id = 0) OR (productions.id = @id AND @id <> 0)
	END
END
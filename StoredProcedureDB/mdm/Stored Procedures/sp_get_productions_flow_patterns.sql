



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_productions_flow_patterns]
	-- Add the parameters for the stored procedure here
	@id AS INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT flow_patterns.[id]
		,product_families.Name As ProducrtFamily
		,categories.name
		,[link_flow_no]
		,[comments]
		,[version_num]
		,[is_released]
		,flow_patterns.[created_at] 
		,flow_patterns.[created_by] 
		,flow_patterns.[updated_at]
		,flow_patterns.[updated_by]
		FROM [APCSProDB].[material].[flow_patterns] 
		inner join [APCSProDB].[material].[categories] on flow_patterns.category_id = categories.id
		inner join [APCSProDB].[man].[product_families] on flow_patterns.product_family_id = product_families.id
		WHERE (flow_patterns.id LIKE '%' AND @id = 0) OR (flow_patterns.id = @id AND @id <> 0)
	END
END
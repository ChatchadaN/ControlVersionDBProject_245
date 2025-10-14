


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_productions_slip]
	-- Add the parameters for the stored procedure here
	@id AS INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT slip_id 
		,product_slips.production_id
		,productions.name
		,product_slips.flow_pattern_id
		,flow_patterns.comments
		,product_slips.version_num
		,product_slips.input_type_id
		,product_slips.is_released
		,product_slips.created_at
		,product_slips.created_by
		,product_slips.updated_at
		,product_slips.updated_by
		FROM APCSProDB.material.product_slips 
		inner join [APCSProDB].[material].[productions] on product_slips.production_id = productions.id
		inner join [APCSProDB].[material].[flow_patterns] on product_slips.flow_pattern_id = flow_patterns.id
		WHERE (slip_id LIKE '%' AND @id = 0) OR (slip_id = @id AND @id <> 0)
	END
END
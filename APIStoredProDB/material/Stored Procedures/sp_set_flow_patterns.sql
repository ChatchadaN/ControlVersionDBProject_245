-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_flow_patterns]
	@id INT = 0, @product_family_id INT, @category_id INT, @link_flow_no decimal(4, 0), @version_num INT, @is_released INT, @emp_code VARCHAR(6), @comment NVARCHAR(255) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_flow_patterns_001]
			@id= @id,
			@product_family_id = @product_family_id,
			@category_id = @category_id,
			@link_flow_no = @link_flow_no,
			@version_num = @version_num,
			@is_released = @is_released,
			@emp_code = @emp_code,
			@comment = @comment

END

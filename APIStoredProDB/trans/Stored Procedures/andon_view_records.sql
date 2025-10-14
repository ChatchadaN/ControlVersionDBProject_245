-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[andon_view_records]
		@location_id INT = NULL,
		@machine_id INT = NULL,
		@category_id INT = NULL,
		@sub_cate_id INT = NULL,
		@abnomal_id INT = NULL,
		@item VARCHAR(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    EXEC [APIStoredProVersionDB].[trans].[andon_view_records_001]
		@location_id = @location_id,
		@machine_id = @machine_id,
		@category_id = @category_id,
		@sub_cate_id = @sub_cate_id,
		@abnomal_id = @abnomal_id,
		@item = @item

END

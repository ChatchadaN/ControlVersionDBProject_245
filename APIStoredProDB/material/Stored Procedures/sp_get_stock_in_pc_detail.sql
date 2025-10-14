
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/07/31>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_get_stock_in_pc_detail]
		@po_id			INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_stock_in_pc_detail_001]
		@po_id		= @po_id	 

END

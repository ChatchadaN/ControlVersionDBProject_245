
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/08/22>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_get_stock_in_pd_detail]
		 @material_outgoings_id			INT 
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_stock_in_pd_detail_001]
		 @material_outgoings_id			= @material_outgoings_id	
	 

END


-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/08/20>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_set_stock_in_pd]
		  @material_outgoings_id	INT
		, @emp_id					INT
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_stock_in_pd_001]
		 @material_outgoings_id	= @material_outgoings_id
		 ,@emp_id				= @emp_id				

END

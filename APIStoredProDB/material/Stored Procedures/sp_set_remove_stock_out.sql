
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/08/29>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_set_remove_stock_out]
		  @material_id				NVARCHAR(255) 
		, @emp_id					INT	
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_remove_stock_out_001]
		  @material_id	= @material_id	
		, @emp_id		= @emp_id		

		 
END

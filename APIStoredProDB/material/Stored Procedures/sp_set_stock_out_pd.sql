
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/08/20>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_set_stock_out_pd]
		  @from_location_id			INT
		, @to_location_id			INT
		, @material_id				NVARCHAR(255) 
		, @emp_id					INT	
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_stock_out_pd_001]
		  @from_location_id	=  @from_location_id	 
		, @to_location_id	=  @to_location_id	 
		, @material_id		=  @material_id		 
		, @emp_id			=  @emp_id			 

END

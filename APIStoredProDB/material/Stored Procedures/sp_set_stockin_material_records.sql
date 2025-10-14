
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/08/20>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_set_stockin_material_records]
		  
		  @material_id				INT 		 
		, @emp_id					INT  
		, @from_location_id			INT 
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_stockin_material_records_001]
		  @material_id			=  @material_id		
		, @emp_id				=  @emp_id			
		, @from_location_id		=  @from_location_id




END	
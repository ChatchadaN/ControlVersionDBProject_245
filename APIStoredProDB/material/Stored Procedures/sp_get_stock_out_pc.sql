
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/07/31>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_get_stock_out_pc]
		 @location_id			INT 
		, @production_id		INT = 0
		, @material_state		INT = 0
		, @process_state		INT = 0
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_stock_out_pc_001]
			@location_id	=  @location_id			 
		, @production_id	=  @production_id		 
		, @material_state	=  @material_state		 
		, @process_state	=  @process_state		 

END

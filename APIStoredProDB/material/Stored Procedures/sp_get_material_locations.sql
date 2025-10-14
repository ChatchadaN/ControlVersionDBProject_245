-- =============================================
-- Author:		<Author, Yutida P.>
-- Create date: <Create Date, 16 July 2025>
-- Description:	<Description, Get flow patterns>
-- =============================================
CREATE PROCEDURE [material].[sp_get_material_locations]
		 
		 @locations_id			INT  = 0
		, @headquarter_id		INT  = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_material_locations_001]
			@locations_id = @locations_id
			, @headquarter_id  = @headquarter_id
END

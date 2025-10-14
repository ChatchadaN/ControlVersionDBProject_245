-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_material_repack]

		@location_id  			INT
	  , @emp_id					INT  = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_material_repack_001]
				@location_id  	= @location_id
			  , @emp_id			= @emp_id		 


END

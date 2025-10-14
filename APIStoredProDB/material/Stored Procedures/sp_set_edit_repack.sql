-- =============================================
-- Author:		<Author, Sadanan B.>
-- Create date: <Create Date, 30 09 2025>
-- Description:	<Description, Get flow patterns>
-- =============================================
CREATE PROCEDURE [material].[sp_set_edit_repack]

	  @material_repack_file_id		INT 
	, @repack_qty					INT  
	, @pack_unit_qty				INT 
	, @emp_id						INT			= 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_edit_repack_001]
			 @material_repack_file_id		= @material_repack_file_id	
			,@repack_qty					= @repack_qty				
			,@pack_unit_qty					= @pack_unit_qty			
			,@emp_id						= @emp_id					





END

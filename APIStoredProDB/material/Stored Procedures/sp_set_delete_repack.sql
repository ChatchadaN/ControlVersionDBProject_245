
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/08/29>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_set_delete_repack]
		 @material_repack_file_id		INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		EXEC [APIStoredProVersionDB].[material].[sp_set_delete_repack_001]
			 @material_repack_file_id		=  @material_repack_file_id		

		 
END

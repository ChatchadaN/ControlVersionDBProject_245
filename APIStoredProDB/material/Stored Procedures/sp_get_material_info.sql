
-- =============================================
-- Author:		NUCHA
-- Create date: 2025/06/27
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_material_info]

			@barcode	NVARCHAR(20) =  NULL 
			, @material_id INT  = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	-- ########## VERSION 001 ##########  
		EXEC [APIStoredProVersionDB].[material].sp_get_material_info_001
			  @barcode			= @barcode		
			, @material_id		= @material_id
	-- ########## VERSION 001 ##########

END

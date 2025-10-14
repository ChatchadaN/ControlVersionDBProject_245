
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/08/29>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_set_delete_receiving]
		 @material_receiving_process_id		NVARCHAR(255)  
		  , @emp_id								INT	
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		EXEC [APIStoredProVersionDB].[material].[sp_set_delete_receiving_001]
			  @material_receiving_process_id	= @material_receiving_process_id	
			, @emp_id		= @emp_id		

		 
END

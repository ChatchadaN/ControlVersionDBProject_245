-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_categories]

		  @short_name	NVARCHAR(100) 
		, @name			NVARCHAR(100)  
		, @emp_id		INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_categories_001]
			  @short_name	= @short_name	
			, @name			= @name			
			, @emp_id		= @emp_id		
			 
END

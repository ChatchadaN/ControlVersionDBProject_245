-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_edit_suppliers]

		  @supplier_cd	VARCHAR(10) 
		, @name			NVARCHAR(100)  
		, @emp_id		INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_edit_suppliers_001]
			  @supplier_cd	= @supplier_cd	
			, @name			= @name			
			, @emp_id		= @emp_id		
			 
END

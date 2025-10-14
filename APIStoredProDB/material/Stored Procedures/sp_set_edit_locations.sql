-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_edit_locations]

		  @name					NVARCHAR(40)
		, @headquarter_id		INT
		, @address				VARCHAR(5)
		, @x					VARCHAR(5)
		, @y					VARCHAR(5)
		, @z					VARCHAR(5)
		, @depth				INT
		, @queue				INT
		, @wh_code				VARCHAR(5)
		, @lsi_process_id		INT
		, @emp_id				INT  
		, @locations_id			INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_edit_locations_001]
		  @name					= @name				
		, @headquarter_id		= @headquarter_id	
		, @address				= @address			
		, @x					= @x				
		, @y					= @y				
		, @z					= @z				
		, @depth				= @depth			
		, @queue				= @queue			
		, @wh_code				= @wh_code			
		, @lsi_process_id		= @lsi_process_id	
		, @emp_id				= @emp_id			
		, @locations_id			= @locations_id		
			 
END

-- =============================================
-- Author:		Apichaya Sazuzao
-- Create date: 22/07/2025
-- Description:	Get lot details 
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lot_in_process]
	-- Add the parameters for the stored procedure here
		@lot_no			varchar(10) = '%'
	  , @lot_type		varchar(1) = '%'
	  , @package_group	varchar(50) = '%'
	  , @package		varchar(50) = '%'
	  , @device			varchar(50) = '%'
	  , @process		varchar(50) = '%'
	  , @job			varchar(50) = '%'
	  , @status			varchar(50) = '%'
	  , @process_state	varchar(50) = '%'
	  , @quality_state	varchar(50) = '%'
	  , @app_name		varchar(100) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---- ########## VERSION 001 ##########
	EXEC APIStoredProVersionDB.[atom].[sp_get_lot_in_process_001]
		@lot_no					= @lot_no			
		, @lot_type				= @lot_type		
		, @package_group		= @package_group	
		, @package				= @package		
		, @device				= @device			
		, @process				= @process		
		, @job					= @job			
		, @status				= @status			
		, @process_state		= @process_state	
		, @quality_state		= @quality_state	
		, @app_name				= @app_name		












	---- ########## VERSION 001 ##########
END

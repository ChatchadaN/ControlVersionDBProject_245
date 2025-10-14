
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_language] 
	-- Add the parameters for the stored procedure here
	  @app_name			AS VARCHAR(100)
	, @languageCode		AS INT
	, @op_no			AS VARCHAR(6)
	, @language			AS VARCHAR(5) =  '' 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	
		--INSERT INTO APIStoredProDB.[dbo].[exec_sp_history]
		--(	
		--		  [record_at]
		--		, [record_class]
		--		, [login_name]
		--		, [hostname]
		--		, [appname]
		--		, [command_text] 
		--		, lot_no

		--)
		--SELECT    GETDATE()
		--		, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
		--		, ORIGINAL_LOGIN()
		--		, HOST_NAME()
		--		, APP_NAME()
		--		, 'EXEC [trans].[sp_get_language]  @app_name = ''' + ISNULL(CAST(@app_name AS nvarchar(MAX)),'') + ''', @languageCode = ''' + ISNULL(CAST(@languageCode AS nvarchar(MAX)),'') +''', @language = ''' + ISNULL(CAST(@language AS nvarchar(MAX)),'')+  ''',@op_no = ''' 
		--			+ ISNULL(CAST(@op_no AS nvarchar(MAX)),'') +  ''''
		--		, @app_name


	-- ########## VERSION 001 ##########
 	EXEC [APIStoredProVersionDB].[trans].[sp_get_language_001]

		  @app_name				= @app_name		
		, @languageCode			= @languageCode	
		, @op_no				= @op_no		
		, @language				= @language
		 
	-- ########## VERSION 001 ##########	 

 END

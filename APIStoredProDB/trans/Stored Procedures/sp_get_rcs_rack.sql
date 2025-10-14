-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_rcs_rack] 
	-- Add the parameters for the stored procedure here
	  @lot_no				VARCHAR(20)
	, @emp_id				INT
	, @categories			INT			= 0 
	, @isCurrentStepNo		BIT			= 0 --False
	, @app_name				NVARCHAR(100) = NULL 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
 
 	INSERT INTO APIStoredProDB.[dbo].[exec_sp_history]
		   ([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , [lot_no])
		SELECT GETDATE()
			,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			, 'EXEC [trans].[sp_get_rcs_rack_003] @lot_no  = ''' + ISNULL(CAST(@lot_no AS nvarchar(MAX)),'') 
				+ ''',@emp_id = ''' + ISNULL(CAST(@emp_id AS nvarchar(MAX)),'') +  
				+ ''',@app_name = ''' + ISNULL(CAST(@app_name AS nvarchar(MAX)),'') + 
				+ ''',@categories = ''' + ISNULL(CAST(@categories AS nvarchar(MAX)),'') +
				+ ''',@isCurrentStepNo = ''' + ISNULL(CAST(@isCurrentStepNo AS nvarchar(MAX)),'') +
				''''
			, @lot_no

		-- ########## VERSION 003 ##########
		EXEC [APIStoredProVersionDB].[trans].[sp_get_rcs_rack_003]
			  @lot_no			= @lot_no			
			, @emp_id			= @emp_id			
			, @categories		= @categories		
			, @isCurrentStepNo	= @isCurrentStepNo

		-- ########## VERSION 003 ##########
 
END

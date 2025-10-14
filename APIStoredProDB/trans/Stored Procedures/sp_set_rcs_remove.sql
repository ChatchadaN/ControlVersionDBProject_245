-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_remove] 
	-- Add the parameters for the stored procedure here
		@emp_id		INT
	  , @app_name	VARCHAR(100) 
	  , @Item		VARCHAR(20) 
	  , @Address_id	INT 
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
			, 'EXEC [trans].[sp_set_rcs_remove_003] @LotNo  = ''' + ISNULL(CAST(@Item AS nvarchar(MAX)),'') 
				+ ''',@emp_id = ''' + ISNULL(CAST(@emp_id AS nvarchar(MAX)),'') +  
				+ ''',@App_Name = ''' + ISNULL(CAST(@App_Name AS nvarchar(MAX)),'') + 
				+ ''',@Address_id = ''' + ISNULL(CAST(@Address_id AS nvarchar(MAX)),'') + 
				''''
			, @Item


		---- ########## VERSION 001 ##########
		--EXEC [APIStoredProVersionDB].[trans].[sp_set_rcs_remove_001]
		--		@emp_id		= @emp_id		
		--	  , @app_name	= @app_name	
		--	  , @Item		= @Item		
		--	  , @Address_id	= @Address_id	 
		---- ########## VERSION 001 ##########

		--UPDATE FOR CASE 
		--1. Please send @Rack = 1 for remove Lot from Hasuu Rack 
		--2. ADD LOG FOR > RETURN TRUE แต่ไม่ลบ data ออก

		-- ########## VERSION 003 ########## --20250520 08.45
		EXEC [APIStoredProVersionDB].[trans].[sp_set_rcs_remove_003]
				@emp_id		= @emp_id		
			  , @app_name	= @app_name	
			  , @Item		= @Item		
			  , @Address_id	= @Address_id	 
		-- ########## VERSION 003 ##########


 
END

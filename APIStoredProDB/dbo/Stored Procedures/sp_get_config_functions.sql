-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_config_functions] 
	-- Add the parameters for the stored procedure here
	  @app_name			AS VARCHAR(50)
	, @process			AS VARCHAR(50)	=  NULL
	, @function_name	AS VARCHAR(50)
	, @mc_no			AS VARCHAR(20)  = NULL
	, @factory_code		AS VARCHAR(20)	= NULL
	, @emp_num			AS VARCHAR(10)	= NULL
	--@factory = 1 RIST ,2 REPI
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[dbo].[sp_get_config_functions_001]
		  @app_name			=  @app_name		
		, @process			=  @process		
		, @function_name	=  @function_name
		, @mc_no			=  @mc_no		
		, @factory_code		=  @factory_code	
		, @emp_num			=  @emp_num		


	-- ########## VERSION 001 ##########
 
END

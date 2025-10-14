
-- =============================================
-- Author:		Chatchadaporn
-- Create date: 2024/08/22
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_wfdata_chipbank] 
	@OPNo				NVARCHAR(20)			
	, @App_Name			NVARCHAR(20)
	, @WFLOTNO			NVARCHAR(20)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

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
			, 'EXEC [material].[sp_set_input_chipbank_001] @WFLOTNO  = ''' + ISNULL(CAST(@WFLOTNO AS nvarchar(MAX)),'') 
				+ ''',@OPNo = ''' + ISNULL(CAST(@OPNo AS nvarchar(MAX)),'') +  
				+ ''',App_Name = ''' + ISNULL(CAST(@App_Name AS nvarchar(MAX)),'') +
				''''
			, @WFLOTNO

	---- ########## VERSION 001 ##########

	EXEC [APIStoredProVersionDB].[material].[sp_get_wfdata_chipbank_001] 
		 		@OPNo			= 	@OPNo			
			,	@App_Name		=   @App_Name		
			,	@WFLOTNO		=	@WFLOTNO

	---- ########## VERSION 001 ##########

END

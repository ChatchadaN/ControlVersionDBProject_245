
-- =============================================
-- Author:		NUCHA
-- Create date: 2022/07/01
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_rcs_remove_rack] 
		@emp_id			NVARCHAR(10)
		, @App_Name		NVARCHAR(20)
		, @Item			NVARCHAR(20)
		--, @Location		NVARCHAR(20)
		--, @Rackname		NVARCHAR(20)
		--, @Address		NVARCHAR(20)
		, @Address_id	INT
		, @qty			INT = 1

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
			, 'EXEC [trans].[sp_set_rcs_remove_rack_003] @Item  = ''' + ISNULL(CAST(@Item AS nvarchar(MAX)),'') 
				+ ''',@emp_id = ''' + ISNULL(CAST(@emp_id AS nvarchar(MAX)),'') +  
				+ ''',@App_Name = ''' + ISNULL(CAST(@App_Name AS nvarchar(MAX)),'') +
				+ ''',@Address_id = ''' + ISNULL(CAST(@Address_id AS nvarchar(MAX)),'') +
				--+ ''',@Location = ''' + ISNULL(CAST(@Location AS nvarchar(MAX)),'') +
				--+ ''',@Rackname = ''' + ISNULL(CAST(@Rackname AS nvarchar(MAX)),'') +
				--+ ''',@Address = ''' + ISNULL(CAST(@Address AS nvarchar(MAX)),'') +
				''''
			, @Item

	------ ########## VERSION TEST ##########

	--		EXEC [APIStoredProVersionDB].[trans].[sp_set_rcs_remove_rack_test] 
	--			 	  @OPNo			= 	@OPNo			
	--			   ,  @App_Name		=   @App_Name		
	--			   ,  @Item			=   @Item	
	--			   ,  @Location		=	@Location
	--			   ,  @Rackname		=	@Rackname
	--			   ,  @Address		=	@Address

	------ ########## VERSION TEST ##########

	------ ########## VERSION 002 ##########

	--		EXEC [APIStoredProVersionDB].[trans].[sp_set_rcs_remove_rack_002] 
	--			 	  @emp_id		= 	@emp_id			
	--			   ,  @App_Name		=   @App_Name		
	--			   ,  @Item			=   @Item	
	--			   ,  @Location		=	@Location
	--			   ,  @Rackname		=	@Rackname
	--			   ,  @Address		=	@Address

	------ ########## VERSION 002 ##########

		---- ########## VERSION 003 ##########

			EXEC [APIStoredProVersionDB].[trans].[sp_set_rcs_remove_rack_003] 
				 	  @emp_id		= 	@emp_id			
				   ,  @App_Name		=   @App_Name		
				   ,  @Item			=   @Item	
				   ,  @Address_id	=	@Address_id

	---- ########## VERSION 003 ##########
 
END

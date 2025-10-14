-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_outsource_lot_info] 
	-- Add the parameters for the stored procedure here
	@lot_outsource AS VARCHAR(70), 
	@mc_no AS VARCHAR(50), 
	@app_name AS VARCHAR(50)
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
			,4 --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			, 'EXEC [trans].[sp_get_outsource_lot_info] @lot_outsource = ''' + ISNULL(CAST(@lot_outsource AS varchar),'') 
				 + '''' + ''', @mc_no = ''' + ISNULL(CAST(@mc_no AS varchar),'') 
				 + '''' + ''', @app_name = ''' + ISNULL(CAST(@app_name AS varchar),'') + ''''				 
			, @lot_outsource

		---- ########## VERSION 001 ##########
		--	EXEC [APIStoredProVersionDB].trans.[sp_get_outsource_lot_info_001]
		--		@lot_outsource = @lot_outsource, 
		--		@mc_no = @mc_no, 
		--		@app_name = @app_name
		---- ########## VERSION 001 ##########


		
		-- ########## VERSION 001 ##########
			EXEC [APIStoredProVersionDB].trans.[sp_get_outsource_lot_info_002]
				@lot_outsource = @lot_outsource, 
				@mc_no = @mc_no, 
				@app_name = @app_name
		-- ########## VERSION 001 ##########
END

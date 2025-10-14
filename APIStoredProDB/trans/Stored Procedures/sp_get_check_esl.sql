-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_check_esl] 
	-- Add the parameters for the stored procedure here
	 
	@e_slip_id AS VARCHAR(50),
	@op_no AS VARCHAR(6),
	@app_name AS VARCHAR(255)
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
			,'EXEC [trans].[sp_get_check_esl_001]  @e_slip_id =''' + ISNULL(@e_slip_id,'') + '''' + ' @op_no =''' + ISNULL(@op_no,'')  + ''''+ ' @app_name =''' + ISNULL(@app_name,'') + ''''
			,@e_slip_id

		-- ########## VERSION 001 ##########
		EXEC [APIStoredProVersionDB].trans.sp_get_check_esl_001
		 
			@e_slip_id = @e_slip_id,
			@op_no = @op_no,
			@app_name = @app_name
		-- ########## VERSION 001 ##########
END

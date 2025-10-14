-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_data_lot] 
	-- Add the parameters for the stored procedure here
	 @lot_no		NVARCHAR(10)		
	,@e_slip_id		NVARCHAR(MAX)	= NULL
	,@app_name		NVARCHAR(MAX)	= NULL
	,@op_no			NVARCHAR(MAX)	= NULL
	,@mc_no			NVARCHAR(MAX)	= NULL
	,@department	NVARCHAR(MAX)	= NULL
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
			,'EXEC [trans].[sp_get_data_lot] @lot_no =''' + ISNULL(@lot_no,'') + '''' + ' @e_slip_id =''' + ISNULL(@e_slip_id,'') + '''' + ' @op_no =''' + ISNULL(@op_no,'')  + '''' +   ' @app_name =''' + ISNULL(@app_name,'') + ''''
			,@lot_no

		-- ########## VERSION 001 ##########
		EXEC [APIStoredProVersionDB].trans.[sp_get_data_lot_002]
			@lot_no = @lot_no,
			@e_slip_id = @e_slip_id,
			@op_no = @op_no,
			@app_name = @app_name,
			@mc_no =@mc_no,
			@department = @department 
		-- ########## VERSION 001 ##########
END

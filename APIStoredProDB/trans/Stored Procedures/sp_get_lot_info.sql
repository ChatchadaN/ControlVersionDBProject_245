-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_lot_info] 
	-- Add the parameters for the stored procedure here
	@e_slip_id varchar(50),
	@get_type tinyint = 0,  -- 0: Lot info  1:Check Lot
	@mc_no varchar(50) = NULL, 
	@app_name varchar(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---- ########## VERSION 001 ##########
	--EXEC [APIStoredProVersionDB].[trans].[sp_get_lot_info_001]
	--	@e_slip_id = @e_slip_id,
	--	@get_type = @get_type,
	--	@mc_no = @mc_no, 
	--	@app_name = @app_name
	---- ########## VERSION 001 ##########

	---- ########## VERSION 002 ##########
		EXEC [APIStoredProVersionDB].[trans].[sp_get_lot_info_002]
		@e_slip_id = @e_slip_id,
		@get_type = @get_type,
		@mc_no = @mc_no, 
		@app_name = @app_name
	-- ########## VERSION 002 ##########
END

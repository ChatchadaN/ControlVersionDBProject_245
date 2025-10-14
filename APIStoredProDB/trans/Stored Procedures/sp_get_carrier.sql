-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_carrier] 
	-- Add the parameters for the stored procedure here
	@lot_no nvarchar(20) = NULL,
	@carrier_no varchar(11) = NULL,
	@next_carrier_no varchar(11) = NULL,
	@mc_no varchar(50) = NULL, 
	@app_name varchar(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@lot_no != '' OR @lot_no IS NOT NULL)
	BEGIN
		-- ########## VERSION 002 ##########
		EXEC [APIStoredProVersionDB].[trans].[sp_get_carrier_002]
			@lot_no = @lot_no,
			@carrier_no = @carrier_no,
			@next_carrier_no = @next_carrier_no,
			@mc_no = @mc_no, 
			@app_name = @app_name
		-- ########## VERSION 002 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION 001 ##########
		EXEC [APIStoredProVersionDB].[trans].[sp_get_carrier_001]
			@lot_no = @lot_no,
			@carrier_no = @carrier_no,
			@next_carrier_no = @next_carrier_no,
			@mc_no = @mc_no, 
			@app_name = @app_name
		-- ########## VERSION 001 ##########
	END
END

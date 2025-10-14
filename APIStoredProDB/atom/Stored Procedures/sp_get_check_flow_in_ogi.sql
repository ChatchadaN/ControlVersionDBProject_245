
CREATE PROCEDURE [atom].[sp_get_check_flow_in_ogi]	
	-- Add the parameters for the stored procedure here	
	@lot_id int
	,@is_production bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -------------------------------------------------------------------------------------------------
	IF(@is_production = 1)
	BEGIN
		-- ########## VERSION 001 ##########
		EXEC [APIStoredProVersionDB].[atom].[sp_get_check_flow_in_ogi_ver_001]
		@lot_id = @lot_id
		-- ########## VERSION 001 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION TEST ##########
		EXEC [APIStoredProVersionDB].[atom].[sp_get_check_flow_in_ogi_ver_001]
		@lot_id = @lot_id
		-- ########## VERSION TEST ##########
	END
END


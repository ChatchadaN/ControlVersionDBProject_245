-- =============================================
-- Author:		Apichaya Sazuzao
-- Create date: 22/07/2025
-- Description:	Get lot details 
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_lot_flows_operator]
	-- Add the parameters for the stored procedure here
	@lot_id int	
	--, @device_slip_id int
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---- ########## VERSION 001 ##########
	EXEC APIStoredProVersionDB.[atom].[sp_get_trans_lot_flows_operator_001]
		@lot_id = @lot_id
	---- ########## VERSION 001 ##########
END

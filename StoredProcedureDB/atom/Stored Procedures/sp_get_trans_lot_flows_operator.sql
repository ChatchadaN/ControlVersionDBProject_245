-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
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
	--EXEC [StoredProcedureDB].[atom].[sp_get_trans_lot_flows_operator_ver_001]
	--	@lot_id = @lot_id
	---- ########## VERSION 001 ##########

	-- -- ########## VERSION 002 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_get_trans_lot_flows_operator_ver_002]
	--	@lot_id = @lot_id
	---- ########## VERSION 002 ##########

	-- -- ########## VERSION 003 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_get_trans_lot_flows_operator_ver_003]
	--	@lot_id = @lot_id
	---- ########## VERSION 003 ##########

	---- ########## VERSION 004 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_get_trans_lot_flows_operator_ver_004]
	--	@lot_id = @lot_id
	---- ########## VERSION 004 ##########

	---- ########## VERSION 005 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_get_trans_lot_flows_operator_ver_00]
	--	@lot_id = @lot_id
	---- ########## VERSION 005 ##########

	---- ########## VERSION 006 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_get_trans_lot_flows_operator_ver_006]
	--	@lot_id = @lot_id
	---- ########## VERSION 006 ##########

	------ ########## VERSION 007 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_get_trans_lot_flows_operator_ver_007]
	--	@lot_id = @lot_id
	------ ########## VERSION 007 ##########

	---- ########## VERSION 008 ##########
	EXEC [StoredProcedureDB].[atom].[sp_get_trans_lot_flows_operator_ver_008]
		@lot_id = @lot_id
	---- ########## VERSION 008 ##########
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_cancel_lot]
	-- Add the parameters for the stored procedure here
	@lot_id varchar(10)
	,@update_by varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	------ ########## VERSION 001 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_set_cancel_lot_ver_001]
	--	@lot_id = @lot_id,
	--	@update_by = @update_by;
	------ ########## VERSION 001 ##########
	
	---- ########## VERSION 002 ##########
	---- 2022-08-29 08.30
	EXEC [StoredProcedureDB].[atom].[sp_set_cancel_lot_ver_002]
		@lot_id = @lot_id,
		@update_by = @update_by;
	---- ########## VERSION 002 ##########

END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lot_materials]
	 @lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	------ ########## VERSION 001 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_get_lot_materials_ver_001]
	--	@lot_no = @lot_no;
	------ ########## VERSION 001 ##########

	---- ########## VERSION 002 ##########
	EXEC [StoredProcedureDB].[atom].[sp_get_lot_materials_ver_002]
		@lot_no = @lot_no;
	---- ########## VERSION 002 ##########
END

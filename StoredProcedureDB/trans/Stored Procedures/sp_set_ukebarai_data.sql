-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_ukebarai_data]
	-- Add the parameters for the stored procedure here
	@lot_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	------ ########## VERSION 001 ##########
	--EXEC [StoredProcedureDB].[trans].[sp_set_ukebarai_data_ver_001]
	--	@lot_id = @lot_id
	------ ########## VERSION 001 #########

	---- ########## VERSION 002 ##########
	EXEC [StoredProcedureDB].[trans].[sp_set_ukebarai_data_ver_002]
		@lot_id = @lot_id
	---- ########## VERSION 002 #########
END

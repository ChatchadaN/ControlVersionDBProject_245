-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_production_category]
	-- Add the parameters for the stored procedure here
	@lot_id varchar(10)
	,@update_by varchar(20)
	,@is_clear tinyint = 0  --0 : save , 1 : clear
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---- ########## VERSION 001 ##########
		--EXEC [StoredProcedureDB].[atom].[sp_set_production_category_ver001] @lot_id = @lot_id
		--, @update_by = @update_by
		--, @is_clear = @is_clear
	---- ########## VERSION 001 ##########

	------ ########## VERSION 002 ##########
		--EXEC [StoredProcedureDB].[atom].[sp_set_production_category_ver002] @lot_id = @lot_id
		--, @update_by = @update_by
		--, @is_clear = @is_clear
	------ ########## VERSION 002 ##########

	------ ########## VERSION 003 UPDATE DATETIME : 2024/12/20 11.09 By Aomsin ##########
		EXEC [StoredProcedureDB].[atom].[sp_set_production_category_ver003] @lot_id = @lot_id
		, @update_by = @update_by
		, @is_clear = @is_clear
	------ ########## VERSION 003 ##########
END

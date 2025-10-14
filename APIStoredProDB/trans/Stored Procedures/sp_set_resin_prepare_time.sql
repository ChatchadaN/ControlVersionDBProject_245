-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_resin_prepare_time]
	@barcode VARCHAR(255), 
	@emp_code VARCHAR(6), 
	@action INT -- 0 Cancel, 1 Unfreeze
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[trans].[sp_set_resin_prepare_time_ver_001]
		@barcode  = @barcode, 
		@emp_code = @emp_code, 
		@action   = @action

END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_resin_prepare_list]
	@barcode VARCHAR(255) = NULL, 
	@status INT = NULL -- 1 In prepare, 2 Prepared
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[trans].[sp_get_resin_prepare_list_ver_001]
		@barcode  = @barcode,
		@status   = @status

END

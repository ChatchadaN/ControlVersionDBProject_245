-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_get_lot_record_templates]
	@id INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[lds].[sp_get_lot_record_templates_ver_001]
		@id = @id

END

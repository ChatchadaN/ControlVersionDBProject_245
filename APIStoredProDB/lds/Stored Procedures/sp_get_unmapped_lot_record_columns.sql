-- =============================================
-- Author:		<Yutida Pongkanawat (010854)>
-- Create date: <8 July 2025 09:30>
-- Description:	<Used to retrieve the column data for mapping with the template.>
-- =============================================
CREATE PROCEDURE [lds].[sp_get_unmapped_lot_record_columns]
	@template_id INT
AS
BEGIN

	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[lds].[sp_get_unmapped_lot_record_columns_ver_001]
		@template_id = @template_id;

END

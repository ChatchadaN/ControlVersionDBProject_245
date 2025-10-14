-- =============================================
-- Author:		<Author, Yutida P.>
-- Create date: <Create Date, 16 July 2025>
-- Description:	<Description, Get flow patterns>
-- =============================================
CREATE PROCEDURE [material].[sp_get_supplier]
	@supplier_cd	 NVARCHAR(10) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_supplier_001]
			@supplier_cd = @supplier_cd
END

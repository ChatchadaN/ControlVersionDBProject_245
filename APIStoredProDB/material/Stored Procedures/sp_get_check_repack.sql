
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/07/31>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_get_check_repack]
		  @barcode				VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_check_repack_001]
		 @barcode		=  @barcode
END

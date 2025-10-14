-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_ocr_read_request_ver_001] 
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [lot_no]
	FROM [APIStoredProDB].[dbo].[lot_request_ocr_records]
	WHERE [lot_request_ocr_records].[status] = 1)
	BEGIN
		SELECT TOP(1) CAST(1 AS BIT) AS [status]
		, [id]
		, [lot_no]
		, [ip_address]
		, [path_image]
		FROM [APIStoredProDB].[dbo].[lot_request_ocr_records]
		WHERE [lot_request_ocr_records].[status] = 1
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
		, 0 AS [id]
		, '' AS [lot_no]
		, '' AS [ip_address]
		, '' AS [path_image]
	END
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_ocr_read_request_ver_003]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@request_status int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @request_id INT

	SELECT TOP(1) @request_id = [id]
	FROM [APIStoredProDB].[dbo].[lot_request_ocr_records]
	WHERE [lot_request_ocr_records].[status] = @request_status
	AND [lot_request_ocr_records].[request_count] < 5


	IF EXISTS(SELECT [lot_no]
	FROM [APIStoredProDB].[dbo].[lot_request_ocr_records]
	WHERE [lot_request_ocr_records].[id] = @request_id)
	BEGIN
		IF(@request_status != 6)
		BEGIN
			UPDATE [APIStoredProDB].[dbo].[lot_request_ocr_records]
			   SET [request_count] = [request_count] + 1
			WHERE [lot_request_ocr_records].[id] = @request_id
		END

		SELECT TOP(1) CAST(1 AS BIT) AS [status]
		, [id]
		, [lot_no]
		, [ip_address]
		, [path_image]
		FROM [APIStoredProDB].[dbo].[lot_request_ocr_records]
		WHERE [lot_request_ocr_records].[id] = @request_id
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

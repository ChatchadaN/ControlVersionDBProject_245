-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_ocr_read_request_ver_002]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [lot_request_ocr_records].[lot_no]
	FROM [APIStoredProDB].[dbo].[lot_request_ocr_records]
	INNER JOIN [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] ON [LCQW_UNION_WORK_DENPYO_PRINT].[LOT_NO_2] = [lot_request_ocr_records].[lot_no]
	WHERE [lot_request_ocr_records].[status] = 1)
	BEGIN
		SELECT TOP(1) CAST(1 AS BIT) AS [status]
		, [lot_request_ocr_records].[id]
		, [lot_request_ocr_records].[lot_no]
		, [lot_request_ocr_records].[ip_address]
		, [lot_request_ocr_records].[path_image]
		, [LCQW_UNION_WORK_DENPYO_PRINT].[MANUAL_TITLE_1] AS [mark]
		FROM [APIStoredProDB].[dbo].[lot_request_ocr_records]
		INNER JOIN [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] ON [LCQW_UNION_WORK_DENPYO_PRINT].[LOT_NO_2] = [lot_request_ocr_records].[lot_no]
		WHERE [lot_request_ocr_records].[status] = 1
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
		, 0 AS [id]
		, '' AS [lot_no]
		, '' AS [ip_address]
		, '' AS [path_image]
		, '' AS [mark]
	END
END

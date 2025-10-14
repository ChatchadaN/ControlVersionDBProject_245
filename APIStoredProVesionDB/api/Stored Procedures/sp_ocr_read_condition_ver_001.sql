-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_ocr_read_condition_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [lot_marking_verify_master].[value] AS [mark_from]
	, [lot_marking_verify_master].[to_value] AS [mark_to]
	FROM [APCSProDB].[trans].[lot_marking_verify_master])
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, [lot_marking_verify_master].[value] AS [mark_from]
		, [lot_marking_verify_master].[to_value] AS [mark_to]
		FROM [APCSProDB].[trans].[lot_marking_verify_master]
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
		, '' AS [mark_from]
		, '' AS [mark_to]
	END
END

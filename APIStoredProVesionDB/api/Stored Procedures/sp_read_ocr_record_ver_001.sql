-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_ocr_record_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [lot_marking_verify].[id]
	, [lots].[lot_no]
	, [packages].[name] AS [package]
	, [device_names].[name] AS [device]
	, [lot_marking_verify].[value]
	, CAST([lot_marking_verify].[is_pass] AS INT) AS [is_pass]
	, [lot_marking_verify].[marking_picture_id]
	FROM [APCSProDB].[trans].[lot_marking_verify]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_marking_verify].[lot_id]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
	ORDER BY [lot_marking_verify].[is_pass]
	, [lot_marking_verify].[id]
END

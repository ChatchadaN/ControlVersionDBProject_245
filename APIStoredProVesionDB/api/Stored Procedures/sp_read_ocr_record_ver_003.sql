-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_ocr_record_ver_003]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [lot_marking_verify_records].[id]
	FROM [APCSProDB].[trans].[lot_marking_verify_records]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_marking_verify_records].[lot_id]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
	INNER JOIN [APCSProDB].[trans].[item_labels] ON [item_labels].[val] = [lot_marking_verify_records].[is_pass] AND [item_labels].[name] = 'lot_marking_verify.is_pass')
	BEGIN
		SELECT TOP(1000) CAST(1 AS BIT) as [status]
		, [lot_marking_verify_records].[id]
		, [lots].[lot_no]
		, [packages].[name] AS [package]
		, [device_names].[name] AS [device]
		, ISNULL([lot_marking_verify_records].[value],'-') AS [value]
		, CAST([lot_marking_verify_records].[is_pass] AS INT) AS [is_pass]
		, ISNULL([lot_marking_verify_records].[marking_picture_id],0) AS [marking_picture_id]
		, [item_labels].[label_eng] AS [is_pass_detail]
		, [lot_marking_verify_records].[updated_at]
		FROM [APCSProDB].[trans].[lot_marking_verify_records]
		INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_marking_verify_records].[lot_id]
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[trans].[item_labels] ON [item_labels].[val] = [lot_marking_verify_records].[is_pass] AND [item_labels].[name] = 'lot_marking_verify.is_pass'
		ORDER BY [lot_marking_verify_records].[id] DESC
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) as [status]
		, 0 AS [id]
		, '' AS [lot_no]
		, '' AS [package]
		, '' AS [device]
		, '' AS [value]
		, 0 AS [is_pass]
		, 0 AS [marking_picture_id]
		, '' AS [is_pass_detail]
		, '2000-01-01' AS [updated_at]
	END
END

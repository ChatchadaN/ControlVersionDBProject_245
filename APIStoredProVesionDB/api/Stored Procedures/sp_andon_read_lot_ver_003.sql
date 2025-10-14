-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_andon_read_lot_ver_003]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [lots].[id]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
	LEFT JOIN [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] ON [LCQW_UNION_WORK_DENPYO_PRINT].[LOT_NO_2] = [lots].[lot_no]
	WHERE [lots].[lot_no] = @lot_no)
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, [lots].[lot_no] AS [lot_no]
		, [packages].[name] AS [package]
		, [device_names].[name] AS [device]
		, CASE WHEN [LCQW_UNION_WORK_DENPYO_PRINT].[MANU_COMMENT_1] like '%Important%' THEN [LCQW_UNION_WORK_DENPYO_PRINT].[MANU_COMMENT_1] ELSE '' END AS [comment_1]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
		LEFT JOIN [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] ON [LCQW_UNION_WORK_DENPYO_PRINT].[LOT_NO_2] = [lots].[lot_no]
		WHERE [lots].[lot_no] = @lot_no
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
		, '' AS [lot_no]
		, '' AS [package]
		, '' AS [device]
		, '' AS [comment_1]
	END
END

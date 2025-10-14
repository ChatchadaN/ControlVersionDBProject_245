-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_ocr_get_mark_info_ver_003]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @lot_id INT

	IF EXISTS(SELECT [LOT_NO_2]
		FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
		WHERE [LOT_NO_2] = @lot_no)
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, [ASSY_SYMBOL_1]
			+ [ASSY_SYMBOL_2]
			+ [ASSY_SYMBOL_3]
			+ [ASSY_SYMBOL_4]
			+ [ASSY_SYMBOL_5]
			+ [ASSY_SYMBOL_6] AS [mark]
		FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
		WHERE [LOT_NO_2] = @lot_no
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT id
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [lots].[id]
			WHERE lot_no = @lot_no)
		BEGIN
			SELECT @lot_id = id
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [lots].[id]
			WHERE lot_no = @lot_no

			SELECT TOP(1) CAST(1 AS BIT) AS [status]
			, [ASSY_SYMBOL_1]
					+ [ASSY_SYMBOL_2]
					+ [ASSY_SYMBOL_3]
					+ [ASSY_SYMBOL_4]
					+ [ASSY_SYMBOL_5]
					+ [ASSY_SYMBOL_6] AS [mark]
			FROM [APCSProDB].[trans].[lot_combine]
			INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_combine].[member_lot_id]
			INNER JOIN [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] ON [LCQW_UNION_WORK_DENPYO_PRINT].[LOT_NO_2] = [lots].[lot_no]
			WHERE [lot_combine].[lot_id] = @lot_id
			ORDER BY [lots].[qty_hasuu]
		END
		ELSE
		BEGIN
			SELECT CAST(0 AS BIT) AS [status]
			, [ASSY_SYMBOL_1]
				+ [ASSY_SYMBOL_2]
				+ [ASSY_SYMBOL_3]
				+ [ASSY_SYMBOL_4]
				+ [ASSY_SYMBOL_5]
				+ [ASSY_SYMBOL_6] AS [mark]
			FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
			WHERE [LOT_NO_2] = @lot_no
		END
	END
END
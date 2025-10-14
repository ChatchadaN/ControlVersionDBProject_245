-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_ocr_get_mark_info_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [LOT_NO_1]
	FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
	WHERE [LOT_NO_1] = @lot_no)
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, [ASSY_SYMBOL_1]
			+ [ASSY_SYMBOL_2]
			+ [ASSY_SYMBOL_3]
			+ [ASSY_SYMBOL_4]
			+ [ASSY_SYMBOL_5]
			+ [ASSY_SYMBOL_6] AS [mark]
		FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
		WHERE [LOT_NO_1] = @lot_no
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
		WHERE [LOT_NO_1] = @lot_no
	END
END

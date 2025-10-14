-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_update_ocr_denpyo_logo_ver_001]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
	SET [MANUAL_TITLE_1] = [marking_logo_picture].[id]
	FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
	INNER JOIN [APCSProDBFile].[ocr].[marking_logo_picture] ON [marking_logo_picture].[value] = [APIStoredProVersionDB].[dbo].[showASCII](CONCAT([ASSY_SYMBOL_1]
			,[ASSY_SYMBOL_2]
			,[ASSY_SYMBOL_3]
			,[ASSY_SYMBOL_4]
			,[ASSY_SYMBOL_5]
			,[ASSY_SYMBOL_6]))
	WHERE LEN(MANUAL_TITLE_1) = 0

	UPDATE [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
	SET [MANUAL_TITLE_2] = [marking_logo_picture].[id]
	FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
	INNER JOIN [APCSProDBFile].[ocr].[marking_logo_picture] ON [marking_logo_picture].[value] = [APIStoredProVersionDB].[dbo].[showASCII](CONCAT([FT_SYMBOL_1]
			,[FT_SYMBOL_2]
			,[FT_SYMBOL_3]
			,[FT_SYMBOL_4]
			,[FT_SYMBOL_5]
			,[FT_SYMBOL_6]))
	WHERE LEN(MANUAL_TITLE_2) = 0
END

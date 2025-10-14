-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_update_ocr_denpyo_logo_ver_002]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
	SET [MANUAL_TITLE_1] = CASE WHEN LEN(CONCAT([ASSY_SYMBOL_1], [ASSY_SYMBOL_2], [ASSY_SYMBOL_3], [ASSY_SYMBOL_4], [ASSY_SYMBOL_5], [ASSY_SYMBOL_6])) 
			>= LEN(CONCAT([FT_SYMBOL_1], [FT_SYMBOL_2], [FT_SYMBOL_3], [FT_SYMBOL_4], [FT_SYMBOL_5], [FT_SYMBOL_6]))
		THEN CASE WHEN ([ASSY_SYMBOL_1] LIKE '%**%') OR ([ASSY_SYMBOL_1] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_1]),' ','') END
			+ CASE WHEN ([ASSY_SYMBOL_2] LIKE '%**%') OR ([ASSY_SYMBOL_2] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_2]),' ','') END
			+ CASE WHEN ([ASSY_SYMBOL_3] LIKE '%**%') OR ([ASSY_SYMBOL_3] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_3]),' ','') END
			+ CASE WHEN ([ASSY_SYMBOL_4] LIKE '%**%') OR ([ASSY_SYMBOL_4] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_4]),' ','') END
			+ CASE WHEN ([ASSY_SYMBOL_5] LIKE '%**%') OR ([ASSY_SYMBOL_5] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_5]),' ','') END
			+ CASE WHEN ([ASSY_SYMBOL_6] LIKE '%**%') OR ([ASSY_SYMBOL_6] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_6]),' ','') END
		ELSE CASE WHEN ([FT_SYMBOL_1] LIKE '%**%') OR ([FT_SYMBOL_1] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_1]),' ','') END
			+ CASE WHEN ([FT_SYMBOL_2] LIKE '%**%') OR ([FT_SYMBOL_2] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_2]),' ','') END
			+ CASE WHEN ([FT_SYMBOL_3] LIKE '%**%') OR ([FT_SYMBOL_3] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_3]),' ','') END
			+ CASE WHEN ([FT_SYMBOL_4] LIKE '%**%') OR ([FT_SYMBOL_4] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_4]),' ','') END
			+ CASE WHEN ([FT_SYMBOL_5] LIKE '%**%') OR ([FT_SYMBOL_5] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_5]),' ','') END
			+ CASE WHEN ([FT_SYMBOL_6] LIKE '%**%') OR ([FT_SYMBOL_6] = 'MX') THEN '' ELSE REPLACE([APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_6]),' ','') END
		END
	, [MANUAL_TITLE_2] = CASE WHEN LEN(CONCAT([ASSY_SYMBOL_1], [ASSY_SYMBOL_2], [ASSY_SYMBOL_3], [ASSY_SYMBOL_4], [ASSY_SYMBOL_5], [ASSY_SYMBOL_6])) 
			>= LEN(CONCAT([FT_SYMBOL_1], [FT_SYMBOL_2], [FT_SYMBOL_3], [FT_SYMBOL_4], [FT_SYMBOL_5], [FT_SYMBOL_6]))
		THEN [assy_mark].[id] 
		ELSE [ft_mark].[id] END
	FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
	LEFT JOIN [APCSProDBFile].[ocr].[marking_logo_picture] AS [assy_mark] ON [assy_mark].[value] = [APIStoredProVersionDB].[dbo].[showASCII](CONCAT([ASSY_SYMBOL_1]
		,[ASSY_SYMBOL_2]
		,[ASSY_SYMBOL_3]
		,[ASSY_SYMBOL_4]
		,[ASSY_SYMBOL_5]
		,[ASSY_SYMBOL_6]))
	LEFT JOIN [APCSProDBFile].[ocr].[marking_logo_picture] AS [ft_mark] ON  [ft_mark].[value] = [APIStoredProVersionDB].[dbo].[showASCII](CONCAT([FT_SYMBOL_1]
		,[FT_SYMBOL_2]
		,[FT_SYMBOL_3]
		,[FT_SYMBOL_4]
		,[FT_SYMBOL_5]
		,[FT_SYMBOL_6]))
	WHERE LEN(MANUAL_TITLE_2) = 0
END

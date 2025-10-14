-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_create_ocr_denpyo_mark_ver_001]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [APIStoredProDB].[dbo].[lot_masks]
	([lot_no]
	, [mno])
	SELECT [lot_no_2]
	, MAX([mark])
	FROM
	(
		SELECT [lot_no_2]
		, CASE WHEN LEN(CONCAT([ASSY_SYMBOL_1], [ASSY_SYMBOL_2], [ASSY_SYMBOL_3], [ASSY_SYMBOL_4], [ASSY_SYMBOL_5], [ASSY_SYMBOL_6])) 
			>= LEN(CONCAT([FT_SYMBOL_1], [FT_SYMBOL_2], [FT_SYMBOL_3], [FT_SYMBOL_4], [FT_SYMBOL_5], [FT_SYMBOL_6]))
		THEN CASE WHEN ([ASSY_SYMBOL_1] LIKE '%**%') OR ([ASSY_SYMBOL_1] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_1]) END
			+ CASE WHEN ([ASSY_SYMBOL_2] LIKE '%**%') OR ([ASSY_SYMBOL_2] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_2]) END
			+ CASE WHEN ([ASSY_SYMBOL_3] LIKE '%**%') OR ([ASSY_SYMBOL_3] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_3]) END
			+ CASE WHEN ([ASSY_SYMBOL_4] LIKE '%**%') OR ([ASSY_SYMBOL_4] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_4]) END
			+ CASE WHEN ([ASSY_SYMBOL_5] LIKE '%**%') OR ([ASSY_SYMBOL_5] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_5]) END
			+ CASE WHEN ([ASSY_SYMBOL_6] LIKE '%**%') OR ([ASSY_SYMBOL_6] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([ASSY_SYMBOL_6]) END
		ELSE CASE WHEN ([FT_SYMBOL_1] LIKE '%**%') OR ([FT_SYMBOL_1] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_1]) END
			+ CASE WHEN ([FT_SYMBOL_2] LIKE '%**%') OR ([FT_SYMBOL_2] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_2]) END
			+ CASE WHEN ([FT_SYMBOL_3] LIKE '%**%') OR ([FT_SYMBOL_3] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_3]) END
			+ CASE WHEN ([FT_SYMBOL_4] LIKE '%**%') OR ([FT_SYMBOL_4] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_4]) END
			+ CASE WHEN ([FT_SYMBOL_5] LIKE '%**%') OR ([FT_SYMBOL_5] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_5]) END
			+ CASE WHEN ([FT_SYMBOL_6] LIKE '%**%') OR ([FT_SYMBOL_6] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo]([FT_SYMBOL_6]) END
		END AS [mark]
		--, CASE WHEN LEN(CONCAT([ASSY_SYMBOL_1], [ASSY_SYMBOL_2], [ASSY_SYMBOL_3], [ASSY_SYMBOL_4], [ASSY_SYMBOL_5], [ASSY_SYMBOL_6])) 
		--	>= LEN(CONCAT([FT_SYMBOL_1], [FT_SYMBOL_2], [FT_SYMBOL_3], [FT_SYMBOL_4], [FT_SYMBOL_5], [FT_SYMBOL_6]))
		--THEN CASE WHEN ([ASSY_SYMBOL_1] LIKE '%**%') OR ([ASSY_SYMBOL_1] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([ASSY_SYMBOL_1] AS VARCHAR(MAX))) END
		--	+ CASE WHEN ([ASSY_SYMBOL_2] LIKE '%**%') OR ([ASSY_SYMBOL_2] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([ASSY_SYMBOL_2] AS VARCHAR(MAX))) END
		--	+ CASE WHEN ([ASSY_SYMBOL_3] LIKE '%**%') OR ([ASSY_SYMBOL_3] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([ASSY_SYMBOL_3] AS VARCHAR(MAX))) END
		--	+ CASE WHEN ([ASSY_SYMBOL_4] LIKE '%**%') OR ([ASSY_SYMBOL_4] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([ASSY_SYMBOL_4] AS VARCHAR(MAX))) END
		--	+ CASE WHEN ([ASSY_SYMBOL_5] LIKE '%**%') OR ([ASSY_SYMBOL_5] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([ASSY_SYMBOL_5] AS VARCHAR(MAX))) END
		--	+ CASE WHEN ([ASSY_SYMBOL_6] LIKE '%**%') OR ([ASSY_SYMBOL_6] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([ASSY_SYMBOL_6] AS VARCHAR(MAX))) END
		--ELSE CASE WHEN ([FT_SYMBOL_1] LIKE '%**%') OR ([FT_SYMBOL_1] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([FT_SYMBOL_1] AS VARCHAR(MAX))) END
		--	+ CASE WHEN ([FT_SYMBOL_2] LIKE '%**%') OR ([FT_SYMBOL_2] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([FT_SYMBOL_2] AS VARCHAR(MAX))) END
		--	+ CASE WHEN ([FT_SYMBOL_3] LIKE '%**%') OR ([FT_SYMBOL_3] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([FT_SYMBOL_3] AS VARCHAR(MAX))) END
		--	+ CASE WHEN ([FT_SYMBOL_4] LIKE '%**%') OR ([FT_SYMBOL_4] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([FT_SYMBOL_4] AS VARCHAR(MAX))) END
		--	+ CASE WHEN ([FT_SYMBOL_5] LIKE '%**%') OR ([FT_SYMBOL_5] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([FT_SYMBOL_5] AS VARCHAR(MAX))) END
		--	+ CASE WHEN ([FT_SYMBOL_6] LIKE '%**%') OR ([FT_SYMBOL_6] = 'MX') THEN '' ELSE [APIStoredProVersionDB].[dbo].[removeASCIILogo](CAST([FT_SYMBOL_6] AS VARCHAR(MAX))) END
		--END AS [mark2]
		, [UNION_WORK_DENPYO_SEQ]
		FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
		LEFT JOIN [APIStoredProDB].[dbo].[lot_masks] ON [lot_masks].[lot_no] = [LCQW_UNION_WORK_DENPYO_PRINT].[LOT_NO_2]
		WHERE [lot_masks].[lot_no] IS NULL
	) AS master_data
	GROUP BY [lot_no_2]
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_data_mli02_lsi_table]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	---- # Update flag 0 --> 2
	UPDATE [APCSProDB].[trans].[mli02_lsi]
	SET [import_flg] = 2
	WHERE [import_flg] = 0;
	
	---- # Insert flag 2 to APCSProDWH.dbo.MLI02
	INSERT INTO [APCSProDWH].[dbo].[MLI02]
		( [NYKP]
		, [MSGS]
		, [BSIJD]
		, [SHGM]
		, [KEIJ]
		, [SOFS]
		, [HKNK]
		, [LOCT]
		, [TOKI]
		, [TOKI2]
		, [KGSS]
		, [KGBS]
		, [HASM]
		, [SMGS]
		, [TKEM]
		, [NKYS]
		, [TMSS]
		, [SZON]
		, [LOTN]
		, [INVN]
		, [NYKD]
		, [NYID]
		, [BRKC]
		, [FG01]
		, [FG02]
		, [FG03]
		, [FG04]
		, [FG05]
		, [LSI_FLG] )
	SELECT [NYKP]
		, [MSGS]
		, [BSIJD]
		, [SHGM]
		, [KEIJ]
		, [SOFS]
		, [HKNK]
		, [LOCT]
		, [TOKI]
		, [TOKI2]
		, [KGSS]
		, [KGBS]
		, [HASM]
		, [SMGS]
		, [TKEM]
		, [NKYS]
		, [TMSS]
		, [SZON]
		, [LOTN]
		, [INVN]
		, [NYKD]
		, [NYID]
		, [BRKC]
		, [FG01]
		, [FG02]
		, [FG03]
		, [FG04]
		, [FG05]
		, 0 AS [LSI_FLG]
	FROM [APCSProDB].[trans].[mli02_lsi]
	WHERE [import_flg] = 2;

	---- # Update flag 2 --> 1
	UPDATE [APCSProDB].[trans].[mli02_lsi]
	SET [import_flg] = 1
	WHERE [import_flg] = 2;
END
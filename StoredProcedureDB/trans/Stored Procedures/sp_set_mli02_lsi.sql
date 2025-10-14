-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_mli02_lsi]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	BEGIN TRY 
		DECLARE @table_mli02 table ( 
			[NYKP] [char](13) NOT NULL,
			[MSGS] [char](4) NOT NULL,
			[BSIJD] [char](8) NULL,
			[SHGM] [char](5) NULL,
			[KEIJ] [char](10) NULL,
			[SOFS] [char](15) NULL,
			[HKNK] [char](3) NULL,
			[LOCT] [char](6) NULL,
			[TOKI] [char](15) NULL,
			[TOKI2] [char](20) NULL,
			[KGSS] [int] NULL,
			[KGBS] [int] NULL,
			[HASM] [varchar](6) NULL,
			[SMGS] [char](4) NULL,
			[TKEM] [char](20) NULL,
			[NKYS] [decimal](18, 0) NULL,
			[TMSS] [int] NULL,
			[SZON] [char](15) NULL,
			[LOTN] [char](10) NULL,
			[INVN] [varchar](15) NULL,
			[NYKD] [char](8) NULL,
			[NYID] [char](5) NULL,
			[BRKC] [char](5) NULL,
			[FG01] [char](1) NULL,
			[FG02] [char](1) NULL,
			[FG03] [char](1) NULL,
			[FG04] [char](1) NULL,
			[FG05] [char](1) NULL,
			[TR_FLG] [char](1) NULL,
			[import_flg] [int] NULL
		)

		DECLARE @table_mli02_is table ( 
			[NYKP] [char](13) NOT NULL,
			[MSGS] [char](4) NOT NULL,
			[BSIJD] [char](8) NULL,
			[SHGM] [char](5) NULL,
			[KEIJ] [char](10) NULL,
			[SOFS] [char](15) NULL,
			[HKNK] [char](3) NULL,
			[LOCT] [char](6) NULL,
			[TOKI] [char](15) NULL,
			[TOKI2] [char](20) NULL,
			[KGSS] [int] NULL,
			[KGBS] [int] NULL,
			[HASM] [varchar](6) NULL,
			[SMGS] [char](4) NULL,
			[TKEM] [char](20) NULL,
			[NKYS] [decimal](18, 0) NULL,
			[TMSS] [int] NULL,
			[SZON] [char](15) NULL,
			[LOTN] [char](10) NULL,
			[INVN] [varchar](15) NULL,
			[NYKD] [char](8) NULL,
			[NYID] [char](5) NULL,
			[BRKC] [char](5) NULL,
			[FG01] [char](1) NULL,
			[FG02] [char](1) NULL,
			[FG03] [char](1) NULL,
			[FG04] [char](1) NULL,
			[FG05] [char](1) NULL,
			[TR_FLG] [char](1) NULL
		)

		DECLARE @lotno VARCHAR(MAX)
		DECLARE @sql NVARCHAR(MAX)

		-----------------------------------------------(1)-----------------------------------------------
		-------------<<< INSERT lot lsi to @table_mli02
		INSERT INTO @table_mli02 (
			[NYKP]
			,[MSGS]
			,[BSIJD]
			,[SHGM]
			,[KEIJ]
			,[SOFS]
			,[HKNK]
			,[LOCT]
			,[TOKI]
			,[TOKI2]
			,[KGSS]
			,[KGBS]
			,[HASM]
			,[SMGS]
			,[TKEM]
			,[NKYS]
			,[TMSS]
			,[SZON]
			,[LOTN]
			,[INVN]
			,[NYKD]
			,[NYID]
			,[BRKC]
			,[FG01]
			,[FG02]
			,[FG03]
			,[FG04]
			,[FG05]
			,[TR_FLG]
			,[import_flg]
		) 
		SELECT [NYKP]
			,[MSGS]
			,[BSIJD]
			,[SHGM]
			,[KEIJ]
			,[SOFS]
			,[HKNK]
			,[LOCT]
			,[TOKI]
			,[TOKI2]
			,[KGSS]
			,[KGBS]
			,[HASM]
			,[SMGS]
			,[TKEM]
			,[NKYS]
			,[TMSS]
			,[SZON]
			,[LOTN]
			,[INVN]
			,[NYKD]
			,[NYID]
			,[BRKC]
			,[FG01]
			,[FG02]
			,[FG03]
			,[FG04]
			,[FG05]
			,[TR_FLG]
			,[import_flg]
		FROM [APCSProDB].[trans].[mli02_lsi]
		WHERE [mli02_lsi].[import_flg] = 0;
		------------->>> INSERT lot lsi to @table_mli02

		-------------<<< INSERT lot is to @table_mli02_is
		SELECT @lotno = COALESCE(@lotno + ''''',''''','''''', '') + [LOTN]
		FROM @table_mli02 as [mli02_lsi]
		WHERE [mli02_lsi].[import_flg] = 0
		GROUP BY [LOTN]

		SET @sql = 'SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
					'''SELECT * FROM [DBLSISHT].[dbo].[MLI02_LSI] '+ 
					'WHERE [LOTN] in (' + @lotno + ''''')'')';

		INSERT INTO @table_mli02_is EXEC sp_executesql @sql
		------------->>> INSERT lot is to @table_mli02_is

		-------------<<< update [import_flg] 0 to 1
		UPDATE [mli02_lsi]
			SET [mli02_lsi].[import_flg] = 1
		FROM @table_mli02 AS [mli02_lsi]
		INNER JOIN @table_mli02_is AS [mli02_lsi_is] ON [mli02_lsi].[LOTN] = [mli02_lsi_is].[LOTN] 
			AND [mli02_lsi].[NYKP] = [mli02_lsi_is].[NYKP]
		WHERE [mli02_lsi].[import_flg] = 0;
		------------->>> update [import_flg] 0 to 1

		-------------<<< update @table_mli02 to [APCSProDB].[trans].[mli02_lsi]
		UPDATE [APCSProDB].[trans].[mli02_lsi]
		  set [mli02_lsi].[import_flg] = 1
		FROM [APCSProDB].[trans].[mli02_lsi] 
		INNER JOIN @table_mli02 as [mli02_lsi_table] on [mli02_lsi].[LOTN] = [mli02_lsi_table].[LOTN]
			and [mli02_lsi].[NYKP] = [mli02_lsi_table].[NYKP]
			and [mli02_lsi_table].[import_flg] = 1
		------------->>> update @table_mli02 to [APCSProDB].[trans].[mli02_lsi]
		-----------------------------------------------(1)-----------------------------------------------

		-----------------------------------------------(2)-----------------------------------------------
		------------<<< Insert to mli02_lsi (is)
		INSERT INTO OPENDATASOURCE ('SQLNCLI', 'Server= 10.28.1.144;Uid=ship;Pwd=ship').[DBLSISHT].[dbo].[MLI02_LSI]
		(
			[NYKP]
			,[MSGS]
			,[BSIJD]
			,[SHGM]
			,[KEIJ]
			,[SOFS]
			,[HKNK]
			,[LOCT]
			,[TOKI]
			,[TOKI2]
			,[KGSS]
			,[KGBS]
			,[HASM]
			,[SMGS]
			,[TKEM]
			,[NKYS]
			,[TMSS]
			,[SZON]
			,[LOTN]
			,[INVN]
			,[NYKD]
			,[NYID]
			,[BRKC]
			,[FG01]
			,[FG02]
			,[FG03]
			,[FG04]
			,[FG05]
			,[TR_FLG]
		)
		SELECT [NYKP]
			,[MSGS]
			,[BSIJD]
			,[SHGM]
			,[KEIJ]
			,[SOFS]
			,[HKNK]
			,[LOCT]
			,[TOKI]
			,[TOKI2]
			,[KGSS]
			,[KGBS]
			,[HASM]
			,[SMGS]
			,[TKEM]
			,[NKYS]
			,[TMSS]
			,[SZON]
			,[LOTN]
			,[INVN]
			,[NYKD]
			,[NYID]
			,[BRKC]
			,[FG01]
			,[FG02]
			,[FG03]
			,[FG04]
			,[FG05]
			,[TR_FLG]
		FROM @table_mli02 as [mli02_lsi]
		WHERE [mli02_lsi].[import_flg] = 0;
		------------>>> Insert to mli02_lsi (is)
		-----------------------------------------------(2)-----------------------------------------------

		-----------------------------------------------(3)-----------------------------------------------
		------------<<< Clear parameter table
		DELETE FROM @table_mli02;
		DELETE FROM @table_mli02_is;
		SET @lotno = NULL;
		SET @sql = NULL;
		------------>>> Clear parameter table

		-------------<<< INSERT lot lsi to @table_mli02
		INSERT INTO @table_mli02 (
			[NYKP]
			,[MSGS]
			,[BSIJD]
			,[SHGM]
			,[KEIJ]
			,[SOFS]
			,[HKNK]
			,[LOCT]
			,[TOKI]
			,[TOKI2]
			,[KGSS]
			,[KGBS]
			,[HASM]
			,[SMGS]
			,[TKEM]
			,[NKYS]
			,[TMSS]
			,[SZON]
			,[LOTN]
			,[INVN]
			,[NYKD]
			,[NYID]
			,[BRKC]
			,[FG01]
			,[FG02]
			,[FG03]
			,[FG04]
			,[FG05]
			,[TR_FLG]
			,[import_flg]
		) 
		SELECT [NYKP]
			,[MSGS]
			,[BSIJD]
			,[SHGM]
			,[KEIJ]
			,[SOFS]
			,[HKNK]
			,[LOCT]
			,[TOKI]
			,[TOKI2]
			,[KGSS]
			,[KGBS]
			,[HASM]
			,[SMGS]
			,[TKEM]
			,[NKYS]
			,[TMSS]
			,[SZON]
			,[LOTN]
			,[INVN]
			,[NYKD]
			,[NYID]
			,[BRKC]
			,[FG01]
			,[FG02]
			,[FG03]
			,[FG04]
			,[FG05]
			,[TR_FLG]
			,[import_flg]
		FROM [APCSProDB].[trans].[mli02_lsi]
		WHERE [mli02_lsi].[import_flg] = 0;
		------------->>> INSERT lot lsi to @table_mli02

		-------------<<< INSERT lot is to @table_mli02_is
		SELECT @lotno = COALESCE(@lotno + ''''',''''','''''', '') + [LOTN]
		FROM @table_mli02 as [mli02_lsi]
		WHERE [mli02_lsi].[import_flg] = 0
		GROUP BY [LOTN]

		SET @sql = 'SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
					'''SELECT * FROM [DBLSISHT].[dbo].[MLI02_LSI] '+ 
					'WHERE [LOTN] in (' + @lotno + ''''')'')';

		INSERT INTO @table_mli02_is EXEC sp_executesql @sql
		------------->>> INSERT lot is to @table_mli02_is

		-------------<<< update [import_flg] 0 to 1
		UPDATE [mli02_lsi]
			SET [mli02_lsi].[import_flg] = 1
		FROM @table_mli02 AS [mli02_lsi]
		INNER JOIN @table_mli02_is AS [mli02_lsi_is] ON [mli02_lsi].[LOTN] = [mli02_lsi_is].[LOTN] 
			AND [mli02_lsi].[NYKP] = [mli02_lsi_is].[NYKP]
		WHERE [mli02_lsi].[import_flg] = 0;
		------------->>> update [import_flg] 0 to 1

		-------------<<< update @table_mli02 to [APCSProDB].[trans].[mli02_lsi]
		UPDATE [APCSProDB].[trans].[mli02_lsi]
		  set [mli02_lsi].[import_flg] = 1
		FROM [APCSProDB].[trans].[mli02_lsi] 
		INNER JOIN @table_mli02 as [mli02_lsi_table] on [mli02_lsi].[LOTN] = [mli02_lsi_table].[LOTN]
			and [mli02_lsi].[NYKP] = [mli02_lsi_table].[NYKP]
			and [mli02_lsi_table].[import_flg] = 1
		------------->>> update @table_mli02 to [APCSProDB].[trans].[mli02_lsi]
		-----------------------------------------------(3)-----------------------------------------------

		---------------edit 26/02/2022 10.00
	END TRY  
	BEGIN CATCH  
		SELECT  
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_SEVERITY() AS ErrorSeverity  
			,ERROR_STATE() AS ErrorState  
			,ERROR_PROCEDURE() AS ErrorProcedure  
			,ERROR_MESSAGE() AS ErrorMessage;  
	END CATCH;  
END

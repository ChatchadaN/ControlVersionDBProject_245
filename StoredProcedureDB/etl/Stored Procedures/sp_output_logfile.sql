


/************************************************************/
/*  RIST APCS Pro                                           */
/*                                                          */
/*  ファイル出力                                            */
/*                                                          */
/*                2018-04-17 Created by T.Hori              */
/*                                                          */
/*   引数：@FilePath_Name	出力先パス・ファイル名			*/
/*   引数：@Function_Name	ファンクション名				*/
/*   引数：@Text			出力テキスト					*/
/*                                                          */
/************************************************************/

CREATE PROCEDURE [etl].[sp_output_logfile] (
										@FilePathName_ NVARCHAR(1000),
										@FunctionName_ NVARCHAR(128),
										@Text_ NVARCHAR(1000)
										) AS
BEGIN

    ---------------------------------------------------------------------------
	--(1)引数チェック
    ---------------------------------------------------------------------------
	BEGIN
		IF RTRIM(@filePathName_) = ''
			RETURN -1
	END;

	-----------------------------------------------------------------------------
	----(2)LINK設定変更
	----xp_cmdshell=Trueになっているようなので、設定しない
	-----------------------------------------------------------------------------
	--DECLARE @sqlLink NVARCHAR(4000) = '';
	--BEGIN TRY
	--	/* SQL Serverの設定変更可能に */
	--	SET @sqlLink = '';
	--	SET @sqlLink = @sqlLink + 'sp_configure ''show advanced options'', 1; ';
	--	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	--	PRINT @sqlLink;
	--	EXECUTE (@sqlLink);

	--	/* ファイル出力設定可能にする */
	--	SET @sqlLink = '';
	--	SET @sqlLink = @sqlLink + 'sp_configure ''xp_cmdshell'', 1; ';
	--	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	--	PRINT @sqlLink;
	--	EXECUTE (@sqlLink);

	--	/* SQL Serverの設定変更不可に */
	--	SET @sqlLink = '';
	--	SET @sqlLink = @sqlLink + 'sp_configure ''show advanced options'', 0; ';
	--	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	--	PRINT @sqlLink;
	--	EXECUTE (@sqlLink);
	--END TRY

	--BEGIN CATCH
	--	/* SQL Serverの設定変更可能に */
	--	SET @sqlLink = '';
	--	SET @sqlLink = @sqlLink + 'sp_configure ''show advanced options'', 1; ';
	--	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	--	PRINT @sqlLink;
	--	EXECUTE (@sqlLink);

	--	/* エラー時は戻す */
	--	SET @sqlLink = '';
	--	SET @sqlLink = @sqlLink + 'sp_configure ''xp_cmdshell'', 0; ';
	--	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	--	PRINT @sqlLink;
	--	EXECUTE (@sqlLink);

	--	/* SQL Serverの設定変更不可に */
	--	SET @sqlLink = '';
	--	SET @sqlLink = @sqlLink + 'sp_configure ''show advanced options'', 0; ';
	--	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	--	PRINT @sqlLink;
	--	EXECUTE (@sqlLink);

	--	RETURN -1;
	--END CATCH;

    ---------------------------------------------------------------------------
	--(3)テキスト出力
    ---------------------------------------------------------------------------
	--出力文整形
	DECLARE @output_text NVARCHAR(2000) = '';
	SET @output_text = FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ' + '[' + @FunctionName_ + ']' + @text_

	--出力コマンド生成
	DECLARE @cmd NVARCHAR(4000);
	SET @cmd = 'echo ' + @output_text + '>>' + @filePathName_

	EXECUTE master..xp_cmdshell @cmd;

	-----------------------------------------------------------------------------
	----(4)LINK設定を戻す
	-----------------------------------------------------------------------------
	--BEGIN TRY
	--	/* SQL Serverの設定変更可能に */
	--	SET @sqlLink = '';
	--	SET @sqlLink = @sqlLink + 'sp_configure ''show advanced options'', 1; ';
	--	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	--	PRINT @sqlLink;
	--	EXECUTE (@sqlLink);

	--	/* 設定戻す */
	--	SET @sqlLink = '';
	--	SET @sqlLink = @sqlLink + 'sp_configure ''xp_cmdshell'', 0; ';
	--	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	--	PRINT @sqlLink;
	--	EXECUTE (@sqlLink);

	--	/* SQL Serverの設定変更不可に */
	--	SET @sqlLink = '';
	--	SET @sqlLink = @sqlLink + 'sp_configure ''show advanced options'', 0; ';
	--	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	--	PRINT @sqlLink;
	--	EXECUTE (@sqlLink);
	--END TRY

	--BEGIN CATCH
	--	/* SQL Serverの設定変更不可に */
	--	SET @sqlLink = '';
	--	SET @sqlLink = @sqlLink + 'sp_configure ''show advanced options'', 0; ';
	--	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	--	PRINT @sqlLink;
	--	EXECUTE (@sqlLink);

	--	RETURN -1;
	--END CATCH;

	RETURN 0;

END ;







CREATE PROCEDURE [etl].[sp_etl_2-08_out_insp] (@v_ProServerName NVARCHAR(128) = ''
											,@v_ProDatabaseName NVARCHAR(128) = ''
											,@v_ProSchemeName NVARCHAR(128) = ''
											,@v_ISServerName NVARCHAR(128) = ''
											,@v_ISDatabaseName NVARCHAR(128) = ''
											,@v_ISSchemeName NVARCHAR(128) = ''
											,@o_shiptime_max datetime output
											,@logtext nvarchar(max) output
											,@errnum  INT output
											,@errline INT output
											,@errmsg nvarchar(max) output
)AS
BEGIN

    ---------------------------------------------------------------------------
	--(1) Declare
    ---------------------------------------------------------------------------
	DECLARE @ProServerName NVARCHAR(128) = N'';
	DECLARE @ProDatabaseName NVARCHAR(128) = N'APCSProDB';
	DECLARE @ProSchemeName NVARCHAR(128) = N'trans';
	--DECLARE @ISServerName NVARCHAR(128) = N'10.28.1.145';
	DECLARE @ISServerName NVARCHAR(128) = N'10.28.1.144';
	DECLARE @ISDatabaseName NVARCHAR(128) = N'DBLSISHT';
	DECLARE @ISSchemeName NVARCHAR(128) = N'dbo';
	DECLARE @objectname NVARCHAR(128) = '';
	DECLARE @objectnameIS NVARCHAR(128) = '';
	DECLARE @dot NVARCHAR(1) = '.';
	DECLARE @ret INT = 0;
	DECLARE @sqltmp NVARCHAR(max) = '';
	DECLARE @rowcnt INT = 0;



    ---------------------------------------------------------------------------
	--(1) connection string
    ---------------------------------------------------------------------------
		IF isnull(RTRIM(@v_ProServerName),'') = ''
			BEGIN
				SET @ProServerName = '';
			END;
		ELSE
			BEGIN
				SET @ProServerName = '[' + @v_ProServerName + ']';
			END;

		IF RTRIM(@v_ProDatabaseName) = ''
			BEGIN
				SET @ProDatabaseName = '[' + @ProDatabaseName + ']';
			END;
		ELSE
			BEGIN
				SET @ProDatabaseName = '[' + @v_ProDatabaseName + ']';
			END;

		IF RTRIM(@v_ProSchemeName) = ''
			BEGIN
				SET @ProSchemeName = '[' + @ProSchemeName + ']';
			END;
		ELSE
			BEGIN
				SET @ProSchemeName = '[' + @v_ProSchemeName + ']';
			END;

		IF RTRIM(@v_ISServerName) = ''
			BEGIN
				SET @ISServerName = @ISServerName;
			END;
		ELSE
			BEGIN
				SET @ISServerName = @v_ISServerName;
			END;

		IF RTRIM(@v_ISDatabaseName) = ''
			BEGIN
				SET @ISDatabaseName = '[' + @ISDatabaseName + ']';
			END;
		ELSE
			BEGIN
				SET @ISDatabaseName = '[' + @v_ISDatabaseName + ']';
			END;

		IF RTRIM(@v_ISSchemeName) = ''
			BEGIN
				SET @ISSchemeName = '[' + @ISSchemeName + ']';
			END;
		ELSE
			BEGIN
				SET @ISSchemeName = '[' + @v_ISSchemeName + ']';
			END;

		if RTRIM(@ProServerName) = ''
			BEGIN
				set @objectname = @ProDatabaseName + @dot + @ProSchemeName + @dot
			END;
		else
			BEGIN
				set @objectname = @ProServerName + @dot + @ProDatabaseName + @dot + @ProSchemeName + @dot
			END;

		set @objectnameIS = @dot + @ISDatabaseName + @dot + @ISSchemeName + @dot


    ---------------------------------------------------------------------------
	--(2) declare (log)
    ---------------------------------------------------------------------------
	--DECLARE @pathname NVARCHAR(128) = N'\\10.28.33.5\NewCenterPoint\APCS_PRO\DATABASE\SSISLog\';
	--DECLARE @logfile NVARCHAR(128) = N'Log' + CONVERT(NVARCHAR(8), FORMAT(GETDATE(), 'yyyyMMdd')) + N'.log';
	--DECLARE @logfilepathname NVARCHAR(256) = CONVERT(NVARCHAR(256), (@pathname + @logfile));
	--DECLARE @errlogfile NVARCHAR(128) = N'ErrorLog' + CONVERT(NVARCHAR(8), FORMAT(GETDATE(), 'yyyyMMdd')) + N'.log';
	--DECLARE @errlogfilepathname NVARCHAR(256) = CONVERT(NVARCHAR(256), (@pathname + @errlogfile));
	--DECLARE @logtext NVARCHAR(2000) = '';

	--DECLARE @sqlLink NVARCHAR(4000) = '';

    ---------------------------------------------------------------------------
	--(3) get function_finish_control last_finish
    ---------------------------------------------------------------------------
	DECLARE @functionname NVARCHAR(128) = ''
	DECLARE @starttime DATETIME;
	DECLARE @endtime DATETIME;
	BEGIN TRY
		SELECT @functionname = OBJECT_NAME(@@PROCID);

		SELECT @starttime = dateadd(day,-1,convert(date,finished_at))  FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = @functionname
		PRINT '@starttime=' + CASE WHEN @starttime IS NULL THEN '' ELSE FORMAT(@starttime, 'yyyy-MM-dd HH:mm:ss.fff') END;

		SELECT @endtime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
		PRINT '@endtime=' + FORMAT(@endtime, 'yyyy-MM-dd HH:mm:ss.fff');
	END TRY
	BEGIN CATCH
		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

	/*
    ---------------------------------------------------------------------------
	--(4) exec sp_configure
    ---------------------------------------------------------------------------
	BEGIN TRY
		SET @sqlLink = '';
		SET @sqlLink = @sqlLink + 'sp_configure ''show advanced options'', 1; ';
		SET @sqlLink = @sqllink + 'reconfigure with override; ';
		PRINT @sqlLink;
		EXECUTE (@sqlLink);

		SET @sqlLink = '';
		SET @sqlLink = @sqlLink + 'sp_configure ''Ad Hoc Distributed Queries'', 1; ';
		SET @sqlLink = @sqllink + 'reconfigure with override; ';
		PRINT @sqlLink;
		EXECUTE (@sqlLink);

		SET @sqlLink = '';
		SET @sqlLink = @sqlLink + 'sp_configure ''show advanced options'', 0; ';
		SET @sqlLink = @sqllink + 'reconfigure with override; ';
		PRINT @sqlLink;
		EXECUTE (@sqlLink);
	END TRY

	BEGIN CATCH
		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;

		RETURN -1;
	END CATCH;
	*/

	---------------------------------------------------------------------------
    --(5)([trans].[temp_V_OUT_INSP]) truncate
    ---------------------------------------------------------------------------
    --DECLARE @SqlTrunc NVARCHAR(100) = N'TRUNCATE TABLE ' + @objectname + '[temp_V_OUT_INSP]; ';
    DECLARE @SqlTrunc NVARCHAR(100) = N'DELETE FROM ' + @objectname + '[temp_V_OUT_INSP]; ';
	PRINT @SqlTrunc;
    EXECUTE (@SqlTrunc);

    ---------------------------------------------------------------------------
	--(6) make sql for insert ([trans].[temp_V_OUT_INSP])
    ---------------------------------------------------------------------------
	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N' INSERT INTO ' + @objectname + '[temp_V_OUT_INSP]';
	SET @sqltmp = @sqltmp + N'( ';
	SET @sqltmp = @sqltmp + N' lot_no ';
	SET @sqltmp = @sqltmp + N',qty_out ';
	SET @sqltmp = @sqltmp + N',ship_date_id ';
	SET @sqltmp = @sqltmp + N',ship_at ';
	SET @sqltmp = @sqltmp + N',updated_at ';
	SET @sqltmp = @sqltmp + N',update_flg ';
	SET @sqltmp = @sqltmp + N',record_no ';
	SET @sqltmp = @sqltmp + N',lot_id ';
	SET @sqltmp = @sqltmp + N') ';

	SET @sqltmp = @sqltmp + N' SELECT';
	SET @sqltmp = @sqltmp + N' t1.[2_lot_no]';
	SET @sqltmp = @sqltmp + N',t1.[3_qty_out]';
	SET @sqltmp = @sqltmp + N',t1.[5_ship_date_id]';
	SET @sqltmp = @sqltmp + N',t1.[6_ship_at]';
	SET @sqltmp = @sqltmp + N',t1.[7_updated_at]';
	SET @sqltmp = @sqltmp + N',1 as update_flg';
	SET @sqltmp = @sqltmp + N',t1.record_no AS record_no';
	SET @sqltmp = @sqltmp + N',t1.[lot_id] AS [lot_id]';

	SET @sqltmp = @sqltmp + N' FROM';
	SET @sqltmp = @sqltmp + N' (';

	SET @sqltmp = @sqltmp + N' SELECT';
	SET @sqltmp = @sqltmp + N' RTRIM(INSP.lotno) AS [2_lot_no]';
	SET @sqltmp = @sqltmp + N',INSP.QTY AS [3_qty_out]';
	SET @sqltmp = @sqltmp + N',days.id AS [5_ship_date_id]';
	SET @sqltmp = @sqltmp + N',INSP.Date1 + CONVERT(char(12),dateadd(second, INSP.Time1, CONVERT(datetime, 0)) ,108) AS [6_ship_at]';
	SET @sqltmp = @sqltmp + N',GETDATE() AS [7_updated_at]';
	SET @sqltmp = @sqltmp + N',(INSP.Good_QTY-INSP.QTY) AS [surpluses_pcs]';
	SET @sqltmp = @sqltmp + N',ROW_NUMBER() OVER(PARTITION BY INSP.lotno ORDER BY INSP.lotno, INSP.Date1 desc, INSP.Time1 desc) AS record_no';
	SET @sqltmp = @sqltmp + N',lots.id AS [lot_id]';

	SET @sqltmp = @sqltmp + N' FROM OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ISServerName + ';UID=ship;PWD=ship;'')' + @objectnameIS + '[OUT_INSP] AS INSP ';

	SET @sqltmp = @sqltmp + N' INNER JOIN ' + @objectname + '[days] AS days with (NOLOCK) ON days.date_value = INSP.Date1';
	SET @sqltmp = @sqltmp + N' INNER JOIN ' + @objectname + '[lots] AS lots with (NOLOCK) ON RTRIM(lots.lot_no) = RTRIM(INSP.lotno)';

	SET @sqltmp = @sqltmp + N' where INSP.Date1 >= ''' + convert(varchar,@starttime,21) + ''' ';
	SET @sqltmp = @sqltmp + N'		and lots.id is not null ';
	SET @sqltmp = @sqltmp + N' ) as t1 ';
	SET @sqltmp = @sqltmp + N' where t1.record_no = 1 ';

    ---------------------------------------------------------------------------
	--(6-1) exec sql
    ---------------------------------------------------------------------------
	BEGIN TRY

		PRINT '----------------------------------------';
		PRINT '@sqltmp=' + @sqltmp;

		EXECUTE (@sqltmp);
		set @rowcnt = @@ROWCOUNT

		print '@sqltmp:OK rows:' + convert(varchar,@rowcnt)

	END TRY

	BEGIN CATCH
		SET @logtext = ERROR_MESSAGE() + '/SQL:' + @sqltmp ;
			print '@sqltmp:ERR ' + @logtext

		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;

	END CATCH;

	if @rowcnt = 0
		begin
			RETURN 0;
		end;

	--DECLARE @mxtime DATETIME;
	BEGIN TRY
		set @sqltmp = N'';
		set @sqltmp = @sqltmp + N'SELECT @xtime = max(ship_at) FROM ' + @objectname + '[temp_V_OUT_INSP]';
		EXEC sp_executesql @sqltmp, N'@xtime datetime OUTPUT', @xtime=@o_shiptime_max OUTPUT;

	END TRY
	BEGIN CATCH
		SET @logtext = '[ERR] @mxtime ' + ERROR_MESSAGE() + '/SQL:' + @sqltmp;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;



    ---------------------------------------------------------------------------
	--(8-0)temp update(XV‘ÎÛƒŒƒR[ƒh‚Ì‚ÝAupdate_flg = 1)
    ---------------------------------------------------------------------------
	--SET @tempUpdate = ''
	--SET @tempUpdate = @tempUpdate + ' UPDATE [' + @link_APCSProDB_name + '].[trans].[temp_V_OUT_INSP] ';
	--SET @tempUpdate = @tempUpdate + ' SET ';
	--SET @tempUpdate = @tempUpdate + ' update_flg = 1 ';
	--SET @tempUpdate = @tempUpdate + ' FROM [' + @link_APCSProDB_name + '].[trans].[temp_V_OUT_INSP] AS temp ';
	--SET @tempUpdate = @tempUpdate + ' INNER JOIN ( ';
	--SET @tempUpdate = @tempUpdate + ' SELECT ';
	--SET @tempUpdate = @tempUpdate + ' lot_id ';
	--SET @tempUpdate = @tempUpdate + ',MAX(record_no) AS record_no ';
	--SET @tempUpdate = @tempUpdate + ' FROM [' + @link_APCSProDB_name + '].[trans].[temp_V_OUT_INSP] ';
	--SET @tempUpdate = @tempUpdate + ' WHERE lot_id IS NOT NULL ';
	--SET @tempUpdate = @tempUpdate + ' AND record_no > 0 ';
	--SET @tempUpdate = @tempUpdate + ' GROUP BY lot_id ';
	--SET @tempUpdate = @tempUpdate + ') AS t_lot ';
	--SET @tempUpdate = @tempUpdate + 'ON t_lot.lot_id = temp.lot_id ';
	--SET @tempUpdate = @tempUpdate + 'AND t_lot.record_no = temp.record_no ';

	--BEGIN TRY
	--	BEGIN TRANSACTION;

	--	PRINT '----------------------------------------';
	--	PRINT '@tempUpdate=' + @tempUpdate;

	--	EXECUTE (@tempUpdate);

	--	PRINT '@tempUpdate:OK';


	--	COMMIT TRANSACTION;
	--END TRY
	--BEGIN CATCH
	--	IF @@TRANCOUNT <> 0
	--		BEGIN
	--			ROLLBACK TRANSACTION;
	--		END;
	--	SET @logtext = '[ERR]' + ERROR_MESSAGE();
	--	PRINT '@tempUpdate:NG';
	--	print @logtext;

	--	EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
	--	RETURN -1;
	--END CATCH;

 --   ---------------------------------------------------------------------------
	----(8-1)idŒ”Žæ“¾(lot_process_records)
 --   ---------------------------------------------------------------------------
	--DECLARE @INSP_count_process INT=0;
	--SET @sql1 = ''
	--SET @sql1 = @sql1 + ' SELECT @INSP_count_out = COUNT(lot_no) '
	--SET @sql1 = @sql1 + ' FROM ( '
	--SET @sql1 = @sql1 + ' SELECT temp.lot_no '
	--SET @sql1 = @sql1 + ' FROM [' + @link_APCSProDB_name + '].[trans].[temp_V_OUT_INSP] AS temp '
	--SET @sql1 = @sql1 + ' WHERE temp.lot_id IS NOT NULL '
	--SET @sql1 = @sql1 + ' AND temp.update_flg = 1 '
	--SET @sql1 = @sql1 + ' ) AS INSP'
	--PRINT '----------------------------------------';
	--PRINT '@sql1=' + @sql1;

	--BEGIN TRY
	--	EXEC sp_executesql @sql1, N'@INSP_count_out INT OUTPUT', @INSP_count_out=@INSP_count_process OUTPUT;
	--	PRINT '@sql1:OK';
	--END TRY

	--BEGIN CATCH
	--	SET @logtext = '[ERR]' + ERROR_MESSAGE();
	--	PRINT '@sql1:NG';
	--	print @logtext;
	--	EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
	--	RETURN -1;
	--END CATCH;

 --   DECLARE @idlast_process INT
	--DECLARE @idend_process INT 

	--BEGIN TRY
	--	EXECUTE @ret = [etl].[sp_update_numbers] @servername=@link_APCSProDB_name 
	--										, @schemaname='trans'
	--										, @name = 'lot_process_records.id'
	--										, @count = @INSP_count_process
	--										, @idlast = @idlast_process OUTPUT
	--										, @idend = @idend_process OUTPUT
	--	PRINT 'sp_update_numbers0:OK RET:' + convert(varchar,@ret);

	--	IF @ret<>0
	--		begin
	--			SET @logtext = '[ERR] [etl].[sp_update_numbers]';
	--			PRINT 'sp_update_numbers0:NG';
	--			EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
	--		end;
	--END TRY

	--BEGIN CATCH
	--	IF @@TRANCOUNT <> 0
	--		BEGIN
	--			ROLLBACK TRANSACTION;
	--		END;
	--	SET @logtext = '[ERR]' + ERROR_MESSAGE();
	--		PRINT 'sp_update_numbers0:ERR' + @logtext;

	--	EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
	--	RETURN -1;
	--END CATCH;

 --   ---------------------------------------------------------------------------
	----(8-2)idŒ”Žæ“¾(surpluses)
 --   ---------------------------------------------------------------------------
	--DECLARE @INSP_count_surpluses INT=0;
	--SET @sql2 = ''
	--SET @sql2 = @sql2 + ' SELECT @INSP_count_out = COUNT(lot_no) '
	--SET @sql2 = @sql2 + ' FROM ( '
	--SET @sql2 = @sql2 + ' SELECT temp.lot_no '
	--SET @sql2 = @sql2 + ' FROM [' + @link_APCSProDB_name + '].[trans].[temp_V_OUT_INSP] AS temp '
	--SET @sql2 = @sql2 + ' WHERE temp.surpluses_pcs > 0 '
	--SET @sql2 = @sql2 + ' AND temp.lot_id IS NOT NULL '
	--SET @sql2 = @sql2 + ' AND temp.id_surpluses IS NULL '
	--SET @sql2 = @sql2 + ' AND temp.update_flg = 1 '
	--SET @sql2 = @sql2 + ' GROUP BY temp.lot_no ) AS INSP'
	--PRINT '----------------------------------------';
	--PRINT '@sql2=' + @sql2;

	--BEGIN TRY
	--	EXEC sp_executesql @sql2, N'@INSP_count_out INT OUTPUT', @INSP_count_out=@INSP_count_surpluses OUTPUT;
	--		PRINT '@sql2:OK';
	--END TRY

	--BEGIN CATCH
	--	SET @logtext = '[ERR]' + ERROR_MESSAGE();
	--		PRINT '@sql2:NG' + @logtext;
	--	EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
	--	RETURN -1;
	--END CATCH;

 --   DECLARE @idlast_surpluses INT
	--DECLARE @idend_surpluses INT 

	--BEGIN TRY
	--	EXECUTE [etl].[sp_update_numbers] @servername=@link_APCSProDB_name 
	--								 , @schemaname='trans'
	--								 , @name = 'surpluses.id'
	--								 , @count = @INSP_count_surpluses
	--								 , @idlast = @idlast_surpluses OUTPUT
	--								 , @idend = @idend_surpluses OUTPUT
	--	PRINT 'sp_update_numbers:OK RET:' + convert(varchar,@ret);
	--	IF @ret<>0
	--		begin
	--			SET @logtext = '[ERR] [etl].[sp_update_numbers]';
	--			PRINT 'sp_update_numbers:NG' + convert(varchar,@ret);
	--			EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
	--		end;
	--END TRY

	--BEGIN CATCH
	--	IF @@TRANCOUNT <> 0
	--		BEGIN
	--			ROLLBACK TRANSACTION;
	--		END;
	--	SET @logtext = '[ERR]' + ERROR_MESSAGE();
	--	PRINT 'sp_update_numbers:ERR' + @logtext;
	--	EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
	--	RETURN -1;
	--END CATCH;

    ---------------------------------------------------------------------------
	--(9)“‡—pSQL•¶ì¬
    ---------------------------------------------------------------------------
	--SET @sqllots = '';
	--SET @sqllots = @sqllots + 'MERGE INTO [' + @link_APCSProDB_name + '].[trans].[lots] AS lots ';
	--SET @sqllots = @sqllots + 'USING ( ';
	--SET @sqllots = @sqllots + 'SELECT ';
	--SET @sqllots = @sqllots + ' temp.lot_no ';
	--SET @sqllots = @sqllots + ',temp.qty_out ';
	--SET @sqllots = @sqllots + ',temp.ship_date_id ';
	--SET @sqllots = @sqllots + ',temp.ship_at ';
	--SET @sqllots = @sqllots + ',temp.surpluses_pcs ';
	--SET @sqllots = @sqllots + ',temp.record_no ';
	--SET @sqllots = @sqllots + ',temp.update_flg ';
	--SET @sqllots = @sqllots + ',temp.lot_id ';
	--SET @sqllots = @sqllots + ',temp.id_surpluses ';
	--SET @sqllots = @sqllots + 'FROM [' + @link_APCSProDB_name + '].[trans].[temp_V_OUT_INSP] AS temp ';
	--SET @sqllots = @sqllots + 'INNER JOIN ( ';
	--SET @sqllots = @sqllots + 'SELECT ';
	--SET @sqllots = @sqllots + ' lot_id ';
	--SET @sqllots = @sqllots + ',MAX(record_no) AS record_no ';
	--SET @sqllots = @sqllots + 'FROM [' + @link_APCSProDB_name + '].[trans].[temp_V_OUT_INSP] ';
	--SET @sqllots = @sqllots + 'WHERE lot_id IS NOT NULL ';
	--SET @sqllots = @sqllots + 'AND record_no > 0 ';
	--SET @sqllots = @sqllots + 'GROUP BY lot_id ';
	--SET @sqllots = @sqllots + ') AS t_lot ';
	--SET @sqllots = @sqllots + 'ON t_lot.lot_id = temp.lot_id ';
	--SET @sqllots = @sqllots + 'AND t_lot.record_no = temp.record_no ';
	--SET @sqllots = @sqllots + ') AS INSP ';
	--SET @sqllots = @sqllots + 'ON INSP.lot_id = lots.id '
	--SET @sqllots = @sqllots + 'WHEN MATCHED THEN ';
	--SET @sqllots = @sqllots + 'UPDATE SET ';
	--SET @sqllots = @sqllots + ' qty_out = INSP.qty_out '
	--SET @sqllots = @sqllots + ',wip_state = 100 '
	--SET @sqllots = @sqllots + ',ship_date_id  = INSP.ship_date_id '
	--SET @sqllots = @sqllots + ',ship_at = INSP.ship_at '
	--SET @sqllots = @sqllots + ',updated_at = GETDATE() '
	--SET @sqllots = @sqllots + ';'

	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'MERGE INTO ' + @objectname + '[lots] AS lots ';
	SET @sqltmp = @sqltmp + N'USING ' + @objectname + '[temp_V_OUT_INSP] AS temp ';

	SET @sqltmp = @sqltmp + N'		ON temp.lot_id = lots.id '
	SET @sqltmp = @sqltmp + N'			AND temp.update_flg = 1 '

	SET @sqltmp = @sqltmp + N'WHEN MATCHED THEN ';
	SET @sqltmp = @sqltmp + N'UPDATE SET ';
	SET @sqltmp = @sqltmp + N'		qty_out = temp.qty_out '
	SET @sqltmp = @sqltmp + N'		,wip_state = 100 '
	SET @sqltmp = @sqltmp + N'		,ship_date_id  = temp.ship_date_id '
	SET @sqltmp = @sqltmp + N'		,ship_at = temp.ship_at '
	SET @sqltmp = @sqltmp + N'		,updated_at = GETDATE() '
	SET @sqltmp = @sqltmp + N';'


 --   ---------------------------------------------------------------------------
	----(9-2)process—pSQL•¶ì¬
 --   ---------------------------------------------------------------------------
	--SET @sqlprocess = '';
	--SET @sqlprocess = @sqlprocess + ' INSERT INTO [' + @link_APCSProDB_name + '].[trans].[lot_process_records] ('
	--SET @sqlprocess = @sqlprocess + ' id'
	--SET @sqlprocess = @sqlprocess + ',day_id'
	--SET @sqlprocess = @sqlprocess + ',recorded_at'
	--SET @sqlprocess = @sqlprocess + ',operated_by'
	--SET @sqlprocess = @sqlprocess + ',record_class'
	--SET @sqlprocess = @sqlprocess + ',lot_id'
	--SET @sqlprocess = @sqlprocess + ',process_id'
	--SET @sqlprocess = @sqlprocess + ',job_id'
	--SET @sqlprocess = @sqlprocess + ',step_no'
	--SET @sqlprocess = @sqlprocess + ',qty_in'
	--SET @sqlprocess = @sqlprocess + ',qty_pass'
	--SET @sqlprocess = @sqlprocess + ',qty_fail'
	--SET @sqlprocess = @sqlprocess + ',qty_last_pass'
	--SET @sqlprocess = @sqlprocess + ',qty_last_fail'
	--SET @sqlprocess = @sqlprocess + ',qty_pass_step_sum'
	--SET @sqlprocess = @sqlprocess + ',qty_fail_step_sum'
	--SET @sqlprocess = @sqlprocess + ',qty_divided'
	--SET @sqlprocess = @sqlprocess + ',qty_hasuu'
	--SET @sqlprocess = @sqlprocess + ',qty_out'
	--SET @sqlprocess = @sqlprocess + ',machine_id'
	--SET @sqlprocess = @sqlprocess + ',process_job_id'
	--SET @sqlprocess = @sqlprocess + ',wip_state'
	--SET @sqlprocess = @sqlprocess + ',process_state'
	--SET @sqlprocess = @sqlprocess + ',quality_state'
	--SET @sqlprocess = @sqlprocess + ',first_ins_state'
	--SET @sqlprocess = @sqlprocess + ',final_ins_state'
	--SET @sqlprocess = @sqlprocess + ',is_special_flow'
	--SET @sqlprocess = @sqlprocess + ',special_flow_id'
	--SET @sqlprocess = @sqlprocess + ',is_temp_devided'
	--SET @sqlprocess = @sqlprocess + ',temp_devided_count'
	--SET @sqlprocess = @sqlprocess + ',container_no'
	--SET @sqlprocess = @sqlprocess + ',std_time_sum'
	--SET @sqlprocess = @sqlprocess + ',pass_plan_time'
	--SET @sqlprocess = @sqlprocess + ',pass_plan_time_up'
	--SET @sqlprocess = @sqlprocess + ',created_at'
	--SET @sqlprocess = @sqlprocess + ',created_by'
	--SET @sqlprocess = @sqlprocess + ',updated_at'
	--SET @sqlprocess = @sqlprocess + ',updated_by'
	--SET @sqlprocess = @sqlprocess + ') '
	--SET @sqlprocess = @sqlprocess + ' SELECT'
	--SET @sqlprocess = @sqlprocess + ' null '
	--SET @sqlprocess = @sqlprocess + ',temp.ship_date_id'
	--SET @sqlprocess = @sqlprocess + ',getdate()'
	--SET @sqlprocess = @sqlprocess + ',null'
	--SET @sqlprocess = @sqlprocess + ',7'
	--SET @sqlprocess = @sqlprocess + ',lots.id'
	--SET @sqlprocess = @sqlprocess + ',lots.act_process_id'
	--SET @sqlprocess = @sqlprocess + ',lots.act_job_id'
	--SET @sqlprocess = @sqlprocess + ',lots.step_no'
	--SET @sqlprocess = @sqlprocess + ',lots.qty_in'
	--SET @sqlprocess = @sqlprocess + ',lots.qty_pass'
	--SET @sqlprocess = @sqlprocess + ',lots.qty_fail'
	--SET @sqlprocess = @sqlprocess + ',lots.qty_last_pass'
	--SET @sqlprocess = @sqlprocess + ',lots.qty_last_fail'
	--SET @sqlprocess = @sqlprocess + ',lots.qty_pass_step_sum'
	--SET @sqlprocess = @sqlprocess + ',lots.qty_fail_step_sum'
	--SET @sqlprocess = @sqlprocess + ',lots.qty_divided'
	--SET @sqlprocess = @sqlprocess + ',lots.qty_hasuu'
	--SET @sqlprocess = @sqlprocess + ',lots.qty_out'
	--SET @sqlprocess = @sqlprocess + ',lots.machine_id'
	--SET @sqlprocess = @sqlprocess + ',lots.process_job_id'
	--SET @sqlprocess = @sqlprocess + ',lots.wip_state'
	--SET @sqlprocess = @sqlprocess + ',lots.process_state'
	--SET @sqlprocess = @sqlprocess + ',lots.quality_state'
	--SET @sqlprocess = @sqlprocess + ',lots.first_ins_state'
	--SET @sqlprocess = @sqlprocess + ',lots.final_ins_state'
	--SET @sqlprocess = @sqlprocess + ',lots.is_special_flow'
	--SET @sqlprocess = @sqlprocess + ',lots.special_flow_id'
	--SET @sqlprocess = @sqlprocess + ',lots.is_temp_devided'
	--SET @sqlprocess = @sqlprocess + ',lots.temp_devided_count'
	--SET @sqlprocess = @sqlprocess + ',lots.container_no'
	--SET @sqlprocess = @sqlprocess + ',lots.std_time_sum'
	--SET @sqlprocess = @sqlprocess + ',lots.pass_plan_time'
	--SET @sqlprocess = @sqlprocess + ',lots.pass_plan_time_up'
	--SET @sqlprocess = @sqlprocess + ',lots.created_at'
	--SET @sqlprocess = @sqlprocess + ',lots.created_by'
	--SET @sqlprocess = @sqlprocess + ',lots.updated_at'
	--SET @sqlprocess = @sqlprocess + ',lots.updated_by'
	--SET @sqlprocess = @sqlprocess + ' FROM [' + @link_APCSProDB_name + '].[trans].[lots] AS lots '
	--SET @sqlprocess = @sqlprocess + ' WHERE lots.id IS NULL '
	--SET @sqlprocess = @sqlprocess + '; '

 --   ---------------------------------------------------------------------------
	----(9-3)’[”—pSQL•¶ì¬
 --   ---------------------------------------------------------------------------
	--SET @sqlSurpIns = @sqlSurpIns + ' INSERT INTO [' + @link_APCSProDB_name + '].[trans].[surpluses] ('
	--SET @sqlSurpIns = @sqlSurpIns + ' id'
	--SET @sqlSurpIns = @sqlSurpIns + ',lot_id'
	--SET @sqlSurpIns = @sqlSurpIns + ',pcs'
	--SET @sqlSurpIns = @sqlSurpIns + ',serial_no'
	--SET @sqlSurpIns = @sqlSurpIns + ',in_stock'
	--SET @sqlSurpIns = @sqlSurpIns + ',created_at'
	--SET @sqlSurpIns = @sqlSurpIns + ') '
	--SET @sqlSurpIns = @sqlSurpIns + ' SELECT'
	--SET @sqlSurpIns = @sqlSurpIns + ' ' + RTRIM(CONVERT(NVARCHAR(10),@idlast_surpluses)) + ' + (ROW_NUMBER() OVER(ORDER BY INSP.lot_no)) '
	--SET @sqlSurpIns = @sqlSurpIns + ',INSP.lot_id'
	--SET @sqlSurpIns = @sqlSurpIns + ',INSP.surpluses_pcs'
	--SET @sqlSurpIns = @sqlSurpIns + ',RTRIM(INSP.lot_no) AS LotNo'
	--SET @sqlSurpIns = @sqlSurpIns + ',1'
	--SET @sqlSurpIns = @sqlSurpIns + ',getdate()'
	--SET @sqlSurpIns = @sqlSurpIns + ' FROM ('
	--SET @sqlSurpIns = @sqlSurpIns + ' SELECT'
	--SET @sqlSurpIns = @sqlSurpIns + ' lot_id'
	--SET @sqlSurpIns = @sqlSurpIns + ',lot_no'
	--SET @sqlSurpIns = @sqlSurpIns + ',SUM(surpluses_pcs) AS surpluses_pcs '
	--SET @sqlSurpIns = @sqlSurpIns + ' FROM [' + @link_APCSProDB_name + '].[trans].[temp_V_OUT_INSP] AS temp '
	--SET @sqlSurpIns = @sqlSurpIns + ' WHERE temp.surpluses_pcs > 0 '
	--SET @sqlSurpIns = @sqlSurpIns + ' AND temp.lot_id IS NOT NULL '
	--SET @sqlSurpIns = @sqlSurpIns + ' AND temp.id_surpluses IS NULL '
	--SET @sqlSurpIns = @sqlSurpIns + ' AND temp.update_flg = 1 '
	--SET @sqlSurpIns = @sqlSurpIns + ' GROUP BY temp.lot_id, lot_no '
	--SET @sqlSurpIns = @sqlSurpIns + ') AS INSP '

	--SET @sqlSurpUpd = @sqlSurpUpd + ' UPDATE [' + @link_APCSProDB_name + '].[trans].[surpluses] '
	--SET @sqlSurpUpd = @sqlSurpUpd + ' SET '
	--SET @sqlSurpUpd = @sqlSurpUpd + ' pcs = temp.surpluses_pcs '
	--SET @sqlSurpUpd = @sqlSurpUpd + ',in_stock = 1'
	--SET @sqlSurpUpd = @sqlSurpUpd + ',created_at = getdate()'
	--SET @sqlSurpUpd = @sqlSurpUpd + ' FROM [' + @link_APCSProDB_name + '].[trans].[temp_V_OUT_INSP] AS temp '
	--SET @sqlSurpUpd = @sqlSurpUpd + ' WHERE temp.id_surpluses = id '
	--SET @sqlSurpUpd = @sqlSurpUpd + ' AND temp.update_flg = 1 '

    ---------------------------------------------------------------------------
	--(9-4)“‡ˆ—
    ---------------------------------------------------------------------------
	BEGIN TRY
		BEGIN TRANSACTION;

		PRINT '----------------------------------------';
		PRINT @sqltmp;

		EXECUTE (@sqltmp);
		PRINT '@sqllots:OK';

		EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='', @finished_at_=@o_shiptime_max, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
			IF @ret<>0
				begin
					IF @@TRANCOUNT <> 0
						BEGIN
							ROLLBACK TRANSACTION;
						END;
					SET @logtext = '@ret<>0 [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline)+ '/msg:' + @errmsg;				
					PRINT 'sp_update_function_finish_control:NG' + convert(varchar,@ret) + @logtext;
					--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;

					return -1;
				end;


		--PRINT '----------------------------------------';
		--PRINT @sqlprocess;

		--EXECUTE (@sqlprocess);
		--PRINT '@sqlprocess:OK';

		--PRINT '----------------------------------------';
		--PRINT @sqlSurpIns;

		--EXECUTE (@sqlSurpIns);
		--PRINT '@sqlSurpIns:OK';

		--PRINT '----------------------------------------';
		--PRINT @sqlSurpUpd;

		--EXECUTE (@sqlSurpUpd);
		--PRINT '@sqlSurpUpd:OK';

		COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END;
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = '[ERR] [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg + '/SQL:' + @sqltmp ;
		PRINT 'transaction err ' + @logtext;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;
	
	RETURN 0;

END ;



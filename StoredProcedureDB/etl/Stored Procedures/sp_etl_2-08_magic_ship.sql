

CREATE PROCEDURE [etl].[sp_etl_2-08_magic_ship] (@v_ProServerName NVARCHAR(128) = ''
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
	DECLARE @starttime2 DATETIME;
	DECLARE @endtime2 DATETIME;
	BEGIN TRY
		SELECT @functionname = OBJECT_NAME(@@PROCID);

		SELECT @starttime = dateadd(day,-1,convert(date,finished_at))  FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = @functionname
		select @starttime2 = DATEADD(day,-10,@starttime)
		PRINT '@starttime=' + CASE WHEN @starttime IS NULL THEN '' ELSE FORMAT(@starttime, 'yyyy-MM-dd HH:mm:ss.fff') END;
		PRINT '@starttime2=' + CASE WHEN @starttime2 IS NULL THEN '' ELSE FORMAT(@starttime2, 'yyyy-MM-dd HH:mm:ss.fff') END;

		SELECT @endtime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
		select @endtime2 = dateadd(day,1,convert(datetime,FORMAT(GETDATE(), 'yyyy-MM-dd 00:00:00.000')))
		PRINT '@endtime=' + FORMAT(@endtime, 'yyyy-MM-dd HH:mm:ss.fff');
		PRINT '@endtime2=' + FORMAT(@endtime2, 'yyyy-MM-dd HH:mm:ss.fff');
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
	--(6) make sql for insert ([trans].[temp_V_OUT_INSP])
    ---------------------------------------------------------------------------
	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'update ' + @objectname + 'lots ';
	SET @sqltmp = @sqltmp + N'	set qty_divided = magic.shipment_qty ';
	SET @sqltmp = @sqltmp + N'from ' + @objectname + 'lots as l with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'inner join ( ';
	SET @sqltmp = @sqltmp + N'		select ';
	SET @sqltmp = @sqltmp + N'			* ';
	SET @sqltmp = @sqltmp + N'			from ';
	SET @sqltmp = @sqltmp + N'		 OPENROWSET(''SQLNCLI'', ''Server=' + @ISServerName + ';UID=ship;PWD=ship;'',''select LotNo,Process_No,Process_Date,Good_Qty,Shipment_Qty from DBLSISHT.dbo.WORK_R_DB with (NOLOCK) where Process_no= 1201'') as t1 ';
	SET @sqltmp = @sqltmp + N'		 where t1.Process_date between ''' + convert(varchar,@starttime2,21) + ''' and ''' + convert(varchar,@endtime2,21) + ''' ';
	SET @sqltmp = @sqltmp + N'				) as magic ';
	SET @sqltmp = @sqltmp + N'				on magic.LotNo = l.lot_no ';
	SET @sqltmp = @sqltmp + N'where l.wip_state in(70,100) ';
	SET @sqltmp = @sqltmp + N'	and l.ship_at between ''' + convert(varchar,@starttime,21) + ''' and ''' + convert(varchar,@endtime,21) + ''' ';
	SET @sqltmp = @sqltmp + N'	and isnull(l.qty_divided,0)  = 0 ';
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


    ---------------------------------------------------------------------------
	--(9-4) update [sp_update_function_finish_control]
    ---------------------------------------------------------------------------
	BEGIN TRY
		EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
			IF @ret<>0
				begin
					SET @logtext = '@ret<>0 [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline)+ '/msg:' + @errmsg;				
					PRINT 'sp_update_function_finish_control:NG' + convert(varchar,@ret) + @logtext;
					return -1;
				end;
	END TRY

	BEGIN CATCH
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



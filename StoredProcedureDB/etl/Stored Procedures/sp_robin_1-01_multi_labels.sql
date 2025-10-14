

CREATE PROCEDURE [etl].[sp_robin_1-01_multi_labels] (@v_ProServerName NVARCHAR(128) = ''
											,@v_ProDatabaseName NVARCHAR(128) = ''
											,@v_ProSchemeName NVARCHAR(128) = ''
											,@v_ISServerName NVARCHAR(128) = ''
											,@v_ISDatabaseName NVARCHAR(128) = ''
											,@v_ISSchemeName NVARCHAR(128) = ''
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
	DECLARE @ProSchemeName NVARCHAR(128) = N'method';
	DECLARE @ISServerName NVARCHAR(128) = N'10.28.1.144';
	DECLARE @ISDatabaseName NVARCHAR(128) = N'DBLSISHT';
	DECLARE @ISSchemeName NVARCHAR(128) = N'dbo';
	DECLARE @objectname NVARCHAR(128) = '';
	DECLARE @objectnameIS NVARCHAR(128) = '';
	DECLARE @dot NVARCHAR(1) = '.';
	DECLARE @ret INT = 0;
	DECLARE @sqltmp NVARCHAR(max) = '';
	DECLARE @rowcnt INT = 0;
	DECLARE @exec_hour INT = 17;



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
	DECLARE @exectime DATETIME;	
	DECLARE @endtime DATETIME;
	BEGIN TRY
		SELECT @functionname = OBJECT_NAME(@@PROCID);

		SELECT @starttime = finished_at FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = @functionname
		PRINT '@starttime=' + CASE WHEN @starttime IS NULL THEN '' ELSE FORMAT(@starttime, 'yyyy-MM-dd HH:mm:ss.fff') END;

		SELECT @exectime = dateadd(hour,@exec_hour,CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd 00:00:00.000')))
		PRINT '@exectime=' + FORMAT(@exectime, 'yyyy-MM-dd HH:mm:ss.fff');


		SELECT @endtime = GETDATE()
		PRINT '@endtime=' + FORMAT(@endtime, 'yyyy-MM-dd HH:mm:ss.fff');
		
	END TRY
	BEGIN CATCH
		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;


	IF @starttime >= @exectime or @endtime < @exectime
		BEGIN
			print 'skip:' + @functionname
			return 0;
		END;

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
    --(5)([trans].[temp_V_OUT_INSP]) delete
    ---------------------------------------------------------------------------
    --DECLARE @SqlTrunc NVARCHAR(100) = N'TRUNCATE TABLE ' + @objectname + '[multi_labels]; ';
    DECLARE @SqlTrunc NVARCHAR(100) = N'DELETE FROM ' + @objectname + '[temp_multi_labels]; ';
	PRINT @SqlTrunc;
    EXECUTE (@SqlTrunc);

    ---------------------------------------------------------------------------
	--(6) make sql for insert ([trans].[temp_multi_labels])
    ---------------------------------------------------------------------------
	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'insert into ' + @objectname + 'temp_multi_labels ';
	SET @sqltmp = @sqltmp + N'(';
	SET @sqltmp = @sqltmp + N'	rohm_model_name';
	SET @sqltmp = @sqltmp + N'	,user_model_name';
	SET @sqltmp = @sqltmp + N'	,start_date';
	SET @sqltmp = @sqltmp + N'	,fin_date';
	SET @sqltmp = @sqltmp + N'	,delete_flag';
	SET @sqltmp = @sqltmp + N'	,rank_class';
	SET @sqltmp = @sqltmp + N'	,timestamp_date';
	SET @sqltmp = @sqltmp + N') ';
	SET @sqltmp = @sqltmp + N'select ';
	SET @sqltmp = @sqltmp + N'	lbl.rohm_model_name';
	SET @sqltmp = @sqltmp + N'	,lbl.user_model_name';
	SET @sqltmp = @sqltmp + N'	,lbl.start_date';
	SET @sqltmp = @sqltmp + N'	,lbl.fin_date';
	SET @sqltmp = @sqltmp + N'	,lbl.delete_flag';
	SET @sqltmp = @sqltmp + N'	,lbl.rank_class';
	SET @sqltmp = @sqltmp + N'	,lbl.timestamp_date ';
 	SET @sqltmp = @sqltmp + N'from OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ISServerName + ';UID=ship;PWD=ship;'')' + @objectnameIS + 'MULTI_LABEL_M AS lbl ';

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
			print 'rowcnt=0 ' + @functionname
			return 0;
		end

	
    ---------------------------------------------------------------------------
	--(7) make sql for insert ([trans].[multi_labels])
    ---------------------------------------------------------------------------

	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'insert into ' + @objectname + 'multi_labels ';
	SET @sqltmp = @sqltmp + N'( ';
	SET @sqltmp = @sqltmp + N'	device_name';
	SET @sqltmp = @sqltmp + N'	,user_model_name';
	SET @sqltmp = @sqltmp + N'	,start_date';
	SET @sqltmp = @sqltmp + N'	,fin_date';
	SET @sqltmp = @sqltmp + N'	,delete_flag';
	SET @sqltmp = @sqltmp + N'	,rank_class';
	SET @sqltmp = @sqltmp + N'	,created_at';
	SET @sqltmp = @sqltmp + N'	,updated_at';
	SET @sqltmp = @sqltmp + N') ';
	SET @sqltmp = @sqltmp + N'select ';
	SET @sqltmp = @sqltmp + N'	d.name ';
	SET @sqltmp = @sqltmp + N'	,t_lbl.user_model_name';
	SET @sqltmp = @sqltmp + N'	,t_lbl.start_date';
	SET @sqltmp = @sqltmp + N'	,t_lbl.fin_date';
	SET @sqltmp = @sqltmp + N'	,t_lbl.delete_flag';
	SET @sqltmp = @sqltmp + N'	,t_lbl.rank_class';
	SET @sqltmp = @sqltmp + N'	,GETDATE() as created_at';
	SET @sqltmp = @sqltmp + N'	,null as updated_at ';
	SET @sqltmp = @sqltmp + N'from ' + @objectname + 'device_names as d with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'	inner join ' + @objectname + 'temp_multi_labels as t_lbl with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'		on d.name = t_lbl.rohm_model_name ';
	SET @sqltmp = @sqltmp + N'	left outer join ' + @objectname + 'multi_labels as lbl with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'		on d.name = lbl.device_name ';
	SET @sqltmp = @sqltmp + N'where lbl.device_name is null ';
	SET @sqltmp = @sqltmp + N'group by ';
	SET @sqltmp = @sqltmp + N'	d.name ';
	SET @sqltmp = @sqltmp + N'	,t_lbl.user_model_name';
	SET @sqltmp = @sqltmp + N'	,t_lbl.start_date';
	SET @sqltmp = @sqltmp + N'	,t_lbl.fin_date';
	SET @sqltmp = @sqltmp + N'	,t_lbl.delete_flag';
	SET @sqltmp = @sqltmp + N'	,t_lbl.rank_class';


    ---------------------------------------------------------------------------
	--(7-1) exec sql
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
	--(8-0)different column update
    ---------------------------------------------------------------------------

	SET @sqltmp = N'';	
	SET @sqltmp = @sqltmp + N'update ' + @objectname + 'multi_labels ';
	SET @sqltmp = @sqltmp + N'	set user_model_name = t1.user_model_name ';
	SET @sqltmp = @sqltmp + N'	,start_date = t1.start_date';
	SET @sqltmp = @sqltmp + N'	,fin_date = t1.fin_date';
	SET @sqltmp = @sqltmp + N'	,delete_flag = t1.delete_flag';
	SET @sqltmp = @sqltmp + N'	,rank_class = t1.rank_class ';
	SET @sqltmp = @sqltmp + N'	,updated_at = getdate() ';
	SET @sqltmp = @sqltmp + N'from ' + @objectname + 'multi_labels as l ';
	SET @sqltmp = @sqltmp + N'	inner join ';
	SET @sqltmp = @sqltmp + N'	( ';
	SET @sqltmp = @sqltmp + N'		select ';
	SET @sqltmp = @sqltmp + N'			d.name as device_name';
	SET @sqltmp = @sqltmp + N'			,t_lbl.user_model_name';
	SET @sqltmp = @sqltmp + N'			,t_lbl.start_date';
	SET @sqltmp = @sqltmp + N'			,t_lbl.fin_date';
	SET @sqltmp = @sqltmp + N'			,t_lbl.delete_flag';
	SET @sqltmp = @sqltmp + N'			,t_lbl.rank_class';
	SET @sqltmp = @sqltmp + N'			,GETDATE() as created_at ';
	SET @sqltmp = @sqltmp + N'			,null as updated_at ';
	SET @sqltmp = @sqltmp + N'		from ' + @objectname + 'device_names as d with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'			inner join ' + @objectname + 'temp_multi_labels as t_lbl with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				on d.name = t_lbl.rohm_model_name ';
	SET @sqltmp = @sqltmp + N'			inner join ' + @objectname + 'multi_labels as lbl with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				on d.name = lbl.device_name ';
	SET @sqltmp = @sqltmp + N'		where lbl.user_model_name <> t_lbl.user_model_name ';
	SET @sqltmp = @sqltmp + N'			or lbl.start_date <> t_lbl.start_date ';
	SET @sqltmp = @sqltmp + N'			or lbl.fin_date <> t_lbl.fin_date ';
	SET @sqltmp = @sqltmp + N'			or lbl.delete_flag <> t_lbl.delete_flag ';
	SET @sqltmp = @sqltmp + N'			or lbl.rank_class <> t_lbl.rank_class ';
	SET @sqltmp = @sqltmp + N'		group by ';
	SET @sqltmp = @sqltmp + N'			d.name ';
	SET @sqltmp = @sqltmp + N'			,t_lbl.user_model_name';
	SET @sqltmp = @sqltmp + N'			,t_lbl.start_date';
	SET @sqltmp = @sqltmp + N'			,t_lbl.fin_date';
	SET @sqltmp = @sqltmp + N'			,t_lbl.delete_flag';
	SET @sqltmp = @sqltmp + N'			,t_lbl.rank_class';
	SET @sqltmp = @sqltmp + N'			,lbl.user_model_name';
	SET @sqltmp = @sqltmp + N'			,lbl.start_date';
	SET @sqltmp = @sqltmp + N'			,lbl.fin_date';
	SET @sqltmp = @sqltmp + N'			,lbl.delete_flag';
	SET @sqltmp = @sqltmp + N'			,lbl.rank_class';
	SET @sqltmp = @sqltmp + N'	) as t1 ';
	SET @sqltmp = @sqltmp + N'	on l.device_name = t1.device_name ';

    ---------------------------------------------------------------------------
	--(8-1) exec sql
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

	BEGIN TRY

		EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
			IF @ret<>0
				begin
					SET @logtext = '@ret<>0 [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline)+ '/msg:' + @errmsg;				
					PRINT 'sp_update_function_finish_control:NG' + convert(varchar,@ret) + @logtext;
					--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;

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



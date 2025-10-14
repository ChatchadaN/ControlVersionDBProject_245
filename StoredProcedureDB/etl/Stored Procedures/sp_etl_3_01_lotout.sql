

CREATE PROCEDURE [etl].[sp_etl_3_01_lotout] (@v_ProServerName NVARCHAR(128) = ''
											,@v_ProDatabaseName NVARCHAR(128) = ''
											,@v_DwhDatabaseName NVARCHAR(128) = ''
											,@logtext nvarchar(max) output
											,@errnum  INT output
											,@errline INT output
											,@errmsg nvarchar(max) output
) AS
BEGIN
    ---------------------------------------------------------------------------
	--(1) Declare
    ---------------------------------------------------------------------------
	DECLARE @ProServerName NVARCHAR(128) = N'';
	DECLARE @ProDatabaseName NVARCHAR(128) = N'APCSProDB';
	DECLARE @DwhDatabaseName NVARCHAR(128) = N'APCSProDWH';
	DECLARE @objectname NVARCHAR(128) = '';
	DECLARE @objectnamedwh NVARCHAR(128) = '';
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

		IF RTRIM(@v_DwhDatabaseName) = ''
			BEGIN
				SET @DwhDatabaseName = '[' + @DwhDatabaseName + ']';
			END;
		ELSE
			BEGIN
				SET @DwhDatabaseName = '[' + @v_DwhDatabaseName + ']';
			END;


		if RTRIM(@ProServerName) = ''
			BEGIN
				set @objectname = @ProDatabaseName + @dot
				set @objectnamedwh = @DwhDatabaseName + @dot
			END;
		else
			BEGIN
				set @objectname = @ProServerName + @dot + @ProDatabaseName + @dot
				set @objectnamedwh = @ProServerName + @dot + @DwhDatabaseName + @dot
			END;

    ---------------------------------------------------------------------------
	--(3) get function_finish_control last_finish
    ---------------------------------------------------------------------------
	DECLARE @functionname NVARCHAR(128) = ''
	DECLARE @starttime DATETIME;
	DECLARE @endtime DATETIME;
	BEGIN TRY
		SELECT @functionname = OBJECT_NAME(@@PROCID);

		SELECT @starttime = isnull(finished_at,'2018-04-01')  FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		PRINT '@starttime=' + CASE WHEN @starttime IS NULL THEN '' ELSE FORMAT(@starttime, 'yyyy-MM-dd HH:mm:ss.fff') END;

		SELECT @endtime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
		PRINT '@endtime=' + FORMAT(@endtime, 'yyyy-MM-dd HH:mm:ss.fff');
	END TRY
	BEGIN CATCH
		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(4)SQL Make
    ---------------------------------------------------------------------------
	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'UPDATE DLO SET ';
	SET @sqltmp = @sqltmp + N'		DLO.lotout_day_id = DY.id ';
	SET @sqltmp = @sqltmp + N'FROM ';
	SET @sqltmp = @sqltmp + N'		APCSProDWH.dwh.dim_lots as DLO ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN' + @objectname + 'trans.Lots as LO';
	SET @sqltmp = @sqltmp + N'		ON LO.id = DLO.id ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN( ';
	SET @sqltmp = @sqltmp + N'		SELECT ';
	SET @sqltmp = @sqltmp + N'			LPR.lot_id, ';
	SET @sqltmp = @sqltmp + N'			MAX ( LPR.recorded_at ) as recorded_at ';
	SET @sqltmp = @sqltmp + N'		FROM ';
	SET @sqltmp = @sqltmp + N'			' + @objectname + 'trans.lot_process_records as LPR with ( NOLOCK )';
	SET @sqltmp = @sqltmp + N'		GROUP BY ';
	SET @sqltmp = @sqltmp + N'				LPR.lot_id ) as LPR ';
	SET @sqltmp = @sqltmp + N'		ON LPR.lot_id = LO.id ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN' + @objectname + 'trans.days as DY ';
	SET @sqltmp = @sqltmp + N'		ON DY.date_value = CONVERT ( DATE, LPR.recorded_at ) '
	SET @sqltmp = @sqltmp + N'WHERE ';
	SET @sqltmp = @sqltmp + N'	DLO.lotout_day_id is null and ';
	SET @sqltmp = @sqltmp + N'	(LO.wip_state in (200, 210) and ';
	SET @sqltmp = @sqltmp + N'	(LO.in_at is not null)) ';

	PRINT '-----------------sqltmp-----------------------';
	PRINT @sqltmp;

    ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------
	BEGIN TRY
		BEGIN TRANSACTION;
		EXECUTE (@sqltmp);
		set @rowcnt = @@ROWCOUNT
		set @logtext = '@sqltmp:OK row:' + convert(varchar,@rowcnt)
		print @logtext

		if @rowcnt > 0 
			begin
				EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='dwh.dim_lots', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
					IF @ret<>0
						begin
							IF @@TRANCOUNT <> 0
								BEGIN
									ROLLBACK TRANSACTION;
								END;
							SET @logtext = '@ret<>0 [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg;				
							PRINT 'sp_update_function_finish_control:NG' + convert(varchar,@ret) + @logtext;
							--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
							return -1;
						end;
			end;
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

		SET @logtext = '[ERR] [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret)  + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg + '/SQL:' + @sqltmp;
		PRINT 'transaction err ' + @logtext;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

	RETURN 0;

END ;




CREATE PROCEDURE [etl].[sp_etl_3_02_max_stepno] (@v_ProServerName NVARCHAR(128) = ''
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
	DECLARE @DwhDatabaseName NVARCHAR(128) = N'APCSProDwh';
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
	SET @sqltmp = @sqltmp + N'UPDATE DPJ SET ';
	SET @sqltmp = @sqltmp + N'		DPJ.max_step_no = CASE when DPJ.job_no = 10 then 5 ';
	SET @sqltmp = @sqltmp + N'							   when DPJ.job_no = 11 then 10 ';
	SET @sqltmp = @sqltmp + N'							   when DPJ.job_no = 101 then 50 ';
	SET @sqltmp = @sqltmp + N'							   when TEMP4.max_step_no is not null then TEMP4.max_step_no ';
	SET @sqltmp = @sqltmp + N'							   when TEMP3.max_step_no is not null then TEMP3.max_step_no ';
	SET @sqltmp = @sqltmp + N'					      ELSE TEMP1.max_step_no END ';
	SET @sqltmp = @sqltmp + N'FROM ';
	SET @sqltmp = @sqltmp + N'		APCSProDWH.dwh.dim_package_jobs as DPJ ';
	SET @sqltmp = @sqltmp + N'	LEFT OUTER JOIN APCSProDWH.pbi.jobname_convert as JC ';
	SET @sqltmp = @sqltmp + N'		ON JC.actual_job_no = DPJ.job_no ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN( ';
	SET @sqltmp = @sqltmp + N'		SELECT ';
	SET @sqltmp = @sqltmp + N'			DN.package_id, ';
	SET @sqltmp = @sqltmp + N'			DF.job_id, ';
	SET @sqltmp = @sqltmp + N'			MAX(DF.step_no) as max_step_no ';
	SET @sqltmp = @sqltmp + N'		FROM ';
	SET @sqltmp = @sqltmp + N'			' + @objectname + 'method.device_names as DN ';
	SET @sqltmp = @sqltmp + N'			INNER JOIN' + @objectname + 'method.device_versions as DV ';
	SET @sqltmp = @sqltmp + N'				ON DV.device_name_id = DN.id ';
	SET @sqltmp = @sqltmp + N'			INNER JOIN ( ';
	SET @sqltmp = @sqltmp + N'				SELECT ';
	SET @sqltmp = @sqltmp + N'					DS.device_id, ';
	SET @sqltmp = @sqltmp + N'					MAX(DS.device_slip_id) as device_slip_id ';
	SET @sqltmp = @sqltmp + N'				FROM ';
	SET @sqltmp = @sqltmp + N'					' + @objectname + 'method.device_slips as DS ';	
	SET @sqltmp = @sqltmp + N'				WHERE ';
	SET @sqltmp = @sqltmp + N'					DS.is_released IN (1,2) ';
	SET @sqltmp = @sqltmp + N'				GROUP BY ';
	SET @sqltmp = @sqltmp + N'					DS.device_id) as DS ';	 
	SET @sqltmp = @sqltmp + N'				ON DS.device_id = DV.device_id';
	SET @sqltmp = @sqltmp + N'			INNER JOIN' + @objectname + 'method.device_flows as DF ';
	SET @sqltmp = @sqltmp + N'				ON DF.device_slip_id = DS.device_slip_id '
	SET @sqltmp = @sqltmp + N'		GROUP BY ';
	SET @sqltmp = @sqltmp + N'		DN.package_id, DF.job_id) as TEMP1 ';
	SET @sqltmp = @sqltmp + N'		ON TEMP1.package_id = DPJ.package_id and TEMP1.job_id = DPJ.job_id '
	SET @sqltmp = @sqltmp + N'	LEFT OUTER JOIN( ';
	SET @sqltmp = @sqltmp + N'		SELECT ';
	SET @sqltmp = @sqltmp + N'			TEMP2.package_id, ';
	SET @sqltmp = @sqltmp + N'			JB.id as job_id, ';
	SET @sqltmp = @sqltmp + N'			TEMP2.max_step_no ';
	SET @sqltmp = @sqltmp + N'		FROM ';
	SET @sqltmp = @sqltmp + N'			' + @objectname + 'method.jobs as JB ';
	SET @sqltmp = @sqltmp + N'			INNER JOIN APCSProDWH.pbi.jobname_convert as JC ';
	SET @sqltmp = @sqltmp + N'				ON JC.actual_job_no = JB.job_no ';	
	SET @sqltmp = @sqltmp + N'			INNER JOIN( ';
	SET @sqltmp = @sqltmp + N'				SELECT ';
	SET @sqltmp = @sqltmp + N'					DN.package_id, ';
	SET @sqltmp = @sqltmp + N'					JC.process_name2 as convert_jobname, ';
	SET @sqltmp = @sqltmp + N'					MAX(DF.step_no) as max_step_no ';
	SET @sqltmp = @sqltmp + N'				FROM ';
	SET @sqltmp = @sqltmp + N'					' + @objectname + 'method.device_names as DN ';
	SET @sqltmp = @sqltmp + N'					INNER JOIN' + @objectname + 'method.device_versions as DV ';
	SET @sqltmp = @sqltmp + N'						ON DV.device_name_id = DN.id ';
	SET @sqltmp = @sqltmp + N'					INNER JOIN ( ';
	SET @sqltmp = @sqltmp + N'						SELECT ';
	SET @sqltmp = @sqltmp + N'							DS.device_id, ';
	SET @sqltmp = @sqltmp + N'							MAX(DS.device_slip_id) as device_slip_id ';
	SET @sqltmp = @sqltmp + N'						FROM ';
	SET @sqltmp = @sqltmp + N'							' + @objectname + 'method.device_slips as DS ';	
	SET @sqltmp = @sqltmp + N'						WHERE ';
	SET @sqltmp = @sqltmp + N'							DS.is_released IN (1,2) ';
	SET @sqltmp = @sqltmp + N'						GROUP BY ';
	SET @sqltmp = @sqltmp + N'							DS.device_id) as DS ';	 
	SET @sqltmp = @sqltmp + N'						ON DS.device_id = DV.device_id';
	SET @sqltmp = @sqltmp + N'			INNER JOIN' + @objectname + 'method.device_flows as DF ';
	SET @sqltmp = @sqltmp + N'				ON DF.device_slip_id = DS.device_slip_id '
	SET @sqltmp = @sqltmp + N'			INNER JOIN' + @objectname + 'method.jobs as JB ';
	SET @sqltmp = @sqltmp + N'				ON JB.id = DF.job_id '
	SET @sqltmp = @sqltmp + N'			INNER JOIN APCSProDWH.pbi.jobname_convert as JC ';
	SET @sqltmp = @sqltmp + N'				ON JC.actual_job_no = JB.job_no '
	SET @sqltmp = @sqltmp + N'			GROUP BY ';
	SET @sqltmp = @sqltmp + N'			DN.package_id, JC.process_name2) as TEMP2 ';
	SET @sqltmp = @sqltmp + N'		ON TEMP2.convert_jobname = JC.process_name2 ) as TEMP3 '
	SET @sqltmp = @sqltmp + N'	ON TEMP3.package_id = DPJ.package_id and TEMP3.job_id = DPJ.job_id '
	SET @sqltmp = @sqltmp + N'	LEFT OUTER JOIN( ';
	SET @sqltmp = @sqltmp + N'		SELECT ';
	SET @sqltmp = @sqltmp + N'			DPJ.package_id, ';
	SET @sqltmp = @sqltmp + N'			JC.process_name2, ';
	SET @sqltmp = @sqltmp + N'			MAX(DPJ.max_step_no) as max_step_no ';
	SET @sqltmp = @sqltmp + N'		FROM ';
	SET @sqltmp = @sqltmp + N'			APCSProDWH.dwh.dim_package_jobs as DPJ ';
	SET @sqltmp = @sqltmp + N'			INNER JOIN APCSProDWH.pbi.jobname_convert as JC ';
	SET @sqltmp = @sqltmp + N'				ON JC.actual_job_no = DPJ.job_no ';	
	SET @sqltmp = @sqltmp + N'		WHERE ';
	SET @sqltmp = @sqltmp + N'			DPJ.max_step_no IS NOT NULL ';
	SET @sqltmp = @sqltmp + N'		GROUP BY ';
	SET @sqltmp = @sqltmp + N'			DPJ.package_id, JC.process_name2) as TEMP4 ';
	SET @sqltmp = @sqltmp + N'	ON TEMP4.package_id = DPJ.package_id and TEMP4.process_name2 = JC.process_name2 '
	SET @sqltmp = @sqltmp + N'WHERE ';
	SET @sqltmp = @sqltmp + N'	DPJ.max_step_no is null ';

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
				EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='dwh.dim_package_jobs', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
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


CREATE PROCEDURE [etl].[sp_etl_2-05_fact_start] (@v_ProServerName NVARCHAR(128) = ''
											,@v_ProDatabaseName NVARCHAR(128) = ''
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

		if RTRIM(@ProServerName) = ''
			BEGIN
				set @objectname = @ProDatabaseName + @dot
			END;
		else
			BEGIN
				set @objectname = @ProServerName + @dot + @ProDatabaseName + @dot
			END;

    ---------------------------------------------------------------------------
	--(3) get function_finish_control last_finish
    ---------------------------------------------------------------------------
	DECLARE @functionname NVARCHAR(128) = ''
	DECLARE @starttime DATETIME;
	DECLARE @endtime DATETIME;
	BEGIN TRY
		SELECT @functionname = OBJECT_NAME(@@PROCID);

		SELECT @starttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000'))  FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		PRINT '@starttime=' + CASE WHEN @starttime IS NULL THEN '' ELSE FORMAT(@starttime, 'yyyy-MM-dd HH:mm:ss.fff') END;

		SELECT @endtime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
		PRINT '@endtime=' + FORMAT(@endtime, 'yyyy-MM-dd HH:mm:ss.fff');
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()
		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

	if @starttime is not null
		begin
			if @starttime = @endtime 
				begin
					SET @logtext = @functionname + ' has already finished at this hour.' + convert(varchar,@endtime,21);
					return 0;
				end;
		end ;

    ---------------------------------------------------------------------------
	--(4)SQL Make
    ---------------------------------------------------------------------------
	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'INSERT INTO [apcsprodwh].[dwh].[fact_start] ';
	SET @sqltmp = @sqltmp + N'	(day_id ';
	SET @sqltmp = @sqltmp + N'	,hour_code ';
	SET @sqltmp = @sqltmp + N'	,package_group_id ';
	SET @sqltmp = @sqltmp + N'	,package_id ';
	SET @sqltmp = @sqltmp + N'	,device_id ';
	SET @sqltmp = @sqltmp + N'	,assy_name_id ';
	SET @sqltmp = @sqltmp + N'	,factory_id ';
	SET @sqltmp = @sqltmp + N'	,product_family_id ';
	SET @sqltmp = @sqltmp + N'	,lot_id ';
	SET @sqltmp = @sqltmp + N'	,process_id ';
	SET @sqltmp = @sqltmp + N'	,job_id ';
	SET @sqltmp = @sqltmp + N'	,input_pcs ';
	SET @sqltmp = @sqltmp + N'	,[code] ';
	SET @sqltmp = @sqltmp + N'	,machine_id ';
	SET @sqltmp = @sqltmp + N'	,machine_model_id ';
	SET @sqltmp = @sqltmp + N'	,production_category ';
	SET @sqltmp = @sqltmp + N'	) ';
	SET @sqltmp = @sqltmp + N'SELECT ';
	SET @sqltmp = @sqltmp + N'		dwh_days.id AS [1_day_id] ';
	SET @sqltmp = @sqltmp + N'		,dwh_hours.code AS [2_hour_code] ';
	SET @sqltmp = @sqltmp + N'		,t1.[3_package_group_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[4_package_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[5_device_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[6_assy_name_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[7_factory_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[8_product_family_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[9_lot_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[10_process_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[11_job_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[12_input_pcs] ';
	SET @sqltmp = @sqltmp + N'		,CASE WHEN t1.rank_no = 1 THEN 1 ELSE 0 END AS [13_code] ';
	SET @sqltmp = @sqltmp + N'		,t1.[14_machine_id] ';
	SET @sqltmp = @sqltmp + N'		,isnull(t1.[15_machine_model_id],0) as machine_model_id ';
	SET @sqltmp = @sqltmp + N'		,case substring(t1.lot_no,5,1) ';
	SET @sqltmp = @sqltmp + N'			when ''A'' then 0 when ''V'' then 1 when ''W'' then 2 when ''X'' then 3 when ''Y'' then 4 ';
	SET @sqltmp = @sqltmp + N'			when ''B'' then 10 when ''Q'' then 11 when ''R'' then 12 when ''S'' then 13 when ''T'' then 14 ';
	SET @sqltmp = @sqltmp + N'			when ''D'' then 20 ';
	SET @sqltmp = @sqltmp + N'			when ''E'' then 30 when ''5'' then 31 when ''6'' then 32 when ''7'' then 33 when ''8'' then 34 ';
	SET @sqltmp = @sqltmp + N'			when ''F'' then 40 when ''K'' then 41 when ''L'' then 42 when ''M'' then 43 when ''N'' then 44 ';
	SET @sqltmp = @sqltmp + N'			when ''G'' then 50 when ''0'' then 51 when ''1'' then 52 when ''2'' then 53 when ''3'' then 54 ';
	SET @sqltmp = @sqltmp + N'			when ''H'' then 60 when ''P'' then 61 when ''U'' then 62 when ''Z'' then 63 when ''4'' then 64 else 0 end as production_category ';

	SET @sqltmp = @sqltmp + N'FROM ( ';
	SET @sqltmp = @sqltmp + N'			SELECT ';
	SET @sqltmp = @sqltmp + N'				CONVERT(date, trans_lotrec.recorded_at) AS date_value ';
	SET @sqltmp = @sqltmp + N'				,DATEPART(hour, trans_lotrec.recorded_at) AS h ';
	SET @sqltmp = @sqltmp + N'				,dwh_pkg.package_group_id AS [3_package_group_id] ';
	SET @sqltmp = @sqltmp + N'				,trans_lots.act_package_id AS [4_package_id] ';
	SET @sqltmp = @sqltmp + N'				,trans_lots.act_device_name_id AS [5_device_id] ';
	SET @sqltmp = @sqltmp + N'				,dwh_assy.id AS [6_assy_name_id] ';
	SET @sqltmp = @sqltmp + N'				,man_prd.factory_id AS [7_factory_id] ';
	SET @sqltmp = @sqltmp + N'				,trans_lots.product_family_id AS [8_product_family_id] ';
	SET @sqltmp = @sqltmp + N'				,trans_lots.id AS [9_lot_id] ';
	SET @sqltmp = @sqltmp + N'				,trans_lotrec.process_id AS [10_process_id] ';
	SET @sqltmp = @sqltmp + N'				,trans_lotrec.job_id AS [11_job_id] ';
	SET @sqltmp = @sqltmp + N'				,case when ISNULL(trans_lotrec.qty_pass, 0) > 0 then ISNULL(trans_lotrec.qty_pass, 0) else ISNULL(trans_lotrec.qty_in, 0) end AS [12_input_pcs] ';
	SET @sqltmp = @sqltmp + N'				,met_devflow.rank_no ';
	SET @sqltmp = @sqltmp + N'				,trans_lotrec.machine_id AS [14_machine_id] ';
	SET @sqltmp = @sqltmp + N'				,mc_mcn.machine_model_id as [15_machine_model_id] ';
	SET @sqltmp = @sqltmp + N'				,rtrim(trans_lots.lot_no) as lot_no ';
	SET @sqltmp = @sqltmp + N'			FROM ' + @objectname + '[trans].[lot_process_records] AS trans_lotrec with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN ' + @objectname + '[trans].[lots] AS trans_lots with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON trans_lots.id = trans_lotrec.lot_id ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN ' + @objectname + '[man].[product_families] AS man_prd with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON man_prd.id = trans_lots.product_family_id ';
	SET @sqltmp = @sqltmp + N'						AND RTRIM(man_prd.product_code) = RTRIM(( ';
	SET @sqltmp = @sqltmp + N'																	SELECT val ';
	SET @sqltmp = @sqltmp + N'																	FROM [apcsprodwh].[dwh].[act_settings] with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'																	WHERE name = ''ProductFamilyCode''))  COLLATE SQL_Latin1_General_CP1_CI_AS ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN [apcsprodwh].[dwh].[dim_packages] AS dwh_pkg with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh_pkg.id = trans_lots.act_package_id ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN ' + @objectname + '[method].[device_names] AS met_dev with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON met_dev.id = trans_lots.act_device_name_id ';
	SET @sqltmp = @sqltmp + N'						AND met_dev.is_assy_only in (0,1) ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN [apcsprodwh].[dwh].[dim_assy_device_names] AS dwh_assy with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh_assy.id = met_dev.id ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN ' + @objectname + '[mc].[machines] AS mc_mcn with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON mc_mcn.id = trans_lotrec.machine_id ';
	SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN ';
	SET @sqltmp = @sqltmp + N'					(SELECT ';
	SET @sqltmp = @sqltmp + N'						step_no ';
	SET @sqltmp = @sqltmp + N'						,device_slip_id ';
	SET @sqltmp = @sqltmp + N'						,job_id ';
	SET @sqltmp = @sqltmp + N'						,rank_no ';
	SET @sqltmp = @sqltmp + N'					FROM ( ';
	SET @sqltmp = @sqltmp + N'							SELECT ';
	SET @sqltmp = @sqltmp + N'								step_no ';
	SET @sqltmp = @sqltmp + N'								,device_slip_id ';
	SET @sqltmp = @sqltmp + N'								,act_process_id ';
	SET @sqltmp = @sqltmp + N'								,job_id ';
	SET @sqltmp = @sqltmp + N'								,rank() over (partition by device_slip_id,act_process_id order by step_no ) AS rank_no ';
	SET @sqltmp = @sqltmp + N'							FROM ' + @objectname + '[method].[device_flows] with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'							WHERE (is_skipped IS NULL OR is_skipped = 0) ';
	SET @sqltmp = @sqltmp + N'						) AS devdev ';
	SET @sqltmp = @sqltmp + N'					WHERE rank_no = 1) AS met_devflow ';
	SET @sqltmp = @sqltmp + N'					ON met_devflow.device_slip_id = trans_lots.device_slip_id ';
	SET @sqltmp = @sqltmp + N'						AND met_devflow.job_id = trans_lotrec.job_id ';
	SET @sqltmp = @sqltmp + N'			WHERE trans_lotrec.record_class = 1 ';
	SET @sqltmp = @sqltmp + N'				AND trans_lotrec.process_state IN (2,102) ';
	BEGIN
		IF @starttime IS NOT NULL 
			SET @sqltmp = @sqltmp + N'		AND trans_lotrec.recorded_at >= ''' + FORMAT(@starttime, 'yyyy-MM-dd HH:mm:ss.fff') + ''' ';
	END
	SET @sqltmp = @sqltmp + N'				AND trans_lotrec.recorded_at < ''' + FORMAT(@endtime, 'yyyy-MM-dd HH:mm:ss.fff') + ''' ';
	SET @sqltmp = @sqltmp + N'		) AS t1 ';
	SET @sqltmp = @sqltmp + N'		INNER JOIN [apcsprodwh].[dwh].[dim_days] AS dwh_days ';
	SET @sqltmp = @sqltmp + N'			ON dwh_days.date_value = t1.date_value ';
	SET @sqltmp = @sqltmp + N'		INNER JOIN [apcsprodwh].[dwh].[dim_hours] AS dwh_hours ';
	SET @sqltmp = @sqltmp + N'			ON dwh_hours.h = T1.h ';
	SET @sqltmp = @sqltmp + N'where [11_job_id] is not null and [10_process_id] is not null ';


	PRINT '----------------------------------------';
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
		EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='dwh.fact_start', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
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

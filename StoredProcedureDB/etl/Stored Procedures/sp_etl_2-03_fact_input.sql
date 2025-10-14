
CREATE PROCEDURE [etl].[sp_etl_2-03_fact_input] (@v_ProServerName NVARCHAR(128) = ''
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

		SELECT @starttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
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
	SET @sqltmp = @sqltmp + N'INSERT INTO [apcsprodwh].[dwh].[fact_input] ';
	SET @sqltmp = @sqltmp + N'	(day_id ';
	SET @sqltmp = @sqltmp + N'	,hour_code ';
	SET @sqltmp = @sqltmp + N'	,package_group_id ';
	SET @sqltmp = @sqltmp + N'	,package_id ';
	SET @sqltmp = @sqltmp + N'	,device_id ';
	SET @sqltmp = @sqltmp + N'	,assy_name_id ';
	SET @sqltmp = @sqltmp + N'	,factory_id ';
	SET @sqltmp = @sqltmp + N'	,product_family_id ';
	SET @sqltmp = @sqltmp + N'	,lot_count ';
	SET @sqltmp = @sqltmp + N'	,pcs ';
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
	SET @sqltmp = @sqltmp + N'		,SUM([9_lot_count]) AS [9_lot_count] ';
	SET @sqltmp = @sqltmp + N'		,SUM([10_pcs]) AS [10_pcs] ';
	SET @sqltmp = @sqltmp + N'FROM ( ';
	SET @sqltmp = @sqltmp + N'			SELECT ';
	SET @sqltmp = @sqltmp + N'				trans_lots.in_at ';
	SET @sqltmp = @sqltmp + N'				,CONVERT(date, in_at) AS date_value ';
	SET @sqltmp = @sqltmp + N'				,DATEPART(hour, in_at) AS h ';
	SET @sqltmp = @sqltmp + N'				,dwh_pkg.package_group_id AS [3_package_group_id] ';
	SET @sqltmp = @sqltmp + N'				,trans_lots.act_package_id AS [4_package_id] ';
	SET @sqltmp = @sqltmp + N'				,dwh_dev.id AS [5_device_id] ';
	SET @sqltmp = @sqltmp + N'				,dwh_assy.id AS [6_assy_name_id] ';
	SET @sqltmp = @sqltmp + N'				,man_prd.factory_id AS [7_factory_id] ';
	SET @sqltmp = @sqltmp + N'				,trans_lots.product_family_id AS [8_product_family_id] ';
	SET @sqltmp = @sqltmp + N'				,1 AS [9_lot_count] ';
	SET @sqltmp = @sqltmp + N'				,ISNULL(trans_lots.qty_pass, 0) AS [10_pcs] ';
	SET @sqltmp = @sqltmp + N'			FROM ' + @objectname + '[trans].[lots] AS trans_lots with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN ' + @objectname + '[man].[product_families] AS man_prd with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON man_prd.id = trans_lots.product_family_id ';
	SET @sqltmp = @sqltmp + N'						AND man_prd.product_code in(RTRIM(( ';
	SET @sqltmp = @sqltmp + N'															SELECT val ';
	SET @sqltmp = @sqltmp + N'															FROM [apcsprodwh].[dwh].[act_settings] with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'															WHERE name = ''ProductFamilyCode''))  COLLATE SQL_Latin1_General_CP1_CI_AS) ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN ' + @objectname + '[method].[device_names] AS met_dev with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON met_dev.id = trans_lots.act_device_name_id ';
	SET @sqltmp = @sqltmp + N'						AND met_dev.is_assy_only in(0,1) ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN [apcsprodwh].[dwh].[dim_devices] AS dwh_dev with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh_dev.id = met_dev.id ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN [apcsprodwh].[dwh].[dim_assy_device_names] AS dwh_assy with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh_assy.id = met_dev.id ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN [apcsprodwh].[dwh].[dim_packages] AS dwh_pkg with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh_pkg.id = trans_lots.act_package_id ';
	SET @sqltmp = @sqltmp + N'			WHERE trans_lots.in_at IS NOT NULL ';
	SET @sqltmp = @sqltmp + N'				and trans_lots.wip_state in(10,20) ';
	BEGIN
		IF @starttime IS NOT NULL 
			SET @sqltmp = @sqltmp + N'		AND trans_lots.in_at >= ''' + FORMAT(@starttime, 'yyyy-MM-dd HH:mm:ss.fff') + ''' ';
	END
	SET @sqltmp = @sqltmp + N'				AND trans_lots.in_at < ''' + FORMAT(@endtime, 'yyyy-MM-dd HH:mm:ss.fff') + ''' ';

	SET @sqltmp = @sqltmp + N'		) AS t1 ';
	SET @sqltmp = @sqltmp + N'		INNER JOIN [apcsprodwh].[dwh].[dim_days] AS dwh_days with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'			ON dwh_days.date_value = t1.date_value ';
	SET @sqltmp = @sqltmp + N'		INNER JOIN [apcsprodwh].[dwh].[dim_hours] AS dwh_hours with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'			ON dwh_hours.h = T1.h ';
	SET @sqltmp = @sqltmp + N'GROUP BY ';
	SET @sqltmp = @sqltmp + N'	dwh_days.[id] ';
	SET @sqltmp = @sqltmp + N'	,dwh_hours.[code] ';
	SET @sqltmp = @sqltmp + N'	,t1.[3_package_group_id] ';
	SET @sqltmp = @sqltmp + N'	,t1.[4_package_id] ';
	SET @sqltmp = @sqltmp + N'	,t1.[5_device_id] ';
	SET @sqltmp = @sqltmp + N'	,t1.[6_assy_name_id] ';
	SET @sqltmp = @sqltmp + N'	,t1.[7_factory_id] ';
	SET @sqltmp = @sqltmp + N'	,t1.[8_product_family_id] ';

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
		EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='dwh.fact_input', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
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

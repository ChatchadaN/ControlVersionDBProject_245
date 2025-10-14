
CREATE PROCEDURE [etl].[sp_etl_2-02_fact_plan] (@v_ProServerName NVARCHAR(128) = ''
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
	DECLARE @endtime DATETIME;
	BEGIN TRY
		SELECT @functionname = OBJECT_NAME(@@PROCID);
		SELECT @endtime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()
		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(4)SQL Make
    ---------------------------------------------------------------------------
	---------------------------------------------------------------------------
    --(5-1) TRUNCATE ([apcsprodwh].[dwh].[temp_fact_plan]) 
    ---------------------------------------------------------------------------
	TRUNCATE TABLE [apcsprodwh].[dwh].[temp_fact_plan];

    ---------------------------------------------------------------------------
	--(5-2) ([apcsprodwh].[dwh].[temp_fact_plan]) SQL Make
    ---------------------------------------------------------------------------
	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'INSERT INTO [apcsprodwh].[dwh].[temp_fact_plan] ';
	SET @sqltmp = @sqltmp + N'		( ';
	SET @sqltmp = @sqltmp + N'			day_id ';
	SET @sqltmp = @sqltmp + N'			,package_group_id ';
	SET @sqltmp = @sqltmp + N'			,package_id ';
	SET @sqltmp = @sqltmp + N'			,device_id ';
	SET @sqltmp = @sqltmp + N'			,assy_name_id ';
	SET @sqltmp = @sqltmp + N'			,factory_id ';
	SET @sqltmp = @sqltmp + N'			,product_family_id ';
	SET @sqltmp = @sqltmp + N'			,pcs ';
	SET @sqltmp = @sqltmp + N'		) ';

	SET @sqltmp = @sqltmp + N'select ';
 	SET @sqltmp = @sqltmp + N'		dwh_days.id AS [1_day_id] ';
	SET @sqltmp = @sqltmp + N'		,dwh_pkg.id AS [2_package_group_id] ';
	SET @sqltmp = @sqltmp + N'		,dwh_pk.id AS [3_package_id] ';
	SET @sqltmp = @sqltmp + N'		,NULL AS [4_device_id] ';
	SET @sqltmp = @sqltmp + N'		,NULL AS [5_assy_name_id] ';
	SET @sqltmp = @sqltmp + N'		,dwh_fact.id AS [6_factory_id] ';
	SET @sqltmp = @sqltmp + N'		,dwh_prf.id AS [7_product_family_id] ';
	SET @sqltmp = @sqltmp + N'		,pp.pcs AS [8_pcs] ';
	--,pp.HNSCM as package_name
	--,dwh_pln.pcs as old_pcs
	SET @sqltmp = @sqltmp + N'FROM OPENDATASOURCE(''SQLNCLI'', ''Server=200.1.15.125\sql2017express;UID=sa;PWD=Rohm789;'').[APCSProDWH].[dwh].[temp_ProductionPlan] AS PP ';
	--SET @sqltmp = @sqltmp + N'FROM OPENDATASOURCE(''SQLNCLI'', ''Server=200.1.15.125\sql2016std;UID=sa;PWD=Rohm789;'').[APCSProDWH].[dwh].[temp_ProductionPlan] AS PP ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN [apcsprodwh].[dwh].[dim_days] AS dwh_days with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'		ON CONVERT(VARCHAR, dwh_days.date_value, 112) = RTRIM(pp.date_value) ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN [apcsprodwh].[dwh].[dim_factories] AS dwh_fact with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'		ON dwh_fact.factory_code = CONVERT(INT, pp.factory_code) ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN [apcsprodwh].[dwh].[dim_product_families] as dwh_prf with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'		ON dwh_prf.factory_id = dwh_prf.id ';
	SET @sqltmp = @sqltmp + N'			and dwh_prf.product_code = CONVERT(INT, pp.SHGC) ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN [apcsprodwh].[dwh].[dim_packages] AS dwh_pk with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'		ON dwh_pk.product_family_id = dwh_prf.id ';
	SET @sqltmp = @sqltmp + N'			AND dwh_pk.form_code = CONVERT(INT, pp.form_code) ';
	SET @sqltmp = @sqltmp + N'			AND dwh_pk.pin_num_code = CONVERT(INT, pp.pin_num_code) ';
	SET @sqltmp = @sqltmp + N'			AND dwh_pk.item_code = CONVERT(INT, pp.item_code) ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN [apcsprodwh].[dwh].[dim_package_groups] as dwh_pkg with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'		on dwh_pkg.id = dwh_pk.package_group_id ';
	SET @sqltmp = @sqltmp + N'where PP.factory_code =''64646'' and PP.SHGC=''10'' ';


	PRINT '----------------------------------------';
	PRINT @sqltmp;

    ---------------------------------------------------------------------------
	--(5-3)([apcsprodwh].[dwh].[temp_fact_plan]) 
    ---------------------------------------------------------------------------
	BEGIN TRY
		BEGIN TRANSACTION;

		EXECUTE (@sqltmp);
		set @rowcnt = @@ROWCOUNT
		set @logtext = '@sqltmp:OK row:' + convert(varchar,@rowcnt)
		print @logtext

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

		SET @logtext = '[ERR] [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + '/SQL:' + @sqltmp + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg;
		PRINT 'transaction err ' + @logtext;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(6-1)Merge into
    ---------------------------------------------------------------------------
	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'MERGE INTO [apcsprodwh].[dwh].[fact_plan] AS dwh '
	SET @sqltmp = @sqltmp + N'USING [apcsprodwh].[dwh].[temp_fact_plan] AS tmp '
	SET @sqltmp = @sqltmp + N'ON ( '
	SET @sqltmp = @sqltmp + N'	    tmp.day_id = dwh.day_id '
	SET @sqltmp = @sqltmp + N'	AND tmp.package_group_id = dwh.package_group_id '
	SET @sqltmp = @sqltmp + N'	AND tmp.package_id = dwh.package_id '
	SET @sqltmp = @sqltmp + N'	AND tmp.factory_id = dwh.factory_id '
	SET @sqltmp = @sqltmp + N'	AND tmp.product_family_id = dwh.product_family_id '
	SET @sqltmp = @sqltmp + N') '
	SET @sqltmp = @sqltmp + N'WHEN MATCHED THEN '
	SET @sqltmp = @sqltmp + N'	UPDATE '
	SET @sqltmp = @sqltmp + N'	SET dwh.pcs = tmp.pcs '

	SET @sqltmp = @sqltmp + N'WHEN NOT MATCHED THEN '
	SET @sqltmp = @sqltmp + N'	INSERT '
	SET @sqltmp = @sqltmp + N'	( '
	SET @sqltmp = @sqltmp + N'	 day_id	'
	SET @sqltmp = @sqltmp + N'	,package_group_id '
	SET @sqltmp = @sqltmp + N'	,package_id '
	SET @sqltmp = @sqltmp + N'	,factory_id '
	SET @sqltmp = @sqltmp + N'	,product_family_id '
	SET @sqltmp = @sqltmp + N'	,pcs '
	SET @sqltmp = @sqltmp + N'	) '
	SET @sqltmp = @sqltmp + N'	VALUES '
	SET @sqltmp = @sqltmp + N'	( '
	SET @sqltmp = @sqltmp + N'	 tmp.day_id '
	SET @sqltmp = @sqltmp + N'	,tmp.package_group_id '
	SET @sqltmp = @sqltmp + N'	,tmp.package_id '
	SET @sqltmp = @sqltmp + N'	,tmp.factory_id '
	SET @sqltmp = @sqltmp + N'	,tmp.product_family_id '
	SET @sqltmp = @sqltmp + N'	,tmp.pcs '
	SET @sqltmp = @sqltmp + N'	); ';

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
		EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='dwh.fact_plan', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
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

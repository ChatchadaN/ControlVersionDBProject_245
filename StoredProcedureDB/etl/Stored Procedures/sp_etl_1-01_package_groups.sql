

CREATE PROCEDURE [etl].[sp_etl_1-01_package_groups] (@v_ProServerName NVARCHAR(128) = ''
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
	--(2)declare (log)
    ---------------------------------------------------------------------------
	--DECLARE @pathname NVARCHAR(128) = N'\\10.28.33.5\NewCenterPoint\APCS_PRO\DATABASE\SSISLog\';
	--DECLARE @logfile NVARCHAR(128) = N'Log' + CONVERT(NVARCHAR(8), FORMAT(GETDATE(), 'yyyyMMdd')) + N'.log';
	--DECLARE @logfilepathname NVARCHAR(256) = CONVERT(NVARCHAR(256), (@pathname + @logfile));
	--DECLARE @errlogfile NVARCHAR(128) = N'ErrorLog' + CONVERT(NVARCHAR(8), FORMAT(GETDATE(), 'yyyyMMdd')) + N'.log';
	--DECLARE @errlogfilepathname NVARCHAR(256) = CONVERT(NVARCHAR(256), (@pathname + @errlogfile));
	--DECLARE @logtext NVARCHAR(2000) = '';

	DECLARE @update_flg INT = 0;
	DECLARE @met_id INT;
	DECLARE @met_name CHAR(10);
	DECLARE @man_factory_id INT;
	DECLARE @man_product_family_id INT;

    ---------------------------------------------------------------------------
	--(3) get function_finish_control last_finish
    ---------------------------------------------------------------------------
	DECLARE @functionname NVARCHAR(128) = '';
	DECLARE @endtime DATETIME;
	BEGIN TRY
		SELECT @functionname = OBJECT_NAME(@@PROCID);
		SELECT @endtime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'));
	END TRY
	BEGIN CATCH
		SET @logtext = '[ERR](3)' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(4)SQL•¶ì¬
    ---------------------------------------------------------------------------
	--DECLARE @sqltmp NVARCHAR(4000) = '';
	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'SELECT ';
	SET @sqltmp = @sqltmp + N'		t1.met_id ';
	SET @sqltmp = @sqltmp + N'		,t1.met_name ';
	SET @sqltmp = @sqltmp + N'		,t1.man_factory_id ';
	SET @sqltmp = @sqltmp + N'		,t1.man_product_family_id ';
	SET @sqltmp = @sqltmp + N'		,t1.update_flg ';
	SET @sqltmp = @sqltmp + N'FROM ( ';
	SET @sqltmp = @sqltmp + N'			SELECT ';
	SET @sqltmp = @sqltmp + N'				met.id as met_id ';
	SET @sqltmp = @sqltmp + N'				,met.name as met_name ';
	SET @sqltmp = @sqltmp + N'				,man.factory_id as man_factory_id ';
	SET @sqltmp = @sqltmp + N'				,man.id as man_product_family_id ';
	SET @sqltmp = @sqltmp + N'				,CASE WHEN (met.id = dwh.id) THEN ';
	SET @sqltmp = @sqltmp + N'						CASE WHEN (RTRIM(met.name) = RTRIM(dwh.name) COLLATE SQL_Latin1_General_CP1_CI_AS) THEN ';
	SET @sqltmp = @sqltmp + N'							CASE WHEN ((man.factory_id IS NULL AND dwh.factory_id IS NULL) OR (man.factory_id = dwh.factory_id )) THEN ';
	SET @sqltmp = @sqltmp + N'								CASE WHEN ((man.id IS NULL AND dwh.product_family_id IS NULL) OR (man.id = dwh.product_family_id)) THEN 0 ';
	SET @sqltmp = @sqltmp + N'									ELSE 2 ';
	SET @sqltmp = @sqltmp + N'									END ';
	SET @sqltmp = @sqltmp + N'								ELSE 2 ';
	SET @sqltmp = @sqltmp + N'								END ';
	SET @sqltmp = @sqltmp + N'							ELSE 2 ';
	SET @sqltmp = @sqltmp + N'							END ';
	SET @sqltmp = @sqltmp + N'						ELSE 1 ';
	SET @sqltmp = @sqltmp + N'						END AS update_flg ';
	SET @sqltmp = @sqltmp + N'			FROM ' + @objectname + '[method].[package_groups] AS met with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN [apcsprodwh].[dwh].[dim_package_groups] AS dwh with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh.id = met.id ';
	SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN ' + @objectname + '[man].[product_families] AS man with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON man.id = met.product_family_id ';
	SET @sqltmp = @sqltmp + N'		) AS t1 ';
	SET @sqltmp = @sqltmp + N'WHERE t1.update_flg > 0 ';

	PRINT '----------------------------------------';
	PRINT @sqltmp;

    ---------------------------------------------------------------------------
	--(5) Open Cur
    ---------------------------------------------------------------------------
	EXECUTE ('DECLARE Cur_package_groups CURSOR FOR ' + @sqltmp ) ;
	OPEN Cur_package_groups;

	FETCH NEXT FROM Cur_package_groups
	INTO
		 @met_id
		,@met_name
		,@man_factory_id
		,@man_product_family_id
		,@update_flg;

    ---------------------------------------------------------------------------
	--(6) update
    ---------------------------------------------------------------------------
	BEGIN TRY
		BEGIN TRANSACTION;

		WHILE (@@FETCH_STATUS = 0)

			BEGIN


				IF @update_flg = 1	--INSERT
					BEGIN
						INSERT INTO [APCSProDWH].[dwh].[dim_package_groups]
							(id
							,name
							,factory_id
							,product_family_id
							)
						VALUES
							(@met_id
							,@met_name
							,@man_factory_id
							,@man_product_family_id
							);
					END;

				ELSE	--UPDATE
					BEGIN
						UPDATE [APCSProDWH].[dwh].[dim_package_groups]
						SET    name = @met_name
								,factory_id = @man_factory_id
								,product_family_id = @man_product_family_id
						WHERE id = @met_id;
					END;
 

				FETCH NEXT FROM Cur_package_groups
				INTO
					 @met_id
					,@met_name
					,@man_factory_id
					,@man_product_family_id
					,@update_flg;
			END;
			
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

		SET @logtext = '[ERR]' + @errmsg;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(7) close
    ---------------------------------------------------------------------------
	CLOSE Cur_package_groups;
	DEALLOCATE Cur_package_groups;

	---------------------------------------------------------------------------
	--(8)[sp_update_function_finish_control]
	---------------------------------------------------------------------------
	BEGIN TRY
		EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
			IF @ret<>0
				begin
					SET @logtext = '@ret<>0 [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg;				
					PRINT 'sp_update_function_finish_control:NG' + convert(varchar,@ret) + @logtext;
					--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;

					return -1;
				end;
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = '[ERR2]' + @errmsg;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;


    ---------------------------------------------------------------------------
	--(9)Return
    ---------------------------------------------------------------------------
	RETURN 0;

END ;


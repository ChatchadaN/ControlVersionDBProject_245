

CREATE PROCEDURE [etl].[sp_etl_1-02_packages] (@v_ProServerName NVARCHAR(128) = ''
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

	DECLARE @update_flg INT = 0;
	DECLARE @met_id INT;
	DECLARE @met_name CHAR(20);
	DECLARE @man_factory_id INT;
	DECLARE @man_product_family_id INT;
	DECLARE @met_package_group_id INT;
	DECLARE @form_code varCHAR(3);
	DECLARE @pin_num_code varCHAR(3);
	DECLARE @item_code varCHAR(2);

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
	--(4) SQL Make
    ---------------------------------------------------------------------------
	SET @sqltmp = '';
	SET @sqltmp = @sqltmp + 'SELECT ';
	SET @sqltmp = @sqltmp + '	t1.met_id ';
	SET @sqltmp = @sqltmp + '	,t1.met_name ';
	SET @sqltmp = @sqltmp + '	,t1.man_factory_id ';
	SET @sqltmp = @sqltmp + '	,t1.man_product_family_id ';
	SET @sqltmp = @sqltmp + '	,t1.met_package_group_id ';
	SET @sqltmp = @sqltmp + '	,t1.met_form_code ';
	SET @sqltmp = @sqltmp + '	,t1.met_pin_num_code ';
	SET @sqltmp = @sqltmp + '	,t1.met_item_code ';
	SET @sqltmp = @sqltmp + '	,t1.update_flg ';
	SET @sqltmp = @sqltmp + 'FROM ( ';
	SET @sqltmp = @sqltmp + '		SELECT ';
	SET @sqltmp = @sqltmp + '			met.id as met_id ';
	SET @sqltmp = @sqltmp + '			,rtrim(met.name) as met_name ';
	SET @sqltmp = @sqltmp + '			,man.factory_id as man_factory_id ';
	SET @sqltmp = @sqltmp + '			,man.id as man_product_family_id ';
	SET @sqltmp = @sqltmp + '			,met.package_group_id as met_package_group_id ';
	SET @sqltmp = @sqltmp + '			,met.form_code as met_form_code ';
	SET @sqltmp = @sqltmp + '			,met.pin_num_code as met_pin_num_code ';
	SET @sqltmp = @sqltmp + '			,met.item_code as met_item_code ';
	SET @sqltmp = @sqltmp + '			,CASE WHEN (met.id = dwh.id) THEN ';
	SET @sqltmp = @sqltmp + '					CASE WHEN (RTRIM(met.name) = RTRIM(dwh.name) COLLATE SQL_Latin1_General_CP1_CI_AS) THEN ';
	SET @sqltmp = @sqltmp + '							CASE WHEN ((man.factory_id IS NULL AND dwh.factory_id IS NULL) OR (man.factory_id = dwh.factory_id )) THEN ';
	SET @sqltmp = @sqltmp + '								CASE WHEN ((man.id IS NULL AND dwh.product_family_id IS NULL) OR (man.id = dwh.product_family_id)) THEN ';
	SET @sqltmp = @sqltmp + '										CASE WHEN ((met.package_group_id IS NULL AND dwh.package_group_id IS NULL) OR (met.package_group_id = dwh.package_group_id)) THEN ';
	SET @sqltmp = @sqltmp + '												CASE WHEN (RTRIM(met.form_code) = RTRIM(dwh.form_code) COLLATE SQL_Latin1_General_CP1_CI_AS) THEN ';
	SET @sqltmp = @sqltmp + '													CASE WHEN (RTRIM(met.pin_num_code) = RTRIM(dwh.pin_num_code) COLLATE SQL_Latin1_General_CP1_CI_AS) THEN ';
	SET @sqltmp = @sqltmp + '														CASE WHEN (RTRIM(met.item_code) = RTRIM(dwh.item_code) COLLATE SQL_Latin1_General_CP1_CI_AS) THEN 0 ';
	SET @sqltmp = @sqltmp + '															ELSE 2 END ';
	SET @sqltmp = @sqltmp + '														ELSE 2 END ';
	SET @sqltmp = @sqltmp + '													ELSE 2 END ';
	SET @sqltmp = @sqltmp + '												ELSE 2 ';
	SET @sqltmp = @sqltmp + '												END ';
	SET @sqltmp = @sqltmp + '										ELSE 2 ';
	SET @sqltmp = @sqltmp + '										END ';
	SET @sqltmp = @sqltmp + '								ELSE 2 ';
	SET @sqltmp = @sqltmp + '								END ';
	SET @sqltmp = @sqltmp + '							ELSE 2 ';
	SET @sqltmp = @sqltmp + '							END ';
	SET @sqltmp = @sqltmp + '					ELSE 1 ';
	SET @sqltmp = @sqltmp + '					END AS update_flg ';
	SET @sqltmp = @sqltmp + '		FROM ' + @objectname + '[method].[packages] AS met with (NOLOCK) ';
	SET @sqltmp = @sqltmp + '			LEFT OUTER JOIN [apcsprodwh].[dwh].[dim_packages] AS dwh with (NOLOCK) ';
	SET @sqltmp = @sqltmp + '				ON dwh.id = met.id ';
	SET @sqltmp = @sqltmp + '			LEFT OUTER JOIN ' + @objectname + '[method].[package_groups] AS met2 with (NOLOCK) ';
	SET @sqltmp = @sqltmp + '				ON met2.id = met.package_group_id ';
	SET @sqltmp = @sqltmp + '			LEFT OUTER JOIN ' + @objectname + '[man].[product_families] AS man with (NOLOCK) ';
	SET @sqltmp = @sqltmp + '				ON man.id = met.product_family_id ';
	SET @sqltmp = @sqltmp + '	) AS t1 ';
	SET @sqltmp = @sqltmp + 'WHERE t1.update_flg > 0 ';

	PRINT '----------------------------------------';
	PRINT @sqltmp;

    ---------------------------------------------------------------------------
	--(5) Open Cur
    ---------------------------------------------------------------------------
	EXECUTE ('DECLARE Cur_packages CURSOR FOR ' + @sqltmp ) ;
	OPEN Cur_packages;

	FETCH NEXT FROM Cur_packages
	INTO
		 @met_id
		,@met_name
		,@man_factory_id
		,@man_product_family_id
		,@met_package_group_id
		,@form_code
		,@pin_num_code
		,@item_code
		,@update_flg;

    ---------------------------------------------------------------------------
	--(6) update
    ---------------------------------------------------------------------------
	BEGIN TRY
		BEGIN TRANSACTION;

		WHILE @@FETCH_STATUS = 0

			BEGIN


				IF @update_flg = 1	--INSERT
					BEGIN
						INSERT INTO [APCSProDWH].[dwh].[dim_packages]
							(id
							,name
							,factory_id
							,product_family_id
							,package_group_id
							,form_code
							,pin_num_code
							,item_code
							)
						VALUES
							(@met_id
							,@met_name
							,@man_factory_id
							,@man_product_family_id
							,@met_package_group_id
							,@form_code
							,@pin_num_code
							,@item_code
							);
					END;

				ELSE	--UPDATE
					BEGIN
						UPDATE [APCSProDWH].[dwh].[dim_packages]
						SET    name = @met_name
								,factory_id = @man_factory_id
								,product_family_id = @man_product_family_id
								,package_group_id = @met_package_group_id
								,form_code = @form_code
								,pin_num_code = @pin_num_code
								,item_code = @item_code
						WHERE id = @met_id;
					END;
 

				FETCH NEXT FROM Cur_packages
				INTO
					 @met_id
					,@met_name
					,@man_factory_id
					,@man_product_family_id
					,@met_package_group_id
					,@form_code 
					,@pin_num_code
					,@item_code
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

		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

	---------------------------------------------------------------------------
	--(7) close
    ---------------------------------------------------------------------------
	CLOSE Cur_packages;
	DEALLOCATE Cur_packages;

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

	RETURN 0;

END;


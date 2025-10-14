

CREATE PROCEDURE [etl].[sp_etl_1-04_assy_device_name] (@v_ProServerName NVARCHAR(128) = ''
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

	--2019-09-13 add yama
	DECLARE @sqlTreat NVARCHAR(4000) = '';

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
	--(4)SQL  Make
    ---------------------------------------------------------------------------
	--2019-09-13 yama modifiy
	/*
	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'INSERT INTO [apcsprodwh].[dwh].[dim_assy_device_names] ';
	SET @sqltmp = @sqltmp + N'		( ';
	SET @sqltmp = @sqltmp + N'			id ';
	SET @sqltmp = @sqltmp + N'			,name ';
	SET @sqltmp = @sqltmp + N'			,factory_id ';
	SET @sqltmp = @sqltmp + N'			,product_family_id ';
	SET @sqltmp = @sqltmp + N'			,package_id ';
	SET @sqltmp = @sqltmp + N'		) ';
	SET @sqltmp = @sqltmp + N'SELECT ';
	SET @sqltmp = @sqltmp + N'		t1.met_id ';
	SET @sqltmp = @sqltmp + N'		,t1.met_name ';
	SET @sqltmp = @sqltmp + N'		,t1.man_factory_id ';
	SET @sqltmp = @sqltmp + N'		,t1.man_product_family_id ';
	SET @sqltmp = @sqltmp + N'		,t1.met_package_id ';
	SET @sqltmp = @sqltmp + N'FROM ( ';
	SET @sqltmp = @sqltmp + N'			SELECT ';
	SET @sqltmp = @sqltmp + N'				met.id as met_id ';
	SET @sqltmp = @sqltmp + N'				,rtrim(met.assy_name) as met_name ';
	SET @sqltmp = @sqltmp + N'				,man.factory_id as man_factory_id ';
	SET @sqltmp = @sqltmp + N'				,man.id as man_product_family_id ';
	SET @sqltmp = @sqltmp + N'				,met2.id as met_package_id ';
	SET @sqltmp = @sqltmp + N'			FROM ' + @objectname + '[method].[device_names] AS met with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN ' + @objectname + '[method].[packages] AS met2 with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON met2.id = met.package_id ';
	SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN ' + @objectname + '[man].[product_families] AS man with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON man.id = met2.product_family_id ';
	SET @sqltmp = @sqltmp + N'			WHERE (met.assy_name IS NOT NULL AND RTRIM(met.assy_name) <> '''' ) ';
	SET @sqltmp = @sqltmp + N'				AND met.is_assy_only in(0,1) ';
	SET @sqltmp = @sqltmp + N'			GROUP BY met.id,met.assy_name ,man.factory_id ,man.id ,met2.id ';
	SET @sqltmp = @sqltmp + N'		) AS t1 ';
	SET @sqltmp = @sqltmp + N'WHERE NOT EXISTS ';
	SET @sqltmp = @sqltmp + N'		(SELECT ''X'' ';
	SET @sqltmp = @sqltmp + N'			FROM [apcsprodwh].[dwh].[dim_assy_device_names] AS dwh  with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'			WHERE dwh.name = t1.met_name COLLATE SQL_Latin1_General_CP1_CI_AS ';
	SET @sqltmp = @sqltmp + N'				AND dwh.factory_id = t1.man_factory_id ';
	SET @sqltmp = @sqltmp + N'				AND dwh.product_family_id = t1.man_product_family_id ';
	SET @sqltmp = @sqltmp + N'				AND dwh.package_id =  t1.met_package_id ) ';
	*/

	DECLARE @id　INT;
	DECLARE @name NVARCHAR(30);
	DECLARE @factoryid INT;
	DECLARE @productfamilyid INT;
	DECLARE @packageid INT;
	DECLARE @update_flg INT = 0;

	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'select ';
	SET @sqltmp = @sqltmp + N'	t2.id ';
	SET @sqltmp = @sqltmp + N'	,t2.name ';
	SET @sqltmp = @sqltmp + N'	,t2.factory_id ';
	SET @sqltmp = @sqltmp + N'	,t2.product_family_id ';
	SET @sqltmp = @sqltmp + N'	,t2.package_id ';
	SET @sqltmp = @sqltmp + N'	,t2.update_flg ';
	SET @sqltmp = @sqltmp + N'from ';
	SET @sqltmp = @sqltmp + N'( ';
	SET @sqltmp = @sqltmp + N'	SELECT ';
	SET @sqltmp = @sqltmp + N'		t1.met_id id ';
	SET @sqltmp = @sqltmp + N'		,t1.met_name name ';
	SET @sqltmp = @sqltmp + N'		,t1.man_factory_id factory_id ';
	SET @sqltmp = @sqltmp + N'		,t1.man_product_family_id product_family_id ';
	SET @sqltmp = @sqltmp + N'		,t1.met_package_id package_id ';
	SET @sqltmp = @sqltmp + N'		,case when  (isnull(t1.met_id,0) = isnull(dwh.id,0)) then ';
	SET @sqltmp = @sqltmp + N'			case when isnull(rtrim(dwh.name),'''') <> isnull(rtrim(t1.met_name),'''') COLLATE SQL_Latin1_General_CP1_CI_AS ';
	SET @sqltmp = @sqltmp + N'					or isnull(dwh.factory_id,0) <> isnull(t1.man_factory_id,0) ';
	SET @sqltmp = @sqltmp + N'					or isnull(dwh.product_family_id,0) <> isnull(t1.man_product_family_id,0) ';
	SET @sqltmp = @sqltmp + N'					or isnull(dwh.package_id,0) <> isnull(t1.met_package_id,0) ';
	SET @sqltmp = @sqltmp + N'				then 2 ';
	SET @sqltmp = @sqltmp + N'				else 0 end ';
	SET @sqltmp = @sqltmp + N'			else 1 end as update_flg ';
	SET @sqltmp = @sqltmp + N'	FROM ';
	SET @sqltmp = @sqltmp + N'	( ';
	SET @sqltmp = @sqltmp + N'		SELECT ';
	SET @sqltmp = @sqltmp + N'			met.id AS met_id ';
	SET @sqltmp = @sqltmp + N'			,rtrim(met.assy_name) AS met_name ';
	SET @sqltmp = @sqltmp + N'			,man.factory_id AS man_factory_id ';
	SET @sqltmp = @sqltmp + N'			,man.id AS man_product_family_id ';
	SET @sqltmp = @sqltmp + N'			,met2.id AS met_package_id ';
	SET @sqltmp = @sqltmp + N'		FROM ';
	SET @sqltmp = @sqltmp + N'			[APCSProDB].[method].[device_names] AS met WITH (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'			LEFT OUTER JOIN [APCSProDB].[method].[packages] AS met2 WITH (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON met2.id = met.package_id ';
	SET @sqltmp = @sqltmp + N'			LEFT OUTER JOIN [APCSProDB].[man].[product_families] AS man WITH (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON man.id = met2.product_family_id ';
	SET @sqltmp = @sqltmp + N'		WHERE ';
	SET @sqltmp = @sqltmp + N'			isnull(rtrim(met.assy_name),'''') <> '''' ';
	SET @sqltmp = @sqltmp + N'				AND met.is_assy_only IN (0,1) ';
	SET @sqltmp = @sqltmp + N'		GROUP BY ';
	SET @sqltmp = @sqltmp + N'			met.id ';
	SET @sqltmp = @sqltmp + N'			,met.assy_name ';
	SET @sqltmp = @sqltmp + N'			,man.factory_id ';
	SET @sqltmp = @sqltmp + N'			,man.id ';
	SET @sqltmp = @sqltmp + N'			,met2.id ';
	SET @sqltmp = @sqltmp + N'	) AS t1 ';
	SET @sqltmp = @sqltmp + N'	LEFT OUTER JOIN [APCSProDWH].[dwh].[dim_assy_device_names] AS dwh WITH (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'		ON dwh.id = t1.met_id ';
	SET @sqltmp = @sqltmp + N') t2 ';
	SET @sqltmp = @sqltmp + N'where t2.update_flg > 0 ';


	PRINT '----------------------------------------';
	PRINT @sqltmp;


	--2019-09-13 yama modifiy
	/*
    ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------

	BEGIN TRY
		BEGIN TRANSACTION;
		EXECUTE (@sqltmp);
		set @rowcnt = @@ROWCOUNT
		set @logtext = '@sqltmp:OK row:' + convert(varchar,@rowcnt)
		print @logtext
		EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
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

		SET @logtext = '[ERR] [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + '/SQL:' + @sqltmp + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg;
		PRINT 'transaction err ' + @logtext;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

*/

	---------------------------------------------------------------------------
	--(5) Open Cur
    ---------------------------------------------------------------------------
	EXECUTE ('DECLARE Cur_select CURSOR FOR ' + @sqltmp ) ;
	OPEN Cur_select;

	FETCH NEXT FROM Cur_select
	INTO
		@id
		,@name
		,@factoryid
		,@productfamilyid
		,@packageid
		,@update_flg;

	---------------------------------------------------------------------------
	--(6) update
    ---------------------------------------------------------------------------
	BEGIN TRY
		BEGIN TRANSACTION;

		WHILE @@FETCH_STATUS = 0

			BEGIN
				SET @RowCnt = @RowCnt + 1;
				IF @update_flg = 1	--INSERT
					BEGIN
		 				SET @sqlTreat = N'';
						SET @sqlTreat = @sqlTreat + N'insert into [apcsprodwh].[dwh].[dim_assy_device_names] ';
						SET @sqlTreat = @sqlTreat + N'	(id ';
						SET @sqlTreat = @sqlTreat + N'	,name ';
						SET @sqlTreat = @sqlTreat + N'	,factory_id ';
						SET @sqlTreat = @sqlTreat + N'	,product_family_id ';
						SET @sqlTreat = @sqlTreat + N'	,package_id ';
						SET @sqlTreat = @sqlTreat + N'	) ';
						SET @sqlTreat = @sqlTreat + N' values ';
						SET @sqlTreat = @sqlTreat + N'	(';
						SET @sqlTreat = @sqlTreat + convert(varchar, @id) ;
						SET @sqlTreat = @sqlTreat + N' ,N''' + RTRIM(@name) + N'''';
						SET @sqlTreat = @sqlTreat + N' ,' + convert(varchar, @factoryid) ;
						SET @sqlTreat = @sqlTreat + N' ,' + convert(varchar, @productfamilyid) ;
						SET @sqlTreat = @sqlTreat + N' ,' + convert(varchar, @packageid) ;
						SET @sqlTreat = @sqlTreat + N')';
						print @sqltreat;
					END;
				else	--update
					BEGIN
						SET @sqlTreat = N'';
						SET @sqlTreat = @sqlTreat + N'update [apcsprodwh].[dwh].[dim_assy_device_names] WITH (ROWLOCK) ';
						SET @sqlTreat = @sqlTreat + N'	set name=N''' + RTRIM(@name) + N'''';
						SET @sqlTreat = @sqlTreat + N'	,factory_id=' + convert(varchar, @factoryid);
						SET @sqlTreat = @sqlTreat + N'	,product_family_id=' + convert(varchar, @productfamilyid);
						SET @sqlTreat = @sqlTreat + N'	,package_id=' + convert(varchar, @packageid);
						SET @sqlTreat = @sqlTreat + N' where id=' + convert(varchar, @id) ;
					END;

				print  convert(varchar, @RowCnt)+ N'/' + @sqltreat;
				EXECUTE (@sqlTreat);

				FETCH NEXT FROM Cur_select
					INTO
						@id
						,@name
						,@factoryid
						,@productfamilyid
						,@packageid
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

		SET @logtext = '[ERR]' + @errmsg + '/sql=' + @sqlTreat;
		PRINT @logtext;

		CLOSE Cur_select;
		DEALLOCATE Cur_select;

		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

	---------------------------------------------------------------------------
	--(7) close
    ---------------------------------------------------------------------------
	CLOSE Cur_select;
	DEALLOCATE Cur_select;

	---------------------------------------------------------------------------
	--(8)[sp_update_function_finish_control]
	---------------------------------------------------------------------------
	BEGIN TRY

		EXECUTE @Ret = [etl].[sp_update_function_finish_control] @function_name_=@FunctionName
															, @to_fact_table_ = '', @finished_at_=@EndTime
															, @errnum = @errnum OUTPUT,@errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;

		IF @Ret<>0
			begin
				SET @logtext = N'@ret<>0 [sp_update_function_finish_control] /ret:' ;
				SET @logtext = @logtext + convert(varchar,@Ret) ;
				SET @logtext = @logtext + N'/func:';
				SET @logtext = @logtext + @FunctionName;
				SET @logtext = @logtext + N'/fin:';
				SET @logtext = @logtext + convert(varchar,@Endtime,21);
				SET @logtext = @logtext + N'/num:';
				SET @logtext = @logtext + convert(varchar,@errnum);
				SET @logtext = @logtext + N'/line:';
				SET @logtext = @logtext + convert(varchar,@errline);
				SET @logtext = @logtext + N'/msg:';
				SET @logtext = @logtext + convert(varchar,@errmsg);
				PRINT 'logtext=' + @logtext;
				return -1;

			end;

	END TRY

	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @FunctionName;
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + N'/msg:';
		SET @logtext = @logtext + convert(varchar,@errmsg);
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

	RETURN 0;

END ;

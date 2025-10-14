


CREATE PROCEDURE [etl].[sp_etl_1-07_processes] (@v_ProServerName NVARCHAR(128) = ''
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
	DECLARE @sqltmp2 NVARCHAR(max) = '';
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
	--(4)SQL  Make
    ---------------------------------------------------------------------------

	DECLARE @update_flg INT = 0;
	DECLARE @met_id INT;
	DECLARE @met_name NVARCHAR(20);
	DECLARE @met_process_no VARCHAR(10);
	DECLARE @man_factory_id INT;
	DECLARE @man_product_family_id INT;

	--SET @sqltmp = N'';
	--SET @sqltmp = @sqltmp + N'SELECT ';
	--SET @sqltmp = @sqltmp + N'		t1.met_id ';
	--SET @sqltmp = @sqltmp + N'		,t1.met_name ';
	--SET @sqltmp = @sqltmp + N'		,t1.met_process_no ';
	--SET @sqltmp = @sqltmp + N'		,t1.man_factory_id ';
	--SET @sqltmp = @sqltmp + N'		,t1.man_product_family_id ';
	--SET @sqltmp = @sqltmp + N'		,t1.update_flg ';
	--SET @sqltmp = @sqltmp + N'FROM ( ';
	--SET @sqltmp = @sqltmp + N'			SELECT ';
	--SET @sqltmp = @sqltmp + N'				met.id as met_id ';
	--SET @sqltmp = @sqltmp + N'				,met.name as met_name ';
	--SET @sqltmp = @sqltmp + N'				,met.process_no as met_process_no ';
	--SET @sqltmp = @sqltmp + N'				,man.factory_id as man_factory_id ';
	--SET @sqltmp = @sqltmp + N'				,man.id as man_product_family_id ';
	--SET @sqltmp = @sqltmp + N'				,CASE WHEN (met.id = dwh.id) THEN ';
	--SET @sqltmp = @sqltmp + N'						CASE WHEN (RTRIM(met.name) = RTRIM(dwh.name) COLLATE SQL_Latin1_General_CP1_CI_AS) THEN ';
	--SET @sqltmp = @sqltmp + N'							CASE WHEN ((met.process_no IS NULL AND dwh.process_no IS NULL) OR (RTRIM(met.process_no) = RTRIM(dwh.process_no) COLLATE SQL_Latin1_General_CP1_CI_AS)) THEN ';
	--SET @sqltmp = @sqltmp + N'								CASE WHEN ((man.factory_id IS NULL AND dwh.factory_id IS NULL) OR (man.factory_id = dwh.factory_id)) THEN ';
	--SET @sqltmp = @sqltmp + N'									CASE WHEN ((man.id IS NULL AND dwh.product_family_id IS NULL) OR (man.id = dwh.product_family_id)) THEN 0 ';
	--SET @sqltmp = @sqltmp + N'										ELSE 2 ';
	--SET @sqltmp = @sqltmp + N'										END ';
	--SET @sqltmp = @sqltmp + N'									ELSE 2 ';
	--SET @sqltmp = @sqltmp + N'									END ';
	--SET @sqltmp = @sqltmp + N'								ELSE 2 ';
	--SET @sqltmp = @sqltmp + N'								END ';
	--SET @sqltmp = @sqltmp + N'							ELSE 2 ';
	--SET @sqltmp = @sqltmp + N'							END ';
	--SET @sqltmp = @sqltmp + N'						ELSE 1 ';
	--SET @sqltmp = @sqltmp + N'						END AS update_flg ';
	--SET @sqltmp = @sqltmp + N'			FROM ' + @objectname + '[method].[processes] AS met with (NOLOCK) ';
	--SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN [apcsprodwh].[dwh].[dim_processes] AS dwh with (NOLOCK) ';
	--SET @sqltmp = @sqltmp + N'					ON dwh.id = met.id ';
	--SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN ' + @objectname + '[man].[product_families] AS man with (NOLOCK) ';
	--SET @sqltmp = @sqltmp + N'					ON man.id = met.act_product_family_id ';
	--SET @sqltmp = @sqltmp + N'		) AS t1 ';
	--SET @sqltmp = @sqltmp + N'WHERE t1.update_flg > 0 ';

	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'select ';
	SET @sqltmp = @sqltmp + N'	t3.met_id ';
	SET @sqltmp = @sqltmp + N'	,t3.met_name ';
	SET @sqltmp = @sqltmp + N'	,t3.met_process_no ';
	SET @sqltmp = @sqltmp + N'	,t3.met_factory_id';
	SET @sqltmp = @sqltmp + N'	,t3.met_product_family_id ';
	SET @sqltmp = @sqltmp + N'	,t3.update_flg ';
	SET @sqltmp = @sqltmp + N'from ';
	SET @sqltmp = @sqltmp + N'	(';
	SET @sqltmp = @sqltmp + N'		select ';
	SET @sqltmp = @sqltmp + N'			*';
	SET @sqltmp = @sqltmp + N'			,CASE WHEN (t2.met_id = dwh.id) ';
	SET @sqltmp = @sqltmp + N'					THEN CASE WHEN (RTRIM(t2.met_name) = RTRIM(dwh.name) COLLATE SQL_Latin1_General_CP1_CI_AS) ';
	SET @sqltmp = @sqltmp + N'								THEN CASE WHEN ((t2.met_process_no IS NULL AND dwh.process_no IS NULL) OR (RTRIM(t2.met_process_no) = RTRIM(dwh.process_no) COLLATE SQL_Latin1_General_CP1_CI_AS)) ';
	SET @sqltmp = @sqltmp + N'											THEN CASE WHEN ((t2.met_id IS NULL AND dwh.product_family_id IS NULL) OR (t2.met_product_family_id = dwh.product_family_id)) ';
	SET @sqltmp = @sqltmp + N'														THEN 0 ';
	SET @sqltmp = @sqltmp + N'														ELSE 2 ';
	SET @sqltmp = @sqltmp + N'														END ';
	SET @sqltmp = @sqltmp + N'											ELSE 2 ';
	SET @sqltmp = @sqltmp + N'											END ';
	SET @sqltmp = @sqltmp + N'								ELSE 2 ';
	SET @sqltmp = @sqltmp + N'								END ';
	SET @sqltmp = @sqltmp + N'					ELSE 1 ';
	SET @sqltmp = @sqltmp + N'					END AS update_flg ';
	SET @sqltmp = @sqltmp + N'		from ';
	SET @sqltmp = @sqltmp + N'			(';
	SET @sqltmp = @sqltmp + N'				select ';
	SET @sqltmp = @sqltmp + N'					t1.met_id';
	SET @sqltmp = @sqltmp + N'					,t1.met_name';
	SET @sqltmp = @sqltmp + N'					,t1.met_process_no';
	SET @sqltmp = @sqltmp + N'					,max(t1.met_factory_id) over () as met_factory_id';
	SET @sqltmp = @sqltmp + N'					,max(t1.met_product_family_id) over () as met_product_family_id ';
	SET @sqltmp = @sqltmp + N'				from ';
	SET @sqltmp = @sqltmp + N'					(';
	SET @sqltmp = @sqltmp + N'						SELECT ';
	SET @sqltmp = @sqltmp + N'							met.id as met_id ';
	SET @sqltmp = @sqltmp + N'							,met.name as met_name ';
	SET @sqltmp = @sqltmp + N'							,met.process_no as met_process_no ';
	SET @sqltmp = @sqltmp + N'							,pf.factory_id as met_factory_id';
	SET @sqltmp = @sqltmp + N'							,met.act_product_family_id as met_product_family_id ';
	SET @sqltmp = @sqltmp + N'						FROM ' + @objectname + '[method].[processes] AS met with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'							inner join ' + @objectname + 'man.product_families as pf with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'								on pf.id = met.act_product_family_id';
	SET @sqltmp = @sqltmp + N'						union ';
	SET @sqltmp = @sqltmp + N'						SELECT ';
	SET @sqltmp = @sqltmp + N'							-1 as met_id ';
	SET @sqltmp = @sqltmp + N'							,''PRE-PLAN'' as met_name ';
	SET @sqltmp = @sqltmp + N'							,''0010'' as met_process_no ';
	SET @sqltmp = @sqltmp + N'							,null as met_factory_id ';
	SET @sqltmp = @sqltmp + N'							,null as met_product_family_id ';
	SET @sqltmp = @sqltmp + N'						union ';
	SET @sqltmp = @sqltmp + N'						SELECT ';
	SET @sqltmp = @sqltmp + N'							0 as met_id ';
	SET @sqltmp = @sqltmp + N'							,''PRE-DC'' as met_name ';
	SET @sqltmp = @sqltmp + N'							,''0011'' as met_process_no ';
	SET @sqltmp = @sqltmp + N'							,null as met_factory_id ';
	SET @sqltmp = @sqltmp + N'							,null as met_product_family_id ';
	SET @sqltmp = @sqltmp + N'					) as t1';
	SET @sqltmp = @sqltmp + N'			) as t2';
	SET @sqltmp = @sqltmp + N'			left outer join [apcsprodwh].[dwh].[dim_processes] AS dwh with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON dwh.id = t2.met_id ';
	SET @sqltmp = @sqltmp + N'					and dwh.product_family_id = t2.met_product_family_id';
	SET @sqltmp = @sqltmp + N'	) as t3 ';
	SET @sqltmp = @sqltmp + N'where t3.update_flg > 0';



	PRINT '----------------------------------------';
	PRINT @sqltmp;

    ---------------------------------------------------------------------------
	--(5) Open Cur
    ---------------------------------------------------------------------------
	EXECUTE ('DECLARE Cur_processes CURSOR FOR ' + @sqltmp ) ;
	OPEN Cur_processes;

	FETCH NEXT FROM Cur_processes
	INTO
		 @met_id
		,@met_name
		,@met_process_no
		,@man_factory_id
		,@man_product_family_id
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
						INSERT INTO [apcsprodwh].[dwh].[dim_processes]
							(id
							,name
							,process_no
							,factory_id
							,product_family_id
							)
						VALUES
							(@met_id
							,@met_name
							,@met_process_no
							,@man_factory_id
							,@man_product_family_id
							);
					END;

				ELSE	--UPDATE
					BEGIN
						UPDATE [apcsprodwh].[dwh].[dim_processes]
						SET    name = @met_name
								,process_no = @met_process_no
								,factory_id = @man_factory_id
								,product_family_id = @man_product_family_id
						WHERE id = @met_id;
					END;
 
				FETCH NEXT FROM Cur_processes
				INTO
					 @met_id
					,@met_name
					,@met_process_no
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

		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(7)close
    ---------------------------------------------------------------------------
	CLOSE Cur_processes;
	DEALLOCATE Cur_processes;


    ---------------------------------------------------------------------------
	--(8)SQL  Make2
    ---------------------------------------------------------------------------
	DECLARE @package_id INT;
	DECLARE @process_id INT;
	DECLARE @process_name NVARCHAR(30);
	DECLARE @process_no VARCHAR(10);
	SET @sqltmp2 = N'';
	SET @sqltmp2 = @sqltmp2 + N'select ';
	SET @sqltmp2 = @sqltmp2 + N' t.package_id '; 
	SET @sqltmp2 = @sqltmp2 + N' ,t.process_id ';
	SET @sqltmp2 = @sqltmp2 + N' ,t.process_no '; 
	SET @sqltmp2 = @sqltmp2 + N' ,t.process_name '; 
	SET @sqltmp2 = @sqltmp2 + N' ,t.man_factory_id '; 
	SET @sqltmp2 = @sqltmp2 + N' ,t.man_product_family_id ';  
	SET @sqltmp2 = @sqltmp2 + N' ,t.update_flg ';
    SET @sqltmp2 = @sqltmp2 + N'from ';
	SET @sqltmp2 = @sqltmp2 + N'( ';
	SET @sqltmp2 = @sqltmp2 + N'SELECT ';
	SET @sqltmp2 = @sqltmp2 + N'	pk.id as package_id ';
	SET @sqltmp2 = @sqltmp2 + N'	,p.id  as process_id ';
	SET @sqltmp2 = @sqltmp2 + N'	,p.process_no as process_no ';
	SET @sqltmp2 = @sqltmp2 + N'	,p.name as process_name ';
	SET @sqltmp2 = @sqltmp2 + N'	,fm.factory_id as man_factory_id  ';
	SET @sqltmp2 = @sqltmp2 + N'	,fm.id as man_product_family_id  ';
	SET @sqltmp2 = @sqltmp2 + N'	,CASE WHEN (pk.id = dwh.package_id)  ';
	SET @sqltmp2 = @sqltmp2 + N'		THEN CASE WHEN p.id = dwh.process_id ';
	SET @sqltmp2 = @sqltmp2 + N'			THEN CASE WHEN (isnull(RTRIM(p.process_no),'''')=isnull(RTRIM(dwh.process_no),'''') COLLATE SQL_Latin1_General_CP1_CI_AS) ';
	SET @sqltmp2 = @sqltmp2 + N'				then case when (isnull(RTRIM(p.name),'''')=isnull(rtrim(dwh.process_name),'''') COLLATE SQL_Latin1_General_CP1_CI_AS) ';
	SET @sqltmp2 = @sqltmp2 + N'					THEN CASE WHEN (isnull(fm.factory_id,0) = isnull(dwh.factory_id,0)) ';
	SET @sqltmp2 = @sqltmp2 + N'						THEN CASE WHEN (isnull(fm.id,0) = isnull( dwh.product_family_id ,0)) ';
	SET @sqltmp2 = @sqltmp2 + N'							THEN 0  ';
	SET @sqltmp2 = @sqltmp2 + N'							ELSE 2  ';
	SET @sqltmp2 = @sqltmp2 + N'							END  ';
	SET @sqltmp2 = @sqltmp2 + N'						ELSE 2  ';
	SET @sqltmp2 = @sqltmp2 + N'						END  ';
	SET @sqltmp2 = @sqltmp2 + N'					ELSE 2  ';
	SET @sqltmp2 = @sqltmp2 + N'					END  ';
	SET @sqltmp2 = @sqltmp2 + N'				ELSE 2  ';
	SET @sqltmp2 = @sqltmp2 + N'				END  ';
	SET @sqltmp2 = @sqltmp2 + N'			ELSE 2  ';
	SET @sqltmp2 = @sqltmp2 + N'			END  ';
	SET @sqltmp2 = @sqltmp2 + N'		ELSE 1 ';
	SET @sqltmp2 = @sqltmp2 + N'		END AS update_flg  ';
	SET @sqltmp2 = @sqltmp2 + N'FROM ' + @objectname + 'method.packages as pk with (NOLOCK)  ';
	SET @sqltmp2 = @sqltmp2 + N'	inner join ' + @objectname + 'method.device_names as d with (NOLOCK)  ';
	SET @sqltmp2 = @sqltmp2 + N'		on d.package_id = pk.id  ';
	SET @sqltmp2 = @sqltmp2 + N'			and d.is_assy_only in(0,1)  ';
	SET @sqltmp2 = @sqltmp2 + N'	inner join ' + @objectname + 'method.device_versions as dv with (NOLOCK)  ';
	SET @sqltmp2 = @sqltmp2 + N'		on dv.device_name_id = d.id  ';
	SET @sqltmp2 = @sqltmp2 + N'	inner join ' + @objectname + 'method.device_slips as ds with (NOLOCK)  ';
	SET @sqltmp2 = @sqltmp2 + N'		on ds.device_id = dv.device_id  ';
	SET @sqltmp2 = @sqltmp2 + N'	inner join ' + @objectname + 'method.device_flows as df with (NOLOCK)  ';
	SET @sqltmp2 = @sqltmp2 + N'		on df.device_slip_id = ds.device_slip_id  ';
	SET @sqltmp2 = @sqltmp2 + N'	inner join ' + @objectname + '[method].[jobs] AS j with (NOLOCK)  ';
	SET @sqltmp2 = @sqltmp2 + N'		on j.id = df.job_id ';
	SET @sqltmp2 = @sqltmp2 + N'	inner join ' + @objectname + '[method].[processes] AS p with (NOLOCK)  ';
	SET @sqltmp2 = @sqltmp2 + N'		on p.id = j.process_id or p.process_no in(''0000'',''0001'',''0100'') ';
	SET @sqltmp2 = @sqltmp2 + N'	LEFT OUTER JOIN [apcsprodwh].[dwh].[dim_package_processes] AS dwh with (NOLOCK)  ';
	SET @sqltmp2 = @sqltmp2 + N'		ON dwh.package_id = pk.id  ';
	SET @sqltmp2 = @sqltmp2 + N'			and dwh.process_id = p.id ';
	SET @sqltmp2 = @sqltmp2 + N'	LEFT OUTER JOIN ' + @objectname + '[man].[product_families] AS fm with (NOLOCK)  ';
	SET @sqltmp2 = @sqltmp2 + N'		ON fm.id = p.act_product_family_id  ';
	SET @sqltmp2 = @sqltmp2 + N'group by ';
	SET @sqltmp2 = @sqltmp2 + N'	pk.id ';
	SET @sqltmp2 = @sqltmp2 + N'	,p.id  ';
	SET @sqltmp2 = @sqltmp2 + N'	,p.process_no ';
	SET @sqltmp2 = @sqltmp2 + N'	,p.name ';
	SET @sqltmp2 = @sqltmp2 + N'	,fm.factory_id ';
	SET @sqltmp2 = @sqltmp2 + N'	,fm.id ';
	SET @sqltmp2 = @sqltmp2 + N'	,dwh.package_id ';
	SET @sqltmp2 = @sqltmp2 + N'	,dwh.process_name ';
	SET @sqltmp2 = @sqltmp2 + N'	,dwh.process_no ';
	SET @sqltmp2 = @sqltmp2 + N'	,dwh.process_id ';
	SET @sqltmp2 = @sqltmp2 + N'	,dwh.factory_id  ';
	SET @sqltmp2 = @sqltmp2 + N'	,dwh.product_family_id ';
	SET @sqltmp2 = @sqltmp2 + N') t ';
	SET @sqltmp2 = @sqltmp2 + N'where ';
	SET @sqltmp2 = @sqltmp2 + N' t.update_flg > 0 ';

	PRINT '----------------------------------------';
	PRINT @sqltmp2;

    ---------------------------------------------------------------------------
	--(9) Open Cur2
    ---------------------------------------------------------------------------
	EXECUTE ('DECLARE Cur_pack_processes CURSOR FOR ' + @sqltmp2 ) ;
	OPEN Cur_pack_processes;

	FETCH NEXT FROM Cur_pack_processes
	INTO
		 @package_id
		,@process_id
		,@process_no
		,@process_name
		,@man_factory_id
		,@man_product_family_id
		,@update_flg;

    ---------------------------------------------------------------------------
	--(10) update (package_processes)
    ---------------------------------------------------------------------------
	BEGIN TRY
		BEGIN TRANSACTION;

		WHILE @@FETCH_STATUS = 0

			BEGIN


				IF @update_flg = 1	--INSERT
					BEGIN
						INSERT INTO [apcsprodwh].[dwh].[dim_package_processes]
							(package_id
							,process_id
							,process_no
							,process_name
							,factory_id
							,product_family_id
							)
						VALUES
							(@package_id
							,@process_id
							,@process_no
							,@process_name
							,@man_factory_id
							,@man_product_family_id
							);
					END;

				ELSE	--UPDATE
					BEGIN
						UPDATE [apcsprodwh].[dwh].[dim_package_processes]
						SET    process_name = @process_name
								,process_no = @process_no
								,factory_id = @man_factory_id
								,product_family_id = @man_product_family_id
						WHERE package_id = @package_id
							and process_id = @process_id;
					END;
 
				FETCH NEXT FROM Cur_pack_processes
				INTO
					 @package_id
					,@process_id
					,@process_no
					,@process_name
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

		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(11)close2
    ---------------------------------------------------------------------------
	CLOSE Cur_pack_processes;
	DEALLOCATE Cur_pack_processes;

	---------------------------------------------------------------------------
	--(12)[sp_update_function_finish_control]
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

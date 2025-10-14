

CREATE PROCEDURE [etl].[sp_etl_1-10_headquarters] (@v_ProServerName NVARCHAR(128) = ''
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
	--(4)SQL  Make
    ---------------------------------------------------------------------------

	DECLARE @update_flg INT = 0;
	DECLARE @man_id INT;
	DECLARE @man_name NVARCHAR(50);
	DECLARE @man_factory_id INT;

	SET @sqltmp = '';
	SET @sqltmp = @sqltmp + N'SELECT ';
	SET @sqltmp = @sqltmp + N'		t1.man_id ';
	SET @sqltmp = @sqltmp + N'		,t1.man_name ';
	SET @sqltmp = @sqltmp + N'		,t1.man_factory_id ';
	SET @sqltmp = @sqltmp + N'		,t1.update_flg ';
	SET @sqltmp = @sqltmp + N'FROM ( ';
	SET @sqltmp = @sqltmp + N'			SELECT ';
	SET @sqltmp = @sqltmp + N'				man.id as man_id ';
	SET @sqltmp = @sqltmp + N'				,man.name as man_name ';
	SET @sqltmp = @sqltmp + N'				,man.factory_id as man_factory_id ';
	SET @sqltmp = @sqltmp + N'				,CASE WHEN (man.id = dwh.id) THEN ';
	SET @sqltmp = @sqltmp + N'					CASE WHEN (RTRIM(man.name) = RTRIM(dwh.name) COLLATE SQL_Latin1_General_CP1_CI_AS) THEN ';
	SET @sqltmp = @sqltmp + N'							CASE WHEN ((man.factory_id IS NULL AND dwh.factory_id IS NULL) OR (man.factory_id = dwh.factory_id )) THEN 0 ';
	SET @sqltmp = @sqltmp + N'								ELSE 2 ';
	SET @sqltmp = @sqltmp + N'								END ';
	SET @sqltmp = @sqltmp + N'							ELSE 2 ';
	SET @sqltmp = @sqltmp + N'							END ';
	SET @sqltmp = @sqltmp + N'						ELSE 1 ';
	SET @sqltmp = @sqltmp + N'						END AS update_flg ';
	SET @sqltmp = @sqltmp + N'			FROM ' + @objectname + '[man].[headquarters] AS man with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN [apcsprodwh].[dwh].[dim_headquarters] AS dwh with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh.id = man.id ';
	SET @sqltmp = @sqltmp + N'		) AS t1 ';
	SET @sqltmp = @sqltmp + N'WHERE t1.update_flg > 0 ';

	PRINT '----------------------------------------';
	PRINT @sqltmp;

    ---------------------------------------------------------------------------
	--(5) Open Cur
    ---------------------------------------------------------------------------
	EXECUTE ('DECLARE Cur_headquarters CURSOR FOR ' + @sqltmp ) ;
	OPEN Cur_headquarters;

	FETCH NEXT FROM Cur_headquarters
	INTO
		 @man_id
		,@man_name
		,@man_factory_id
		,@update_flg;

    ---------------------------------------------------------------------------
	--(6)update
    ---------------------------------------------------------------------------
	BEGIN TRY

		BEGIN TRANSACTION;

		WHILE @@FETCH_STATUS = 0

			BEGIN


				IF @update_flg = 1	--INSERT
					BEGIN
						INSERT INTO [apcsprodwh].[dwh].dim_headquarters
							(id
							,name
							,factory_id
							)
						VALUES
							(@man_id
							,@man_name
							,@man_factory_id
							);
					END;

				ELSE	--UPDATE
					BEGIN
						UPDATE [apcsprodwh].[dwh].dim_headquarters
						SET    name = @man_name
								,factory_id = @man_factory_id
						WHERE id = @man_id;
					END;
 

				FETCH NEXT FROM Cur_headquarters
				INTO
					 @man_id
					,@man_name
					,@man_factory_id
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
	CLOSE Cur_headquarters;
	DEALLOCATE Cur_headquarters;

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

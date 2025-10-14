



CREATE PROCEDURE [etl].[sp_etl_1-16_alarm_codes](@ServerName_APCSPro NVARCHAR(128) 
													,@DatabaseName_APCSPro NVARCHAR(128)
													,@ServerName_APCSProDWH NVARCHAR(128) 
													,@DatabaseName_APCSProDWH NVARCHAR(128)
													,@logtext NVARCHAR(max) output
													,@errnum  int output
													,@errline int output
													,@errmsg nvarchar(max) output
) AS
BEGIN
    ---------------------------------------------------------------------------
	--(1) Declare
    ---------------------------------------------------------------------------
	DECLARE @pObjAPCSPro NVARCHAR(128) = N'APCSProDB'
	DECLARE @pObjAPCSProDWH NVARCHAR(128) = N''

	DECLARE @pFunctionName NVARCHAR(128) = N'';
	--DECLARE @pStarttime DATETIME;
	DECLARE @pEndTime DATETIME;
	--DECLARE @pInputTime varchar(max);

	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 
	DECLARE @sqlSelect NVARCHAR(4000) = '';
	DECLARE @sqlTreat NVARCHAR(4000) = '';
	--DECLARE @pSqlRowCnt NVARCHAR(4000) = N'';
	DECLARE @pRowCnt INT = 0;

    ---------------------------------------------------------------------------
	--(1) connection string
    ---------------------------------------------------------------------------
	BEGIN
		IF RTRIM(@DatabaseName_APCSPro) = '' RETURN 1;
	END;

	BEGIN
		IF RTRIM(@DatabaseName_APCSProDWH) = '' RETURN 1;
	END;

	BEGIN
		IF RTRIM(@ServerName_APCSPro) = '' 
			BEGIN
				SET @pObjAPCSPro = '[' + @DatabaseName_APCSPro + ']'
			END;
		ELSE
		BEGIN
			SET @pObjAPCSPro = '[' + @ServerName_APCSPro + '].[' + @DatabaseName_APCSPro + ']'
		END;
	END;

	BEGIN
		IF RTRIM(@ServerName_APCSProDWH) = '' 
			BEGIN
				SET @pObjAPCSProDWH = '[' + @DatabaseName_APCSProDWH + ']'
			END;
		ELSE
		BEGIN
			SET @pObjAPCSProDWH = '[' + @ServerName_APCSProDWH + '].[' + @DatabaseName_APCSProDWH + ']'
		END;
	END;

    ---------------------------------------------------------------------------
	--(3) get function_finish_control last_finish
    ---------------------------------------------------------------------------
	BEGIN TRY
		SELECT @pFunctionName = OBJECT_NAME(@@PROCID);
		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()
		SET @logtext = N'[ERR]';
		SET @logtext = @logtext + ERROR_MESSAGE();
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(4)SQL Make
    ---------------------------------------------------------------------------
	DECLARE @id　INT;
	DECLARE @code NVARCHAR(20);
	DECLARE @machine_model_id INT;
	DECLARE @alarm_text_id INT;
	DECLARE @alarm_level INT;
	DECLARE @is_disabled INT;
	DECLARE @update_flg INT = 0;

	SET @sqlSelect = N''
	SET @sqlSelect = @sqlSelect + N'select ';
	SET @sqlSelect = @sqlSelect + N'	t1.id ';
	SET @sqlSelect = @sqlSelect + N'	,t1.code ';
	SET @sqlSelect = @sqlSelect + N'	,t1.machine_model_id ';
	SET @sqlSelect = @sqlSelect + N'	,t1.alarm_text_id ';
	SET @sqlSelect = @sqlSelect + N'	,t1.alarm_level ';
	SET @sqlSelect = @sqlSelect + N'	,t1.is_disabled ';
	SET @sqlSelect = @sqlSelect + N'	,t1.update_flg ';
	SET @sqlSelect = @sqlSelect + N'from ( ';
	SET @sqlSelect = @sqlSelect + N'		select ';
	SET @sqlSelect = @sqlSelect + N'			mc.id ';
	SET @sqlSelect = @sqlSelect + N'			,mc.alarm_code code ';
	SET @sqlSelect = @sqlSelect + N'			,mc.machine_model_id ';
	SET @sqlSelect = @sqlSelect + N'			,mc.alarm_text_id ';
	SET @sqlSelect = @sqlSelect + N'			,isnull(mc.alarm_level,0) alarm_level ';
	SET @sqlSelect = @sqlSelect + N'			,isnull(mc.is_disabled,0) is_disabled ';
	SET @sqlSelect = @sqlSelect + N'			,case when (mc.id = dwh.id) then ';
	--SET @sqlSelect = @sqlSelect + N'				case when (RTRIM(mc.alarm_code) <> RTRIM(dwh.code) COLLATE SQL_Latin1_General_CP1_CI_AS) ';
	SET @sqlSelect = @sqlSelect + N'				case when (isnull(RTRIM(mc.alarm_code),'''') <> isnull(RTRIM(dwh.code),'''') COLLATE SQL_Latin1_General_CP1_CI_AS) ';
	SET @sqlSelect = @sqlSelect + N'					or ';
	SET @sqlSelect = @sqlSelect + N'					(isnull(mc.machine_model_id,0) <> isnull(dwh.machine_model_id,0)) ';
	SET @sqlSelect = @sqlSelect + N'					or ';
	SET @sqlSelect = @sqlSelect + N'					(isnull(mc.alarm_text_id,0) <> isnull(dwh.alarm_text_id,0)) ';
	SET @sqlSelect = @sqlSelect + N'					or ';
	SET @sqlSelect = @sqlSelect + N'					(isnull(mc.alarm_level,0) <> isnull(dwh.alarm_level,0)) ';
	SET @sqlSelect = @sqlSelect + N'					or ';
	SET @sqlSelect = @sqlSelect + N'					(isnull(mc.is_disabled,0) <> isnull(dwh.is_disabled,0)) ';
	SET @sqlSelect = @sqlSelect + N'				then 2 ';
	SET @sqlSelect = @sqlSelect + N'				else 0 end ';
	SET @sqlSelect = @sqlSelect + N'			else 1 end as update_flg ';
	SET @sqlSelect = @sqlSelect + N'		from ';
	SET @sqlSelect = @sqlSelect + N'			' + @pObjAPCSPro + N'.[mc].[model_alarms] mc with (NOLOCK) ';
	SET @sqlSelect = @sqlSelect + N'			left outer join ' + @pObjAPCSProDWH + N'.[dwh].[dim_alarm_codes] dwh with (NOLOCK) ';
	SET @sqlSelect = @sqlSelect + N'				on dwh.id = mc.id ';
	SET @sqlSelect = @sqlSelect + N'	) as t1 ';
	SET @sqlSelect = @sqlSelect + N'where t1.update_flg > 0';
	PRINT '----------------------------------------';
	PRINT @sqlSelect;
    ---------------------------------------------------------------------------
	--(5) Open Cur
    ---------------------------------------------------------------------------
	EXECUTE ('DECLARE Cur_select CURSOR FOR ' + @sqlSelect ) ;
	OPEN Cur_select;

	FETCH NEXT FROM Cur_select
	INTO
		 @id
		,@code
		,@machine_model_id
		,@alarm_text_id
		,@alarm_level
		,@is_disabled
		,@update_flg;

    ---------------------------------------------------------------------------
	--(6) update
    ---------------------------------------------------------------------------
	BEGIN TRY
		BEGIN TRANSACTION;

		WHILE @@FETCH_STATUS = 0

			BEGIN

				SET @pRowCnt = @pRowCnt + 1;
				IF @update_flg = 1	--INSERT
					BEGIN

		 				SET @sqlTreat = N'';
						SET @sqlTreat = @sqlTreat + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[dim_alarm_codes] ';
						SET @sqlTreat = @sqlTreat + N' (id';
						SET @sqlTreat = @sqlTreat + N' ,code ';
						SET @sqlTreat = @sqlTreat + N' ,machine_model_id ';
						SET @sqlTreat = @sqlTreat + N' ,alarm_text_id ';
						SET @sqlTreat = @sqlTreat + N' ,alarm_level ';
						SET @sqlTreat = @sqlTreat + N' ,is_disabled) ';
						SET @sqlTreat = @sqlTreat + N' values ';
						SET @sqlTreat = @sqlTreat + N' (';
						SET @sqlTreat = @sqlTreat + convert(varchar, @id) ; 
						--SET @sqlTreat = @sqlTreat + N' ,''' + RTRIM(@code) + N'''';

						if @code is null
							SET @sqlTreat = @sqlTreat + N' ,null';
						else
							SET @sqlTreat = @sqlTreat + N' ,N''' + RTRIM(@code) + N'''';


						SET @sqlTreat = @sqlTreat + N' ,' + convert(varchar,@machine_model_id) ;
						SET @sqlTreat = @sqlTreat + N' ,' + convert(varchar,@alarm_text_id) ;
						SET @sqlTreat = @sqlTreat + N' ,' + convert(varchar,@alarm_level) ;
						SET @sqlTreat = @sqlTreat + N' ,' + convert(varchar,@is_disabled) ;
						SET @sqlTreat = @sqlTreat + N' )';
						--print @sqltreat;

					END;
				else	--update
					BEGIN
						SET @sqlTreat = N'';
						SET @sqlTreat = @sqlTreat + N'update ' + @pObjAPCSProDWH + N'.[dwh].[dim_alarm_codes] WITH (ROWLOCK) ';
						--SET @sqlTreat = @sqlTreat + N' set code=''' + RTRIM(@code) + N'''';

						if @code is null
							SET @sqlTreat = @sqlTreat + N' set code=null';
						else
							SET @sqlTreat = @sqlTreat + N' set code=N''' + RTRIM(@code) + N'''';

						SET @sqlTreat = @sqlTreat + N' ,machine_model_id = ' + convert(varchar,@machine_model_id) ;
						SET @sqlTreat = @sqlTreat + N' ,alarm_text_id =  ' + convert(varchar,@alarm_text_id) ;
						SET @sqlTreat = @sqlTreat + N' ,alarm_level = ' + convert(varchar,@alarm_level) ;
						SET @sqlTreat = @sqlTreat + N' ,is_disabled = ' + convert(varchar,@is_disabled) ;
						SET @sqlTreat = @sqlTreat + N' where id=' + convert(varchar, @id) ;
						--print @sqltreat;
					END;

				EXECUTE (@sqlTreat);
				print  convert(varchar, @pRowCnt)+ N'/' + @sqltreat;

				FETCH NEXT FROM Cur_select
					INTO
						 @id
						,@code
						,@machine_model_id
						,@alarm_text_id
						,@alarm_level
						,@is_disabled
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

		SET @logtext = '[ERR]' + @errmsg + '/sql=' + @sqlTreat + '/RowCnt=' + convert(varchar, @pRowCnt);
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

		EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName
															, @to_fact_table_ = '', @finished_at_=@pEndTime
															, @errnum = @errnum OUTPUT,@errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;

		IF @pRet<>0
			begin
				SET @logtext = N'@ret<>0 [sp_update_function_finish_control] /ret:' ;
				SET @logtext = @logtext + convert(varchar,@pRet) ;
				SET @logtext = @logtext + N'/func:';
				SET @logtext = @logtext + @pFunctionName;
				SET @logtext = @logtext + N'/fin:';
				SET @logtext = @logtext + convert(varchar,@pEndtime,21);
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
		SET @logtext = @logtext + @pFunctionName;
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

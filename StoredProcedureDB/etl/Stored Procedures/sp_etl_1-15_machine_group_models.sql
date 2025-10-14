






-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <20th May 2019>
-- Description:	<>
-- =============================================
CREATE PROCEDURE [etl].[sp_etl_1-15_machine_group_models] (@ServerName_APCSPro NVARCHAR(128) 
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
	--(4)SQL  Make
    ---------------------------------------------------------------------------

	DECLARE @group_id　INT;
	DECLARE @model_id　INT;
	DECLARE @dwh_id INT;
	DECLARE @update_flg INT = 0;

	SET @sqlSelect = N''
	SET @sqlSelect = @sqlSelect + N'select ';
	SET @sqlSelect = @sqlSelect + N'	t1.group_id ';
	SET @sqlSelect = @sqlSelect + N'	,t1.model_id ';
	SET @sqlSelect = @sqlSelect + N'	,t1.dwh_id ';
	SET @sqlSelect = @sqlSelect + N'	,t1.update_flg ';
	SET @sqlSelect = @sqlSelect + N'from ( ';
	SET @sqlSelect = @sqlSelect + N'		select ';
	SET @sqlSelect = @sqlSelect + N'			mc.machine_group_id group_id ';
	SET @sqlSelect = @sqlSelect + N'			,mc.machine_model_id model_id ';
	SET @sqlSelect = @sqlSelect + N'			,dwh.id dwh_id ';
	SET @sqlSelect = @sqlSelect + N'			,case when (mc.machine_group_id is null) or (mc.machine_model_id is null) then ';
	SET @sqlSelect = @sqlSelect + N'				case when dwh.is_disabled = 1 then 0 '; -- already known
	SET @sqlSelect = @sqlSelect + N'				else 2 end '; -- is_disabled = 0 to 1
	SET @sqlSelect = @sqlSelect + N'			else ';
	SET @sqlSelect = @sqlSelect + N'				case when (dwh.group_id is null) or (dwh.model_id is null) then 1 '; --additional
	SET @sqlSelect = @sqlSelect + N'				else ';
	SET @sqlSelect = @sqlSelect + N'					case when (dwh.group_id = mc.machine_group_id) and (dwh.model_id = mc.machine_model_id) then ';
	SET @sqlSelect = @sqlSelect + N'						case when dwh.is_disabled = 1 ';
	SET @sqlSelect = @sqlSelect + N'							then 3 '; --(is_enabled=1 to 0)
	SET @sqlSelect = @sqlSelect + N'							else 0 ';
	SET @sqlSelect = @sqlSelect + N'							end ';
	SET @sqlSelect = @sqlSelect + N'						end ';
	SET @sqlSelect = @sqlSelect + N'				end ';
	SET @sqlSelect = @sqlSelect + N'			end as update_flg ';
	SET @sqlSelect = @sqlSelect + N'		from ';
	SET @sqlSelect = @sqlSelect + N'			' + @pObjAPCSPro + N'.[mc].group_models mc with (NOLOCK) ';
	SET @sqlSelect = @sqlSelect + N'			full outer join ' + @pObjAPCSProDWH + N'.[dwh].[dim_mc_group_models] dwh with (NOLOCK) ';
	SET @sqlSelect = @sqlSelect + N'				on dwh.group_id = mc.machine_group_id ';
	SET @sqlSelect = @sqlSelect + N'					and dwh.model_id = mc.machine_model_id ';
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
		 @group_id
		,@model_id
		,@dwh_id
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
						SET @sqlTreat = @sqlTreat + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[dim_mc_group_models] ';
						SET @sqlTreat = @sqlTreat + N' (group_id ';
						SET @sqlTreat = @sqlTreat + N' ,model_id ';
						SET @sqlTreat = @sqlTreat + N' ,is_disabled) ';
						SET @sqlTreat = @sqlTreat + N' values ';
						SET @sqlTreat = @sqlTreat + N' (';
						SET @sqlTreat = @sqlTreat + convert(varchar, @group_id) ; 
						SET @sqlTreat = @sqlTreat + N' ,' + convert(varchar,@model_id) ;
						SET @sqlTreat = @sqlTreat + N' ,0)';
						--print @sqltreat;
					END;
				else --update is_disabled (2:0>1 or 3:1>0)
					BEGIN
						SET @sqlTreat = N'';
						SET @sqlTreat = @sqlTreat + N'update ' + @pObjAPCSProDWH + N'.[dwh].[dim_mc_group_models] WITH (ROWLOCK) ';
						SET @sqlTreat = @sqlTreat + N' set is_disabled = case when ' + convert(varchar,@update_flg) + N' = 2 then 1 else 0 end ';
						SET @sqlTreat = @sqlTreat + N' where id=' + convert(varchar, @dwh_id) ;
						--print @sqltreat;
					END;				

				EXECUTE (@sqlTreat);
				print  convert(varchar, @pRowCnt)+ N'/' + @sqltreat;

				FETCH NEXT FROM Cur_select
					INTO
						 @group_id
						,@model_id
						,@dwh_id
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








CREATE PROCEDURE [etl].[sp_etl_1-19_lots](@ServerName_APCSPro NVARCHAR(128) 
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
	DECLARE @psqlIns NVARCHAR(4000) = '';
	DECLARE @psqlUp NVARCHAR(4000) = '';
	--DECLARE @sqlTreat NVARCHAR(4000) = '';
	--DECLARE @pSqlRowCnt NVARCHAR(4000) = N'';
	DECLARE @pRowCnt INT = 0;
	declare @pUpRowCnt INT = 0;

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
	--(4)SQL Make (Insert)
    ---------------------------------------------------------------------------
	SET @psqlIns = N''
	SET @psqlIns = @psqlIns + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[dim_lots] ';
	SET @psqlIns = @psqlIns + N'( ';
	SET @psqlIns = @psqlIns + N'	id ';
	SET @psqlIns = @psqlIns + N'	,lot_no ';
	SET @psqlIns = @psqlIns + N'	,production_category ';
	SET @psqlIns = @psqlIns + N'	,package_group_id ';
	SET @psqlIns = @psqlIns + N'	,package_id ';
	SET @psqlIns = @psqlIns + N'	,device_id ';
	SET @psqlIns = @psqlIns + N'	,assy_name_id ';
	SET @psqlIns = @psqlIns + N'	,factory_id ';
	SET @psqlIns = @psqlIns + N'	,product_family_id ';
	SET @psqlIns = @psqlIns + N') ';
	SET @psqlIns = @psqlIns + N'select ';
	SET @psqlIns = @psqlIns + N'	lot.id ';
	SET @psqlIns = @psqlIns + N'	,lot.lot_no ';
	SET @psqlIns = @psqlIns + N'	,case SUBSTRING(lot.lot_no,5,1) ';
	SET @psqlIns = @psqlIns + N'		when ''A'' then 0 when ''V'' then 1 when ''W'' then 2 when ''X'' then 3 when ''Y'' then 4 ';
	SET @psqlIns = @psqlIns + N'		when ''B'' then 10 when ''Q'' then 11 when ''R'' then 12 when ''S'' then 13 when ''T'' then 14 ';
	SET @psqlIns = @psqlIns + N'		when ''D'' then 20 ';
	SET @psqlIns = @psqlIns + N'		when ''E'' then 30 when ''5'' then 31 when ''6'' then 32 when ''7'' then 33 when ''8'' then 34 ';
	SET @psqlIns = @psqlIns + N'		when ''F'' then 40 when ''K'' then 41 when ''L'' then 42 when ''M'' then 43 when ''N'' then 44 ';
	SET @psqlIns = @psqlIns + N'		when ''G'' then 50 when ''0'' then 51 when ''1'' then 52 when ''2'' then 53 when ''3'' then 54 ';
	SET @psqlIns = @psqlIns + N'		when ''H'' then 60 when ''P'' then 61 when ''U'' then 62 when ''Z'' then 63 when ''4'' then 64 ';
	SET @psqlIns = @psqlIns + N'		else 0 end as production_category ';
	SET @psqlIns = @psqlIns + N'	,pkg.package_group_id ';
	SET @psqlIns = @psqlIns + N'	,lot.act_package_id package_id ';
	SET @psqlIns = @psqlIns + N'	,lot.act_device_name_id device_id ';
	SET @psqlIns = @psqlIns + N'	,lot.act_device_name_id assy_name_id ';
	SET @psqlIns = @psqlIns + N'	,hq.factory_id ';
	SET @psqlIns = @psqlIns + N'	,lot.product_family_id ';
	--SET @psqlIns = @psqlIns + N'	,dwh.id ';
	SET @psqlIns = @psqlIns + N'from ';
	SET @psqlIns = @psqlIns + N'	' + @pObjAPCSPro + N'.[trans].[lots] lot with (NOLOCK) ';
	SET @psqlIns = @psqlIns + N'	inner join ' + @pObjAPCSPro + N'.[method].[packages] pkg with (NOLOCK) ';
	SET @psqlIns = @psqlIns + N'		on pkg.id = lot.act_package_id ';
	SET @psqlIns = @psqlIns + N'	inner join ' + @pObjAPCSPro + N'.[man].[product_headquarters] ph with (NOLOCK) ';
	SET @psqlIns = @psqlIns + N'		on ph.product_family_id = lot.product_family_id ';
	SET @psqlIns = @psqlIns + N'	inner join ' + @pObjAPCSPro + N'.[man].[headquarters] hq with (NOLOCK) ';
	SET @psqlIns = @psqlIns + N'		on hq.id = ph.headquarter_id ';
	SET @psqlIns = @psqlIns + N'	left outer join ' + @pObjAPCSProDWH + N'.[dwh].[dim_lots] dwh with (NOLOCK) ';
	SET @psqlIns = @psqlIns + N'		on dwh.id = lot.id ';
	SET @psqlIns = @psqlIns + N'where ';
	SET @psqlIns = @psqlIns + N'	dwh.id is null';

	PRINT '----------------------------------------';
	PRINT @psqlIns;

    ---------------------------------------------------------------------------
	--(4)SQL Make (Update production_category)
    ---------------------------------------------------------------------------
	SET @psqlUp = N''
	SET @psqlUp = @psqlUp + N'update ' + @pObjAPCSPro + N'.[trans].[lots] ';
	SET @psqlUp = @psqlUp + N'	set production_category = ';
	SET @psqlUp = @psqlUp + N'		case SUBSTRING(lot.lot_no,5,1) ';
	SET @psqlUp = @psqlUp + N'			when ''A'' then 0 when ''V'' then 1 when ''W'' then 2 when ''X'' then 3 when ''Y'' then 4 ';
	SET @psqlUp = @psqlUp + N'			when ''B'' then 10 when ''Q'' then 11 when ''R'' then 12 when ''S'' then 13 when ''T'' then 14 ';
	SET @psqlUp = @psqlUp + N'			when ''D'' then 20 ';
	SET @psqlUp = @psqlUp + N'			when ''E'' then 30 when ''5'' then 31 when ''6'' then 32 when ''7'' then 33 when ''8'' then 34 ';
	SET @psqlUp = @psqlUp + N'			when ''F'' then 40 when ''K'' then 41 when ''L'' then 42 when ''M'' then 43 when ''N'' then 44 ';
	SET @psqlUp = @psqlUp + N'			when ''G'' then 50 when ''0'' then 51 when ''1'' then 52 when ''2'' then 53 when ''3'' then 54 ';
	SET @psqlUp = @psqlUp + N'			when ''H'' then 60 when ''P'' then 61 when ''U'' then 62 when ''Z'' then 63 when ''4'' then 64 ';
	SET @psqlUp = @psqlUp + N'			else 0 end ';
	SET @psqlUp = @psqlUp + N'from ';
	SET @psqlUp = @psqlUp + N' ' + @pObjAPCSPro + N'.[trans].[lots] lot with (NOLOCK) ';
	SET @psqlUp = @psqlUp + N'where ';
	SET @psqlUp = @psqlUp + N'	lot.production_category is null';

	PRINT '----------------------------------------';
	PRINT @psqlUp;



    ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------
	BEGIN TRY

		BEGIN TRANSACTION;

			PRINT '-----1) dwh.dim_lots';
			SET @pStepNo = 1;
			PRINT N'@psqlIns=' + @psqlIns;	
			EXECUTE (@psqlIns);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = N'Insert(dim_lots) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----2) trans.lots.production_category';
			SET @pStepNo = 2;
			PRINT N'@psqlUp=' + @psqlUp;	
			EXECUTE (@psqlUp);
			SET @pUpRowCnt = @@ROWCOUNT;
			SET @logtext = N'Update(trans.lots.production_category) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pUpRowCnt);
			PRINT @logtext;


			PRINT '-----3) save the process log';
			SET @pStepNo = 3;
			--PRINT '@functionname=' + @functionname + ' / ' +  '@FromTime=' + format(@FromTime,'yyyy/MM/dd HH:mm:ss.ff3') + ' / ' +  '@ToTime=' + format(@ToTime,'yyyy/MM/dd HH:mm:ss.ff3');
			EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName
												, @to_fact_table_ = '', @finished_at_=@pEndTime
												, @errnum = @errnum OUTPUT,@errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;

			IF @pRet<>0
				begin
					IF @@TRANCOUNT <> 0
					BEGIN
						ROLLBACK TRANSACTION;
					END;

					SET @logtext = N'@ret<>0 [sp_update_function_finish_control] /ret:' ;
					SET @logtext = @logtext + convert(varchar,@pRet) ;
					SET @logtext = @logtext + N'/func:';
					SET @logtext = @logtext + @pFunctionName;
					SET @logtext = @logtext + N'/fin:';
					SET @logtext = @logtext + convert(varchar,@pEndtime,21);
					SET @logtext = @logtext + N'/step:';
					SET @logtext = @logtext + convert(varchar,@pStepNo);
					SET @logtext = @logtext + N'/num:';
					SET @logtext = @logtext + convert(varchar,@errnum);
					SET @logtext = @logtext + N'/line:';
					SET @logtext = @logtext + convert(varchar,@errline);
					SET @logtext = @logtext + N'/msg:';
					SET @logtext = @logtext + convert(varchar,@errmsg);
					PRINT 'logtext=' + @logtext;
					RETURN -1;

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

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @pFunctionName;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/count1:';
		SET @logtext = @logtext + convert(varchar,@pRowCnt);
		SET @logtext = @logtext + N'/count2:';
		SET @logtext = @logtext + convert(varchar,@pUpRowCnt);
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + '/msg:';
		SET @logtext = @logtext + @errmsg;
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

END ;

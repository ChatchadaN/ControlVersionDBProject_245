




-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <24th Jun 2019>
-- Description:	<>
-- =============================================
CREATE PROCEDURE [etl].[sp_etl_2-23_fact_mc_efficiency] (@ServerName_APCSPro NVARCHAR(128) 
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
	DECLARE @pStarttime DATETIME;
	DECLARE @pEndTime DATETIME;

	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 

	DECLARE @pSqlInsTmp NVARCHAR(4000) = N'';
	DECLARE @pSqlInsFact NVARCHAR(4000) = N'';
	DECLARE @pSqlDel NVARCHAR(4000) = N'';
	DECLARE @pSqlUpdate NVARCHAR(4000) = N'';

	DECLARE @pSqlRowCnt NVARCHAR(4000) = N'';

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
		SELECT @pStarttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		-- 2019-08-30 Add
		SET @pStarttime = ISNULL(@pStarttime,convert(datetime,'2019-08-01 00:00:00.000',21));
		--SET @pStarttime = convert(datetime,'2019-08-01 00:00:00.000',21)

		PRINT '@starttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;
		--yyyy/MM/dd HH:mm:ss.ff3
		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
		PRINT '@endtime=' + FORMAT(@pEndtime, 'yyyy-MM-dd HH:mm:ss.fff');

	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()
		SET @logtext = N'[ERR]';
		SET @logtext = @logtext + ERROR_MESSAGE();
		RETURN -1;
	END CATCH;

	if @pstarttime is not null
	begin
		if @pStarttime = @pEndTime 
			begin
				SET @logtext = @pfunctionname ;
				SET @logtext = @logtext + N' has already finished at this hour(' ;
				SET @logtext = @logtext + convert(varchar,@pEndTime,21);
				SET @logtext = @logtext + N')';
				RETURN 0;
			end;
	end ;

	---------------------------------------------------------------------------
	--(4)SQL  Make
    ---------------------------------------------------------------------------
	BEGIN
		SET @pSqlInsTmp = N'';
		SET @pSqlInsTmp = @pSqlInsTmp + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[temp_fact_mc_efficiency] ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'( ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	id ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	,started_at ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	,machine_id ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	,run_state ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	,ended_at ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	,record_class ';
		SET @pSqlInsTmp = @pSqlInsTmp + N') ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'select ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	t.id ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	,t.started_at ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	,t.machine_id ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	,t.run_state ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	,lead(t.started_at) over (partition by t.machine_id order by t.started_at) ended_time ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	,1 record_class ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'from ';
		-- <<t
		SET @pSqlInsTmp = @pSqlInsTmp + N'	( ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	select ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'		rec.id ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'		,rec.started_at ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'		,rec.machine_id ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'		,rec.run_state ';
		-- comment out 2019-09-06
		--next_rec
		--SET @pSqlInsTmp = @pSqlInsTmp + N'		,lead(rec.started_at) over (partition by rec.machine_id order by rec.started_at) next_time ';
		--SET @pSqlInsTmp = @pSqlInsTmp + N'		,lead(rec.run_state) over (partition by rec.machine_id order by rec.started_at) next_state ';
		--pre_rec
		--SET @pSqlInsTmp = @pSqlInsTmp + N'		,lag(rec.updated_at) over (partition by rec.machine_id order by rec.updated_at) pre_time ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'		,lag(rec.run_state) over (partition by rec.machine_id order by rec.started_at) pre_state ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	from ';
		-- <<rec
		SET @pSqlInsTmp = @pSqlInsTmp + N'		( ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'			( ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'				select ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					tmp.id ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					,tmp.started_at ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					,tmp.machine_id ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					,tmp.run_state ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					,tmp.ended_at ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'				from ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					' +	@pObjAPCSProDWH + N'.[dwh].[temp_fact_mc_efficiency] tmp with (NOLOCK) ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'			) ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'			union all ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'			( ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'				select ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					rec.id ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					,rec.updated_at started_at ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					,rec.machine_id ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					,rec.run_state ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					,null ended_at ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'				from ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					' +	@pObjAPCSPro + N'.[trans].[machine_state_records] rec with (NOLOCK) ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'				where ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'					updated_at > ''' + convert(varchar,@pStarttime,21) + N''' and updated_at <= ''' + convert(varchar,@pEndTime,21) + N''' ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'			) '; 
		SET @pSqlInsTmp = @pSqlInsTmp + N'		) rec ';
		-- >>rec
		SET @pSqlInsTmp = @pSqlInsTmp + N'	) t ';
		-- >>t
		SET @pSqlInsTmp = @pSqlInsTmp +	N'where ';
		SET @pSqlInsTmp = @pSqlInsTmp + N'	t.run_state <> t.pre_state or t.pre_state is null '; -- N' or t.next_state is null ';
	END;

	PRINT '----------------------------------------';
	PRINT @pSqlInsTmp;

	BEGIN
		SET @pSqlInsFact = N'';
		SET @pSqlInsFact = @pSqlInsFact + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[fact_mc_efficiency] ';
		SET @pSqlInsFact = @pSqlInsFact + N'( ';
		SET @pSqlInsFact = @pSqlInsFact + N'	day_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,hour_code ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,factory_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,product_family_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,machine_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,machine_model_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,code ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,started_at ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,ended_at ';
		SET @pSqlInsFact = @pSqlInsFact + N') ';
		SET @pSqlInsFact = @pSqlInsFact + N'select ';
		--Modify 2019.09.06 
		--SET @pSqlInsFact = @pSqlInsFact + N'	dt.d day_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	dt.id day_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,hr.code hour_code ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,hq.factory_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,ph.product_family_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,tmp.machine_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,mc.machine_model_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,eff.code code ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,tmp.started_at ';
		SET @pSqlInsFact = @pSqlInsFact + N'	,tmp.ended_at ';
		SET @pSqlInsFact = @pSqlInsFact + N'from ';
		SET @pSqlInsFact = @pSqlInsFact + N'	' + @pObjAPCSProDWH + N'.[dwh].[temp_fact_mc_efficiency] tmp with (NOLOCK) ';
		SET @pSqlInsFact = @pSqlInsFact + N'	inner join ' + @pObjAPCSPro +N'.[mc].[machines] mc with (NOLOCK) ';
		SET @pSqlInsFact = @pSqlInsFact + N'		on mc.id = tmp.machine_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	left outer join ' + @pObjAPCSPro+ N'.[man].[product_headquarters] ph with (NOLOCK) ';
		SET @pSqlInsFact = @pSqlInsFact + N'		on ph.headquarter_id = mc.headquarter_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	left outer join ' + @pObjAPCSPro + N'.[man].[headquarters] hq with (NOLOCK) ';
		SET @pSqlInsFact = @pSqlInsFact + N'		on hq.id = mc.headquarter_id ';
		SET @pSqlInsFact = @pSqlInsFact + N'	left outer join ' + @pObjAPCSProDWH + N'.[dwh].[dim_efficiencies] eff with (NOLOCK) ';
		--Debug 2019-09-02
		--SET @pSqlInsFact = @pSqlInsFact + N'		on eff.run_status = tmp.run_state ';
		SET @pSqlInsFact = @pSqlInsFact + N'		on eff.run_state = tmp.run_state ';
		SET @pSqlInsFact = @pSqlInsFact + N'	left join ' + @pObjAPCSProDWH + N'.[dwh].[dim_days] dt with (NOLOCK) ';
		SET @pSqlInsFact = @pSqlInsFact + N'		on dt.date_value = format(tmp.started_at,''yyyy-MM-dd'') ';
		SET @pSqlInsFact = @pSqlInsFact + N'	left join ' + @pObjAPCSProDWH + N'.[dwh].[dim_hours] hr with (NOLOCK) ';
		SET @pSqlInsFact = @pSqlInsFact + N'			on hr.h = format(tmp.started_at,''HH'') ';
		SET @pSqlInsFact = @pSqlInsFact + N'where ';
		SET @pSqlInsFact = @pSqlInsFact + N'	tmp.ended_at is not null ';
		--Add 2019-09-06
		SET @pSqlInsFact = @pSqlInsFact + N'order by tmp.id ';
	END;	
	PRINT '----------------------------------------';
	PRINT @pSqlInsFact;

	BEGIN
		SET @pSqlDel = N'';
		SET @pSqlDel = @pSqlDel + N'delete from ' + @pObjAPCSProDWH + N'.[dwh].[temp_fact_mc_efficiency] ';
		SET @pSqlDel = @pSqlDel + N'where ';
		SET @pSqlDel = @pSqlDel + N'	ended_at is not null ';
		SET @pSqlDel = @pSqlDel + N'	or record_class = 0 ';
	END;
	PRINT '----------------------------------------';
	PRINT @pSqlDel;

	BEGIN
		SET @pSqlUpdate = N'';
		SET @pSqlUpdate = @pSqlUpdate + N'update ' + @pObjAPCSProDWH + N'.[dwh].[temp_fact_mc_efficiency] with (ROWLOCK) ';
		SET @pSqlUpdate = @pSqlUpdate + N' set ';
		SET @pSqlUpdate = @pSqlUpdate + N'	record_class = 0 ';
	END;
	PRINT '----------------------------------------';
	PRINT @pSqlUpdate;

    ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------
	BEGIN TRY

		BEGIN TRANSACTION;

			PRINT '-----1) dwh.temp_fact_mc_efficiency';
			SET @pStepNo = 1;
			PRINT N'@pSqlInsTmp=' + @pSqlInsTmp;	
			EXECUTE (@pSqlInsTmp);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = N'Insert(temp_fact_mc_efficiency) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			--COMMIT TRANSACTION;
			--return 0;


			PRINT '-----2) dwh.fact_mc_efficiency';
			SET @pStepNo = 2;
			PRINT '@pSqlInsFact=' + @pSqlInsFact;	
			EXECUTE (@pSqlInsFact);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = N'Insert(fact_mc_efficiency) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----3) delete temp data';
			SET @pStepNo = 3;
			PRINT '@pSqlDel=' + @pSqlDel ;	
			EXECUTE (@pSqlDel);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = N'Delete(temp_fact_mc_efficiency) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----4) update temp data';
			SET @pStepNo = 4;
			PRINT '@pSqlUpdate=' + @pSqlUpdate ;	
			EXECUTE (@pSqlUpdate);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = N'Update(temp_fact_mc_efficiency) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----5) save the process log';
			SET @pStepNo = 5;
			--PRINT '@functionname=' + @functionname + ' / ' +  '@FromTime=' + format(@FromTime,'yyyy/MM/dd HH:mm:ss.ff3') + ' / ' +  '@ToTime=' + format(@ToTime,'yyyy/MM/dd HH:mm:ss.ff3');
			EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName
												, @to_fact_table_ = 'dwh.fact_mc_efficiency', @finished_at_=@pEndTime
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
		SET @logtext = @logtext + N'/count:';
		SET @logtext = @logtext + convert(varchar,@pRowCnt);
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + '/msg:';
		SET @logtext = @logtext + @errmsg;
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

RETURN 0;

END ;


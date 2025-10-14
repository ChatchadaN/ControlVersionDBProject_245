


-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <6th Dec 2018>
-- Description:	<update Lots for shipped lot>
-- =============================================
CREATE PROCEDURE [etl].[sp_apcs_05_update_lots_for_shipped_parent_lot_bak] (
	@ServerName_APCS NVARCHAR(128) 
    ,@DatabaseName_APCS NVARCHAR(128)
	,@ServerName_APCSPro NVARCHAR(128) 
    ,@DatabaseName_APCSPro NVARCHAR(128)
	,@logtext NVARCHAR(max) output
	,@errnum  int output
	,@errline int output
	,@errmsg nvarchar(max) output
	) AS
BEGIN
/*
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
*/

	---------------------------------------------------------------------------
	--(1) declare
    ---------------------------------------------------------------------------
	DECLARE @pObjAPCS NVARCHAR(128) = N''
	DECLARE @pObjAPCSPro NVARCHAR(128) = N''

	DECLARE @pFunctionName NVARCHAR(128) = N'';
	DECLARE @pStarttime DATETIME;
	DECLARE @pEndTime DATETIME;
	
	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 

	DECLARE @pRowCnt INT = 0;

	DECLARE @pSqlUpdate NVARCHAR(4000) = '';

   ---------------------------------------------------------------------------
	--(2) connect string
    ---------------------------------------------------------------------------
	-- ''=local
	/*
	BEGIN
		IF RTRIM(@ServerName_APCS_) = '' RETURN 1;
	END;
	*/
	BEGIN
		IF RTRIM(@DatabaseName_APCS) = '' RETURN 1;
	END;
	-- ''=local
	/*
	BEGIN
		IF RTRIM(@ServerName_APCSPro_) = '' RETURN 1;
	END;
	*/
	BEGIN
		IF RTRIM(@DatabaseName_APCSPro) = '' RETURN 1;
	END;

	BEGIN
		IF RTRIM(@ServerName_APCS) = '' 
			BEGIN
				SET @pObjAPCS = '[' + @DatabaseName_APCS + ']'
			END;
		ELSE
		BEGIN
			SET @pObjAPCS = '[' + @ServerName_APCS + '].[' + @DatabaseName_APCS + ']'
		END;
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

	---------------------------------------------------------------------------
	--(3) get functionname & time
	---------------------------------------------------------------------------
	BEGIN TRY

		SELECT @pFunctionName = OBJECT_NAME(@@PROCID);
		--yyyy/MM/dd HH:mm:ss.ff3

		PRINT '-----0) Get StartTime & EndTime';
		SET @pStepNo = 0;
		/* v10 change
		SELECT @pStarttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID);
		--set oldest data 
		SET @pStarttime = ISNULL(@pStarttime,convert(datetime,'2018-01-01 00:00:00.000',21));
		PRINT '@pStarttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;

		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(),'yyyy-MM-dd HH:00:00.000'));
		PRINT '@endtime=' + FORMAT(@pEndtime, 'yyyy-MM-dd HH:mm:ss.fff');
		*/

		SELECT @pStarttime = dateadd(minute,(-1)*(DATEPART(n,finished_at) % 10),convert(datetime,format(finished_at,'yyyy-MM-dd HH:mm:00.000'))) FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID);
		--set oldest data 
		SET @pStarttime = ISNULL(@pStarttime,convert(datetime,'2019-08-01 00:00:00.000',21));
		PRINT '@pStarttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;

		SELECT @pEndTime =  dateadd(minute,(-1)*(DATEPART(n,GETDATE()) % 10),convert(datetime,format(GETDATE(),'yyyy-MM-dd HH:mm:00.000')));
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
	--(4) make SQL
    ---------------------------------------------------------------------------

/*
update
	APCSProDB.trans.lots with (ROWLOCK)
set
	wip_state = 100
	,updated_at = l2.REAL_DAY 
	,updated_by = null
from
	APCSProDB.trans.lots 
	inner join APCSDB.dbo.LOT2_TABLE l2 with (NOLOCK) 
		on l2.LOT_NO = lots.lot_no
	inner join APCSProDB.method.device_slips ds with (NOLOCK)
		on ds.device_slip_id = lots.device_slip_id
	inner join APCSProDB.method.device_names dn with (NOLOCK)
		on dn.id = ds.device_id
where
	lots.wip_state = 20
	and l2.STATUS2 = 8
	and dn.is_assy_only not in (0,1)


*/

	SET @pSqlUpdate = N'';
	SET @pSqlUpdate = @pSqlUpdate + N'update ';
	SET @pSqlUpdate = @pSqlUpdate + N'	' + @pObjAPCSPro + N'.[trans].[lots] ';  
	SET @pSqlUpdate = @pSqlUpdate + N'set ';
	SET @pSqlUpdate = @pSqlUpdate + N'	wip_state = 100 ';
	SET @pSqlUpdate = @pSqlUpdate + N'	,ship_at = l2.REAL_DAY ';
	SET @pSqlUpdate = @pSqlUpdate + N'	,ship_date_id = da.id ';
	SET @pSqlUpdate = @pSqlUpdate + N'	,updated_at = l2.REAL_DAY ';
	SET @pSqlUpdate = @pSqlUpdate + N'	,updated_by = null ';
	SET @pSqlUpdate = @pSqlUpdate + N'from ';
	SET @pSqlUpdate = @pSqlUpdate + N'	' + @pObjAPCSPro + N'.[trans].[lots] WITH (ROWLOCK) ';
	SET @pSqlUpdate = @pSqlUpdate + N'  inner join ' + @pObjAPCSPro + N'.[method].[device_names] dn with (NOLOCK) ';
	SET @pSqlUpdate = @pSqlUpdate + N'	on dn.id = lots.act_device_name_id ';
	SET @pSqlUpdate = @pSqlUpdate + N'  inner join ' + @pObjAPCSPro + N'.[method].[packages] p with (NOLOCK) ';
	SET @pSqlUpdate = @pSqlUpdate + N'	on p.id = dn.package_id ';
	SET @pSqlUpdate = @pSqlUpdate + N'	inner join OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + ';UID=dbxuser;'').[' + @DatabaseName_APCS + '].[dbo].[LOT2_TABLE] as l2 ';
	SET @pSqlUpdate = @pSqlUpdate + N'	on l2.LOT_NO = lots.lot_no ';
	SET @pSqlUpdate = @pSqlUpdate + N'	and l2.STATUS2 = 8';
	SET @pSqlUpdate = @pSqlUpdate + N'  inner join ' + @pObjAPCSPro + N'.[trans].[days] da with (NOLOCK) ';
	SET @pSqlUpdate = @pSqlUpdate + N'	on da.date_value = convert(date,l2.REAL_DAY) ';
	SET @pSqlUpdate = @pSqlUpdate + N'where lots.wip_state = 20 ';
	SET @pSqlUpdate = @pSqlUpdate + N'	and dn.is_assy_only in (0,1)';
	SET @pSqlUpdate = @pSqlUpdate + N'	and isnull(p.is_enabled,0) = 0';

	PRINT '----------------------------------------';
	PRINT @pSqlUpdate;
   ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------

 	BEGIN TRY

		BEGIN TRANSACTION;

			PRINT '-----1) update(trans.lots)';
			SET @pStepNo = 1;
			--PRINT (@pSqlupdate);
			EXECUTE (@pSqlupdate);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Update(Shipped lots) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----2) save the process log';
			SET @pStepNo = 2;
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



CREATE PROCEDURE [etl].[sp_etl_2-00_update_wip_state_old] (
	@ServerName_APCSPro NVARCHAR(128) 
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
	DECLARE @pSqlUpdate2 NVARCHAR(4000) = '';


   ---------------------------------------------------------------------------
	--(2) connect string
    ---------------------------------------------------------------------------
	BEGIN
		IF RTRIM(@DatabaseName_APCSPro) = '' RETURN 1;
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
	--(4) make SQL
    ---------------------------------------------------------------------------

/*
update
	APCSProDB.trans.lots with (ROWLOCK)
set
	wip_state = 210
	,updated_at = l2.REAL_DAY 
	,updated_by = null
from
	APCSProDB.trans.lots 
	inner join APCSDB.dbo.LOT2_TABLE l2 with (NOLOCK) 
		on l2.LOT_NO = lots.lot_no
where
	lots.wip_state = 20
	and l2.STATUS2 = 9
*/

	SET @pSqlUpdate = N'';
	SET @pSqlUpdate = @pSqlUpdate + N'update ' + @pObjAPCSPro + N'.trans.lots ';
	SET @pSqlUpdate = @pSqlUpdate + N'	set wip_state = 10 ';
	SET @pSqlUpdate = @pSqlUpdate + N'from apcsprodb.trans.lots as l ';
	SET @pSqlUpdate = @pSqlUpdate + N'	inner join '; 
	SET @pSqlUpdate = @pSqlUpdate + N'		( ';
	SET @pSqlUpdate = @pSqlUpdate + N'			select '; 
	SET @pSqlUpdate = @pSqlUpdate + N'			dy.date_value, ';
	SET @pSqlUpdate = @pSqlUpdate + N'			l2.id as lot_id '; 
	SET @pSqlUpdate = @pSqlUpdate + N'			from ' + @pObjAPCSPro + N'.trans.lots as l2 with (NOLOCK) '; 
	SET @pSqlUpdate = @pSqlUpdate + N'				inner join ' + @pObjAPCSPro + N'.trans.days as dy with (NOLOCK) '; 
	SET @pSqlUpdate = @pSqlUpdate + N'					on dy.id= l2.in_plan_date_id ';
	SET @pSqlUpdate = @pSqlUpdate + N'			where l2.wip_state =0 ';
	SET @pSqlUpdate = @pSqlUpdate + N'				and dateadd(hour,8,convert(datetime,dy.date_value)) < getdate() '; 
	SET @pSqlUpdate = @pSqlUpdate + N'				and l2.step_no < 100 ';
	SET @pSqlUpdate = @pSqlUpdate + N'		) as t1 '; 
	SET @pSqlUpdate = @pSqlUpdate + N'		on t1.lot_id = l.id '; 	

	PRINT '----------------------------------------';
	PRINT @pSqlUpdate;


	SET @pSqlUpdate2 = N'';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'update ' + @pObjAPCSPro + N'.trans.lots ';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'	set wip_state = 20 '; 
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'from ' + @pObjAPCSPro + N'.trans.lots as l ';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'	inner join '; 
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'		( ';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'			select ';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'			dy.date_value, ';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'			l2.id as lot_id '; 
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'			from ' + @pObjAPCSPro + N'.trans.lots as l2 with (NOLOCK) '; 
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'				inner join ' + @pObjAPCSPro + N'.trans.days as dy with (NOLOCK) '; 
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'					on dy.id= l2.in_plan_date_id ';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'			where l2.wip_state =0 ';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'				and dateadd(hour,8,convert(datetime,dy.date_value)) < getdate() ';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'				and step_no >= 100 ';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'		) as t1 ';
	SET @pSqlUpdate2 = @pSqlUpdate2 + N'		on t1.lot_id = l.id '; 	

	PRINT '----------------------------------------';
	PRINT @pSqlUpdate2;


   ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------

 	BEGIN TRY


			PRINT '-----1) update wip_state to 10 ';
			SET @pStepNo = 1;
			--PRINT (@pSqlupdate);
			EXECUTE (@pSqlupdate);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Update wip_state to 10 OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;


			PRINT '-----2) update wip_state to 20 ';
			SET @pStepNo = 2;
			--PRINT (@pSqlupdate);
			EXECUTE (@pSqlupdate2);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Update wip_state to 20 OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;


	
	END TRY

	BEGIN CATCH

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

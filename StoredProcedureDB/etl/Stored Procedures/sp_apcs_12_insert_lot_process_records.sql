


-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <12th Oct 2018>
-- Description:	<LOT1_TABLE to Lots>
-- =============================================
CREATE PROCEDURE [etl].[sp_apcs_12_insert_lot_process_records] (

	@ServerName_APCS NVARCHAR(128) 
    ,@DatabaseName_APCS NVARCHAR(128)
	,@ServerName_APCSPro NVARCHAR(128) 
    ,@DatabaseName_APCSPro NVARCHAR(128)
	,@ServerName_APCSProDWH NVARCHAR(128) 
    ,@DatabaseName_APCSProDWH NVARCHAR(128)
	,@logtext NVARCHAR(max) output
	,@errnum  INT output
	,@errline int output
	,@errmsg nvarchar(max) output
	) AS
BEGIN

	---------------------------------------------------------------------------
	--(1) declare
    ---------------------------------------------------------------------------
	DECLARE @pObjAPCS NVARCHAR(128) = N''
	DECLARE @pObjAPCSPro NVARCHAR(128) = N''
	DECLARE @pObjAPCSProDWH NVARCHAR(128) = N''

	DECLARE @pFunctionName NVARCHAR(128) = N'';
	DECLARE @pStarttime DATETIME;
	DECLARE @pEndTime DATETIME;
	
	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 

	DECLARE @pSqlTrunc NVARCHAR(4000) = N'';
	
	-- for dwh.temp_lot_process_records
	DECLARE @pSqlInsToTmp NVARCHAR(4000) = N'';
	-- for trans.lot_process_records
	DECLARE @pSqlInsToTrans NVARCHAR(4000) = N'';
	
	DECLARE @pSqlInsCommon NVARCHAR(4000) = N'';
	-- for dwh.temp_lot_process_records : @pSqlInsCommon + @pSqlInsTmp
	DECLARE @pSqlInsTmp NVARCHAR(4000) = N''; 
	-- for trans.lot_process_records : @pSqlInsCommon + @@pSqlInsTrans
	DECLARE @pSqlInsTrans NVARCHAR(4000) = N'';

	DECLARE @pSqlSelTmp1 NVARCHAR(4000) = N'';-- for dwh.temp_lot_process_records
	DECLARE @pSqlSelTmp2 NVARCHAR(4000) = N'';-- for dwh.temp_lot_process_records

	DECLARE @pSqlRowCnt NVARCHAR(4000) = N'';

	DECLARE @pSqlSelTrans NVARCHAR(4000) = N'';

	DECLARE @pRowCnt INT = 0;
	DECLARE @pIdBefore INT=0;
	DECLARE @pIdAfter INT=0;

	-- for update lots
	DECLARE @pID INT = 0;
	DECLARE @pLotID INT = 0;
	DECLARE @pStepNum INT = 0; 
	DECLARE @pProcessId INT = 0; 
	DECLARE @pJobId INT = 0; 
	DECLARE @pQtyPass INT = 0;
	DECLARE @pQtyFail INT = 0;
	DECLARE @pQtyLastPass INT = 0;
	DECLARE @pQtyLastFail INT = 0;
	DECLARE @pQtyPassStepSum INT = 0;
	DECLARE @pQtyFailStepSum INT = 0;
	DECLARE @pRecordClass TINYINT = 0;
	DECLARE @pProcessState TINYINT = 0;
	DECLARE @pDayId INT = 0;
	DECLARE @pRecordedAt DATETIME ;
	DECLARE @pMachineId INT = 0;
	DECLARE @pIsLastStepNo INT = 0; --2018-Nov-13 add

	DECLARE @pSqlSelect NVARCHAR(4000) = '';
	DECLARE @pSqlUpdate NVARCHAR(4000) = '';
	DECLARE @pCurCnt INT = 0;

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
	-- ''=local
	/*
	BEGIN
		IF RTRIM(@ServerName_APCSProDWH_) = '' RETURN 1;
	END;
	*/
	BEGIN
		IF RTRIM(@DatabaseName_APCSProDWH) = '' RETURN 1;
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
	--(3) get functionname & time
	---------------------------------------------------------------------------
	BEGIN TRY

		SELECT @pFunctionName = OBJECT_NAME(@@PROCID);
		--yyyy/MM/dd HH:mm:ss.ff3

		PRINT '-----0) Get StartTime & EndTime';
		SET @pStepNo = 0;
		--12-08 edit
		--SELECT @pStarttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID);
		SELECT @pStarttime = finished_at FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID);
		--set oldest data 
		SET @pStarttime = ISNULL(@pStarttime,convert(datetime,'2018-01-01 00:00:00.000',21));
		--2019-02-14 ADD
		-- It corresponds to the time lag of each cellcon PC : -60  
		SET @pStarttime = dateadd(minute,-60,CONVERT(DATETIME , FORMAT(@pStarttime,'yyyy-MM-dd HH:mm:00.000')));
		
		PRINT '@pStarttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;

		--SELECT @pEndTime = dateadd(m,-1,CONVERT(DATETIME , FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:00.000')));
		
		--2019-02-14 edit
		--SELECT @pEndTime = dateadd(minute,-1,CONVERT(DATETIME , FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:00.000')));
		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:00.000'));
		
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


	BEGIN TRY

		PRINT '-----4) Check row counts';
		SET @pStepNo = 4;

		if @pRowCnt = 0

			BEGIN
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

				-- rowcnt=0 then exit
			
				SET @logtext = @pfunctionname ;
				SET @logtext = @logtext + N' has no additional lot record data(' ;
				SET @logtext = @logtext + convert(varchar,@pEndTime,21);
				SET @logtext = @logtext + N')';
				PRINT 'logtext=' + @logtext;
				RETURN 0;

			END;


	END TRY

	BEGIN CATCH

		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @pFunctionName;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/count:'
		SET @logtext = @logtext + convert(varchar,@pRowCnt);
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


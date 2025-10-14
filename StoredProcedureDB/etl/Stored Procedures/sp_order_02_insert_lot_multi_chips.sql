




-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <18th Mar 2019>
-- Description:	<Insert trans.lot_multi_chips>
-- =============================================
CREATE PROCEDURE [etl].[sp_order_02_insert_lot_multi_chips] (
	--@ServerName_APCS NVARCHAR(128) 
    --,@DatabaseName_APCS NVARCHAR(128)
	--,
	@ServerName_APCSPro NVARCHAR(128) 
    ,@DatabaseName_APCSPro NVARCHAR(128)
	--,@ServerName_APCSProDWH NVARCHAR(128) 
    --,@DatabaseName_APCSProDWH NVARCHAR(128)
	,@logtext NVARCHAR(max) output
	,@errnum  int output
	,@errline int output
	,@errmsg nvarchar(max) output
	) AS
BEGIN

    ---------------------------------------------------------------------------
	--(1) declare
    ---------------------------------------------------------------------------
	--DECLARE @pObjAPCS NVARCHAR(128) = N''
	DECLARE @pObjAPCSPro NVARCHAR(128) = N''
	--DECLARE @pObjAPCSProDWH NVARCHAR(128) = N''

	DECLARE @pFunctionName NVARCHAR(128) = N'';
	DECLARE @pStarttime DATETIME;
	DECLARE @pEndTime DATETIME;
	DECLARE @pInputTime varchar(max);

	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 

	DECLARE @pSqlTrunc NVARCHAR(4000) = N'';

	--DECLARE @pSqlInsHeaderTemp NVARCHAR(4000) = N'';
	DECLARE @pSqlInsHeader NVARCHAR(4000) = N'';
	DECLARE @pSqlInsBody NVARCHAR(4000) = N'';

	DECLARE @pSqlRowCnt NVARCHAR(4000) = N'';

	DECLARE @pRowCnt INT = 0;
	DECLARE @pIdBefore INT=0;
	DECLARE @pIdAfter INT=0;
   ---------------------------------------------------------------------------
	--(2) connection string
    ---------------------------------------------------------------------------
	-- ''=local
	/*
	BEGIN
		IF RTRIM(@DatabaseName_APCS) = '' RETURN 1;
	END;
	*/
	-- ''=local
	BEGIN
		IF RTRIM(@DatabaseName_APCSPro) = '' RETURN 1;
	END;
	-- ''=local
	/*
	BEGIN
		IF RTRIM(@DatabaseName_APCSProDWH) = '' RETURN 1;
	END;
	*/
	/*
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
	*/

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
	/*
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
	*/
	---------------------------------------------------------------------------
	--(3) get functionname & time
    ---------------------------------------------------------------------------
	BEGIN TRY
		SELECT @pFunctionName = OBJECT_NAME(@@PROCID);
		SELECT @pStarttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		PRINT '@starttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;
		--yyyy/MM/dd HH:mm:ss.ff3
		SELECT @pInputTime = FORMAT(dateadd(hour,-1,GETDATE()), 'yyyy-MM-dd HH:00:00.000');
		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'));
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
	--(4)make SQL
    ---------------------------------------------------------------------------
-- insert into lot_multi_chips  
	BEGIN

		SET @pSqlInsHeader = N'';
		SET @pSqlInsHeader = @pSqlInsHeader + N'insert into ' + @pObjAPCSPro + N'.[trans].[lot_multi_chips] ';
		SET @pSqlInsHeader = @pSqlInsHeader + N'( ';
		SET @pSqlInsHeader = @pSqlInsHeader + N'lot_id ';
		SET @pSqlInsHeader = @pSqlInsHeader + N',child_lot_id ';
		SET @pSqlInsHeader = @pSqlInsHeader + N',job_id ';
		SET @pSqlInsHeader = @pSqlInsHeader + N',created_at ';
		SET @pSqlInsHeader = @pSqlInsHeader + N') ';
	END; 

	/* raw strings

select
	--t2.*
	--,
	--ROW_NUMBER() over(order by order_id,lot_order,is_assy_only) as id
	--,
	parent_lot_id as lot_id
	,lot_id as child_lot_id
	,null as job_id
	,null as created_at
from
	(
	select
		t1.*
		,FIRST_VALUE(t1.lot_id) over (partition by order_id,lot_order order by order_id,lot_order,is_assy_only) as parent_lot_id 
	from
		(
		select 
			lot.id lot_id
			,lot_no
			,act_device_name_id		
			,qty_in		
			,order_id	
			,d.is_assy_only	
		  ,rank() over (partition by order_id,act_device_name_id order by lot_no) as lot_order	
		  ,max(is_assy_only) over (partition by order_id) as child_check
		  ,ml1.id multi_record_id
		  ,ml2.id multi_record_id2
		from 
			[APCSProDB].[trans].[lots] as lot
			inner join  [APCSProDB].[method].[device_names] as d 	
				on d.id = lot.act_device_name_id
			left outer join [APCSProDB].[trans].[lot_multi_chips] as ml1
				on ml1.lot_id = lot.id 
			left outer join [APCSProDB].[trans].[lot_multi_chips] as ml2
				on ml2.lot_id = lot.id 
		where 
			d.is_assy_only < 10
			and order_id > 0
			--order by order_id,is_assy_only,lot_no
			and ml1.id is null
			and ml2.id is null
		) t1
	where 
		t1.child_check not in (0,1)
	--order by 
	--	order_id,lot_order,is_assy_only
	) t2
 where lot_id <> parent_lot_id
 order by t2.parent_lot_id,t2.lot_id
	*/

	BEGIN
		SET @pSqlInsBody = N'';
		SET @pSqlInsBody = @pSqlInsBody + N' select ';
--		SET @pSqlInsBody = @pSqlInsBody + N'	t2.* ';
--		SET @pSqlInsBody = @pSqlInsBody + N'	, ';
--		SET @pSqlInsBody = @pSqlInsBody + N'	ROW_NUMBER() over(order by order_id,lot_order,is_assy_only) as id ';
--		SET @pSqlInsBody = @pSqlInsBody + N'	, ';
		SET @pSqlInsBody = @pSqlInsBody + N'	parent_lot_id as lot_id ';
		SET @pSqlInsBody = @pSqlInsBody + N'	,lot_id as child_lot_id ';
		SET @pSqlInsBody = @pSqlInsBody + N'	,null as job_id ';
		SET @pSqlInsBody = @pSqlInsBody + N'	,null as created_at ';
		SET @pSqlInsBody = @pSqlInsBody + N' from ';
		SET @pSqlInsBody = @pSqlInsBody + N'	( ';
		SET @pSqlInsBody = @pSqlInsBody + N'		select ';
		SET @pSqlInsBody = @pSqlInsBody + N'			t1.* ';
		SET @pSqlInsBody = @pSqlInsBody + N'			,FIRST_VALUE(t1.lot_id) over (partition by order_id,lot_order order by order_id,lot_order,is_assy_only) as parent_lot_id ';
		SET @pSqlInsBody = @pSqlInsBody + N'		from ';
		SET @pSqlInsBody = @pSqlInsBody + N'			( ';
		SET @pSqlInsBody = @pSqlInsBody + N'				select ';
		SET @pSqlInsBody = @pSqlInsBody + N'					lots.id as lot_id';
		SET @pSqlInsBody = @pSqlInsBody + N'					,lots.lot_no ';
		SET @pSqlInsBody = @pSqlInsBody + N'					,lots.act_device_name_id ';
		SET @pSqlInsBody = @pSqlInsBody + N'					,lots.qty_in ';
		SET @pSqlInsBody = @pSqlInsBody + N'					,lots.order_id ';
		SET @pSqlInsBody = @pSqlInsBody + N'					,dn.is_assy_only ';
		SET @pSqlInsBody = @pSqlInsBody + N'					,rank() over (partition by order_id,act_device_name_id order by lot_no) as lot_order ';
		SET @pSqlInsBody = @pSqlInsBody + N'					,max(is_assy_only) over (partition by order_id) as child_check ';
		SET @pSqlInsBody = @pSqlInsBody + N'					,ml1.id multi_record_id ';
		SET @pSqlInsBody = @pSqlInsBody + N'					,ml2.id multi_record_id2 ';
		SET @pSqlInsBody = @pSqlInsBody + N'				from ';
		SET @pSqlInsBody = @pSqlInsBody + N'					' + @pObjAPCSPro + N'.[trans].[lots] lots with (NOLOCK) ';
		SET @pSqlInsBody = @pSqlInsBody + N'						inner join ' + @pObjAPCSPro + N'.[method].[device_names] dn with (NOLOCK) ';
		SET @pSqlInsBody = @pSqlInsBody + N'							on dn.id = lots.act_device_name_id ';
		SET @pSqlInsBody = @pSqlInsBody + N'						left outer join ' + @pObjAPCSPro + N'.[trans].[lot_multi_chips] ml1 with (NOLOCK) ';
		SET @pSqlInsBody = @pSqlInsBody + N'							on ml1.lot_id = lots.id ';
		SET @pSqlInsBody = @pSqlInsBody + N'						left outer join ' + @pObjAPCSPro + N'.[trans].[lot_multi_chips] ml2 with (NOLOCK) ';
		SET @pSqlInsBody = @pSqlInsBody + N'							on ml2.child_lot_id = lots.id ';
		SET @pSqlInsBody = @pSqlInsBody + N'				where ';
		SET @pSqlInsBody = @pSqlInsBody + N'					lots.wip_state <= 20 ';
		SET @pSqlInsBody = @pSqlInsBody + N'					and dn.is_assy_only < 10 ';
		SET @pSqlInsBody = @pSqlInsBody + N'					and order_id > 0 ';
		SET @pSqlInsBody = @pSqlInsBody + N'					and ml2.id is null ';
		SET @pSqlInsBody = @pSqlInsBody + N'					and not exists (select * from ' + @pObjAPCSPro + N'.[trans].[lot_multi_chips] ml3 with (NOLOCK) where ml3.lot_id = lots.id) ';
		--SET @pSqlInsBody = @pSqlInsBody + N'				order by order_id,is_assy_only,lot_no ';
		SET @pSqlInsBody = @pSqlInsBody + N'			) as t1 ';
		SET @pSqlInsBody = @pSqlInsBody + N'		where ';
		SET @pSqlInsBody = @pSqlInsBody + N'			t1.child_check not in (0,1) ';
		--SET @pSqlInsBody = @pSqlInsBody + N'		order by ';
		--SET @pSqlInsBody = @pSqlInsBody + N'			order_id,lot_order,is_assy_only ';
		SET @pSqlInsBody = @pSqlInsBody + N'	) as t2 ';
		SET @pSqlInsBody = @pSqlInsBody + N' where ';
		SET @pSqlInsBody = @pSqlInsBody + N'	lot_id <> parent_lot_id ';
		SET @pSqlInsBody = @pSqlInsBody + N' order by ';
		SET @pSqlInsBody = @pSqlInsBody + N'	t2.parent_lot_id, t2.lot_id ';

	END;

   ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------

	BEGIN TRY

		BEGIN TRANSACTION

			PRINT '-----1) trans.lot_multi_chips';
			SET @pStepNo = 1;
			PRINT '@pSqlInsHeader=' + @pSqlInsHeader;
			PRINT '@pSqlInsBody=' + @pSqlInsBody;
			EXECUTE (@pSqlInsHeader + @pSqlInsBody );
			SET @pRowCnt = @@ROWCOUNT;

			PRINT 'Count=' + convert(varchar,@pRowCnt);
			SET @logtext = 'Insert(lot_multi_chips) OK : row=';
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----2) save the process log'
			SET @pStepNo = 2;
			EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName
															, @to_fact_table_ = '', @finished_at_=@pEndTime
															, @errnum = @errnum OUTPUT,@errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;
			IF @pRet<>0
				BEGIN
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
					return -1;

				END;

			if @pRowCnt = 0
				BEGIN
					SET @logtext = @pfunctionname ;
					SET @logtext = @logtext + N' has no additional multichip data(' ;
					SET @logtext = @logtext + convert(varchar,@pEndTime,21);
					SET @logtext = @logtext + N')';
					PRINT 'logtext=' + @logtext;
				END;

		COMMIT TRANSACTION;
	
	END TRY
		
	BEGIN CATCH

		IF @@TRANCOUNT <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END;

		select @errMsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@ErrLine = ERROR_LINE()

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


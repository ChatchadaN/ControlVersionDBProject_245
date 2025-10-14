

Create PROCEDURE [etl].[sp_etlsblsyl_issblsyl_v1] 

AS
BEGIN
    ---------------------------------------------------------------------------
	--(1) Declare
    ---------------------------------------------------------------------------
	DECLARE @logtext nvarchar(max);
	DECLARE @errnum  INT ;
	DECLARE @errline INT ;
	DECLARE @errmsg nvarchar(max);

	DECLARE @ret INT = 0;
	DECLARE @sqlCommon NVARCHAR(max) = '';
	DECLARE @sql NVARCHAR(max) = '';
	DECLARE @rowcnt INT = 0;
	declare @dt datetime ;
	select @dt = GETDATE();


    ---------------------------------------------------------------------------
	--(4)SQL make
    ---------------------------------------------------------------------------
/* SQL1:insert history */
BEGIN TRY
		/**********    part:1  *********/
		--select @partno = 1;

		/* データ確認用スクリプト １*/
		--select 
		--	p.name as package
		--	,d.id as device_name_id
		--	,rtrim(d.name) as device_name
		--	,rtrim(d.assy_name) as assy_name
		--	,v.device_id
		--	,v.device_type
		--	,s.device_slip_id 
		--	,s.version_num
		--	,s.is_sblsyl_approved
		--	,s.is_released
		--	,j.name as job
		--	,f.is_sblsyl
		--	,(select count(*) from trans.lots as l with (NOLOCK) where l.device_slip_id = s.device_slip_id) as lot_cnt
		--	,(select count(*) from trans.lots as l with (NOLOCK) where l.device_slip_id = s.device_slip_id and l.wip_state <=20) as active_lot_cnt
		--from APCSProDB.method.device_flows as f with (NOLOCK)
		--	inner join method.jobs as j with (NOLOCK)
		--		on j.id = f.job_id 
		--	inner join method.device_slips as s with (NOLOCK)
		--		 on s.device_slip_id = f.device_slip_id 
		--	inner join method.device_versions as v with (NOLOCK)	
		--		on v.device_id = s.device_id 
		--	inner join method.device_names as d  with (NOLOCK)
		--		on d.id = v.device_name_id
		--	inner join method.packages as p with (NOLOCK) 
		--		on p.id = d.package_id
		--where j.name like '%SBLSYL%'
		--	and isnull(f.is_sblsyl,0) = 0 
		--	and not exists (select * from method.device_slips as s2 with (NOLOCK) where s2.device_id = s.device_id and s2.is_released in(1,2) and s2.version_num > s.version_num)
		--	and s.is_released in(1,2)
		--order by d.name,s.device_slip_id

		/* データ確認用スクリプト ２*/
		--select 
		--	s.device_slip_id 
		--	,s.version_num
		--	,s.is_sblsyl_approved
		--from APCSProDB.method.device_slips as s 
		--where isnull(s.is_sblsyl_approved,0) <> 10 
		--	and not exists (select * from method.device_slips as s2 with (NOLOCK) 
		--					where s2.device_id =s.device_id and s2.is_released in(1,2) and s2.version_num > s.version_num)
		--	and exists (select * from APCSProDB.method.device_slips as s3 with (NOLOCK) 
		--						inner join APCSProDB.method.device_flows as f3 with (NOLOCK) 
		--							on f3.device_slip_id = s3.device_slip_id and f3.is_sblsyl = 1
		--				where s3.device_slip_id = s.device_slip_id)
		--	and exists (select * from APCSProDB.method.device_slips as s4 with (NOLOCK) 
		--						inner join APCSProDB.method.device_flows as f4 with (NOLOCK) 
		--							on f4.device_slip_id = s4.device_slip_id and f4.is_sblsyl = 1
		--						left outer join APCSProDB.method.device_flows_sblsyl as sbl4 with (NOLOCK) 
		--							on sbl4.device_flow_id = f4.id 
		--				where s4.device_slip_id = s.device_slip_id and sbl4.device_flow_id is null)


		/*　更新用スクリプト １*/
		update APCSProdb.method.device_flows 
		set 
			is_sblsyl = 1 
		from APCSProDB.method.device_flows as f with (NOLOCK)
			inner join APCSProDB.method.jobs as j with (NOLOCK)
				on j.id = f.job_id 
			inner join APCSProDB.method.device_slips as s with (NOLOCK)
				 on s.device_slip_id = f.device_slip_id 
			inner join APCSProDB.method.device_versions as v with (NOLOCK)	
				on v.device_id = s.device_id 
			inner join APCSProDB.method.device_names as d  with (NOLOCK)
				on d.id = v.device_name_id
			inner join APCSProDB.method.packages as p with (NOLOCK) 
				on p.id = d.package_id
		where j.name like '%SBLSYL%'
			and isnull(f.is_sblsyl,0) = 0 
			and not exists (select * from APCSProDB.method.device_slips as s2 with (NOLOCK) where s2.device_id = s.device_id and s2.is_released in(1,2) and s2.version_num > s.version_num)
			and s.is_released in(2)



		set @rowcnt = @@ROWCOUNT;
		set @logtext = 'update APCSProdb.method.device_flows.is_sblsyl :[OK] row:' + convert(varchar,@rowcnt);
		print '---- ' + @logtext + ' ---' ;
		
		print '---- 2 ---' ;

		/*　更新用スクリプト ２*/
		update APCSProDB.method.device_slips
		  set is_sblsyl_approved = 10 
		from APCSProDB.method.device_slips as s 
		where isnull(s.is_sblsyl_approved,0) <> 10 
			and not exists (select * from APCSProDB.method.device_slips as s2 with (NOLOCK) 
							where s2.device_id =s.device_id and s2.is_released in(1,2) and s2.version_num > s.version_num)
			and exists (select * from APCSProDB.method.device_slips as s3 with (NOLOCK) 
								inner join APCSProDB.method.device_flows as f3 with (NOLOCK) 
									on f3.device_slip_id = s3.device_slip_id and f3.is_sblsyl = 1
						where s3.device_slip_id = s.device_slip_id)
			and exists (select * from APCSProDB.method.device_slips as s4 with (NOLOCK) 
								inner join APCSProDB.method.device_flows as f4 with (NOLOCK) 
									on f4.device_slip_id = s4.device_slip_id and f4.is_sblsyl = 1
								left outer join APCSProDB.method.device_flows_sblsyl as sbl4 with (NOLOCK) 
									on sbl4.device_flow_id = f4.id 
						where s4.device_slip_id = s.device_slip_id and sbl4.device_flow_id is null)


		set @rowcnt = @@ROWCOUNT;
		set @logtext = 'update APCSProDB.method.device_slips  :[OK] row:' + convert(varchar,@rowcnt);
		print @logtext;


	END TRY

	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = '[ERROR] sp_etlsblsyl_issblsyl' +'/ret:' + convert(varchar,@ret)  + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg;
		PRINT @logtext;
		RETURN -1;
	END CATCH;

	RETURN 0;

END ;




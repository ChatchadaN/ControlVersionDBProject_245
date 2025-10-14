-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_scheduler_get_operation_result]
	-- Add the parameters for the stored procedure here
	--@fromdate1 varchar(20),
	--@packageid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select 
	t1.lot_no+':'+t1.job as 作業コード,
	case when re.recorded_at is null then 'MS' else 'MF' end as ステータス,
	format(t1.recorded_at,'yyyy-MM-dd HH:mm:ss') as 製造開始日時,
	convert(varchar,isnull(format(re.recorded_at,'yyyy-MM-dd HH:mm:ss'),'')) as 製造終了日時
from 
(
	select 
		l.id as lot_id,
		rtrim(l.lot_no) as lot_no,
		rtrim(p.name) as package,
		rtrim(d.name) as device,
		r.record_class,
		r.job_id
		,j.name as job
		,r.recorded_at
	from apcsprodb.trans.lots as l with (NOLOCK) 
		inner join [APCSProDB].[trans].[lot_process_records] as r with (NOLOCK) 
			on r.lot_id = l.id 
				and r.record_class in(1)
		inner join apcsprodb.method.device_names as d with (NOLOCK) 
			on d.id = l.act_device_name_id
				and d.is_assy_only in(0,1)
		inner join APCSProDB.method.packages as p with (NOLOCK)
			on p.id = l.act_package_id
		inner join APCSProDB.method.jobs as j with (NOLOCK)
			on j.id = r.job_id
	where j.name like 'AUTO(%'
		and l.act_package_id in(242)
		and r.recorded_at > dateadd(day,-1,getdate())
) as t1 
	left outer join APCSProDB.trans.lot_process_records as re with (NOLOCK) 
		on re.lot_id = t1.lot_id 
			and re.recorded_at > t1.recorded_at 
			and re.record_class IN(2) 
			and re.job_id = t1.job_id 
			and not exists (select * from APCSProDB.trans.lot_process_records as r2 with (NOLOCK) 
							where r2.record_class = re.record_class and r2.lot_id = re.lot_id and r2.job_id = re.job_id 
								and r2.recorded_at > t1.recorded_at and  r2.recorded_at < re.recorded_at)
order by t1.recorded_at,t1.lot_no
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_scheduler_get_wip]
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
		rtrim(l.lot_no) as オーダーコード,
		rtrim(p.name) as パッケージ,
		rtrim(d.name) as 品目,
		l.qty_pass as 数量,
		dy.date_value as 製造納期,
		100-isnull(l.priority,50) as 優先度
	from [APCSProDB].[trans].[lots] as l with (NOLOCK) 
		inner join APCSProDB.trans.days as dy with (NOLOCK) 
			on dy.id = l.out_plan_date_id 
		inner join apcsprodb.method.device_names as d with (NOLOCK) 
			on d.id = l.act_device_name_id
				and d.is_assy_only in(0,1)
		inner join APCSProDB.method.packages as p with (NOLOCK)
			on p.id = l.act_package_id
		inner join APCSProDB.method.device_flows as f with (NOLOCK)
			on f.device_slip_id = l.device_slip_id 
				and f.step_no = l.step_no
		inner join APCSProDB.method.jobs as j with (NOLOCK)
			on j.id = f.job_id
	where l.wip_state = 20 and j.name = 'AUTO(1)'
		and l.act_package_id in(242)
	order by l.lot_no

END

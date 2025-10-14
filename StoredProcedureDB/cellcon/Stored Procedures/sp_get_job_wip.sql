-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_job_wip]
	-- Add the parameters for the stored procedure here
	@job_name VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		-- Insert statements for procedure here
		SELECT [APCSProDB].[mc].[machines].[name] AS mc_no
		, [APCSProDB].[trans].[lots].lot_no
		, [APCSProDB].[method].device_names.name AS device_name 
		, [APCSProDB] .[method].device_names.ft_name AS ft_device
		, [APCSProDB].[method].[packages].name AS package_name
		, job.[name] as job_name
		, '' as next_job
		, [APCSProDB].[trans] .lots.qty_in  AS kpcs 
		, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		,item_lots_process_state.label_eng AS [state]
		, device_flows.process_minutes as standard_time
		, lots.act_job_id as job_id 
		, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
		, lots.quality_state
		, locations.[address]
		, locations.[name]
		,'0' as is_special_flow
		FROM [APCSProDB].[trans].lots with (NOLOCK)
		INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = job.id 
		INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNER JOIN [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		LEFT JOIN [APCSProDB].trans.item_labels AS item_lots_process_state ON item_lots_process_state.[name] = 'lots.process_state' AND item_lots_process_state.val = lots.process_state
		--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no  
		left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
		where lots.wip_state = 20   and  job.[name] = @job_name   and is_special_flow = 0  and lots.process_state in ('0','100')
		union all
		-- Retest
		SELECT [APCSProDB].[mc].[machines].name AS mc_no
		  , [APCSProDB].[trans].[lots].lot_no
		  , [APCSProDB].[method].device_names.name AS device_name 
		  , [APCSProDB].[method].device_names.ft_name AS ft_device
		  , [APCSProDB].[method].[packages].name AS package_name
		  ,job.[name] as job_name-- REPLACE(REPLACE(job.name,'(',''),')','') AS job_name
		  , lots.act_job_id as next_job
		  , [APCSProDB].[trans] .lots.qty_in  AS kpcs 
		  , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		  , item_lots_process_state.label_eng AS [state]
		  , device_flows.process_minutes as standard_time
		  , lotspecial.job_id as job_id 
		  , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
		  , lots.quality_state
		  , locations.[address]
		  , locations.[name]
      	  ,'1' as is_special_flow
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
		INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
		inner join APCSProDB.trans.special_flows as special with (NOLOCK) on lots.special_flow_id = special.id
		inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
		INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
		INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		INNER JOIN [APCSProDB].trans.item_labels AS item_lots_process_state ON item_lots_process_state.[name] = 'lots.process_state' AND item_lots_process_state.val = special.process_state
		--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no 
		left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
		where lots.wip_state = 20   and job.[name] = @job_name  and lots.is_special_flow = 1 and special.process_state in ('0','100')
END

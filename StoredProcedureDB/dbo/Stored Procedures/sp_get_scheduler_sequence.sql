-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_sequence]
	-- Add the parameters for the stored procedure here
	@machine_no int
AS
BEGIN
-- Insert statements for procedure here
	declare @priority int
	,@mc_no varchar(20)
	,@sequence_result int
	,@device_scheduler_set varchar(30)
	,@device_scheduler_now varchar(30)
	,@device_ft_set varchar(30)
	,@flow_ft_set varchar(20)
	,@date_device_set datetime
	,@flowafter varchar(10)
	  select @sequence_result = scheduler.[sequence] - 
	  (SELECT COUNT(*) FROM [APCSProDB].[trans].[lot_process_records] as lot_pr 
	  --inner join APCSProDB.mc.machines as mc on mc.id = lot_pr.machine_id 
	  where record_class = 2 
	  and recorded_at >= scheduler.date_change and lot_pr.machine_id = @machine_no ) 
	  ,@priority = scheduler.[priority]
	  ,@mc_no = scheduler.mc_no
	  ,@device_scheduler_set = scheduler.device_change
	  ,@device_scheduler_now = scheduler.device_now
	  ,@device_ft_set = ft_set.DeviceName
	  ,@flow_ft_set = ft_set.TestFlow
	  ,@date_device_set = scheduler.date_change
	  ,@flowafter =scheduler.flow_after
	  from DBx.dbo.scheduler_setup as scheduler 
	  inner join DBx.dbo.FTSetupReport as ft_set on ft_set.MCNo = scheduler.mc_no
	  where scheduler.[date_complete] is null and scheduler.mc_id = @machine_no

  
		if(@device_ft_set = @device_scheduler_set and @flow_ft_set = @flowafter or (@device_ft_set != @device_scheduler_now and @device_ft_set != @device_scheduler_set))
			begin
				UPDATE DBx.dbo.scheduler_setup 
				SET [date_complete] = GETDATE()
				WHERE mc_no = @mc_no and date_complete is null
				--select * from (select null as [sequence],null as mc_no,null as [priority],null as device_set,null as device_now , @date_device_set as device_set_date) as table1 where table1.device_now is not null	
			end
		else if (@sequence_result < 2)
			begin
		 set @sequence_result = 2
				select @sequence_result as [sequence],@mc_no as mc_no,@priority as [priority],@device_scheduler_set as device_set,@device_scheduler_now as device_now,@date_device_set as device_set_date,@flowafter as flow_after
			end
		else
			begin
				select * from (select @sequence_result as [sequence],@mc_no as mc_no,@priority as [priority],@device_scheduler_set as device_set,@device_scheduler_now as device_now,@date_device_set as device_set_date,@flowafter as flow_after) as table1 where table1.device_now is not null				
			end
  

		
END

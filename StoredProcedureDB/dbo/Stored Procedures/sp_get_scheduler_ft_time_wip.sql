-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_ft_time_wip]
	---- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Thai_CI_AS
    

	--select endtime.FORM_NAME_1 as PKG,lot.id,lot.lot_no,device.name as DeviceName, mc.name as McName, lot.process_state,max(lot_record.recorded_at) as update_time , endtime.AREA_TIME_RESRV_A1 as timeAuto1,
	--endtime.AREA_TIME_RESRV_A2 as timeAuto2 ,endtime.AREA_TIME_RESRV_A3 as timeAuto3,'A4 6.0'  as timeAuto4 ,lot.act_job_id as job_Id from  [APCSProDB].trans.lot_process_records as lot_record
 -- inner join [APCSProDB].[trans].lots as lot on lot.id = lot_record.lot_id
 -- inner join [APCSProDB].[mc].[machines] as mc on mc.id = lot.machine_id
 -- inner join [APCSProDB] .[method].device_names as device on lot.act_device_name_id = device.id 
 -- inner join [APCSDB] .[dbo].LCQW_UNION_WORK_DENPYO_PRINT as endtime on lot.lot_no  = endtime.LOT_NO_1
 -- inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = device.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
 -- where lot.act_job_id  in (106,108,110,119)  and lot.wip_state= 20 and endtime.FORM_NAME_1 = 'ssop-b20W'
 -- group by endtime.FORM_NAME_1,lot.lot_no,lot.process_state,mc.name,lot.id,device.name,endtime.AREA_TIME_RESRV_A1,endtime.AREA_TIME_RESRV_A2,endtime.AREA_TIME_RESRV_A3,endtime.AREA_TIME_RESRV_NS,lot.act_job_id
 -- order by lot_no
	
END

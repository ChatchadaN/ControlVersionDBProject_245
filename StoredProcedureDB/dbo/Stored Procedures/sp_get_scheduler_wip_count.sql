-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_wip_count] 
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
	@MC_Name VARCHAR(30) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT  MC.id as McId,MC.name as McName,MAX( [recorded_at] ) as  McStop
	, (SELECT TOP (1)  bm.TimeFinish 
	from DBx.dbo.BMMaintenance as BM with (NOLOCK)
	where Bm.MachineID = MC.name
	order by Bm.id DESC) as BMTimeFinish
	,(SELECT TOP (1) [date_complete]
  FROM [DBx].[dbo].[scheduler_setup] with (NOLOCK)
  where mc_no = MC.name
  order by date_complete DESC) as TCTimeFinish
	FROM [APCSProDB].[trans].[lot_process_records] as Lotrecord with (NOLOCK)
	inner join APCSProDB.mc.machines as MC with (NOLOCK) on MC.id = Lotrecord.machine_id
	inner join APCSProDB.trans.lots as Lot with (NOLOCK) on Lot.id = Lotrecord.lot_id
	WHERE  job_id in (106,108,110,119,231,236,289) and record_class = 2 
	and MC.name like @MC_Name
	GROUP BY MC.name,MC.id
END

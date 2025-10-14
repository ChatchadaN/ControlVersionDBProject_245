-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_test_tor]
	-- Add the parameters for the stored procedure here
	
	@MC_Name varchar(30) 
AS
BEGIN

	IF((SELECT SUBSTRING(@MC_Name, 1, 2)) = 'FT')
	BEGIN
		SELECT  MC.id as McId,MC.name as McName,MAX( Lotrecord.[recorded_at] ) as  McStop ,MAX( TC.date_complete) as TCTimeFinish 
	
		FROM [APCSProDB].[trans].[lot_process_records] as Lotrecord WITH (NOLOCK)
		inner join APCSProDB.mc.machines as MC  on MC.id = Lotrecord.machine_id and recorded_at > dateadd(day, -3, getdate())
		inner join DBx.dbo.scheduler_setup as TC on TC.mc_id = MC.id and TC.date_change > dateadd(day, -3, getdate())
		WHERE  Lotrecord.job_id in (119,110,108,106,87,88,278,263,359,361,362,363,364,120,329,385,378,263,155) and Lotrecord. record_class = 2  
		and MC.name = @MC_Name and Lotrecord.day_id > 2500
		GROUP BY MC.name,MC.id
	END
	ELSE IF((SELECT SUBSTRING(@MC_Name, 1, 2)) = 'TP')
	BEGIN
		SELECT  MC.id as McId,MC.name as McName,MAX( Lotrecord.[recorded_at] ) as  McStop ,null as TCTimeFinish 
	
		FROM [APCSProDB].[trans].[lot_process_records] as Lotrecord WITH (NOLOCK)
		inner join APCSProDB.mc.machines as MC  on MC.id = Lotrecord.machine_id and recorded_at > dateadd(day, -3, getdate())
		--inner join DBx.dbo.scheduler_setup as TC on TC.mc_id = MC.id
		WHERE  Lotrecord.job_id in (222,231,236,289,397,401) and Lotrecord. record_class = 2 
		and MC.name = @MC_Name and Lotrecord.day_id > 2500
		GROUP BY MC.name,MC.id
	END
END
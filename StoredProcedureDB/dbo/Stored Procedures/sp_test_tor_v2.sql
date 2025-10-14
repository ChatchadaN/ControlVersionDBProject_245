-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_test_tor_v2]

	@MC_Name varchar(MAX) 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		SELECT value as machine_name INTO #McTable from STRING_SPLIT ( @MC_Name , ',' )
    -- Insert statements for procedure here
		IF((SELECT TOP(1) SUBSTRING(@MC_Name, 1, 2) from #McTable) = 'FT')
	BEGIN
	--update at 2202/06/04

	SELECT  mc.id as McId ,mc.name as McName,mc_s.updated_at as McStop ,MAX( TC.date_complete) as TCTimeFinish 
		FROM APCSProDB.mc.machines as MC WITH (NOLOCK)
		inner join DBx.dbo.scheduler_setup as TC WITH (NOLOCK) on TC.mc_id = MC.id 
		inner join APCSProDB.trans.machine_states MC_S ON MC_S.machine_id = mc.id
		inner join (select distinct * from #McTable) mc_tb  on mc_tb.machine_name = mc.name
		WHERE TC.date_change > dateadd(day, -14, getdate())
		GROUP BY mc.id ,mc.name,mc_s.updated_at

		--SELECT McId,McName,McStop,TCTimeFinish FROM 
		--(SELECT   machine_id
		--,MAX( Lotrecord.[recorded_at] ) as  McStop 
		--FROM [APCSProDB].[trans].[lot_process_records] as Lotrecord  WITH (NOLOCK)
		--INNER JOIN APCSProDB.mc.machines as MC WITH (NOLOCK) on MC.id = machine_id
		--inner join (select distinct * from #McTable) mc_tb  on mc_tb.machine_name = mc.name
		--WHERE  Lotrecord.job_id in (119,110,108,106,87,88,278,263,359,361,362,363,364,120,329,385,378,263,155) and 
		--Lotrecord. record_class = 2 
		--and recorded_at > dateadd(day, -14, getdate()) 
		--and Lotrecord.day_id > 2500
		--GROUP BY machine_id) AS lot_process 
		--INNER JOIN
		--(SELECT  mc.id as McId ,mc.name as McName,MAX( TC.date_complete) as TCTimeFinish 
		--FROM APCSProDB.mc.machines as MC WITH (NOLOCK)
		--inner join DBx.dbo.scheduler_setup as TC WITH (NOLOCK) on TC.mc_id = MC.id 
		--inner join (select distinct * from #McTable) mc_tb  on mc_tb.machine_name = mc.name
		--WHERE TC.date_change > dateadd(day, -14, getdate())
		--GROUP BY mc.id ,mc.name) AS MC ON mc.McId = lot_process.machine_id




		--SELECT  MC.id as McId,MC.name as McName
		--,MAX( Lotrecord.[recorded_at] ) as  McStop 
		--,MAX( TC.date_complete) as TCTimeFinish 

		--FROM [APCSProDB].[trans].[lot_process_records] as Lotrecord WITH (NOLOCK)
		--inner join APCSProDB.mc.machines as MC WITH (NOLOCK) on  
		----DATENAME(year, Lotrecord.recorded_at) = DATENAME(year, GETDATE()) and 
		--MC.id = Lotrecord.machine_id and recorded_at > dateadd(day, -14, getdate()) 
		--inner join DBx.dbo.scheduler_setup as TC WITH (NOLOCK) on TC.mc_id = MC.id and TC.date_change > dateadd(day, -14, getdate())
		--inner join (select distinct * from #McTable) mc_tb  on mc_tb.machine_name = mc.name
		--WHERE  Lotrecord.job_id in (119,110,108,106,87,88,278,263,359,361,362,363,364,120,329,385,378,263,155) and Lotrecord. record_class = 2  
		----and MC.name IN (select distinct * from #McTable) 
		--and Lotrecord.day_id > 2500
		--GROUP BY MC.name,MC.id
	END
	ELSE IF((SELECT TOP(1) SUBSTRING(@MC_Name, 1, 2)) = 'TP' OR (SELECT TOP(1) SUBSTRING(@MC_Name, 1, 2)) = 'FTTP')
	BEGIN
	    SELECT  MC.id as McId,MC.name as McName,mc_s.updated_at as  McStop ,null as TCTimeFinish 
	
		FROM APCSProDB.mc.machines as MC WITH (NOLOCK)  
		inner join APCSProDB.trans.machine_states MC_S ON MC_S.machine_id = mc.id
		inner join (select distinct * from #McTable) mc_tb  on mc_tb.machine_name = mc.name
		
		--GROUP BY MC.name,MC.id


		--SELECT  MC.id as McId,MC.name as McName,MAX( Lotrecord.[recorded_at] ) as  McStop ,null as TCTimeFinish 
	
		--FROM [APCSProDB].[trans].[lot_process_records] as Lotrecord  WITH (NOLOCK)
		--inner join APCSProDB.mc.machines as MC WITH (NOLOCK)  on MC.id = Lotrecord.machine_id 
		--and recorded_at > dateadd(day, -14, getdate()) 
		----and DATENAME(year, Lotrecord.recorded_at) = DATENAME(year, GETDATE())
		--inner join (select distinct * from #McTable) mc_tb  on mc_tb.machine_name = mc.name
		----inner join DBx.dbo.scheduler_setup as TC on TC.mc_id = MC.id////////
		--WHERE  Lotrecord.job_id in (222,231,236,289,397,401,409) and Lotrecord. record_class = 2 
		----and MC.name IN (select distinct * from #McTable) and Lotrecord.day_id > 2500
		--GROUP BY MC.name,MC.id
	END

	drop table #McTable
END

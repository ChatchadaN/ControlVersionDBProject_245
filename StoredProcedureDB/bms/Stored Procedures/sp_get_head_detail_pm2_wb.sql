-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_head_detail_pm2_wb]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select sum(case when DBx.dbo.BMMaintenance.StatusID not in (3,5) then 1 else 0 end) RequestAll,
	sum(case when DBx.dbo.BMMaintenance.StatusID in (1,7) then 1 else 0 end) Remain,
	sum(case when DBx.dbo.BMMaintenance.StatusID in (2,4,6) then 1 else 0 end) Repair,
	sum(case when DBx.dbo.BMMaintenance.StatusID in (9) then 1 else 0 end) Monitor,
	sum(case when DBx.dbo.BMMaintenance.StatusID in (10) then 1 else 0 end) WaitRestart
	from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM6Detail on dbx.dbo.BMMaintenance.id = dbx.dbo.BMPM6Detail.BM_ID 
	left join dbx.dbo.BMMachine on dbx.dbo.BMMaintenance.MachineID = dbx.dbo.BMMachine.ID 
	and dbx.dbo.BMMachine.ProcessID = dbx.dbo.BMMaintenance.ProcessID 
	where pmid = 2  
	and (BMMaintenance.ProcessID ='WB' or (BMMaintenance.ProcessID ='DB' and MachineID like 'P-%'))  -- &CaseSt
	and BMMaintenance.statusid not In (3,5) -- &str
	and dbx.dbo.BMMachine.Location = 'H' -- &building

END

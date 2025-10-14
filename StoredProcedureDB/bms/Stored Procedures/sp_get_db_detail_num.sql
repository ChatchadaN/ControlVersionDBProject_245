-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_db_detail_num]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select sum(case when dbx.dbo.BMMaintenance.StatusID not in(3,5) then 1 else 0 end) RequestAll,
	sum(case when StatusID in(2,4,6) then 1 else 0 end) Repair,
	sum(case when StatusID in(1,7) then 1 else 0 end) Remain,
	sum(case when StatusID in(9) then 1 else 0 end) Monitor,
	sum(case when StatusID in(10) then 1 else 0 end) WaitRestart 
	from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM6Detail on dbx.dbo.BMMaintenance.id = dbx.dbo.BMPM6Detail.BM_ID 
	left join dbx.dbo.BMMachine on BMMaintenance.MachineID = dbx.dbo.BMMachine.ID 
	and BMMachine.ProcessID = BMMaintenance.ProcessID 
	where pmid = '1' 
	and BMMaintenance.statusid not In ('')
	and BMMaintenance.ProcessID ='DB'
	and BMMachine.Location = 'H'
END

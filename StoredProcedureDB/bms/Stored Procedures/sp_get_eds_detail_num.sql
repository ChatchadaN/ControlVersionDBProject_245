-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_eds_detail_num]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select sum(case when dbx.dbo.BMMaintenance.StatusID not in(3,5) then 1 else 0 end) RequestAll,
	sum(case when dbx.dbo.BMMaintenance.StatusID in(2,4,6) then 1 else 0 end) Repair,
	sum(case when dbx.dbo.BMMaintenance.StatusID in(1,7) then 1 else 0 end) Remain,
	sum(case when dbx.dbo.BMMaintenance.StatusID in(9) then 1 else 0 end) Monitor,
	sum(case when dbx.dbo.BMMaintenance.StatusID in(10) then 1 else 0 end) WaitRestart 
	from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM8Detail on dbx.dbo.BMMaintenance.id = dbx.dbo.BMPM8Detail.BM_ID 
	where dbx.dbo.BMMaintenance.PMID = 10 and (dbx.dbo.BMMaintenance.ProcessID = 'EDS')

END

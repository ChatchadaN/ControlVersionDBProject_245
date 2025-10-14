-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_eds_detail]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select BMMaintenance.Urgent
	,dbx.dbo.BMMachine.McControl
	,dbx.dbo.BMMaintenance.MachineID
	,dbx.dbo.BMMaintenance.LotNoforEDS
	,dbx.dbo.BMMaintenance.Device
	,dbx.dbo.BMPM8Detail.frequency1
	,dbx.dbo.BMPM8Detail.frequency2
	,dbx.dbo.BMMaintenance.Requestor
	,dbx.dbo.BMMaintenance.TimeRequest
	,dbx.dbo.BMMaintenance.TimeStart
	,dbx.dbo.BMMaintenance.Inchanger
	,dbx.dbo.BMMaintenance.Problem
	,dbx.dbo.BMMaintenance.NGDescription
	,dbx.dbo.BMMaintenance.ProcessID
	,dbx.dbo.BMMaintenance.PMID
	,dbx.dbo.BMMaintenance.StatusID
	,dbx.dbo.BMMaintenance.Modesetup
	from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM8Detail on dbx.dbo.BMMaintenance.id = dbx.dbo.BMPM8Detail.BM_ID 
	left join dbx.dbo.BMMachine on dbx.dbo.BMMaintenance.MachineID = dbx.dbo.BMMachine.ID 
	where pmid = 10  and BMMaintenance.statusid not In (3,5) and BMMaintenance.ProcessID='EDS' and BMMachine.ProcessID = BMMaintenance.ProcessID 
	and (CategoryID = 1 or CategoryID = 2 or CategoryID = 3 or CategoryID = 4 or CategoryID = 5 or CategoryID = 6 
	or CategoryID = 7 or CategoryID = 8 or CategoryID = 9 or CategoryID = 10 or CategoryID = 11 or CategoryID = 12 
	or CategoryID = 13 or CategoryID = 14 or CategoryID is null)
	order by Urgent desc ,TimeRequest


END

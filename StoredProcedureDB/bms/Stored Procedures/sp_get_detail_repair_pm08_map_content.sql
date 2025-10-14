-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_detail_repair_pm08_map_content]
	-- Add the parameters for the stored procedure here
	@bmid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select dbx.dbo.BMMaintenance.ProcessID
	,dbx.dbo.BMMaintenance.Line
	,dbx.dbo.BMMaintenance.NGDescription
	,dbx.dbo.BMMaintenance.MachineID
	,dbx.dbo.BMMaintenance.Requestor
	,dbx.dbo.BMMaintenance.LotNo
	,dbx.dbo.BMMaintenance.MCStatus
	,dbx.dbo.BMMaintenance.Device
	,dbx.dbo.BMMaintenance.Package
	,dbx.dbo.BMMaintenance.Urgent
	,dbx.dbo.BMMaintenance.Problem
	,dbx.dbo.BMMaintenance.TimeRequest
	,dbx.dbo.BMMaintenance.TimeStart
	,dbx.dbo.BMMaintenance.TimeFinish
	,dbx.dbo.BMMaintenance.Inchanger
	,dbx.dbo.BMMaintenance.CategoryID
	,dbx.dbo.BMMaintenance.BMNoID
	,dbx.dbo.BMMaintenance.BMCaseID
	,dbx.dbo.BMMaintenance.BMUnitID
	,dbx.dbo.BMMaintenance.PositionID
	,dbx.dbo.BMMaintenance.WorkContentID
	,dbx.dbo.BMMaintenance.BMCauseID
	,dbx.dbo.BMEmployee.name As EmpName
	,dbx.dbo.BMStatus.Status
	--,(datediff(mi,(dbx.dbo.BMMaintenance.TimeRequest),dbx.dbo.BMMaintenance.TimeStart)) as MinWaitTime
	,case  when (datediff(mi,(dbx.dbo.BMMaintenance.TimeRequest),dbx.dbo.BMMaintenance.TimeStart)) < 0 then '-'
		   else (datediff(mi,(dbx.dbo.BMMaintenance.TimeRequest),dbx.dbo.BMMaintenance.TimeStart)) end As MinWaitTime
	,case  when (datediff(mi,(dbx.dbo.BMMaintenance.TimeStart),dbx.dbo.BMMaintenance.TimeFinish)) < 0 then '-'
		   else (datediff(mi,(dbx.dbo.BMMaintenance.TimeStart),dbx.dbo.BMMaintenance.TimeFinish)) end As MinRepairTime
	,case  when (datediff(mi,(dbx.dbo.BMMaintenance.TimeRequest),dbx.dbo.BMMaintenance.TimeFinish)) < 0 then '-' 
		   else	(datediff(mi,(dbx.dbo.BMMaintenance.TimeRequest),dbx.dbo.BMMaintenance.TimeFinish)) end As MinMCStopTime
	from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus 
	where dbx.dbo.BMMaintenance.ID = @bmid
	and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
	and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMStatus.StatusID
END

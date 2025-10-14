-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_fl_detail]
	-- Add the parameters for the stored procedure here
	@package int = 0
	-- 0 = all,1 = sop,2 = small
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF(@package = 0)
	BEGIN
	select 
	   dbx.dbo.BMMaintenance.[ID]
	  ,case when (dbx.dbo.BMMaintenance.[Urgent] = 2 and Mccontrol =1) then 'SUPER'
			when dbx.dbo.BMMaintenance.[Urgent] = 2 then 'SUPER' 
			when dbx.dbo.BMMaintenance.[Urgent] = 1 and Mccontrol = 1 then 'SPECIAL'
			when dbx.dbo.BMMaintenance.[Urgent] = 1 then 'SPECIAL'
			when Mccontrol =1 then 'SPECIAL' 
			else convert( varchar(50), ROW_NUMBER() OVER(ORDER BY Urgent desc)) end AS RowID
	  ,case when (dbx.dbo.BMMaintenance.[Urgent] = 2 and Mccontrol =1) then '#ffff00'
			when dbx.dbo.BMMaintenance.[Urgent] = 2 then '#ffcccc' 
			when dbx.dbo.BMMaintenance.[Urgent] = 1 and Mccontrol = 1 then '#ffff00'
			when dbx.dbo.BMMaintenance.[Urgent] = 1 then '#ffcccc'
			when Mccontrol =1 then '#ffff00' 
			else convert( varchar(50), '') end AS Color
      ,case when (dbx.dbo.BMMaintenance.[LotNo] is null or dbx.dbo.BMMaintenance.[LotNo] = '') then '-'
			else dbx.dbo.BMMaintenance.[LotNo] end as LotNo	  
      ,dbx.dbo.BMMaintenance.[MachineID]
      ,dbx.dbo.BMMaintenance.[ProcessID]
      ,case when len(dbx.dbo.BMMaintenance.[Requestor]) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.[Requestor])
			when len(dbx.dbo.BMMaintenance.[Requestor]) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.[Requestor]) 
			end as [Requestor]    
	  ,case when (dbx.dbo.BMMaintenance.[Inchanger] is null or dbx.dbo.BMMaintenance.[Inchanger] = '') then '-'
			when len(dbx.dbo.BMMaintenance.[Inchanger]) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.[Inchanger])
			when len(dbx.dbo.BMMaintenance.[Inchanger]) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.[Inchanger]) 
			else convert( varchar(50), dbx.dbo.BMMaintenance.[Inchanger]) end as [Inchanger]	  
      ,dbx.dbo.BMMaintenance.[TimeRequest]
      ,dbx.dbo.BMMaintenance.[TimeStart]
      ,dbx.dbo.BMMaintenance.[TimeFinish]
      ,dbx.dbo.BMMaintenance.[BMPointID]
      ,dbx.dbo.BMMaintenance.[BMUnitID]
      ,dbx.dbo.BMMaintenance.[BMCaseID]
      ,dbx.dbo.BMMaintenance.[BMNoID]
      ,dbx.dbo.BMMaintenance.[BMCauseID]
      ,dbx.dbo.BMMaintenance.[WorkContentID]
      ,dbx.dbo.BMMaintenance.[PreventionID]
      ,dbx.dbo.BMMaintenance.[CategoryID]
      ,dbx.dbo.BMMaintenance.[PositionID]
      ,dbx.dbo.BMMaintenance.[Problem_No_Use]
      ,dbx.dbo.BMMaintenance.[NGPoint]
      ,dbx.dbo.BMMaintenance.[ActionTake]
      ,dbx.dbo.BMMaintenance.[PMID]
      ,dbx.dbo.BMMaintenance.[NGDuring]
      ,dbx.dbo.BMMaintenance.[Equipment] 
      ,dbx.dbo.BMMaintenance.[NGDescription]
      ,dbx.dbo.BMMaintenance.[Line]
      ,dbx.dbo.BMMaintenance.[Urgent]
      ,dbx.dbo.BMMaintenance.[StatusID]
      ,dbx.dbo.BMMaintenance.[MCStatus]      
	  ,case when (dbx.dbo.BMMaintenance.[Device] is null or dbx.dbo.BMMaintenance.[Device] = '') then '-'
			 else dbx.dbo.BMMaintenance.[Device] end as Device
	  ,case when (dbx.dbo.BMMaintenance.[Package] is null or dbx.dbo.BMMaintenance.[Package] = '') then '-'
			 else dbx.dbo.BMMaintenance.[Package] end as Package      
      ,dbx.dbo.BMMaintenance.[AQI]
      ,dbx.dbo.BMMaintenance.[CaseForPM13]
      ,dbx.dbo.BMMaintenance.[LotNoforEDS]
      ,dbx.dbo.BMMaintenance.[GroupLeader]
      ,dbx.dbo.BMMaintenance.[Restarter]
      ,dbx.dbo.BMMaintenance.[Approver]
      ,dbx.dbo.BMMaintenance.[TimeApprove]
      ,dbx.dbo.BMMaintenance.[Undon]
      ,dbx.dbo.BMMaintenance.[Shokonokoshi]
      ,dbx.dbo.BMMaintenance.[EndTimeMonitoringCase]
      ,dbx.dbo.BMMaintenance.[TimeRestartMC]
      ,dbx.dbo.BMMaintenance.[LotRank]
      ,dbx.dbo.BMMaintenance.[Problem]
	  ,dbx.dbo.BMPM6Detail.[BM_ID]
	  ,Mccontrol
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM6Detail on BMMaintenance.id = dbx.dbo.BMPM6Detail.BM_ID
		left join dbx.dbo.BMMachine on BMMaintenance.MachineID = dbx.dbo.BMMachine.ID
		where (pmid='6' or pmid='7') and BMMaintenance.statusid not In (3,5) and dbx.dbo.BMMachine.ProcessID = 'FL'
		order by Urgent desc ,TimeRequest desc
	END
	IF(@package = 1)
	BEGIN
		select 
	   dbx.dbo.BMMaintenance.[ID]
      ,case when (dbx.dbo.BMMaintenance.[Urgent] = 2 and Mccontrol =1) then 'SUPER'
			when dbx.dbo.BMMaintenance.[Urgent] = 2 then 'SUPER' 
			when dbx.dbo.BMMaintenance.[Urgent] = 1 and Mccontrol = 1 then 'SPECIAL'
			when dbx.dbo.BMMaintenance.[Urgent] = 1 then 'SPECIAL'
			when Mccontrol =1 then 'SPECIAL' 
			else convert( varchar(50), ROW_NUMBER() OVER(ORDER BY Urgent desc)) end AS RowID
	  ,case when (dbx.dbo.BMMaintenance.[Urgent] = 2 and Mccontrol =1) then '#ffff00'
			when dbx.dbo.BMMaintenance.[Urgent] = 2 then '#ffcccc' 
			when dbx.dbo.BMMaintenance.[Urgent] = 1 and Mccontrol = 1 then '#ffff00'
			when dbx.dbo.BMMaintenance.[Urgent] = 1 then '#ffcccc'
			when Mccontrol =1 then '#ffff00' 
			else convert( varchar(50), '') end AS Color
      ,case when (dbx.dbo.BMMaintenance.[LotNo] is null or dbx.dbo.BMMaintenance.[LotNo] = '') then '-'
			else dbx.dbo.BMMaintenance.[LotNo] end as LotNo	  
      ,dbx.dbo.BMMaintenance.[MachineID]
      ,dbx.dbo.BMMaintenance.[ProcessID]
      ,case when len(dbx.dbo.BMMaintenance.[Requestor]) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.[Requestor])
			when len(dbx.dbo.BMMaintenance.[Requestor]) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.[Requestor]) 
			end as [Requestor]    
	  ,case when (dbx.dbo.BMMaintenance.[Inchanger] is null or dbx.dbo.BMMaintenance.[Inchanger] = '') then '-'
			when len(dbx.dbo.BMMaintenance.[Inchanger]) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.[Inchanger])
			when len(dbx.dbo.BMMaintenance.[Inchanger]) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.[Inchanger]) 
			else convert( varchar(50), dbx.dbo.BMMaintenance.[Inchanger]) end as [Inchanger]	  
      ,dbx.dbo.BMMaintenance.[TimeRequest]
      ,dbx.dbo.BMMaintenance.[TimeStart]
      ,dbx.dbo.BMMaintenance.[TimeFinish]
      ,dbx.dbo.BMMaintenance.[BMPointID]
      ,dbx.dbo.BMMaintenance.[BMUnitID]
      ,dbx.dbo.BMMaintenance.[BMCaseID]
      ,dbx.dbo.BMMaintenance.[BMNoID]
      ,dbx.dbo.BMMaintenance.[BMCauseID]
      ,dbx.dbo.BMMaintenance.[WorkContentID]
      ,dbx.dbo.BMMaintenance.[PreventionID]
      ,dbx.dbo.BMMaintenance.[CategoryID]
      ,dbx.dbo.BMMaintenance.[PositionID]
      ,dbx.dbo.BMMaintenance.[Problem_No_Use]
      ,dbx.dbo.BMMaintenance.[NGPoint]
      ,dbx.dbo.BMMaintenance.[ActionTake]
      ,dbx.dbo.BMMaintenance.[PMID]
      ,dbx.dbo.BMMaintenance.[NGDuring]
      ,dbx.dbo.BMMaintenance.[Equipment]
      ,dbx.dbo.BMMaintenance.[NGDescription]
      ,dbx.dbo.BMMaintenance.[Line]
      ,dbx.dbo.BMMaintenance.[Urgent]
      ,dbx.dbo.BMMaintenance.[StatusID]
      ,dbx.dbo.BMMaintenance.[MCStatus]      
	  ,case when (dbx.dbo.BMMaintenance.[Device] is null or dbx.dbo.BMMaintenance.[Device] = '') then '-'
			 else dbx.dbo.BMMaintenance.[Device] end as Device
	  ,case when (dbx.dbo.BMMaintenance.[Package] is null or dbx.dbo.BMMaintenance.[Package] = '') then '-'
			 else dbx.dbo.BMMaintenance.[Package] end as Package      
      ,dbx.dbo.BMMaintenance.[AQI]
      ,dbx.dbo.BMMaintenance.[CaseForPM13]
      ,dbx.dbo.BMMaintenance.[LotNoforEDS]
      ,dbx.dbo.BMMaintenance.[GroupLeader]
      ,dbx.dbo.BMMaintenance.[Restarter]
      ,dbx.dbo.BMMaintenance.[Approver]
      ,dbx.dbo.BMMaintenance.[TimeApprove]
      ,dbx.dbo.BMMaintenance.[Undon]
      ,dbx.dbo.BMMaintenance.[Shokonokoshi]
      ,dbx.dbo.BMMaintenance.[EndTimeMonitoringCase]
      ,dbx.dbo.BMMaintenance.[TimeRestartMC]
      ,dbx.dbo.BMMaintenance.[LotRank]
      ,dbx.dbo.BMMaintenance.[Problem]
	  ,dbx.dbo.BMPM6Detail.[BM_ID]
	  ,Mccontrol
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM6Detail on BMMaintenance.id = dbx.dbo.BMPM6Detail.BM_ID
		left join dbx.dbo.BMMachine on BMMaintenance.MachineID = dbx.dbo.BMMachine.ID
		where pmid='6' and BMMaintenance.statusid not In (3,5) and dbx.dbo.BMMachine.ProcessID = 'FL'
		order by Urgent desc ,TimeRequest desc
	END
	IF(@package = 2)
	BEGIN
		select 
	   dbx.dbo.BMMaintenance.[ID]
      ,case when (dbx.dbo.BMMaintenance.[Urgent] = 2 and Mccontrol =1) then 'SUPER'
			when dbx.dbo.BMMaintenance.[Urgent] = 2 then 'SUPER' 
			when dbx.dbo.BMMaintenance.[Urgent] = 1 and Mccontrol = 1 then 'SPECIAL'
			when dbx.dbo.BMMaintenance.[Urgent] = 1 then 'SPECIAL'
			when Mccontrol =1 then 'SPECIAL' 
			else convert( varchar(50), ROW_NUMBER() OVER(ORDER BY Urgent desc)) end AS RowID
	  ,case when (dbx.dbo.BMMaintenance.[Urgent] = 2 and Mccontrol =1) then '#ffff00'
			when dbx.dbo.BMMaintenance.[Urgent] = 2 then '#ffcccc' 
			when dbx.dbo.BMMaintenance.[Urgent] = 1 and Mccontrol = 1 then '#ffff00'
			when dbx.dbo.BMMaintenance.[Urgent] = 1 then '#ffcccc'
			when Mccontrol =1 then '#ffff00' 
			else convert( varchar(50), '') end AS Color
      ,case when (dbx.dbo.BMMaintenance.[LotNo] is null or dbx.dbo.BMMaintenance.[LotNo] = '') then '-'
			else dbx.dbo.BMMaintenance.[LotNo] end as LotNo	  
      ,dbx.dbo.BMMaintenance.[MachineID]
      ,dbx.dbo.BMMaintenance.[ProcessID]
      ,case when len(dbx.dbo.BMMaintenance.[Requestor]) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.[Requestor])
			when len(dbx.dbo.BMMaintenance.[Requestor]) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.[Requestor]) 
			end as [Requestor]    
	  ,case when (dbx.dbo.BMMaintenance.[Inchanger] is null or dbx.dbo.BMMaintenance.[Inchanger] = '') then '-'
			when len(dbx.dbo.BMMaintenance.[Inchanger]) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.[Inchanger])
			when len(dbx.dbo.BMMaintenance.[Inchanger]) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.[Inchanger]) 
			else convert( varchar(50), dbx.dbo.BMMaintenance.[Inchanger]) end as [Inchanger]	  
      ,dbx.dbo.BMMaintenance.[TimeRequest]
      ,dbx.dbo.BMMaintenance.[TimeStart]
      ,dbx.dbo.BMMaintenance.[TimeFinish]
      ,dbx.dbo.BMMaintenance.[BMPointID]
      ,dbx.dbo.BMMaintenance.[BMUnitID]
      ,dbx.dbo.BMMaintenance.[BMCaseID]
      ,dbx.dbo.BMMaintenance.[BMNoID]
      ,dbx.dbo.BMMaintenance.[BMCauseID]
      ,dbx.dbo.BMMaintenance.[WorkContentID]
      ,dbx.dbo.BMMaintenance.[PreventionID]
      ,dbx.dbo.BMMaintenance.[CategoryID]
      ,dbx.dbo.BMMaintenance.[PositionID]
      ,dbx.dbo.BMMaintenance.[Problem_No_Use]
      ,dbx.dbo.BMMaintenance.[NGPoint]
      ,dbx.dbo.BMMaintenance.[ActionTake]
      ,dbx.dbo.BMMaintenance.[PMID]
      ,dbx.dbo.BMMaintenance.[NGDuring]
      ,dbx.dbo.BMMaintenance.[Equipment]
      ,dbx.dbo.BMMaintenance.[NGDescription]
      ,dbx.dbo.BMMaintenance.[Line]
      ,dbx.dbo.BMMaintenance.[Urgent]
      ,dbx.dbo.BMMaintenance.[StatusID]
      ,dbx.dbo.BMMaintenance.[MCStatus]      
	  ,case when (dbx.dbo.BMMaintenance.[Device] is null or dbx.dbo.BMMaintenance.[Device] = '') then '-'
			 else dbx.dbo.BMMaintenance.[Device] end as Device
	  ,case when (dbx.dbo.BMMaintenance.[Package] is null or dbx.dbo.BMMaintenance.[Package] = '') then '-'
			 else dbx.dbo.BMMaintenance.[Package] end as Package      
      ,dbx.dbo.BMMaintenance.[AQI]
      ,dbx.dbo.BMMaintenance.[CaseForPM13]
      ,dbx.dbo.BMMaintenance.[LotNoforEDS]
      ,dbx.dbo.BMMaintenance.[GroupLeader]
      ,dbx.dbo.BMMaintenance.[Restarter]
      ,dbx.dbo.BMMaintenance.[Approver]
      ,dbx.dbo.BMMaintenance.[TimeApprove]
      ,dbx.dbo.BMMaintenance.[Undon]
      ,dbx.dbo.BMMaintenance.[Shokonokoshi]
      ,dbx.dbo.BMMaintenance.[EndTimeMonitoringCase]
      ,dbx.dbo.BMMaintenance.[TimeRestartMC]
      ,dbx.dbo.BMMaintenance.[LotRank]
      ,dbx.dbo.BMMaintenance.[Problem]
	  ,dbx.dbo.BMPM6Detail.[BM_ID]
	  ,Mccontrol
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM6Detail on BMMaintenance.id = dbx.dbo.BMPM6Detail.BM_ID
		left join dbx.dbo.BMMachine on BMMaintenance.MachineID = dbx.dbo.BMMachine.ID
		where pmid='7' and BMMaintenance.statusid not In (3,5) and dbx.dbo.BMMachine.ProcessID = 'FL'
		order by Urgent desc ,TimeRequest desc
	END
END

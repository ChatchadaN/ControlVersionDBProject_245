-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_db_detail]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select 
	dbx.dbo.BMMaintenance.Line
	,dbx.dbo.BMMachine.Mccontrol 
	,dbx.dbo.BMMaintenance.Urgent
	,dbx.dbo.BMMaintenance.Urgent1
	,case when (McControl = 1) then
		  (case when (urgent = 2 and urgent1 = 2 and McControl = 1) then 'SuperUrgent'
			   when (urgent = 1 and urgent1 = 2 and McControl = 1) then 'Urgent'
               when (urgent = 2 and urgent1 = 1 and McControl = 1) then 'SuperUrgent'
               when (urgent = 1 and urgent1 = 1 and McControl = 1) then 'Urgent'
			   when (urgent = 2 and urgent1 = 0 and McControl = 1) then 'SuperUrgent'
			   when (urgent = 1 and urgent1 = 0 and McControl = 1) then 'Urgent'
			   when (urgent = 0 and urgent1 = 2 and McControl = 1) then 'BottleNeck'
			   when (urgent = 0 and urgent1 = 1 and McControl = 1) then 'Special'
			   when (urgent = 0 and urgent1 = 0 and McControl = 1) then 'Keihin'
		  end)
		  else
		  (case when (urgent = 2 and urgent1 = 2) then 'SuperUrgent/BottleNeck'
			   when (urgent = 1 and urgent1 = 2) then 'Urgent/BottleNeck'
			   when (urgent = 2 and urgent1 = 1) then 'SuperUrgent/Special'
			   when (urgent = 1 and urgent1 = 1) then 'Urgent/Special'
			   when (urgent = 2 and urgent1 = 0) then 'SuperUrgent'
			   when (urgent = 1 and urgent1 = 0) then 'Urgent'
			   when (urgent = 0 and urgent1 = 2) then 'BottleNeck'
			   when (urgent = 0 and urgent1 = 1) then 'Special'
			   else convert( varchar(50), ROW_NUMBER() OVER(ORDER BY Urgent desc)) 
		  end)
	end AS RowID
	,case when (McControl = 1) then
		  (case when (urgent = 2 and urgent1 = 2 and McControl = 1) then '#ffff00'
			    when (urgent = 1 and urgent1 = 2 and McControl = 1) then '#ffff00'
               when (urgent = 2 and urgent1 = 1 and McControl = 1) then '#ffff00'
               when (urgent = 1 and urgent1 = 1 and McControl = 1) then '#ffff00'
			   when (urgent = 2 and urgent1 = 0 and McControl = 1) then '#ffff00'
			   when (urgent = 1 and urgent1 = 0 and McControl = 1) then '#ffff00'
			   when (urgent = 0 and urgent1 = 2 and McControl = 1) then '#ffff00'
			   when (urgent = 0 and urgent1 = 1 and McControl = 1) then '#ffff00'
			   when (urgent = 0 and urgent1 = 0 and McControl = 1) then '#ffff00'
		  end)
		  else
		  (case when (urgent = 2 and urgent1 = 2) then '#ffcccc'
			   when (urgent = 1 and urgent1 = 2) then '#ffcc66'
			   when (urgent = 2 and urgent1 = 1) then '#ffcccc'
			   when (urgent = 1 and urgent1 = 1) then '#ffcc66'
			   when (urgent = 2 and urgent1 = 0) then '#ffcccc'
			   when (urgent = 1 and urgent1 = 0) then '#ffcc66'
			   when (urgent = 0 and urgent1 = 2) then '#e6e6fa'
			   when (urgent = 0 and urgent1 = 1) then '#e6e6fa'
			   else convert( varchar(50), '') 
		  end)
	end AS Color
	,case when dbx.dbo.BMMaintenance.ProcessID is null then '-'
		  else dbx.dbo.BMMaintenance.ProcessID end As ProcessID
	,case when  dbx.dbo.BMMachine.Location is null then 'G'
	      when dbx.dbo.BMMachine.Location = 'F' then 'F'
		  when dbx.dbo.BMMachine.Location = 'H' then 'H'
		  else dbx.dbo.BMMachine.Location end As Location
	,dbx.dbo.BMMaintenance.AQI
	,case when dbx.dbo.BMMaintenance.Equipment is null then '-'
		  else dbx.dbo.BMMaintenance.Equipment end As Equipment
	,case when dbx.dbo.BMMaintenance.MachineID is null then '-'
		  else dbx.dbo.BMMaintenance.MachineID end As MachineID
	,case when dbx.dbo.BMMaintenance.LotNo is null then '-'
		  else dbx.dbo.BMMaintenance.LotNo end As LotNo
	,case when dbx.dbo.BMMaintenance.Package is null then '-'
		  else dbx.dbo.BMMaintenance.Package end As Package
	,case when dbx.dbo.BMMaintenance.Device is null then '-'
		  else dbx.dbo.BMMaintenance.Device end As Device
	,case when dbx.dbo.BMMaintenance.Requestor is null then '-'
		  when len(dbx.dbo.BMMaintenance.Requestor) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.Requestor)
		  when len(dbx.dbo.BMMaintenance.Requestor) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.Requestor)  
	      end As Requestor 
	,dbx.dbo.BMMaintenance.TimeRequest
	,dbx.dbo.BMMaintenance.TimeStart
	,case when dbx.dbo.BMMaintenance.Inchanger is null then '-'
		  when len(dbx.dbo.BMMaintenance.Inchanger) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.Inchanger)
		  when len(dbx.dbo.BMMaintenance.Inchanger) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.Inchanger)  
	      end As Inchanger 
	,dbx.dbo.BMMaintenance.MCStatus
	

	,case when (dbx.dbo.BMMaintenance.Problem != '' and dbx.dbo.BMMaintenance.Problem2 != '') then DBx.dbo.BMMaintenance.Problem + ',' + DBx.dbo.BMMaintenance.Problem2
          when (dbx.dbo.BMMaintenance.Problem != '' or dbx.dbo.BMMaintenance.Problem2 = '') then DBx.dbo.BMMaintenance.Problem
          when (dbx.dbo.BMMaintenance.Problem = '' or dbx.dbo.BMMaintenance.Problem2 != '') then DBx.dbo.BMMaintenance.Problem2
		  end As Problem
	--,dbx.dbo.BMMaintenance.Problem
	,dbx.dbo.BMPM6Detail.AlarmNo
	,dbx.dbo.BMPM6Detail.AlarmName
	,dbx.dbo.BMMaintenance.CaseForPM13
	,dbx.dbo.BMMaintenance.StatusID
	,dbx.dbo.BMPM6Detail.ChkRequestType
	,dbx.dbo.BMPM6Detail.WBData601
	,dbx.dbo.BMPM6Detail.WBData600
	,dbx.dbo.BMMaintenance.Restarter

	from dbx.dbo.BMMaintenance 
	right join dbx.dbo.BMPM6Detail on dbx.dbo.BMMaintenance.id = dbx.dbo.BMPM6Detail.BM_ID 
	left join dbx.dbo.BMMachine on dbx.dbo.BMMaintenance.MachineID = dbx.dbo.BMMachine.ID 
	and dbx.dbo.BMMachine.ProcessID = dbx.dbo.BMMaintenance.ProcessID 
	where pmid = '1' and BMMaintenance.statusid not In (3,5) 
	and BMMaintenance.statusid not In (3,5)
	and BMMaintenance.ProcessID ='DB'
	order by dbx.dbo.BMMaintenance.Urgent desc ,dbx.dbo.BMMaintenance.TimeRequest,dbx.dbo.BMMachine.McControl desc

END

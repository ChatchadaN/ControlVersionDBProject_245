-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_WB_detail]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select dbx.dbo.BMMaintenance.NGDescription
	,dbx.dbo.BMMaintenance.ProcessID
	,dbx.dbo.BMMaintenance.PMID
	,case when dbx.dbo.BMMaintenance.Urgent = '1' and dbx.dbo.BMMachine.McControl = '1' then 'Urgent'
		  when dbx.dbo.BMMaintenance.Urgent = '2' and dbx.dbo.BMMachine.McControl = '1' then 'Special'
		  when dbx.dbo.BMMaintenance.Urgent = '4' and dbx.dbo.BMMachine.McControl = '1' then 'M/C Stop'
		  when dbx.dbo.BMMachine.McControl = '1' then 'Special'
		  when dbx.dbo.BMMaintenance.Urgent = '1' then 'Urgent'
		  when dbx.dbo.BMMaintenance.Urgent = '2' then 'Super Urgent'
		  when dbx.dbo.BMMaintenance.Urgent = '4' then 'M/C Stop'
		  else convert( varchar(50), ROW_NUMBER() OVER(ORDER BY Urgent desc)) end As RowId  
	,case when dbx.dbo.BMMaintenance.Urgent = '1' and dbx.dbo.BMMachine.McControl = '1' then '#ffff00'
		  when dbx.dbo.BMMaintenance.Urgent = '2' and dbx.dbo.BMMachine.McControl = '1' then '#ffff00'
		  when dbx.dbo.BMMaintenance.Urgent = '4' and dbx.dbo.BMMachine.McControl = '1' then '#ffff00'
		  when dbx.dbo.BMMachine.McControl = '1' then '#ffff00'
		  when dbx.dbo.BMMaintenance.Urgent = '1' then '#FFEEEE'
		  when dbx.dbo.BMMaintenance.Urgent = '2' then '#FFDDDD'
		  when dbx.dbo.BMMaintenance.Urgent = '4' then '#FF6565'
		  else convert( varchar(50), '') end AS Color
	,case when dbx.dbo.BMMachine.Location is null then 'G'
		  when dbx.dbo.BMMachine.Location = 'F' then 'F'
		  when dbx.dbo.BMMachine.Location = 'H' then 'H'
		  else dbx.dbo.BMMachine.Location end As  Location
	,case when dbx.dbo.BMMaintenance.Line is null then '-'
		  else dbx.dbo.BMMaintenance.Line end As Line
	,case when dbx.dbo.BMMaintenance.CategoryID is null then 'Others'
		  when dbx.dbo.BMMaintenance.CategoryID = 1 then 'BM'
		  when dbx.dbo.BMMaintenance.CategoryID = 2 then 'PM'
		  when dbx.dbo.BMMaintenance.CategoryID = 3 then 'CM'
		  when dbx.dbo.BMMaintenance.CategoryID = 4 then 'Set Up'
		  when dbx.dbo.BMMaintenance.CategoryID = 5 then 'WM'
		  when dbx.dbo.BMMaintenance.CategoryID = 6 then 'Other Process'
		  when dbx.dbo.BMMaintenance.CategoryID = 7 then 'Materail'
		  else convert( varchar(50), dbx.dbo.BMMaintenance.CategoryID) end As CategoryID
	,dbx.dbo.BMMaintenance.MachineID
	,dbx.dbo.BMMaintenance.AQI
	,case when dbx.dbo.BMMaintenance.LotNo is null then '-'
		  else dbx.dbo.BMMaintenance.LotNo end As LotNo
	,case when dbx.dbo.BMMaintenance.Package is null then '-'
		  else dbx.dbo.BMMaintenance.Package end As Package

	,case when dbx.dbo.BMMaintenance.Package = 'TO252' or dbx.dbo.BMMaintenance.Package = 'TO252-5' or dbx.dbo.BMMaintenance.Package = 'TO252-J5' 
		  or dbx.dbo.BMMaintenance.Package = 'TO252S-3' or dbx.dbo.BMMaintenance.Package = 'SSOP-B28W' or dbx.dbo.BMMaintenance.Package = 'TO25S-5+'
		  or dbx.dbo.BMMaintenance.Package = 'TO252-7+' or dbx.dbo.BMMaintenance.Package = 'TO252S-5' or dbx.dbo.BMMaintenance.Package = 'VQFP-48C' then 'A'
		  when dbx.dbo.BMMaintenance.Package = 'HTQFP64V' or dbx.dbo.BMMaintenance.Package = 'HQFP64V' or dbx.dbo.BMMaintenance.Package = 'HRP5'
		  or dbx.dbo.BMMaintenance.Package = 'HRP7' or dbx.dbo.BMMaintenance.Package = 'TO263-3' or dbx.dbo.BMMaintenance.Package = 'TO263-5'
		  or dbx.dbo.BMMaintenance.Package = 'TO263-7' or dbx.dbo.BMMaintenance.Package = 'QFP32' or dbx.dbo.BMMaintenance.Package = 'SQFP80'
		  or dbx.dbo.BMMaintenance.Package = 'SQFT-T52' or dbx.dbo.BMMaintenance.Package = 'QFP-A64' or dbx.dbo.BMMaintenance.Package = 'HSON-A8' then 'B'
		  when dbx.dbo.BMMaintenance.Package = 'SSOP-A44' or dbx.dbo.BMMaintenance.Package = 'SSOP-B10W' or dbx.dbo.BMMaintenance.Package = 'SSOP-B20W'
		  or dbx.dbo.BMMaintenance.Package = 'SSOP-B20W-4' or dbx.dbo.BMMaintenance.Package = 'SIP9' or dbx.dbo.BMMaintenance.Package = 'HSOP-M36'
		  or dbx.dbo.BMMaintenance.Package = 'HTSSOPC48R' or dbx.dbo.BMMaintenance.Package = 'HTSSOP-C48' then 'C'
		  when dbx.dbo.BMMaintenance.Package = 'HTSSOP-A44' or dbx.dbo.BMMaintenance.Package = 'HTSSOP-B54' or dbx.dbo.BMMaintenance.Package = 'SSOP-A54_23' then 'D'
		  when dbx.dbo.BMMaintenance.Package = 'HTSSOP-B40' or dbx.dbo.BMMaintenance.Package = 'HTSSOP-B20' then 'E'
		  when dbx.dbo.BMMaintenance.Package = 'TSSOP-C48V'  then 'F'
		  when dbx.dbo.BMMaintenance.Package = 'SSOP-A20' or dbx.dbo.BMMaintenance.Package = 'SSOP-A24' or dbx.dbo.BMMaintenance.Package = 'SSOP22' 
		  or dbx.dbo.BMMaintenance.Package = 'SSOP-B24' or dbx.dbo.BMMaintenance.Package = 'SOP24' or dbx.dbo.BMMaintenance.Package = 'SSOP-A44'
		  or dbx.dbo.BMMaintenance.Package = 'SSOP-B28' or dbx.dbo.BMMaintenance.Package = 'HTSSOP-B20' then 'G' 
		  when dbx.dbo.BMMaintenance.Package = 'SSOP-A32' or dbx.dbo.BMMaintenance.Package = 'SSOP-B40' or dbx.dbo.BMMaintenance.Package = 'MSOP8' 
		  or dbx.dbo.BMMaintenance.Package = 'MSOP10' or dbx.dbo.BMMaintenance.Package = 'TSSOP-B8J' then 'H'
		  when dbx.dbo.BMMaintenance.Package = 'HVSOF5' or dbx.dbo.BMMaintenance.Package = 'HVSOF6' or dbx.dbo.BMMaintenance.Package = 'HSON8' 
		  or dbx.dbo.BMMaintenance.Package = 'SOP4' or dbx.dbo.BMMaintenance.Package = 'WSOF5' or dbx.dbo.BMMaintenance.Package = 'VSOF5' 
		  or dbx.dbo.BMMaintenance.Package = 'WSOF6' or dbx.dbo.BMMaintenance.Package = 'SSON004R101' then 'I'
		  when dbx.dbo.BMMaintenance.Package = 'SSON004*1216' or dbx.dbo.BMMaintenance.Package = 'USOM006*1212' or dbx.dbo.BMMaintenance.Package = 'VSON008X2030' 
		  or dbx.dbo.BMMaintenance.Package = 'USON014X3020'  then 'J'
		  else '-' end As HPPP
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
		  else '-'  
	 end As Inchanger 
	,case when dbx.dbo.BMPM6Detail.ChkMag != '' then dbx.dbo.BMPM6Detail.ChkMag
		  else '-' end As ChkMag
	,case when dbx.dbo.BMPM6Detail.ChkFrame != '' then dbx.dbo.BMPM6Detail.ChkFrame
		  else '-' end As ChkFrame
	,dbx.dbo.BMMaintenance.StatusID
	,case when dbx.dbo.BMMaintenance.StatusID = 11 then dbx.dbo.BMMaintenance.Problem + CHAR(13) + '(' + dbx.dbo.BMMaintenance.ActionTake + ')'
		  else
			case when dbx.dbo.BMMaintenance.Problem != '' then dbx.dbo.BMMaintenance.Problem
		  else '-' 
			end
		  end As Problem
	,dbx.dbo.BMPM6Detail.ChkRequestType
	,dbx.dbo.BMPM6Detail.AlarmNo
	,dbx.dbo.BMPM6Detail.AlarmName
	,dbx.dbo.BMPM6Detail.WBData601
	,dbx.dbo.BMPM6Detail.MCTypePDChk
	,dbx.dbo.BMMaintenance.CaseForPM13
	from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM6Detail on dbx.dbo.BMMaintenance.id = dbx.dbo.BMPM6Detail.BM_ID 
	left join dbx.dbo.BMMachine on dbx.dbo.BMMaintenance.MachineID = dbx.dbo.BMMachine.ID 
	and dbx.dbo.BMMachine.ProcessID = dbx.dbo.BMMaintenance.ProcessID 
	where pmid = 2 
	and BMMaintenance.statusid not In (3,5) --&CaseSt
	and (BMMaintenance.ProcessID ='WB' or (BMMaintenance.ProcessID ='DB' and MachineID like 'P-%')) -- &str
	and BMMachine.Location = 'H' --&building
	order by Urgent desc ,Location ,TimeRequest desc
END

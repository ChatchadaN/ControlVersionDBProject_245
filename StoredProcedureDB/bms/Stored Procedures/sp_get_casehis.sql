-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_casehis]
	-- Add the parameters for the stored procedure here
	@pmid varchar(10),
	@process varchar(10),
	@mcno varchar(25)
	-- 0 = all,1 = sop,2 = small
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF(@pmid = '1'or @pmid = '2'or @pmid = '3'or @pmid = '4'or @pmid = '5'or @pmid = '6'or @pmid = '7')
	BEGIN
		select Top 5 
		ROW_NUMBER() OVER(ORDER BY dbx.dbo.BMMaintenance.ID desc) as Rowid
		,DBx.dbo.BMMaintenance.ID
		,dbx.dbo.BMMaintenance.ProcessID
		,dbx.dbo.BMMaintenance.MachineID
		,dbx.dbo.BMMaintenance.Package
		,dbx.dbo.BMMaintenance.Device
		,dbx.dbo.BMMaintenance.LotNo
		,dbx.dbo.BMMaintenance.ActionTake
		,case when len(dbx.dbo.BMMaintenance.Inchanger) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.Inchanger)
			  when len(dbx.dbo.BMMaintenance.Inchanger) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.Inchanger) 
			  end as Inchanger
		,dbx.dbo.BMMaintenance.TimeRequest
		,dbx.dbo.BMMaintenance.Problem
		,dbx.dbo.BMMaintenance.PMID
		,case when (dbx.dbo.BMMaintenance.ActionTake = 'Request EE') then 'Request EE'
			  else (case when DBx.dbo.BMPM6Detail.CountermeasureDetails1 = null or DBx.dbo.BMPM6Detail.CountermeasureDetails2 = null or DBx.dbo.BMPM6Detail.CountermeasureDetails3 = null or DBx.dbo.BMPM6Detail.CountermeasureDetails4 =null then '-'
						 else DBx.dbo.BMPM6Detail.CountermeasureDetails1+' '+DBx.dbo.BMPM6Detail.CountermeasureDetails2+' '+DBx.dbo.BMPM6Detail.CountermeasureDetails3+' '+DBx.dbo.BMPM6Detail.CountermeasureDetails4 end) 
		 end as ActionTakeDescript
		,dbx.dbo.BMPM6Detail.ChkRequestType
		,dbx.dbo.BMPM6Detail.MCTypePDChk
		,dbx.dbo.BMMaintenance.NGDescription
		,dbx.dbo.BMMaintenance.Shokonokoshi
		from DBx.dbo.BMMaintenance,DBx.dbo.BMPM6Detail 
		where BMMaintenance.ID = BMPM6Detail.BM_ID and BMMaintenance.StatusID = '3' 
		and BMMaintenance.ProcessID = @process
		and BMMaintenance.MachineID = @mcno
		order by dbx.dbo.BMMaintenance.ID Desc
	END
	Else IF(@pmid = '8'or @pmid = '9'or @pmid = '10')
	BEGIN
		select Top 5 
		ROW_NUMBER() OVER(ORDER BY dbx.dbo.BMMaintenance.ID desc) as Rowid
		,DBx.dbo.BMMaintenance.ID
		,dbx.dbo.BMMaintenance.ProcessID
		,dbx.dbo.BMMaintenance.MachineID
		,dbx.dbo.BMMaintenance.Package
		,dbx.dbo.BMMaintenance.Device
		,dbx.dbo.BMMaintenance.LotNo
		,dbx.dbo.BMMaintenance.ActionTake
		,DBx.dbo.BMPM8Detail.Bm_ID
		,case when len(dbx.dbo.BMMaintenance.Inchanger) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.Inchanger)
			  when len(dbx.dbo.BMMaintenance.Inchanger) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.Inchanger) 
			  end as Inchanger
		,dbx.dbo.BMMaintenance.TimeRequest
		,dbx.dbo.BMMaintenance.Problem
		,dbx.dbo.BMMaintenance.PMID	
		,(dbx.dbo.BMPM8Detail.Detail1+' '+dbx.dbo.BMPM8Detail.Detail2+' '+dbx.dbo.BMPM8Detail.Detail3) as ActionTakeDescript
		,dbx.dbo.BMMaintenance.NGDescription
		,dbx.dbo.BMMaintenance.Shokonokoshi
		from DBx.dbo.BMMaintenance,DBx.dbo.BMPM8Detail 
		where BMMaintenance.ID = BMPM8Detail.BM_ID and BMMaintenance.StatusID = '3'
		and BMMaintenance.ProcessID =@process
		and BMMaintenance.MachineID =@mcno 
		order by ID Desc
	END
	Else
	BEGIN
		select Top 5 
		ROW_NUMBER() OVER(ORDER BY dbx.dbo.BMMaintenance.ID desc) as Rowid
		,DBx.dbo.BMMaintenance.ID
		,dbx.dbo.BMMaintenance.ProcessID
		,dbx.dbo.BMMaintenance.MachineID
		,dbx.dbo.BMMaintenance.Package
		,dbx.dbo.BMMaintenance.Device
		,dbx.dbo.BMMaintenance.LotNo
		,dbx.dbo.BMMaintenance.ActionTake as ActionTakeDescript
		,case when len(dbx.dbo.BMMaintenance.Inchanger) = 3 then CONCAT('000',dbx.dbo.BMMaintenance.Inchanger)
			  when len(dbx.dbo.BMMaintenance.Inchanger) = 4 then CONCAT('00',dbx.dbo.BMMaintenance.Inchanger) 
			  end as Inchanger
		,dbx.dbo.BMMaintenance.TimeRequest
		,dbx.dbo.BMMaintenance.Problem
		,dbx.dbo.BMMaintenance.PMID
		,dbx.dbo.BMMaintenance.NGDescription
		,dbx.dbo.BMMaintenance.Shokonokoshi
		from DBx.dbo.BMMaintenance,DBx.dbo.BMTEDetail 
		where BMMaintenance.ID = BMTEDetail.BM_ID and BMMaintenance.StatusID = '3'  
		and BMMaintenance.ProcessID = @process 
		and BMMaintenance.MachineID = @mcno 
		order by ID Desc
	END
	
END

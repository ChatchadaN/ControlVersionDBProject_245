-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_detail_repair_pm08_map]
	-- Add the parameters for the stored procedure here
	@bmid int,
	@status varchar
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@status = '1')
	BEGIN
		--select dbx.dbo.BMEmployee.Name As RequestorName ,DBx.dbo.BMEmployee.ID As Requsetor
		--,case when len(dbx.dbo.BMEmployee.ID) = 3 then CONCAT('000',dbx.dbo.BMEmployee.ID)
		--	  when len(dbx.dbo.BMEmployee.ID) = 4 then CONCAT('00',dbx.dbo.BMEmployee.ID)  
		--end As RequestorId 
		--from dbx.dbo.BMEmployee where dbx.dbo.BMEmployee.ID IN (select dbx.dbo.BMMaintenance.Requestor
		--from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		--where dbx.dbo.BMMaintenance.ID = @bmid
		--and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		--and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		--and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID )

		select dbx.dbo.BMEmployee.Name As RequestorName
		,case when len(dbx.dbo.BMEmployee.ID) = 3 then CONCAT('000',dbx.dbo.BMEmployee.ID)
			  when len(dbx.dbo.BMEmployee.ID) = 4 then CONCAT('00',dbx.dbo.BMEmployee.ID)  
		end As RequestorId , CONVERT(date,dbx.dbo.BMMaintenance.TimeRequest) As TimeRequest

		--,dbx.dbo.BMEmployee.ID As RequestorID , CONVERT(date,dbx.dbo.BMMaintenance.TimeRequest) As TimeRequest

		from dbx.dbo.BMMaintenance, dbx.dbo.BMEmployee 
		where dbx.dbo.BMEmployee.ID IN (select dbx.dbo.BMMaintenance.Requestor
		from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee, dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		where dbx.dbo.BMMaintenance.ID = @bmid
		and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID) 
		and  dbx.dbo.BMMaintenance.TimeRequest IN (select dbx.dbo.BMMaintenance.TimeRequest
		from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		where dbx.dbo.BMMaintenance.ID = @bmid
		and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID) 
	END
	IF(@status = '2')
	BEGIN
		select dbx.dbo.BMEmployee.Name As GlName
		--,dbx.dbo.BMEmployee.ID As GlId 
		,case when len(dbx.dbo.BMEmployee.ID) = 3 then CONCAT('000',dbx.dbo.BMEmployee.ID)
		when len(dbx.dbo.BMEmployee.ID) = 4 then CONCAT('00',dbx.dbo.BMEmployee.ID) end As GlId 
		,CONVERT(date,dbx.dbo.BMMaintenance.TimeRequest) As TimeRequest
		from dbx.dbo.BMEmployee ,dbx.dbo.BMMaintenance
		where dbx.dbo.BMEmployee.ID IN (select dbx.dbo.BMPM8Detail.GL
		from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		where dbx.dbo.BMMaintenance.ID = @bmid
		and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID )
		and  dbx.dbo.BMMaintenance.TimeRequest IN (select dbx.dbo.BMMaintenance.TimeRequest
		from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		where dbx.dbo.BMMaintenance.ID = @bmid
		and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID) 
	END
	IF(@status = '3')
	BEGIN
		select dbx.dbo.BMEmployee.Name As InchangerName
		--,dbx.dbo.BMEmployee.ID As InchangerId 
		,case when len(dbx.dbo.BMEmployee.ID) = 3 then CONCAT('000',dbx.dbo.BMEmployee.ID)
		when len(dbx.dbo.BMEmployee.ID) = 4 then CONCAT('00',dbx.dbo.BMEmployee.ID) end As InchangerId 
		,CONVERT(date,dbx.dbo.BMMaintenance.TimeStart) As TimeStart 
		from dbx.dbo.BMEmployee,dbx.dbo.BMMaintenance
		where dbx.dbo.BMEmployee.ID IN (select dbx.dbo.BMMaintenance.Inchanger
		from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		where dbx.dbo.BMMaintenance.ID = @bmid
		and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID )
		and  dbx.dbo.BMMaintenance.TimeStart IN (select dbx.dbo.BMMaintenance.TimeStart
		from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		where dbx.dbo.BMMaintenance.ID = @bmid
		and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID) 
	END
	IF(@status = '4')
	BEGIN
		select dbx.dbo.BMEmployee.Name As Restartername
		--,dbx.dbo.BMEmployee.ID As RestarterId
		,case when len(dbx.dbo.BMEmployee.ID) = 3 then CONCAT('000',dbx.dbo.BMEmployee.ID)
		when len(dbx.dbo.BMEmployee.ID) = 4 then CONCAT('00',dbx.dbo.BMEmployee.ID) end As RestarterId 
		,CONVERT(date,dbx.dbo.BMMaintenance.TimeStart) As TimeStart 
		from dbx.dbo.BMEmployee,dbx.dbo.BMMaintenance
		where dbx.dbo.BMEmployee.ID IN (select dbx.dbo.BMMaintenance.Restarter
		from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		where dbx.dbo.BMMaintenance.ID = @bmid
		and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID )
		and  dbx.dbo.BMMaintenance.TimeStart IN (select dbx.dbo.BMMaintenance.TimeStart
		from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		where dbx.dbo.BMMaintenance.ID = @bmid
		and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID) 
	END
	IF(@status = '5')
	BEGIN
		select dbx.dbo.BMEmployee.Name As EmpApproveName 
		--,dbx.dbo.BMEmployee.ID As EmpApproveId
		,case when len(dbx.dbo.BMEmployee.ID) = 3 then CONCAT('000',dbx.dbo.BMEmployee.ID)
		when len(dbx.dbo.BMEmployee.ID) = 4 then CONCAT('00',dbx.dbo.BMEmployee.ID) end As EmpApproveId 
		,CONVERT(date,dbx.dbo.BMMaintenance.TimeStart) As TimeStart  
		from dbx.dbo.BMEmployee,dbx.dbo.BMMaintenance
		where dbx.dbo.BMEmployee.ID IN (select dbx.dbo.BMMaintenance.Approver as EmpApprove 
		from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		where dbx.dbo.BMMaintenance.ID = @bmid
		and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID )
		and  dbx.dbo.BMMaintenance.TimeStart IN (select dbx.dbo.BMMaintenance.TimeStart
		from dbx.dbo.BMMaintenance,dbx.dbo.BMEmployee,dbx.dbo.BMStatus,dbx.dbo.BMPM8Detail 
		where dbx.dbo.BMMaintenance.ID = @bmid
		and dbx.dbo.BMMaintenance.Requestor = dbx.dbo.BMEmployee.id 
		and dbx.dbo.BMMaintenance.statusid = dbx.dbo.BMstatus.statusid 
		and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID) 
	END
END

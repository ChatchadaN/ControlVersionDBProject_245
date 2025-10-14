-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_detail_repair_pm08]
	-- Add the parameters for the stored procedure here
	@bmid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select dbx.dbo.BMMaintenance.CategoryID
	,dbx.dbo.BMMaintenance.Undon
	,dbx.dbo.BMMaintenance.ProcessID
	,dbx.dbo.BMMaintenance.Line
	,dbx.dbo.BMMaintenance.NGDescription
	,dbx.dbo.BMMaintenance.MachineID
	,dbx.dbo.BMPM8Detail.frequency1
	,dbx.dbo.BMPM8Detail.frequency2
	,dbx.dbo.BMPM8Detail.frequency3
	,dbx.dbo.BMMaintenance.Package
	,dbx.dbo.BMMaintenance.Requestor
	,dbx.dbo.BMMaintenance.LotNo
	,dbx.dbo.BMMaintenance.Device
	,dbx.dbo.BMPM8Detail.alarmNo
	,dbx.dbo.BMPM8Detail.alarmName
	,dbx.dbo.BMMaintenance.AQI
	,dbx.dbo.BMMaintenance.MCStatus
	,dbx.dbo.BMPM8Detail.chkbegood
	,dbx.dbo.BMPM8Detail.chkbeng
	,dbx.dbo.BMPM8Detail.chkbetotal
	,dbx.dbo.BMPM8Detail.chkbemecha
	,dbx.dbo.BMMaintenance.Problem
	,dbx.dbo.BMMaintenance.Urgent
	,dbx.dbo.BMMaintenance.TimeRequest
	,dbx.dbo.BMMaintenance.TimeStart
	,dbx.dbo.BMMaintenance.TimeFinish
	--,dbx.dbo.BMPM8Detail.whyI
	,case  when dbx.dbo.BMPM8Detail.whyI is null or dbx.dbo.BMPM8Detail.whyI = '' then '-'
			else dbx.dbo.BMPM8Detail.whyI end As WhyI
	--,dbx.dbo.BMPM8Detail.whyI_2
	,case  when dbx.dbo.BMPM8Detail.WhyI_2 is null or dbx.dbo.BMPM8Detail.WhyI_2 = '' then '-'
			else dbx.dbo.BMPM8Detail.WhyI_2 end As WhyI_2
	--,dbx.dbo.BMPM8Detail.whyI_3
	,case  when dbx.dbo.BMPM8Detail.WhyI_3 is null or dbx.dbo.BMPM8Detail.WhyI_3 = '' then '-'
			else dbx.dbo.BMPM8Detail.WhyI_3 end As WhyI_3
	--,dbx.dbo.BMPM8Detail.whyII
	,case  when dbx.dbo.BMPM8Detail.whyII is null or dbx.dbo.BMPM8Detail.whyII = '' then '-'
			else dbx.dbo.BMPM8Detail.whyII end As whyII
	--,dbx.dbo.BMPM8Detail.whyII_2
	,case  when dbx.dbo.BMPM8Detail.WhyII_2 is null or dbx.dbo.BMPM8Detail.WhyII_2 = '' then '-'
			else dbx.dbo.BMPM8Detail.WhyII_2 end As WhyII_2
	--,dbx.dbo.BMPM8Detail.whyII_3
	,case  when dbx.dbo.BMPM8Detail.WhyII_3 is null or dbx.dbo.BMPM8Detail.WhyII_3 = '' then '-'
			else dbx.dbo.BMPM8Detail.WhyII_3 end As WhyII_3
	--,dbx.dbo.BMPM8Detail.whyIII
	,case  when dbx.dbo.BMPM8Detail.whyIII is null or dbx.dbo.BMPM8Detail.whyIII = '' then '-'
			else dbx.dbo.BMPM8Detail.whyIII end As whyIII
	--,dbx.dbo.BMPM8Detail.whyIII_2
	,case  when dbx.dbo.BMPM8Detail.WhyIII_2 is null or dbx.dbo.BMPM8Detail.WhyIII_2 = '' then '-'
			else dbx.dbo.BMPM8Detail.WhyIII_2 end As WhyIII_2
	--,dbx.dbo.BMPM8Detail.whyIII_3
	,case  when dbx.dbo.BMPM8Detail.WhyIII_3 is null or dbx.dbo.BMPM8Detail.WhyIII_3 = '' then '-'
			else dbx.dbo.BMPM8Detail.WhyIII_3 end As WhyIII_3
	,dbx.dbo.BMPM8Detail.chkmanlot
	,dbx.dbo.BMPM8Detail.chk4s
	,dbx.dbo.BMPM8Detail.chkdummy
	,dbx.dbo.BMPM8Detail.chkdummypcs
	,dbx.dbo.BMPM8Detail.chkdummypcs22
	,dbx.dbo.BMPM8Detail.chkt1
	,dbx.dbo.BMPM8Detail.chkt2
	,dbx.dbo.BMPM8Detail.Detail1
	,dbx.dbo.BMPM8Detail.valuesDetail1_1
	,dbx.dbo.BMPM8Detail.valuesDetail1_2
	,dbx.dbo.BMPM8Detail.Detail2
	,dbx.dbo.BMPM8Detail.valuesDetail2_1
	,dbx.dbo.BMPM8Detail.valuesDetail2_2
	,dbx.dbo.BMPM8Detail.Detail3
	,dbx.dbo.BMPM8Detail.valuesDetail3_1
	,dbx.dbo.BMPM8Detail.valuesDetail3_2
	,dbx.dbo.BMPM8Detail.Detail4
	,dbx.dbo.BMPM8Detail.valuesDetail4_1
	,dbx.dbo.BMPM8Detail.valuesDetail4_2
	,dbx.dbo.BMPM8Detail.Detail5
	,dbx.dbo.BMPM8Detail.valuesDetail5_1
	,dbx.dbo.BMPM8Detail.valuesDetail5_2
	,dbx.dbo.BMPM8Detail.Detail6
	,dbx.dbo.BMPM8Detail.valuesDetail6_1
	,dbx.dbo.BMPM8Detail.valuesDetail6_2
	,dbx.dbo.BMPM8Detail.Detail7
	,dbx.dbo.BMPM8Detail.valuesDetail7_1
	,dbx.dbo.BMPM8Detail.valuesDetail7_2
	,dbx.dbo.BMPM8Detail.chkjobng1
	,dbx.dbo.BMPM8Detail.chkjobng2
	,dbx.dbo.BMPM8Detail.bechgtype
	,dbx.dbo.BMPM8Detail.afchgtype
	,dbx.dbo.BMPM8Detail.bechkcover
	,dbx.dbo.BMPM8Detail.afchkcover
	,dbx.dbo.BMPM8Detail.bepartlead
	,dbx.dbo.BMPM8Detail.afpartlead
	,dbx.dbo.BMPM8Detail.bechgsocket
	,dbx.dbo.BMPM8Detail.afchgsocket
	,dbx.dbo.BMPM8Detail.bepartseal
	,dbx.dbo.BMPM8Detail.afpartseal
	,dbx.dbo.BMPM8Detail.bepartiron
	,dbx.dbo.BMPM8Detail.afpartiron
	,dbx.dbo.BMPM8Detail.chkbegood
	,dbx.dbo.BMPM8Detail.chkbeng
	,dbx.dbo.BMPM8Detail.chkbetotal
	,dbx.dbo.BMPM8Detail.chkbemecha
	,dbx.dbo.BMPM8Detail.chkafgood
	,dbx.dbo.BMPM8Detail.chkafng
	,dbx.dbo.BMPM8Detail.chkaftotal
	,dbx.dbo.BMPM8Detail.chkafmecha
	,dbx.dbo.BMPM8Detail.bechkstrjig
	,dbx.dbo.BMPM8Detail.afchkstrjig
	,dbx.dbo.BMPM8Detail.bechkstremboss
	,dbx.dbo.BMPM8Detail.afchkstremboss
	,dbx.dbo.BMPM8Detail.bechkdialjig
	,dbx.dbo.BMPM8Detail.afchkdialemboss
	,dbx.dbo.BMPM8Detail.bechkdialemboss
	,dbx.dbo.BMPM8Detail.bechknxjig
	,dbx.dbo.BMPM8Detail.afchknxjig
	,dbx.dbo.BMPM8Detail.bechknxem
	,dbx.dbo.BMPM8Detail.afchknxem
	,dbx.dbo.BMPM8Detail.chkbeqckake
	,dbx.dbo.BMPM8Detail.chkafqckake
	,dbx.dbo.BMPM8Detail.chkbeqcbent
	,dbx.dbo.BMPM8Detail.chkafqcbent
	,dbx.dbo.BMPM8Detail.chkbeqcmark
	,dbx.dbo.BMPM8Detail.chkafqcmark
	,dbx.dbo.BMPM8Detail.chkbeqcdir
	,dbx.dbo.BMPM8Detail.chkafqcdir
	,dbx.dbo.BMPM8Detail.chkafqcbun
	,dbx.dbo.BMPM8Detail.StampB
	,dbx.dbo.BMPM8Detail.StampA
	,dbx.dbo.BMPM8Detail.PeelingB
	,dbx.dbo.BMPM8Detail.PeelingA
	--,dbx.dbo.BMPM8Detail.partname1
	,case  when dbx.dbo.BMPM8Detail.partname1 is null or dbx.dbo.BMPM8Detail.partname1 = '' then '-'
			else dbx.dbo.BMPM8Detail.partname1 end As partname1
	,dbx.dbo.BMPM8Detail.parttype1
	,dbx.dbo.BMPM8Detail.partquantity1
	--,dbx.dbo.BMPM8Detail.partname2
	,case  when dbx.dbo.BMPM8Detail.partname2 is null or dbx.dbo.BMPM8Detail.partname2 = '' then '-'
			else dbx.dbo.BMPM8Detail.partname2 end As partname2
	,dbx.dbo.BMPM8Detail.parttype2
	,dbx.dbo.BMPM8Detail.partquantity2
	--,dbx.dbo.BMPM8Detail.partname3
	,case  when dbx.dbo.BMPM8Detail.partname3 is null or dbx.dbo.BMPM8Detail.partname3 = '' then '-'
			else dbx.dbo.BMPM8Detail.partname3 end As partname3
	,dbx.dbo.BMPM8Detail.parttype3
	,dbx.dbo.BMPM8Detail.partquantity3
	--,dbx.dbo.BMPM8Detail.partname4
	,case  when dbx.dbo.BMPM8Detail.partname4 is null or dbx.dbo.BMPM8Detail.partname4 = '' then '-'
			else dbx.dbo.BMPM8Detail.partname4 end As partname4
	,dbx.dbo.BMPM8Detail.parttype4
	,dbx.dbo.BMPM8Detail.partquantity4
	,dbx.dbo.BMMaintenance.Mcneed
	,dbx.dbo.BMMaintenance.Inchanger
	
	,dbx.dbo.BMMaintenance.BMNoID
	,dbx.dbo.BMMaintenance.BMCaseID
	,dbx.dbo.BMMaintenance.BMUnitID
	,dbx.dbo.BMMaintenance.PositionID
	,dbx.dbo.BMMaintenance.WorkContentID
	,dbx.dbo.BMMaintenance.BMCauseID
	,dbx.dbo.BMPM8Detail.packageno
	,dbx.dbo.BMPM8Detail.period
	,case  when (datediff(mi,(dbx.dbo.BMMaintenance.TimeRequest),dbx.dbo.BMMaintenance.TimeStart)) < 0 then '-'
		   else (datediff(mi,(dbx.dbo.BMMaintenance.TimeRequest),dbx.dbo.BMMaintenance.TimeStart)) end As MinWaitTime
	,case  when (datediff(mi,(dbx.dbo.BMMaintenance.TimeStart),dbx.dbo.BMMaintenance.TimeFinish)) < 0 then '-'
		   else (datediff(mi,(dbx.dbo.BMMaintenance.TimeStart),dbx.dbo.BMMaintenance.TimeFinish)) end As MinRepairTime
	,case  when (datediff(mi,(dbx.dbo.BMMaintenance.TimeRequest),dbx.dbo.BMMaintenance.TimeFinish)) < 0 then '-' 
		   else	(datediff(mi,(dbx.dbo.BMMaintenance.TimeRequest),dbx.dbo.BMMaintenance.TimeFinish)) end As MinMCStopTime
	,dbx.dbo.BMMaintenance.Restarter As EmpRestart
	,dbx.dbo.BMMaintenance.Approver As EmpApprove
	from dbx.dbo.BMMaintenance,dbx.dbo.BMPM8Detail
	where dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM8Detail.BM_ID 
	and dbx.dbo.BMMaintenance.ID = @bmid


END

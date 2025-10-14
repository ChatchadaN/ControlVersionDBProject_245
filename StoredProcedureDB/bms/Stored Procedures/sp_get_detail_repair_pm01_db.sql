-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_detail_repair_pm01_db]
	-- Add the parameters for the stored procedure here
	@bmid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select dbx.dbo.BMMaintenance.categoryid
	,dbx.dbo.BMMaintenance.ProcessID
	,dbx.dbo.BMMaintenance.AQI
	,dbx.dbo.BMMaintenance.MachineID
	,dbx.dbo.BMMaintenance.Requestor
	,dbx.dbo.BMMaintenance.LotNo
	,dbx.dbo.BMMaintenance.Device
	,dbx.dbo.BMPM6Detail.AlarmNo
	,dbx.dbo.BMPM6Detail.AlarmName
	,dbx.dbo.BMPM6Detail.frequency1
	,dbx.dbo.BMPM6Detail.frequency2
	,dbx.dbo.BMMaintenance.MCStatus
	,dbx.dbo.BMMaintenance.Package
	,dbx.dbo.BMPM6Detail.FrameNo
	,dbx.dbo.BMMaintenance.Problem
	,dbx.dbo.BMMaintenance.Problem2
	,case when dbx.dbo.BMMaintenance.Problem !='' and dbx.dbo.BMMaintenance.Problem != 'OTHER' then dbx.dbo.BMMaintenance.Problem
		  when  dbx.dbo.BMMaintenance.Problem2 !='' and dbx.dbo.BMMaintenance.Problem2 != 'OTHER' then dbx.dbo.BMMaintenance.Problem2
		  when  dbx.dbo.BMMaintenance.Problem2 is null and dbx.dbo.BMMaintenance.Problem2 != '' then dbx.dbo.BMMaintenance.Problem2
	 end As Problem
	,dbx.dbo.BMMaintenance.Urgent
	,case when dbx.dbo.BMPM6Detail.displayDetail_1 is null then '-'
		  else dbx.dbo.BMPM6Detail.displayDetail_1 end As displayDetail_1
	,case when dbx.dbo.BMPM6Detail.displayDetail2 is null then '-'
		  else dbx.dbo.BMPM6Detail.displayDetail2 end As displayDetail2
	,case when dbx.dbo.BMPM6Detail.whyI is null then '-'
		  else dbx.dbo.BMPM6Detail.whyI end As whyI
	,case when dbx.dbo.BMPM6Detail.whyII is null then '-'
		  else dbx.dbo.BMPM6Detail.whyII end As whyII
	,case when dbx.dbo.BMPM6Detail.whyIII is null then '-'
		  else dbx.dbo.BMPM6Detail.whyIII end As whyIII
	,case when dbx.dbo.BMPM6Detail.CountermeasureDetails1 is null then '-'
		  else dbx.dbo.BMPM6Detail.CountermeasureDetails1 end As CountermeasureDetails1
	,case when dbx.dbo.BMPM6Detail.CountermeasureDetails2 is null then '-'
		  else dbx.dbo.BMPM6Detail.CountermeasureDetails2 end As CountermeasureDetails2
	,case when dbx.dbo.BMPM6Detail.CountermeasureDetails3 is null then '-'
		  else dbx.dbo.BMPM6Detail.CountermeasureDetails3 end As CountermeasureDetails3
	,case when dbx.dbo.BMPM6Detail.CountermeasureDetails4 is null then '-'
		  else dbx.dbo.BMPM6Detail.CountermeasureDetails4 end As CountermeasureDetails4
	,case when dbx.dbo.BMPM6Detail.TreatmentDetail1 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentDetail1 end As TreatmentDetail1
	,case when dbx.dbo.BMPM6Detail.TreatmentDetail2 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentDetail2 end As TreatmentDetail2
	,case when dbx.dbo.BMPM6Detail.TreatmentDetail3 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentDetail3 end As TreatmentDetail3
	,case when dbx.dbo.BMPM6Detail.TreatmentDetail4 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentDetail4 end As TreatmentDetail4
	,case when dbx.dbo.BMPM6Detail.TreatmentDetail5 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentDetail5 end As TreatmentDetail5
	,dbx.dbo.BMPM6Detail.LotNoAfter
	,dbx.dbo.BMPM6Detail.DeviceAfter
	,case when dbx.dbo.BMPM6Detail.TreatmentContent1 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentContent1 end As TreatmentContent1
	,case when dbx.dbo.BMPM6Detail.TreatmentBefore1 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentBefore1 end As TreatmentBefore1
	,case when dbx.dbo.BMPM6Detail.TreatmentAfter1 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentAfter1 end As TreatmentAfter1
	,case when dbx.dbo.BMPM6Detail.TreatmentContent2 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentContent2 end As TreatmentContent2
	,case when dbx.dbo.BMPM6Detail.TreatmentBefore2 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentBefore2 end As TreatmentBefore2
	,case when dbx.dbo.BMPM6Detail.TreatmentAfter2 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentAfter2 end As TreatmentAfter2
	,case when dbx.dbo.BMPM6Detail.TreatmentContent3 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentContent3 end As TreatmentContent3
	,case when dbx.dbo.BMPM6Detail.TreatmentBefore3 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentBefore3 end As TreatmentBefore3
	,case when dbx.dbo.BMPM6Detail.TreatmentAfter3 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentAfter3 end As TreatmentAfter3
	,case when dbx.dbo.BMPM6Detail.TreatmentContent4 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentContent4 end As TreatmentContent4
	,case when dbx.dbo.BMPM6Detail.TreatmentBefore4 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentBefore4 end As TreatmentBefore4
	,case when dbx.dbo.BMPM6Detail.TreatmentAfter4 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentAfter4 end As TreatmentAfter4
	,case when dbx.dbo.BMPM6Detail.TreatmentContent5 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentContent5 end As TreatmentContent5
	,case when dbx.dbo.BMPM6Detail.TreatmentBefore5 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentBefore5 end As TreatmentBefore5
	,case when dbx.dbo.BMPM6Detail.TreatmentAfter5 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentAfter5 end As TreatmentAfter5
	,case when dbx.dbo.BMPM6Detail.TreatmentContent6 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentContent6 end As TreatmentContent6
	,case when dbx.dbo.BMPM6Detail.TreatmentBefore6 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentBefore6 end As TreatmentBefore6
	,case when dbx.dbo.BMPM6Detail.TreatmentAfter6 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentAfter6 end As TreatmentAfter6
	,case when dbx.dbo.BMPM6Detail.TreatmentContent7 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentContent7 end As TreatmentContent7
	,case when dbx.dbo.BMPM6Detail.TreatmentBefore7 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentBefore7 end As TreatmentBefore7
	,case when dbx.dbo.BMPM6Detail.TreatmentAfter7 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentAfter7 end As TreatmentAfter7
	,case when dbx.dbo.BMPM6Detail.TreatmentContent8 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentContent8 end As TreatmentContent8
	,case when dbx.dbo.BMPM6Detail.TreatmentBefore8 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentBefore8 end As TreatmentBefore8
	,case when dbx.dbo.BMPM6Detail.TreatmentAfter8 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentAfter8 end As TreatmentAfter8
	,case when dbx.dbo.BMPM6Detail.TreatmentContent9 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentContent9 end As TreatmentContent9
	,case when dbx.dbo.BMPM6Detail.TreatmentBefore9 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentBefore9 end As TreatmentBefore9
	,case when dbx.dbo.BMPM6Detail.TreatmentAfter9 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentAfter9 end As TreatmentAfter9
	,case when dbx.dbo.BMPM6Detail.TreatmentContent10 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentContent10 end As TreatmentContent10
	,case when dbx.dbo.BMPM6Detail.TreatmentBefore10 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentBefore10 end As TreatmentBefore10
	,case when dbx.dbo.BMPM6Detail.TreatmentAfter10 is null then '-'
		  else dbx.dbo.BMPM6Detail.TreatmentAfter10 end As TreatmentAfter10
	,case when dbx.dbo.BMPM6Detail.OPConfirmRequestDetail is null then '-'
		  else dbx.dbo.BMPM6Detail.OPConfirmRequestDetail end As OPConfirmRequestDetail
	,case when dbx.dbo.BMPM6Detail.DumyInPcs is null then '-'
		  else dbx.dbo.BMPM6Detail.DumyInPcs end As DumyInPcs
	,dbx.dbo.BMPM6Detail.coverSW
	,case when dbx.dbo.BMPM6Detail.WriteConditioCheckItemBefore is null then '-'
		  when dbx.dbo.BMPM6Detail.WriteConditioCheckItemBefore != '' then dbx.dbo.BMPM6Detail.WriteConditioCheckItemBefore + '/' + dbx.dbo.BMPM6Detail.WriteConditioCheckItemAfter + '' + dbx.dbo.BMPM6Detail.WriteConditioCheckItemAfter
		  end As WriteConditioCheckItemBefore
	--,dbx.dbo.BMPM6Detail.WriteConditioCheckItemBefore
	--,dbx.dbo.BMPM6Detail.WriteConditioCheckItemAfter
	--,dbx.dbo.BMPM6Detail.InspectionRequestDetail
	,dbx.dbo.BMPM6Detail.SavetyCover
	,dbx.dbo.BMPM6Detail.Check4s
	,dbx.dbo.BMPM6Detail.NoMarkBefore
	,dbx.dbo.BMPM6Detail.NoMarkAfter
	,dbx.dbo.BMPM6Detail.WBData300
	,dbx.dbo.BMPM6Detail.MarkMisBefore
	,dbx.dbo.BMPM6Detail.MarkMisAfter
	,dbx.dbo.BMPM6Detail.WBData301
	,dbx.dbo.BMPM6Detail.MarkCutBefore
	,dbx.dbo.BMPM6Detail.MarkCutAfter
	,dbx.dbo.BMPM6Detail.WBData302
	,dbx.dbo.BMPM6Detail.MekkiHigeBefore
	,dbx.dbo.BMPM6Detail.MekkiHigeAfter
	,dbx.dbo.BMPM6Detail.WBData303
	,dbx.dbo.BMPM6Detail.NGRateBefore
	,dbx.dbo.BMPM6Detail.NGRateAfter
	,dbx.dbo.BMPM6Detail.WBData304
	,dbx.dbo.BMPM6Detail.BunruiCheckBefore
	,dbx.dbo.BMPM6Detail.BunruiCheckAfter
	,dbx.dbo.BMPM6Detail.WBData305
	,dbx.dbo.BMPM6Detail.LeadBentBefore
	,dbx.dbo.BMPM6Detail.LeadBentAfter
	,dbx.dbo.BMPM6Detail.WBData306
	,dbx.dbo.BMPM6Detail.KakeCrackKajiriBefore
	,dbx.dbo.BMPM6Detail.KakeCrackKajiriAfter
	,dbx.dbo.BMPM6Detail.WBData307
	,dbx.dbo.BMPM6Detail.AdhesionBefore
	,dbx.dbo.BMPM6Detail.AdhesionAfter
	,dbx.dbo.BMPM6Detail.WBData308
	,dbx.dbo.BMPM6Detail.CoverTapeBefore
	,dbx.dbo.BMPM6Detail.CoverTapeAfter
	,dbx.dbo.BMPM6Detail.WBData309
	,dbx.dbo.BMPM6Detail.PartNo1
	,dbx.dbo.BMPM6Detail.PartName1
	,dbx.dbo.BMPM6Detail.PartType1
	,dbx.dbo.BMPM6Detail.ReplacedQty1
	,dbx.dbo.BMPM6Detail.PartNo2
	,dbx.dbo.BMPM6Detail.PartName2
	,dbx.dbo.BMPM6Detail.PartType2
	,dbx.dbo.BMPM6Detail.ReplacedQty2
	,dbx.dbo.BMPM6Detail.PartNo3
	,dbx.dbo.BMPM6Detail.PartName3
	,dbx.dbo.BMPM6Detail.PartType3
	,dbx.dbo.BMPM6Detail.ReplacedQty3
	,dbx.dbo.BMPM6Detail.PartNo4
	,dbx.dbo.BMPM6Detail.PartName4
	,dbx.dbo.BMPM6Detail.PartType4
	,dbx.dbo.BMPM6Detail.ReplacedQty4
	,dbx.dbo.BMPM6Detail.TreatmentDetail6
	,dbx.dbo.BMPM6Detail.TreatmentDetail7
	,dbx.dbo.BMMaintenance.Inchanger
	,dbx.dbo.BMMaintenance.BMNoID
	,dbx.dbo.BMMaintenance.BMCaseID
	,dbx.dbo.BMMaintenance.BMUnitID
	,dbx.dbo.BMMaintenance.PositionID
	,dbx.dbo.BMMaintenance.WorkContentID
	,dbx.dbo.BMMaintenance.BMCauseID
	,dbx.dbo.BMMaintenance.PreventionID
	from dbx.dbo.BMMaintenance,dbx.dbo.BMPM6Detail
	where dbx.dbo.BMMaintenance.ID = @bmid
	and dbx.dbo.BMMaintenance.ID = dbx.dbo.BMPM6Detail.BM_ID

END

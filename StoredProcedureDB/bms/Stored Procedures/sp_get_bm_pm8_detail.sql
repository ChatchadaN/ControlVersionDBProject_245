-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_bm_pm8_detail]
	-- Add the parameters for the stored procedure here
	@bmid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select alarmNo,alarmName,frequency1,frequency2,whyI,whyII,whyIII,chkmanlot,chk4s,chkdummy,chkdummypcs,Detail1,valuesDetail1_1,valuesDetail1_2,Detail2,valuesDetail2_1,valuesDetail2_2,
	Detail3,valuesDetail3_1,valuesDetail3_2,Detail4,valuesDetail4_1,valuesDetail4_2,Detail5,valuesDetail5_1,valuesDetail5_2,Detail6,valuesDetail6_1,valuesDetail6_2
	Detail7,valuesDetail7_1,valuesDetail7_2,chkjobng1,chkjobng2,bechgtype,afchgtype,bechkcover,afchkcover,bemount,beBlade,afmount,afBlade,beprobepin,afprobepin,
	BeNeedle,BeVacPad,BeChuck,bepartseal,bepartiron,beneedle,afneedle,bevacpad,afvacpad,chkbegood,chkbeng,chkbetotal,chkbemecha,chkafgood,chkafmecha,SpindleRevo,
	WorkTrick,BlackHeighr,FeedSpeed,WaterBlade,WaterSlow,WaterSpray,PickupEject1,PickupEject2,PickupEjectSpeed,PickupEjectLevel,PickupEjectIronTem,PickupEjectSealing,
	chkbeqcFrame,hckafqcFrame,chkbeqcmark,chkafqcmark,chkbeqcTape,chkafqcTape,chkbeqcLead,chkafqcLead,chkbeqcmode,chkafqcmode,partname1,parttype1,partquantity1,
	partname2,parttype2,partquantity2,partname3,parttype3,partquantity3,partname4,parttype4,partquantity4,Period,chkaqi,afchuck,afpartseal,afpartiron,chkafng,chkaftotal,
	PickupEjectSpeed
	from dbx.dbo.BMPM8Detail where bm_id = @bmid
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_kanagata_total_record_endlot_FL_v2]
-- Add the parameters for the stored procedure here
		@KanagataName as varchar(50) ='%'
		,@Date as datetime 
		,@ToDate as datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--INSERT INTO [JIG].[KanagataSearch]
 --          ([KanagataNo]
 --          ,[Date]
 --          ,[ToDate])
 --    VALUES (@KanagataName,@Date,@ToDate)
	 
    -- Insert statements for procedure here
	SELECT * FROM
	(SELECT APCSProDB.trans.jig_records.id
	,CONVERT(varchar,record_at,106) as RecordTime1
	,(SELECT LotNo = Node.Data.value('(LotNo)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS LotNo
	,(SELECT MCType = Node.Data.value('(MCType)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS MCType
	,(SELECT Package = Node.Data.value('(Package)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS Package	
	,ISNULL((SELECT TieBarPunchMax = Node.Data.value('(TieBarPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS TieBarPunchMax	
	,ISNULL((SELECT TieBarDieMax = Node.Data.value('(TieBarDieMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS TieBarDieMax
	,ISNULL((SELECT CurvePunchMax = Node.Data.value('(CurvePunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS CurvePunchMax
	,ISNULL((SELECT LeadCutPunchMax = Node.Data.value('(LeadCutPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LeadCutPunchMax
	,ISNULL((SELECT GuidePostMax = Node.Data.value('(GuidePostMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS GuidePostMax
	,ISNULL((SELECT GuideBushuMax = Node.Data.value('(GuideBushuMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS GuideBushuMax
	,ISNULL((SELECT LeadDieMax = Node.Data.value('(LeadDieMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LeadDieMax
	,ISNULL((SELECT LeadDieEXMax = Node.Data.value('(LeadDieEXMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LeadDieEXMax
    ,ISNULL((SELECT SupportPunchMax = Node.Data.value('(SupportPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS SupportPunchMax
	,ISNULL((SELECT SupportDieMax = Node.Data.value('(SupportDieMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS SupportDieMax
	,ISNULL((SELECT FinCutPunchMax = Node.Data.value('(FinCutPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS FinCutPunchMax
	,ISNULL((SELECT FinCutDieMax = Node.Data.value('(FinCutDieMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS FinCutDieMax
	,ISNULL((SELECT CumMax = Node.Data.value('(CumMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS CumMax
	,ISNULL((SELECT DieBlockMax = Node.Data.value('(DieBlockMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS DieBlockMax
	,ISNULL((SELECT FlashPunchMax = Node.Data.value('(FlashPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS FlashPunchMax
	,ISNULL((SELECT SubGatePunchMax = Node.Data.value('(SubGatePunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS SubGatePunchMax
	
	,(SELECT KanagataName = Node.Data.value('(KanagataName)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS KanagataName
	,CONVERT(varchar(50),FORMAT(record_at,'yyyy/MM/dd HH:mm')) as RecordTime
	,ISNULL((SELECT ShotCount = Node.Data.value('(ShotCount)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS ShotCount
	,(SELECT MCNo = Node.Data.value('(MCNo)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS MCNo	

	FROM	APCSProDB.trans.jig_records	 
	INNER JOIN APCSProDB.trans.jigs		 
	ON		jigs.id =  jig_records.jig_id
	WHERE	jigs.qrcodebyuser =  @KanagataName  
	AND		jig_records.extend_data IS NOT NULL
	AND		jig_records.record_at BETWEEN CONVERT(varchar(50),FORMAT(@Date,'yyyy/MM/dd HH:mm')) 
	AND		CONVERT(varchar(50),FORMAT(@ToDate,'yyyy/MM/dd HH:mm'))
	) AS KanagataRecord
	ORDER BY id DESC
END

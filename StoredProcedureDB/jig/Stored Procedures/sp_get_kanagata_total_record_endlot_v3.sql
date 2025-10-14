-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_kanagata_total_record_endlot_v3]
-- Add the parameters for the stored procedure here
		@KanagataName as varchar(50) ='%'
		,@Date as datetime 
		,@ToDate as datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @root_id as int

	SET @root_id = (SELECT root_jig_id FROM APCSProDB.trans.jigs WHERE qrcodebyuser = @KanagataName)

	SELECT KanagataRecord.* 
	FROM
	(SELECT APCSProDB.trans.jig_records.id
	,(SELECT LotNo = Node.Data.value('(LotNo)[1]', 'Varchar(10)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS LotNo
	,CONVERT(varchar(50),FORMAT(record_at,'yyyy/MM/dd HH:mm')) as RecordTime
	,(SELECT MCNo = Node.Data.value('(MCNo)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS MCNo	
	,ISNull((SELECT TieBarCutDieMax = Node.Data.value('(TieBarCutDieMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS TieBarCutDieMax
	,ISNull((SELECT TieBarCutPunchMax = Node.Data.value('(TieBarCutPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS TieBarCutPunchMax
	,ISNull((SELECT SupportDieMax = Node.Data.value('(SupportDieMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS SupportDieMax
	,ISNull((SELECT SupportPunchMax = Node.Data.value('(SupportPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS SupportPunchMax
	,ISNull((SELECT FlashPunchMax = Node.Data.value('(FlashPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS FlashPunchMax
	,ISNull((SELECT GateCutPunchMax = Node.Data.value('(GateCutPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS GateCutPunchMax
	,ISNull((SELECT FrameCutPunchMax = Node.Data.value('(FrameCutPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS FrameCutPunchMax
    ,ISNull((SELECT FrameCutDieMax = Node.Data.value('(FrameCutDieMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS FrameCutDieMax
	,ISNull((SELECT StripperGuidePunchMax = Node.Data.value('(StripperGuidePunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS StripperGuidePunchMax
	,(SELECT KanagataName = Node.Data.value('(KanagataName)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS KanagataName
	,ISNull((SELECT ShotCount = Node.Data.value('(ShotCount)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS ShotCount
	,(SELECT MCType = Node.Data.value('(MCType)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS MCType
	,(SELECT Package = Node.Data.value('(Package)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS Package
	,ISNull((SELECT PilotPinMax = Node.Data.value('(PilotPinMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS PilotPinMax
	,ISNull((SELECT OverHualMax = Node.Data.value('(OverHualMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS OverHualMax
	,ISNull((SELECT FinGateCutDieMax = Node.Data.value('(FinGateCutDieMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS FinGateCutDieMax
	,ISNull((SELECT FinCutPunchMax = Node.Data.value('(FinCutPunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS FinCutPunchMax
	,ISNull((SELECT TieBarGuidePunchMax = Node.Data.value('(TieBarGuidePunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS TieBarGuidePunchMax	
	,ISNull((SELECT SupportGuidePunchMax = Node.Data.value('(SupportGuidePunchMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS SupportGuidePunchMax
	,ISNull((SELECT DieBlockMax = Node.Data.value('(DieBlockMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0)AS DieBlockMax
	,'' AS Comment 
	,'' AS PMNo 
	,'' AS ResetTime 
	FROM APCSProDB.trans.jig_records	 
	INNER JOIN APCSProDB.trans.jigs		 
	ON		jigs.id =  jig_records.jig_id
	WHERE	jigs.root_jig_id =  @root_id  
	AND		jig_records.extend_data IS NOT NULL
	AND		jig_records.record_at BETWEEN CONVERT(varchar(50),FORMAT(@Date,'yyyy/MM/dd HH:mm')) 
	AND		CONVERT(varchar(50),FORMAT(@ToDate,'yyyy/MM/dd HH:mm'))
	)	AS KanagataRecord 
	ORDER BY id DESC
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_kanagata_total_record_endlot_MP]
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
	,ISNull((SELECT UpperMainCavityBlockMax = Node.Data.value('(UpperMainCavityBlockMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS UpperMainCavityBlockMax
	,ISNull((SELECT UpperCullBlockMax = Node.Data.value('(UpperCullBlockMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS UpperCullBlockMax
	,ISNull((SELECT UpperCullGateEjectorPinMax = Node.Data.value('(UpperCullGateEjectorPinMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS UpperCullGateEjectorPinMax
	,ISNull((SELECT UpperFrameEjectorPinMax = Node.Data.value('(UpperFrameEjectorPinMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS UpperFrameEjectorPinMax
	,ISNull((SELECT UpperPkgEjectorPinMax = Node.Data.value('(UpperPkgEjectorPinMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS UpperPkgEjectorPinMax
	,ISNull((SELECT UpperPilotE_PinMax = Node.Data.value('(UpperPilotE_PinMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS UpperPilotE_PinMax
	,ISNull((SELECT UpperResinStopperPieceMax = Node.Data.value('(UpperResinStopperPieceMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS UpperResinStopperPieceMax
    ,ISNull((SELECT LowerMainCavityBlockMax = Node.Data.value('(LowerMainCavityBlockMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LowerMainCavityBlockMax
	,ISNull((SELECT LowerPotBlockMax = Node.Data.value('(LowerPotBlockMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LowerPotBlockMax
	,ISNull((SELECT LowerCullGateEjectorPinMax = Node.Data.value('(LowerCullGateEjectorPinMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LowerCullGateEjectorPinMax
	,ISNull((SELECT LowerFrameEjectorPinMax = Node.Data.value('(LowerFrameEjectorPinMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LowerFrameEjectorPinMax
	,ISNull((SELECT LowerPkgEjectorPinMax = Node.Data.value('(LowerPkgEjectorPinMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LowerPkgEjectorPinMax
	,ISNull((SELECT LowerResinStopperPieceMax = Node.Data.value('(LowerResinStopperPieceMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LowerResinStopperPieceMax
	,ISNull((SELECT LowerRoundPilotPinMax = Node.Data.value('(LowerRoundPilotPinMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LowerRoundPilotPinMax
	,ISNull((SELECT LowerDia_CutPilotPinMax = Node.Data.value('(LowerDia_CutPilotPinMax)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS LowerDia_CutPilotPinMax
	,(SELECT KanagataName = Node.Data.value('(KanagataName)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS KanagataName
	,ISNull((SELECT ShotCount = Node.Data.value('(ShotCount)[1]', 'INT') FROM extend_data.nodes('EndLots/EndLot') Node(Data)),0) AS ShotCount
	,(SELECT MCType = Node.Data.value('(MCType)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS MCType
	,(SELECT Package = Node.Data.value('(Package)[1]', 'Varchar(50)') FROM extend_data.nodes('EndLots/EndLot') Node(Data)) AS Package
	FROM	APCSProDB.trans.jig_records	 
	INNER JOIN APCSProDB.trans.jigs		 
	ON		jigs.id =  jig_records.jig_id
	WHERE	jigs.root_jig_id =  @root_id  
	AND		jig_records.extend_data IS NOT NULL
	AND		jig_records.record_at BETWEEN CONVERT(varchar(50),FORMAT(@Date,'yyyy/MM/dd HH:mm')) 
	AND		CONVERT(varchar(50),FORMAT(@ToDate,'yyyy/MM/dd HH:mm'))
	) AS KanagataRecord 
	
	ORDER BY id DESC
END

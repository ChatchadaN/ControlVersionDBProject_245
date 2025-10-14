-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_lsisearch_workrecord_xml_FT]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(20) = '%'
	, @process varchar(50) = '%'
	, @jobs varchar(50) = '%'
	, @machine varchar(50) = '%'
	, @opNo varchar(50) = '%'
	, @packages varchar(50) = '%'
	, @device varchar(50) = '%'
	, @status varchar(50) = '%'
	, @start_time DATETIME = ''
	, @end_time DATETIME = ''
	, @packageGroup varchar(50) = '%'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @status = CASE WHEN @status = 'LotStart' THEN 'FirstInspection' ELSE @status END

    -- Insert statements for procedure here
	BEGIN
		SELECT
			_record.id
			--,_xml.extend_data
			,_record.lot_id
			,_lots.lot_no

			,_pkg.name	AS package_group
			,_pk.name	AS packages
			,_dv.name	AS device	
			,_pc.name AS process
			,_jb.name AS jobs
			,_record.step_no
			,_md.name	AS MCType
			,_mc.name	AS machines		
			,_record.record_class
			,CASE WHEN item_labels.label_eng = 'FirstInspection' THEN 'LotStart' ELSE item_labels.label_eng END AS label_eng
			,_record.recorded_at 

			,ISNull(_record.qty_pass,0)			AS input
			,ISNull(_record.qty_last_pass,0)	AS qty_pass
			,ISNull(_record.qty_last_fail,0)	AS qty_fail
			,ISNull(_record.qty_p_nashi,0)		AS p_nashi
			,ISNull(_record.qty_front_ng,0)		AS qty_front_ng
			,ISNull(_record.qty_marker,0)		AS qty_marker
			,ISNull(_record.qty_combined,0)		AS qty_combined
			,ISNull(_record.qty_hasuu,0)		AS qty_hasuu
			,ISNull(_record.qty_out,0)			AS qty_out
			,ISNull(LAG( _record.qty_frame_pass, 1, _record.qty_frame_in ) OVER ( ORDER BY _record.step_no ),0) AS qty_frame_in
			,ISNull(_record.qty_frame_pass,0)	AS qty_frame_pass
			,ISNull(_record.qty_frame_fail,0)	AS qty_frame_fail
			, users.emp_num
			,_record.carrier_no
			,(SELECT Recipe				= Node.Data.value('(Recipe)[1]', 'VARCHAR(MAX)')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS recipe

			,ISNull((SELECT InputQty		= Node.Data.value('(InputQty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS InputQty
			,ISNull((SELECT GoodQty		= Node.Data.value('(GoodQty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS GoodQty
			,ISNull((SELECT NgQty		= Node.Data.value('(NgQty)[1]', 'INT') 			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS NgQty		
			,ISNull((SELECT InputAdjustQty		= Node.Data.value('(InputAdjustQty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS InputAdjustQty
			,ISNull((SELECT GoodAdjustQty		= Node.Data.value('(GoodAdjustQty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS GoodAdjustQty
			,ISNull((SELECT NgAdjustQty		= Node.Data.value('(NgAdjustQty)[1]', 'INT') 			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS NgAdjustQty		
			,(SELECT Yield				= Node.Data.value('(Yield)[1]', 'VARCHAR(MAX)')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS Yield
			,(SELECT Unit				= Node.Data.value('(Unit)[1]', 'VARCHAR(MAX)')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS Unit
			,(SELECT State				= Node.Data.value('(State)[1]', 'VARCHAR(MAX)') 			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS State
			,(SELECT AlarmTotal			= Node.Data.value('(AlarmTotal)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS AlarmTotal
			,(SELECT IsAbnormal			= Node.Data.value('(IsAbnormal)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS IsAbnormal
			,(SELECT OPRate				= Node.Data.value('(OPRate)[1]', 'VARCHAR(MAX)')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS OPRate
			,(SELECT MaximumRPM			= Node.Data.value('(MaximumRPM)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS MaximumRPM
			,(SELECT AverageRPM			= Node.Data.value('(AverageRPM)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS AverageRPM
			,(SELECT MTBF				= Node.Data.value('(MTBF)[1]', 'VARCHAR(MAX)')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS MTBF
			,(SELECT MTTR				= Node.Data.value('(MTTR)[1]', 'VARCHAR(MAX)')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS MTTR
			,(SELECT RunDuration		= Node.Data.value('(RunDuration)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS RunDuration
			,(SELECT AlarmDuration		= Node.Data.value('(AlarmDuration)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS AlarmDuration
			,(SELECT StopDuration		= Node.Data.value('(StopDuration)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS StopDuration
			,ISNull((SELECT FrameGoodAdjust		= Node.Data.value('(FrameGoodAdjust)[1]', 'INT')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FrameGoodAdjust
			,ISNull((SELECT FrameGood			= Node.Data.value('(FrameGood)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FrameGood
			,ISNull((SELECT FrameNgAdjust		= Node.Data.value('(FrameNgAdjust)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FrameNgAdjust
			,ISNull((SELECT FrameNg				= Node.Data.value('(FrameNg)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FrameNg
			,ISNull((SELECT FrameInputAdjust	= Node.Data.value('(FrameInputAdjust)[1]', 'INT')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FrameInputAdjust
			,ISNull((SELECT FrameInput			= Node.Data.value('(FrameInput)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FrameInput
			,ISNull((SELECT PcsPerWork			= Node.Data.value('(PcsPerWork)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS PcsPerWork
			,ISNull((SELECT PcsPerTubeorTray	= Node.Data.value('(PcsPerTubeorTray)[1]', 'INT')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS PcsPerTubeorTray
			,ISNull((SELECT FrontNg				= Node.Data.value('(FrontNg)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FrontNg
			,ISNull((SELECT FrontNg_Scrap		= Node.Data.value('(FrontNg_Scrap)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FrontNg_Scrap
			,ISNull((SELECT MarkerNg			= Node.Data.value('(MarkerNg)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS MarkerNg
			,ISNull((SELECT MarkerNg_Scrap		= Node.Data.value('(MarkerNg_Scrap)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS MarkerNg_Scrap
			,ISNull((SELECT QtyScrap			= Node.Data.value('(QtyScrap)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS QtyScrap
			,ISNull((SELECT P_Nashi				= Node.Data.value('(P_Nashi)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS P_Nashi
			,ISNull((SELECT P_Nashi_Scrap		= Node.Data.value('(P_Nashi_Scrap)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS P_Nashi_Scrap
			,ISNull((SELECT Os_Scrap			= Node.Data.value('(Os_Scrap)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS Os_Scrap
			
			,ISNull((SELECT NeedSBLSYLJudge		= Node.Data.value('(NeedSBLSYLJudge)[1]', 'VARCHAR(MAX)')	FROM _xml.extend_data.nodes('LotDataCommon/SBLSYL') Node(Data)),0)  AS NeedSBLSYLJudge
			,ISNull((SELECT SBLUpperLimit		= Node.Data.value('(SBLUpperLimit)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon/SBLSYL') Node(Data)),0)  AS SBLUpperLimit
			,ISNull((SELECT SYLLowerLimit		= Node.Data.value('(SYLLowerLimit)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon/SBLSYL') Node(Data)),0)  AS SYLLowerLimit
			,ISNull((SELECT SBLResult			= Node.Data.value('(SBLResult)[1]', 'VARCHAR(MAX)')			FROM _xml.extend_data.nodes('LotDataCommon/SBLSYL') Node(Data)),0)  AS SBLResult
			,ISNull((SELECT SYLResult			= Node.Data.value('(SYLResult)[1]', 'VARCHAR(MAX)')			FROM _xml.extend_data.nodes('LotDataCommon/SBLSYL') Node(Data)),0)  AS SYLResult
		
			,ISNull((SELECT FirstGoodBin1Qty	= Node.Data.value('(FirstGoodBin1Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FirstGoodBin1Qty
			,ISNull((SELECT FirstGoodBin2Qty	= Node.Data.value('(FirstGoodBin2Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FirstGoodBin2Qty
			,ISNull((SELECT FirstNGQty			= Node.Data.value('(FirstNGQty)[1]', 'INT')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FirstNGQty
			,ISNull((SELECT FirstMeka1Qty		= Node.Data.value('(FirstMeka1Qty)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FirstMeka1Qty
			,ISNull((SELECT FirstMeka2Qty		= Node.Data.value('(FirstMeka2Qty)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FirstMeka2Qty
			,ISNull((SELECT FirstUnknowQty		= Node.Data.value('(FirstUnknowQty)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FirstUnknowQty
			,ISNull((SELECT SecondGoodBin1Qty	= Node.Data.value('(SecondGoodBin1Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS SecondGoodBin1Qty
			,ISNull((SELECT SecondGoodBin2Qty	= Node.Data.value('(SecondGoodBin2Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS SecondGoodBin2Qty
			,ISNull((SELECT SecondNGQty			= Node.Data.value('(SecondNGQty)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS SecondNGQty
			,ISNull((SELECT SecondMeka1Qty		= Node.Data.value('(SecondMeka1Qty)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS SecondMeka1Qty
			,ISNull((SELECT SecondMeka4Qty		= Node.Data.value('(SecondMeka4Qty)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS SecondMeka4Qty
			,ISNull((SELECT SecondUnknowQty		= Node.Data.value('(SecondUnknowQty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS SecondUnknowQty
			,ISNull((SELECT TotalGoodBin1Qty	= Node.Data.value('(TotalGoodBin1Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalGoodBin1Qty
			,ISNull((SELECT TotalGoodBin2Qty	= Node.Data.value('(TotalGoodBin2Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalGoodBin2Qty
			,ISNull((SELECT TotalNGQty			= Node.Data.value('(TotalNGQty)[1]', 'INT')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalNGQty
			,ISNull((SELECT TotalNGBin17Qty		= Node.Data.value('(TotalNGBin17Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalNGBin17Qty
			,ISNull((SELECT TotalNGBin19PassQty	= Node.Data.value('(TotalNGBin19PassQty)[1]', 'INT')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalNGBin19PassQty
			,ISNull((SELECT TotalNGBin19Qty		= Node.Data.value('(TotalNGBin19Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalNGBin19Qty
			,ISNull((SELECT TotalPassBin27Qty	= Node.Data.value('(TotalPassBin27Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalPassBin27Qty
			,ISNull((SELECT TotalNGBin27Qty		= Node.Data.value('(TotalNGBin27Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalNGBin27Qty
			,ISNull((SELECT TotalMeka1Qty		= Node.Data.value('(TotalMeka1Qty)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalMeka1Qty
			,ISNull((SELECT TotalMeka2Qty		= Node.Data.value('(TotalMeka2Qty)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalMeka2Qty
			,ISNull((SELECT TotalMeka4Qty		= Node.Data.value('(TotalMeka4Qty)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalMeka4Qty
			,ISNull((SELECT TotalUnknowQty		= Node.Data.value('(TotalUnknowQty)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalUnknowQty
			,ISNull((SELECT HandlerCounterQty	= Node.Data.value('(HandlerCounterQty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS HandlerCounterQty
			,ISNull((SELECT TesterACounterQty	= Node.Data.value('(TesterACounterQty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TesterACounterQty
			,ISNull((SELECT TesterBCounterQty	= Node.Data.value('(TesterBCounterQty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TesterBCounterQty
			,ISNull((SELECT TestTemperature		= Node.Data.value('(TestTemperature)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TestTemperature
			,(SELECT TesterType			= Node.Data.value('(TesterType)[1]', 'VARCHAR(MAX)')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS TesterType
			,(SELECT ChannelATesterNo	= Node.Data.value('(ChannelATesterNo)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS ChannelATesterNo
			,(SELECT ChannelBTesterNo	= Node.Data.value('(ChannelBTesterNo)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS ChannelBTesterNo
			,(SELECT BoxName			= Node.Data.value('(BoxName)[1]', 'VARCHAR(MAX)')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS BoxName
			,ISNull((SELECT MarkingInspection				= Node.Data.value('(MarkingInspection)[1]', 'INT')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS MarkingInspection
			,ISNull((SELECT LotStartVisualInspectNGQty		= Node.Data.value('(LotStartVisualInspectNGQty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS LotStartVisualInspectNGQty
			,ISNull((SELECT LotStartVisualInspectTotalQty	= Node.Data.value('(LotStartVisualInspectTotalQty)[1]', 'INT')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS LotStartVisualInspectTotalQty
			,ISNull((SELECT LotEndVisualInspectNGQty		= Node.Data.value('(LotEndVisualInspectNGQty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS LotEndVisualInspectNGQty
			,ISNull((SELECT LotEndVisualInspectTotalQty		= Node.Data.value('(LotEndVisualInspectTotalQty)[1]', 'INT')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS LotEndVisualInspectTotalQty
			,(SELECT LCL				= Node.Data.value('(LCL)[1]',  'VARCHAR(MAX)')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS LCL
			,(SELECT InitialYield		= Node.Data.value('(InitialYield)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS InitialYield
			,(SELECT FirstEndYield		= Node.Data.value('(FirstEndYield)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS FirstEndYield
			,(SELECT FinalYield			= Node.Data.value('(FinalYield)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS FinalYield
			,(SELECT ChannelATestBoxNo	= Node.Data.value('(ChannelATestBoxNo)[1]', 'VARCHAR(MAX)')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS ChannelATestBoxNo
			,(SELECT ChannelBTestBoxNo	= Node.Data.value('(ChannelBTestBoxNo)[1]', 'VARCHAR(MAX)')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS ChannelBTestBoxNo
			,(SELECT FirstAutoAsiCheck	= Node.Data.value('(FirstAutoAsiCheck)[1]','VARCHAR(MAX)')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS FirstAutoAsiCheck
			,(SELECT SocketChange		= Node.Data.value('(SocketChange)[1]','VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS SocketChange
			,(SELECT TubeorTray			= Node.Data.value('(TubeorTray)[1]','INT')					FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS TubeorTray
			,(SELECT GoodinTubeorTray	= Node.Data.value('(GoodinTubeorTray)[1]','INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS GoodinTubeorTray
			,(SELECT HasuuinTubeorTray	= Node.Data.value('(HasuuinTubeorTray)[1]','INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS HasuuinTubeorTray
			,(SELECT LotJudgement		= Node.Data.value('(LotJudgement)[1]','VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS LotJudgement
			,(SELECT Remark				= Node.Data.value('(Remark)[1]','VARCHAR(MAX)')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS Remark

			From APCSProDB.trans.lot_process_records AS _record
			LEFT JOIN APCSProDB.trans.lot_extend_records AS _xml with (NOLOCK) ON _xml.id = _record.id
			INNER JOIN APCSProDB.trans.lots AS _lots with (NOLOCK) ON _lots.id = _record.lot_id
			INNER JOIN APCSProDB.method.processes AS _pc with (NOLOCK) ON _pc.id = _record.process_id
			INNER JOIN APCSProDB.method.jobs AS _jb with (NOLOCK) ON _jb.id = _record.job_id

			INNER JOIN APCSProDB.method.packages AS _pk with (NOLOCK) ON _lots.act_package_id = _pk.id
			INNER JOIN APCSProDB.method.package_groups AS _pkg with (NOLOCK) ON _pkg.id = _pk.package_group_id
			INNER JOIN APCSProDB.method.device_names AS _dv with (NOLOCK) ON _lots.act_device_name_id = _dv.id
			INNER JOIN APCSProDB.mc.machines AS _mc with (NOLOCK) ON _mc.id = _record.machine_id
			INNER JOIN APCSProDB.mc.models AS _md with (NOLOCK) ON _md.id = _mc.machine_model_id

			INNER JOIN [APCSProDB].[trans].[item_labels] with (NOLOCK) ON [item_labels].[name] = 'lot_process_records.record_class' 
			AND [item_labels].[val] = _record.record_class
			INNER JOIN APCSProDB.man.users with (NOLOCK) ON _record.operated_by = users.id

		WHERE _lots.lot_no LIKE @lot_no
				AND _record.record_class in (13,2)  --13 FirstInsp/2 LotEnd
				AND _pc.name LIKE @process
				AND _jb.name LIKE @jobs
				AND _mc.name LIKE @machine
				AND _pk.name LIKE @packages
				AND _dv.name LIKE @device
				AND users.emp_num LIKE @opNo
				AND item_labels.label_eng LIKE @status
				AND _pkg.name LIKE @packageGroup
				AND _record.recorded_at BETWEEN @start_time AND @end_time
		ORDER BY _record.id desc
		--offset 10 rows fetch next 10 rows only

	END
END

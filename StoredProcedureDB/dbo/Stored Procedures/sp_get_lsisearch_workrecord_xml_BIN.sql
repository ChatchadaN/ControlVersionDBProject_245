-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_lsisearch_workrecord_xml_BIN]
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

			,(SELECT InputQty			= Node.Data.value('(InputQty)[1]', 'INT')			   FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS InputQty
			,(SELECT InputAdjustQty		= Node.Data.value('(InputAdjustQty)[1]', 'INT')		   FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS InputAdjustQty
			,(SELECT GoodQty			= Node.Data.value('(GoodQty)[1]', 'INT')			   FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS GoodQty
			,(SELECT GoodAdjustQty		= Node.Data.value('(GoodAdjustQty)[1]', 'INT')		   FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS GoodAdjustQty
			,(SELECT NgQty				= Node.Data.value('(NgQty)[1]', 'INT')				   FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS NgQty
			,(SELECT NgAdjustQty		= Node.Data.value('(NgAdjustQty)[1]', 'INT') 		   FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS NgAdjustQty
			,(SELECT Yield				= Node.Data.value('(Yield)[1]', 'VARCHAR(MAX)')		   FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS Yield
			,(SELECT State				= Node.Data.value('(State)[1]', 'VARCHAR(MAX)') 	   FROM _xml.extend_data.nodes('LotDataCommon') Node(Data))  AS State
	
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
			,ISNull((SELECT FrontNg				= Node.Data.value('(FrontNg)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FrontNg
			,ISNull((SELECT FrontNg_Scrap		= Node.Data.value('(FrontNg_Scrap)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS FrontNg_Scrap
			,ISNull((SELECT MarkerNg			= Node.Data.value('(MarkerNg)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS MarkerNg
			,ISNull((SELECT MarkerNg_Scrap		= Node.Data.value('(MarkerNg_Scrap)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS MarkerNg_Scrap
			,ISNull((SELECT QtyScrap			= Node.Data.value('(QtyScrap)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS QtyScrap
			,ISNull((SELECT P_Nashi				= Node.Data.value('(P_Nashi)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS P_Nashi
			,ISNull((SELECT P_Nashi_Scrap		= Node.Data.value('(P_Nashi_Scrap)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS P_Nashi_Scrap
			,ISNull((SELECT Os_Scrap			= Node.Data.value('(Os_Scrap)[1]', 'INT')			FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS Os_Scrap
		
			,ISNull((SELECT InsertingNGTotal	= Node.Data.value('(InsertingNGTotal)[1]', 'VARCHAR(MAX)')  FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) ,0) AS InsertingNGTotal
			,ISNull((SELECT BurningNGTotal		= Node.Data.value('(BurningNGTotal)[1]', 'VARCHAR(MAX)') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS BurningNGTotal
			,ISNull((SELECT RemovingNGTotal		= Node.Data.value('(RemovingNGTotal)[1]', 'VARCHAR(MAX)')	  FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0)  AS RemovingNGTotal

			, ISNULL((SELECT BatchNo1NG			= Node.Data.value('(BatchDetails/BatchDetails/InsertingNG)[1]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo1_InsertNG]
			, ISNULL((SELECT BatchNo1NGAdjust	= Node.Data.value('(BatchDetails/BatchDetails/InsertingNGAdjust)[1]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo1_InsertNGAdjust]
			, ISNULL((SELECT BatchNo1BurNG		= Node.Data.value('(BatchDetails/BatchDetails/BurningNG)[1]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo1_BurnNG]
			, ISNULL((SELECT BatchNo1BurNGAdjust= Node.Data.value('(BatchDetails/BatchDetails/BurningNGAdjust)[1]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo1_BurnNGAdjust]
			, ISNULL((SELECT BatchNo1RMNG		= Node.Data.value('(BatchDetails/BatchDetails/RemovingNG)[1]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo1_RemoveNG]
			, ISNULL((SELECT BatchNo1RMNGAdjust	= Node.Data.value('(BatchDetails/BatchDetails/RemovingNGAdjust)[1]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo1_RemoveNGAdjust]

			, ISNULL((SELECT BatchNo2NG			= Node.Data.value('(BatchDetails/BatchDetails/InsertingNG)[2]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo2_InsertNG]
			, ISNULL((SELECT BatchNo2NGAdjust	= Node.Data.value('(BatchDetails/BatchDetails/InsertingNGAdjust)[2]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo2_InsertNGAdjust]
			, ISNULL((SELECT BatchNo2BurNG		= Node.Data.value('(BatchDetails/BatchDetails/BurningNG)[2]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo2_BurnNG]
			, ISNULL((SELECT BatchNo2BurNGAdjust= Node.Data.value('(BatchDetails/BatchDetails/BurningNGAdjust)[2]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo2_BurnNGAdjust]
			, ISNULL((SELECT BatchNo2RMNG		= Node.Data.value('(BatchDetails/BatchDetails/RemovingNG)[2]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo2_RemoveNG]
			, ISNULL((SELECT BatchNo2RMNGAdjust	= Node.Data.value('(BatchDetails/BatchDetails/RemovingNGAdjust)[2]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo2_RemoveNGAdjust]

			, ISNULL((SELECT BatchNo3NG			= Node.Data.value('(BatchDetails/BatchDetails/InsertingNG)[3]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo3_InsertNG]
			, ISNULL((SELECT BatchNo3NGAdjust	= Node.Data.value('(BatchDetails/BatchDetails/InsertingNGAdjust)[3]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo3_InsertNGAdjust]
			, ISNULL((SELECT BatchNo3BurNG		= Node.Data.value('(BatchDetails/BatchDetails/BurningNG)[3]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo3_BurnNG]
			, ISNULL((SELECT BatchNo3BurNGAdjust= Node.Data.value('(BatchDetails/BatchDetails/BurningNGAdjust)[3]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo3_BurnNGAdjust]
			, ISNULL((SELECT BatchNo3RMNG		= Node.Data.value('(BatchDetails/BatchDetails/RemovingNG)[3]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo3_RemoveNG]
			, ISNULL((SELECT BatchNo3RMNGAdjust	= Node.Data.value('(BatchDetails/BatchDetails/RemovingNGAdjust)[3]', 'INT') FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS [BatchNo3_RemoveNGAdjust]

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
	END
END

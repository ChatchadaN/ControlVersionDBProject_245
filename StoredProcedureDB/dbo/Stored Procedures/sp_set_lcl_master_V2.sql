-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_lcl_master_V2]
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @iRowFT INT
	DECLARE @LCL decimal(18, 6)
	DECLARE @AVE decimal(18, 6)
	DECLARE @UCL decimal(18, 6)
	DECLARE @STDEV decimal(18, 6)
	DECLARE @UpdateTime datetime
	DECLARE @idLclMaster INT
	DECLARE @Jobid INT
	DECLARE @JobName INT
	DECLARE @Deviceid INT
	DECLARE @iCountLot INT
	DECLARE @iCountMonth INT
	DECLARE @Box VARCHAR(10)
	DECLARE @ft_name VARCHAR(20)
	DECLARE @LCLNEW decimal(18, 6)
	DECLARE @AVENEW decimal(18, 6)
	DECLARE @UCLNEW decimal(18, 6)
	DECLARE @STDEVNEW decimal(18, 6)
	DECLARE @DeviceName VARCHAR(30)
	DECLARE @TestFlow VARCHAR(30)

    -- Insert statements for procedure here

	BEGIN
--Process FT
-- Declare Table
	DECLARE @temp TABLE
		(
			RowID INT IDENTITY (1,1),
			DeviceName VARCHAR(50),
			Testflow VARCHAR(50),
		    LCLid INT,
			LCL decimal(18, 6),
	        AVE decimal(18, 6),
	        UCL decimal(18, 6),
			device_id INT,
			UpdateTime datetime
		)
----# INSERT INTO TABLE @table_data
		INSERT INTO @temp
		SELECT device_names.name,job_id,lcl_masters.id as lclid,lcl,ucl,avg ,device_names.id as devcieid, lcl_masters.update_at as updateAt
		FROM [APCSProDB].[trans].[lcl_masters] INNER JOIN [APCSProDB].[method].[device_names] ON lcl_masters.device_id = device_names.id 
		inner join [APCSProDB].[method].[packages] on device_names.package_id = packages.id
		WHERE packages.name='SSOP-C38W' and device_names.name='SV010A-HE2' 
		--ORDER BY lclid ASC
		ORDER BY job_id ASC

-- Variable
	DECLARE @i INT
	DECLARE @iRow INT
	DECLARE @sName VARCHAR(50)
	DECLARE @sLastName VARCHAR(50)

-- Set Variable
	SET @i = 1
	SELECT @iRow = COUNT(*) FROM @temp

-- Loop Row
	WHILE (@i <= @iRow)
		BEGIN 
			SELECT @TestFlow = CASE WHEN Testflow = 106	THEN 'AUTO(1)'
							 WHEN Testflow = 108	 THEN 'AUTO(2)'
							 WHEN Testflow = 110	 THEN 'AUTO(3)'
							 WHEN Testflow = 119	 THEN 'AUTO(4)'
						END
					,@DeviceName = DeviceName  , @idLclMaster = LCLid , @Deviceid = device_id , @UpdateTime = UpdateTime ,@LCL = LCL
			FROM @temp WHERE RowID = @i

			-- คำนวน LCL  2023-08-07
			----# DECLARE TABLE
					DECLARE @table_data TABLE (
						[LotNo] [VARCHAR](10),
						[LotEndTime] [DATETIME],
						[FinalYield] [REAL],
						[TestFlowName] [VARCHAR](20),
						[ChannelATestBoxNo] [VARCHAR](8),
						[TotalGoodBin1Qty] [INT],
						[TotalNGQty] [INT],
						[rows] [INT]
					);
							----# INSERT INTO TABLE @table_data
							INSERT INTO @table_data
							SELECT _lots.lot_no AS LotNo
							,_record.recorded_at AS LotEndTime
							,(SELECT FinalYield			= Node.Data.value('(FinalYield)[1]', 'REAL')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS FinalYield
							,_jb.name AS TestFlowName
							,(SELECT ChannelATestBoxNo	= Node.Data.value('(ChannelATestBoxNo)[1]', 'VARCHAR(MAX)')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) AS ChannelATestBoxNo
							,ISNull((SELECT TotalGoodBin1Qty	= Node.Data.value('(TotalGoodBin1Qty)[1]', 'INT')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalGoodBin1Qty
							,ISNull((SELECT TotalNGQty			= Node.Data.value('(TotalNGQty)[1]', 'INT')				FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)),0) AS TotalNGQty
							,ROW_NUMBER() OVER ( PARTITION BY _jb.name, (SELECT ChannelATestBoxNo	= Node.Data.value('(ChannelATestBoxNo)[1]', 'VARCHAR(MAX)')	FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) ORDER BY _record.recorded_at ASC ) AS [rows]

			
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

							WHERE _record.record_class in (2) 
									AND (_jb.name LIKE @TestFlow)        
									AND ( _dv.name = @DeviceName ) 
									AND ( _jb.name NOT IN ('GO/NGSampleJudge') ) 
									AND ( SUBSTRING(_lots.lot_no, 5, 1)  NOT IN ('B','D','E'))
									AND ( (SELECT FinalYield = Node.Data.value('(FinalYield)[1]', 'VARCHAR(MAX)')		FROM _xml.extend_data.nodes('LotDataCommon') Node(Data)) IS NOT NULL )
									AND _record.recorded_at BETWEEN  '2024-12-01 08:00:00.000' and '2025-01-20 07:59:59.000'
									--AND ( _record.recorded_at BETWEEN @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00'));
							ORDER BY _record.id ASC


							--# SELECT DATA
							SELECT @UCLNEW = 100
								, @AVENEW = ROUND( AVG( TBGroup1.AVG ), 2 ) 
								, @LCLNEW = ROUND( AVG( TBGroup1.sim2 ), 2 ) 
								, @JobName = CASE WHEN TBGroup1.TestFlowName = 'AUTO(1)'	THEN 106
									  WHEN TBGroup1.TestFlowName = 'AUTO(2)'	 THEN 108
									  WHEN TBGroup1.TestFlowName = 'AUTO(3)'	 THEN 110
									  WHEN TBGroup1.TestFlowName = 'AUTO(4)'	 THEN 119
								 END
								--, TBGroup1.TestFlowName
							FROM (
									SELECT TBSIM4.TestFlowName
										, TBSIM4.ChannelATestBoxNo
										, TBSIM4.AVG
										, ISNULL( TBSIM4.sim4, TBSIM4.AVG ) AS sim4
										, ISNULL( TBSIM2.sim2, TBSIM4.AVG ) AS sim2
									FROM (
											SELECT TB1.TestFlowName
												, TB1.ChannelATestBoxNo
												, ROUND( AVG( TB1.FinalYield ), 2 ) AS AVG
												, ROUND( AVG( TB1.FinalYield ) - STDEV( TB1.FinalYield ) * 4, 3 ) AS sim4
											FROM @table_data AS TB1
											WHERE ( rows <= 30 ) ----# Top 30 row
											GROUP BY TB1.TestFlowName, TB1.ChannelATestBoxNo
									) AS TBSIM4
								----# find sim2 using outer apply
								OUTER APPLY (
									SELECT TB2.TestFlowName
										, TB2.ChannelATestBoxNo
										, ROUND( AVG( TB2.FinalYield ) - STDEV( TB2.FinalYield ) * 2, 3 ) AS sim2
									FROM @table_data AS [TB2]
									WHERE ( rows <= 30 ) ----# Top 30 row
										AND ( TB2.FinalYield >= TBSIM4.sim4 ) ----# finalyield >= sim4 
										AND	( TB2.TestFlowName = TBSIM4.TestFlowName ) 
										AND ( TB2.ChannelATestBoxNo = TBSIM4.ChannelATestBoxNo )
									GROUP BY TB2.TestFlowName, TB2.ChannelATestBoxNo
								) AS TBSIM2 

					) AS TBGroup1
					GROUP BY TBGroup1.TestFlowName

					SELECT @i AS [Row]
						, @UCLNEW AS ucl
						, @AVENEW AS avg
						, @LCLNEW AS lcl
						, @JobName AS flow
						,@idLclMaster  As IDLCL
					--SELECT *
					--FROM @table_data
					
					--PRINT 	'Row = ' + CAST(@i AS VARCHAR(10)) 
					--	+ ', ucl = ' + ISNULL(CAST(@UCLNEW AS VARCHAR(10)), 'NULL') 
					--	+ ', lcl = ' + ISNULL(CAST(@LCLNEW AS VARCHAR(10)), 'NULL') 
					--	+ ', avg = ' + ISNULL(CAST(@AVENEW AS VARCHAR(10)), 'NULL');


			  --Add 
			  --5.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
								--IF (@LCLNEW >= @LCL AND @LCLNEW < '99.8')
								--	----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้
								--		UPDATE [APCSProDB].[trans].[lcl_masters]
								--		SET ucl = @UCLNEW,
								--		lcl = @LCLNEW,
								--		avg = @AVENEW,
								--		--std_deviation = @STDEVNEW,
								--		box_no = 'FTB-1',
								--		Update_at = getdate(),
								--		updated_by = 1
								--		WHERE id = @idLclMaster 
										
									
								--		INSERT INTO [APCSProDB].[trans].[lcl_master_records]
								--		SELECT Top(1)
								--			 id AS lcl_master_id
								--			,device_id AS device_id
								--			,job_id AS job_id
								--			,ucl AS ucl
								--			,lcl AS lcl
								--			,avg AS avg
								--			,std_deviation AS std_deviation
								--			,box_no AS box_no
								--			,is_auto AS is_auto
								--			,is_released AS is_released
								--			,created_at AS created_at
								--			,created_by AS created_by
								--			,update_at AS update_at
								--			,updated_by AS updated_by
								--		FROM [APCSProDB].[trans].[lcl_masters] ORDER BY update_at DESC
								--IF (@LCLNEW >= @LCL AND @LCLNEW > '99.8')
								--		--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
								--		UPDATE [APCSProDB].[trans].[lcl_masters]
								--		SET ucl = @UCLNEW,
								--		avg ='99.9',
								--		LCL ='99.8' ,
								--		--std_deviation = @STDEVNEW,
								--		box_no = 'FTB-1',
								--		Update_at = getdate(),
								--		updated_by = 1
								--		WHERE id = @idLclMaster

								--		INSERT INTO [APCSProDB].[trans].[lcl_master_records]
								--		SELECT Top(1)
								--			 id AS lcl_master_id
								--			,device_id AS device_id
								--			,job_id AS job_id
								--			,ucl AS ucl
								--			,lcl AS lcl
								--			,avg AS avg
								--			,std_deviation AS std_deviation
								--			,box_no AS box_no
								--			,is_auto AS is_auto
								--			,is_released AS is_released
								--			,created_at AS created_at
								--			,created_by AS created_by
								--			,update_at AS update_at
								--			,updated_by AS updated_by
								--		FROM [APCSProDB].[trans].[lcl_masters] ORDER BY update_at DESC
								--IF (@LCLNEW < @LCL)
								--		--ค่า LCL ใหม่ น้อยว่าLCL เดิม ให้ใช้ค่าเดิม และ avg =99.9
								--		UPDATE [APCSProDB].[trans].[lcl_masters]
								--		SET ucl = @UCLNEW,
								--		avg = '99.9',
								--		LCL = @LCL ,
								--		box_no = 'FTB-1',
								--		Update_at = getdate(),
								--		updated_by = 1
								--		WHERE id = @idLclMaster

										
								--		INSERT INTO [APCSProDB].[trans].[lcl_master_records]
								--		SELECT Top(1)
								--			 id AS lcl_master_id
								--			,device_id AS device_id
								--			,job_id AS job_id
								--			,ucl AS ucl 
								--			,lcl AS lcl
								--			,avg AS avg
								--			,std_deviation AS std_deviation
								--			,box_no AS box_no
								--			,is_auto AS is_auto
								--			,is_released AS is_released
								--			,created_at AS created_at
								--			,created_by AS created_by
								--			,update_at AS update_at
								--			,updated_by AS updated_by
								--		FROM [APCSProDB].[trans].[lcl_masters] ORDER BY update_at DESC


		SET @i = @i + 1 
		END
	END
END

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_test_LCLMaster]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	-- Variable
	DECLARE @i INT
	DECLARE @iRow INT
	DECLARE @iRowFT INT
	DECLARE @iRowMAP INT
	DECLARE @iCount INT
	DECLARE @iCountFT INT
	DECLARE @iCountMAP INT
	DECLARE @iCountFTRank INT
	DECLARE @iCountMAPRank INT
	DECLARE @iCountMonth INT
	DECLARE @iCountMonthFT INT
	DECLARE @iCountMonthMAP INT
	DECLARE @iCountMonthFTRank INT
	DECLARE @iCountMonthMAPRank INT
	DECLARE @iID INT
	DECLARE @iRowNumber INT
	DECLARE @Device VARCHAR(100)
	DECLARE @DeviceFT VARCHAR(100)
	DECLARE @DeviceName VARCHAR(100)
	DECLARE @DeviceNameFT VARCHAR(100) = '%'
	DECLARE @DeviceNameR VARCHAR(100)
	DECLARE @DeviceName2 VARCHAR(100)
	DECLARE @DeviceNameMAP VARCHAR(100) = '%'
	DECLARE @DeviceMAP VARCHAR(100)
	DECLARE @DeviceMAPR VARCHAR(100)
	DECLARE @DeviceNameMAPR VARCHAR(100)
	DECLARE @LCL decimal(18, 2)
	DECLARE @OLDLCL decimal(18, 2)
	DECLARE @OLDLCL2 decimal(18, 2)
	DECLARE @LCLCul decimal(18, 2)
	DECLARE @sigma_4 decimal(18, 2)
	DECLARE @sigma_2 decimal(18, 2)
	DECLARE @AVE decimal(18, 2)
	DECLARE @OLDAVE decimal(18, 2)
	DECLARE @OLDAVE2 decimal(18, 2)
	DECLARE @OLDUCL decimal(18, 2) 
	DECLARE @OLDUCL2 decimal(18, 2)
	DECLARE @UpdateTime datetime
	DECLARE @OLDUpdateTime datetime
	DECLARE @OLDUpdateTime2 datetime
	DECLARE @YLD decimal(18, 2)
	DECLARE @DeviceName5 VARCHAR(100)
	DECLARE @AUTO VARCHAR(50)
	DECLARE @DeviceID INT
	DECLARE @CountFTB INT
	DECLARE @FTBName VARCHAR(10)
	DECLARE @OLDBoxFTB VARCHAR(10)
	DECLARE @statusLCLFL VARCHAR(15)
	DECLARE @statusLCLFT VARCHAR(15)
	DECLARE @statusLCLMAP VARCHAR(15)
	DECLARE @statusRankFT VARCHAR(15)
	DECLARE @statusRankMAP VARCHAR(15)
	DECLARE @statusRank VARCHAR(15)
	DECLARE @PackageFT VARCHAR(100)
	DECLARE @PackageMAP VARCHAR(100)
	DECLARE @Box VARCHAR(15)
	DECLARE @BoxMAP VARCHAR(15)
	DECLARE @STDEV1 decimal(18, 2)
	 
	BEGIN
	--Process FL

	SET @i = 1
	--1.หาจำนวน Device ที่มีการผลิต
	SELECT @iRow = COUNT(*) FROM [DBx].[dbo].[View_Device],[DBx].[dbo].[OIS] WHERE View_Device.Device = OIS.DeviceName and ProcessName like '%FL%' 
    -- Loop Row
	WHILE (@i <= @iRow)
		BEGIN 
			--2.หา Device แรกจากจำนวนทั้งหมดวนลูป 
			SELECT @DeviceName = ETC1 FROM (SELECT ROW_NUMBER() OVER(ORDER BY ETC1) AS RowID,* FROM [DBx].[dbo].[View_Device],[DBx].[dbo].[OIS] WHERE View_Device.Device = OIS.DeviceName and ProcessName like '%FL%' ) AS c WHERE c.RowID=@i

			--3.หาค่า LCL ล่าสุด ของแต่ละDevice ในตารางView_UCL_LCL
			SELECT  @Device = Trim(DeviceName),@LCL = LCL,@UpdateTime=UpdateTime,@AUTO=FT_Flow_Name, @statusLCLFL=StatusLCL,@OLDAVE = AVE,@OLDLCL=LCL,@OLDUCL=UCL,@OLDAVE = AVE,@OLDLCL=LCL,@OLDUCL=UCL FROM  [DBx].[dbo].[View_UCL_LCL] WHERE DeviceName= @DeviceName 
			
			--4.1 Select หาจำนวน Lot ที่ Run ว่าครบ 30 Lot แล้วหรือยัง Process FL
			SELECT @iCount = COUNT(*)
			FROM [DBx].[dbo].[View_Transac_FLData] WHERE Device = @Device and LotEndTime Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 

			--4.2 ถ้า Device นี้ไม่ถึง30 Lot ให้เช็คต่อว่า Device นี้ครบ 3 เดือนแล้วหรือยัง Process FL
			SELECT  TOP(1) @iCountMonth =  DATEDIFF(m, @UpdateTime, getdate() )
			FROM [DBx].[dbo].[View_Transac_FLData] WHERE Device = @Device and LotEndTime Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
			
			--5.ถ้าจำนวนLot ไม่ครบ 30 แต่ครบ3เดือนแล้ว ให้คำนวณค่า LCL ใหม่	 (Process FL)
			IF @statusLCLFL = 'AUTO UPDATE'
			BEGIN
			 IF (@iCountMonth >= 3) 
				BEGIN
					---5.1คำนวณ 4sigma และ 2sigma จะได้ค่า Yield 
					SELECT @DeviceName2= Test2.DeviceName,@sigma_2 =(ROUND(AVG(AVG_YLD)-STDEV(AVG_YLD)*2,1)),@AVE = Cal_AVG,@sigma_4 =  Sigma_4
					FROM(
							Select Device,(ROUND(AVG(YLD)-STDEV(YLD)*4,1)) As  Sigma_4,ROUND(AVG(YLD),2) As  Cal_AVG
							From (select  Top(30) Device ,LotEndTime,
										  CASE WHEN GoodAdjust = 0 THEN 0 ELSE CAST((CAST( GoodAdjust AS decimal)/(CAST(GoodAdjust AS decimal)+ CAST( FTNGAdjust AS decimal)))*100 As decimal(10,2)) END AS YLD
								  from [DBx].[dbo].[View_Transac_FLData] 
								  where Device =@Device and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') Order by LotEndTime DESC
						) As YLD1
					GROUP BY Device

					) AS Test1
					JOIN	
					(
						Select DeviceName,LotEndTime,AVG_YLD
						From (select  Top(30) Device As DeviceName,LotEndTime,
						              CASE WHEN GoodAdjust = 0 THEN 0 ELSE CAST((CAST( GoodAdjust AS decimal)/(CAST(GoodAdjust AS decimal)+ CAST( FTNGAdjust AS decimal)))*100 As decimal(10,2))  END AS AVG_YLD
							  from [DBx].[dbo].[View_Transac_FLData] 
							  where  Device =@Device and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')  Order by LotEndTime DESC
						) As YLD2
					) AS Test2
					ON   Test1.Device = Test2.DeviceName
					WHERE Test2.AVG_YLD >= Test1.Sigma_4 
					GROUP BY Test2.DeviceName,Test1.Cal_AVG,Test1.Sigma_4 
				
					--6.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
					IF (@sigma_2 >= @LCL AND @sigma_2 < '99.8')
					----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้)
						UPDATE [DBx].[dbo].[Cal_LCL]
						SET LastAVE= @OLDAVE,LastLCL=@OLDLCL,LastUCL=@OLDUCL,AVE=@AVE,LastUpdateTime=@UpdateTime,LCL=@sigma_2 ,
						UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
						WHERE DeviceName = @Device  and Process='FL'
					IF (@sigma_2 >= @LCL AND  @sigma_2 > '99.8')
					--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
						UPDATE [DBx].[dbo].[Cal_LCL]
						SET LastAVE= @OLDAVE,LastLCL=@OLDLCL,LastUCL=@OLDUCL,LastUpdateTime=@UpdateTime,AVE='99.9',LCL='99.8' ,
						UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
						WHERE DeviceName = @Device  and Process='FL'
					IF (@sigma_2 < @LCL)
						--หาค่าเดิม ก่อนการ Update ค่าใหม่
						UPDATE [DBx].[dbo].[Cal_LCL]
						SET LastAVE= @OLDAVE,LastLCL=@OLDLCL,LastUCL=@OLDUCL,AVE='99.9',LastUpdateTime=@UpdateTime,LCL =@LCL,
						UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
						WHERE DeviceName = @Device 
				END				
			--5.ถ้าจำนวนLot ครบ 30 หรือ มากกว่า ให้คำนวณค่า LCL ใหม่ Process FL
			ELSE IF (@iCount >= 30)
				BEGIN
					---5.1คำนวณ 4sigma และ 2sigma จะได้ค่า Yield 
					SELECT @DeviceName2= Test2.DeviceName,@sigma_2 =(ROUND(AVG(AVG_YLD)-STDEV(AVG_YLD)*2,1)),@AVE = Cal_AVG,@sigma_4 =  Sigma_4
					FROM(
							Select Device,(ROUND(AVG(YLD)-STDEV(YLD)*4,1)) As  Sigma_4, ROUND(AVG(YLD),2) As  Cal_AVG
							From (select Device ,LotEndTime,
										  CASE WHEN GoodAdjust = 0 THEN 0 ELSE CAST((CAST( GoodAdjust AS decimal)/(CAST(GoodAdjust AS decimal)+ CAST( FTNGAdjust AS decimal)))*100 As decimal(10,2)) END AS YLD
								  from [DBx].[dbo].[View_Transac_FLData] 
								  where Device =@Device and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
						) As YLD1
					GROUP BY Device

					) AS Test1
					JOIN	
					(
						Select DeviceName,LotEndTime,AVG_YLD
						From (select  Device As DeviceName,LotEndTime,
						              CASE WHEN GoodAdjust = 0 THEN 0 ELSE CAST((CAST( GoodAdjust AS decimal)/(CAST(GoodAdjust AS decimal)+ CAST( FTNGAdjust AS decimal)))*100 As decimal(10,2))  END AS AVG_YLD
							  from [DBx].[dbo].[View_Transac_FLData] 
							  where  Device =@Device and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
						) As YLD2
					) AS Test2
					ON   Test1.Device = Test2.DeviceName
					WHERE Test2.AVG_YLD >= Test1.Sigma_4 
					GROUP BY Test2.DeviceName,Test1.Cal_AVG,Test1.Sigma_4 
					
					--6.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
					IF (@sigma_2 >= @LCL AND @sigma_2 < '99.8')
					----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้)
						UPDATE [DBx].[dbo].[Cal_LCL]
						SET LastAVE= @OLDAVE,LastLCL=@OLDLCL,LastUCL=@OLDUCL,AVE=@AVE,LastUpdateTime=@UpdateTime,LCL=@sigma_2 ,
						UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
						WHERE DeviceName = @Device  and Process='FL'
					IF (@sigma_2 >= @LCL AND  @sigma_2 > '99.8')
					--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
						UPDATE [DBx].[dbo].[Cal_LCL]
						SET LastAVE= @OLDAVE,LastLCL=@OLDLCL,LastUCL=@OLDUCL,LastUpdateTime=@UpdateTime,AVE='99.9',LCL='99.8' ,
						UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
						WHERE DeviceName = @Device  and Process='FL'
					IF (@sigma_2 < @LCL)
						--หาค่าเดิม ก่อนการ Update ค่าใหม่
						UPDATE [DBx].[dbo].[Cal_LCL]
						SET LastAVE= @OLDAVE,LastLCL=@OLDLCL,LastUCL=@OLDUCL,AVE='99.9',LastUpdateTime=@UpdateTime,LCL=@LCL ,
						UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
						WHERE DeviceName = @Device  and Process='FL'
				END
			END	
		SET @i = @i + 1 --WHILE    
	END -- WHILE	
	END

	BEGIN
	--Process FT
	DECLARE @iFT INT
	DECLARE @iFTB INT
	SET @iFT = 1
	SET @iFTB = 1
	
	--1.หาจำนวน Device ที่มีการผลิต
	SELECT @iRowFT = COUNT(*) FROM [DBx].[dbo].[View_DeviceFT] WHERE ETC1 IS NOT NULL

	--Loop Row FT
	WHILE (@iFT <= @iRowFT)
		BEGIN 
			--2.หา Device แรกจากจำนวนทั้งหมดวนลูป 
			SELECT @DeviceNameFT = SUBSTRING(ETC1,1,case 
							when  CHARINDEX('-', ETC1,0) ='0' then LEN(ETC1) 
						else(CHARINDEX('-',ETC1,0)-1)end),@AUTO = TestFlowName,@PackageFT = Package,@DeviceNameR=ETC1 FROM (SELECT ROW_NUMBER() OVER(ORDER BY ETC1) AS RowID,* FROM [DBx].[dbo].[View_DeviceFT] WHERE ETC1 IS NOT NULL) AS c WHERE c.RowID = @iFT
			
			
		   --3.หาค่า LCL ล่าสุด ของแต่ละDevice ในตารางView_UCL_LCL
		   SELECT  @statusRank = StatusRank ,@DeviceFT = Trim(DeviceName), @LCL = LCL, @UpdateTime=UpdateTime,  @statusLCLFT=StatusLCL , @OLDAVE = AVE, @OLDLCL=LCL, @OLDUCL=UCL,@OLDUCL2=LastUCL,@OLDAVE2=LastAVE,@OLDLCL2=LastLCL,@OLDUpdateTime2=LastUpdateTime
		   FROM  [DBx].[dbo].[View_UCL_LCL] WHERE DeviceName like '%' + @DeviceNameFT + '%' And FT_Flow_Name=@AUTO  and PackageName= @PackageFT  And Process='FT'
			--หา Rank
		   SELECT @statusRankFT = StatusRank,@DeviceFT = Trim(DeviceName), @LCL = LCL, @UpdateTime=UpdateTime,  @statusLCLFT=StatusLCL , @OLDAVE = AVE, @OLDLCL=LCL, @OLDUCL=UCL,@OLDUCL2=LastUCL,@OLDAVE2=LastAVE,@OLDLCL2=LastLCL,@OLDUpdateTime2=LastUpdateTime 
		   FROM  [DBx].[dbo].[View_UCL_LCL] WHERE DeviceName = @DeviceNameR And FT_Flow_Name=@AUTO  and PackageName= @PackageFT  And Process='FT'

		   --หาค่า σ 
		   SELECT  @STDEV1 = STDEV(CAST((CAST( TotalGoodBin1Qty AS decimal)/(CAST(TotalGoodBin1Qty AS decimal)+ CAST( TotalNGQty AS decimal)))*100 As decimal(10,2)))
			FROM [DBx].[dbo].[View_Transac_FTData] 
			WHERE Device like '%' + @DeviceNameFT + '%' and TestFlowName = @AUTO  and LotEndTime  Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 

		   --4.หาจำนวน Lot ที่ Run 
		   --4.1 Select หาจำนวน Lot ที่ Run ว่าครบ 30 Lot แล้วหรือยัง Process FT
			SELECT TOP(1) @iCountFT = COUNT(LotNo) ,@Box=ChannelATestBoxNo
			FROM [DBx].[dbo].[View_Transac_FTData] WHERE Device like '%' + @DeviceNameFT + '%' and TestFlowName = @AUTO  and LotEndTime  Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
			GROUP BY ChannelATestBoxNo,ChannelBTestBoxNo
			ORDER BY COUNT(LotNo) DESC	

			SELECT TOP(1) @iCountFTRank = COUNT(LotNo) ,@Box=ChannelATestBoxNo
			FROM [DBx].[dbo].[View_Transac_FTData] WHERE Device = @DeviceNameR and TestFlowName = @AUTO  and LotEndTime  Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
			GROUP BY ChannelATestBoxNo,ChannelBTestBoxNo
			ORDER BY COUNT(LotNo) DESC
			
		   --4.2 Device นี้ครบ 3 เดือนแล้วหรือยัง Process FT
			SELECT  TOP(1) @iCountMonthFT =  DATEDIFF(m, @UpdateTime, getdate() )
			FROM [DBx].[dbo].[View_Transac_FTData] WHERE Device like '%' + @DeviceNameFT + '%' and TestFlowName = @AUTO  and LotEndTime  Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
					
			SELECT  TOP(1) @iCountMonthFTRank =  DATEDIFF(m, @UpdateTime, getdate() )
			FROM [DBx].[dbo].[View_Transac_FTData] WHERE Device = @DeviceNameR and TestFlowName = @AUTO  and LotEndTime  Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 

			--5.ถ้าจำนวนLot ไม่ครบ 30 แต่ครบ3เดือนแล้ว ให้คำนวณค่า LCL ใหม่	 (Process FL)
			IF @statusLCLFT = 'AUTO UPDATE' and @statusRankFT ='NOT FIX' and @statusRank ='NOT FIX'
			BEGIN
			 IF (@iCountMonthFT >= 3) 
				BEGIN
					---5.1คำนวณ 4sigma และ 2sigma จะได้ค่า Yield 
								SELECT @DeviceName2= Test2.DeviceName,@sigma_2 =(ROUND(AVG(AVG_YLD)-STDEV(AVG_YLD)*2,1)),@AVE = Cal_AVG
								FROM(
										Select Device,(ROUND(AVG(YLD)-STDEV(YLD)*4,1)) As  Sigma_4 ,ROUND(AVG(YLD),2) As  Cal_AVG
										From (select  Top(30) Device ,LotEndTime,
													  CASE WHEN TotalGoodBin1Qty = 0 THEN 0 ELSE CAST((CAST( TotalGoodBin1Qty AS decimal)/(CAST(TotalGoodBin1Qty AS decimal)+ CAST( TotalNGQty AS decimal)))*100 As decimal(10,2)) END AS YLD
											  from [DBx].[dbo].[View_Transac_FTData] 
											  where Device like '%' + @DeviceNameFT + '%' and TestFlowName = @AUTO and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') and (ChannelATestBoxNo =@FTBName Or ChannelBTestBoxNo=@FTBName) Order by LotEndTime DESC
									) As YLD1
								GROUP BY Device

								) AS Test1
								JOIN	
								(
									Select DeviceName,LotEndTime,AVG_YLD
									From (select  Top(30) Device As DeviceName,LotEndTime,
												  CASE WHEN TotalGoodBin1Qty = 0 THEN 0 ELSE CAST((CAST( TotalGoodBin1Qty AS decimal)/(CAST(TotalGoodBin1Qty AS decimal)+ CAST( TotalNGQty AS decimal)))*100 As decimal(10,2))  END AS AVG_YLD
										  from [DBx].[dbo].[View_Transac_FTData] 
										  where  Device like '%' + @DeviceNameFT + '%' and TestFlowName = @AUTO and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') Order by LotEndTime DESC
									) As YLD2
								) AS Test2
								ON   Test1.Device = Test2.DeviceName   
								WHERE Test2.AVG_YLD >= Test1.Sigma_4 
								GROUP BY Test2.DeviceName,Test1.Cal_AVG
				
								--6.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
								IF (@sigma_2 >= @LCL AND @sigma_2 < '99.8')
										----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastUCL=@OLDUCL,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUpdateTime=@UpdateTime,
										LCL=@sigma_2 ,
										AVE=@AVE,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameFT + '%' And FT_Flow_Name = @AUTO And PackageName= @PackageFT And Process='FT' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 >= @LCL AND @sigma_2 > '99.8')
										--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										LastUpdateTime=@UpdateTime,
										AVE='99.9',
										LCL='99.8' ,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameFT + '%' And FT_Flow_Name = @AUTO And PackageName= @PackageFT And Process='FT' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 < @LCL)
										--หาค่าเดิม ก่อนการ Update ค่าใหม่
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										AVE='99.9',
										LastUpdateTime=@UpdateTime,
										LCL=@LCL ,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameFT + '%'  And FT_Flow_Name = @AUTO  And PackageName= @PackageFT  And Process='FT' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
				END	
							
			--5.ถ้าจำนวนLot ครบ 30 หรือ มากกว่า ให้คำนวณค่า LCL ใหม่ Process FT
			ELSE IF (@iCountFT >= 30)
				BEGIN
					---5.1คำนวณ 4sigma และ 2sigma จะได้ค่า Yield 
								SELECT @DeviceName2= Test2.DeviceName,@sigma_2 =(ROUND(AVG(AVG_YLD)-STDEV(AVG_YLD)*2,1)),@AVE = Cal_AVG
								FROM(
										Select Device,(ROUND(AVG(YLD)-STDEV(YLD)*4,1)) As  Sigma_4,ROUND(AVG(YLD),2) As  Cal_AVG
										From (select Device ,LotEndTime,
													  CASE WHEN TotalGoodBin1Qty = 0 THEN 0 ELSE CAST((CAST( TotalGoodBin1Qty AS decimal)/(CAST(TotalGoodBin1Qty AS decimal)+ CAST( TotalNGQty AS decimal)))*100 As decimal(10,2)) END AS YLD
											  from [DBx].[dbo].[View_Transac_FTData] 
											  where Device like '%' + @DeviceNameFT + '%' and TestFlowName = @AUTO and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
									) As YLD1
								GROUP BY Device

								) AS Test1
								JOIN	
								(
									Select DeviceName,LotEndTime,AVG_YLD
									From (select  Device As DeviceName,LotEndTime,
												  CASE WHEN TotalGoodBin1Qty = 0 THEN 0 ELSE CAST((CAST( TotalGoodBin1Qty AS decimal)/(CAST(TotalGoodBin1Qty AS decimal)+ CAST( TotalNGQty AS decimal)))*100 As decimal(10,2))  END AS AVG_YLD
										  from [DBx].[dbo].[View_Transac_FTData] 
										  where  Device like '%' + @DeviceNameFT + '%' and TestFlowName = @AUTO and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
									) As YLD2
								) AS Test2
								ON   Test1.Device = Test2.DeviceName
								WHERE Test2.AVG_YLD >= Test1.Sigma_4 
								GROUP BY Test2.DeviceName,Test1.Cal_AVG
				
								--6.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
								IF (@sigma_2 >= @LCL AND @sigma_2 < '99.8')
										----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastUCL=@OLDUCL,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUpdateTime=@UpdateTime,
										LCL=@sigma_2 ,
										AVE=@AVE,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameFT + '%' And FT_Flow_Name = @AUTO  And PackageName= @PackageFT  And Process='FT' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 >= @LCL AND @sigma_2 > '99.8')
										--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										LastUpdateTime=@UpdateTime,
										AVE='99.9',
										LCL='99.8' ,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameFT + '%' And FT_Flow_Name = @AUTO  And PackageName= @PackageFT  And Process='FT' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 < @LCL)
										--หาค่าเดิม ก่อนการ Update ค่าใหม่
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										AVE='99.9',
										LastUpdateTime=@UpdateTime,
										LCL=@LCL ,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameFT + '%'  And FT_Flow_Name = @AUTO  And PackageName= @PackageFT  And Process='FT' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
				END
			END	

			IF @statusLCLFT = 'AUTO UPDATE' and @statusRankFT ='FIX' and @statusRank ='FIX'
			BEGIN
			 IF (@iCountMonthFTRank >= 3) 
				BEGIN
					---5.1คำนวณ 4sigma และ 2sigma จะได้ค่า Yield 
								SELECT @DeviceName2= Test2.DeviceName,@sigma_2 =(ROUND(AVG(AVG_YLD)-STDEV(AVG_YLD)*2,1)),@AVE = Cal_AVG
								FROM(
										Select Device,(ROUND(AVG(YLD)-STDEV(YLD)*4,1)) As  Sigma_4 ,ROUND(AVG(YLD),2) As  Cal_AVG
										From (select  Top(30) Device ,LotEndTime,
													  CASE WHEN TotalGoodBin1Qty = 0 THEN 0 ELSE CAST((CAST( TotalGoodBin1Qty AS decimal)/(CAST(TotalGoodBin1Qty AS decimal)+ CAST( TotalNGQty AS decimal)))*100 As decimal(10,2)) END AS YLD
											  from [DBx].[dbo].[View_Transac_FTData] 
											  where Device = @DeviceNameR and TestFlowName = @AUTO and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') and (ChannelATestBoxNo =@FTBName Or ChannelBTestBoxNo=@FTBName) Order by LotEndTime DESC
									) As YLD1
								GROUP BY Device

								) AS Test1
								JOIN	
								(
									Select DeviceName,LotEndTime,AVG_YLD
									From (select  Top(30) Device As DeviceName,LotEndTime,
												  CASE WHEN TotalGoodBin1Qty = 0 THEN 0 ELSE CAST((CAST( TotalGoodBin1Qty AS decimal)/(CAST(TotalGoodBin1Qty AS decimal)+ CAST( TotalNGQty AS decimal)))*100 As decimal(10,2))  END AS AVG_YLD
										  from [DBx].[dbo].[View_Transac_FTData] 
										  where  Device = @DeviceNameR and TestFlowName = @AUTO and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') Order by LotEndTime DESC
									) As YLD2
								) AS Test2
								ON   Test1.Device = Test2.DeviceName   
								WHERE Test2.AVG_YLD >= Test1.Sigma_4 
								GROUP BY Test2.DeviceName,Test1.Cal_AVG

								--6.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
								IF (@sigma_2 >= @LCL AND @sigma_2 < '99.8')
										----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastUCL=@OLDUCL,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUpdateTime=@UpdateTime,
										LCL=@sigma_2 ,
										AVE=@AVE,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameR And FT_Flow_Name = @AUTO  And PackageName= @PackageFT  And Process='FT' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 >= @LCL AND @sigma_2 > '99.8')
										--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										LastUpdateTime=@UpdateTime,
										AVE='99.9',
										LCL='99.8' ,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameR And FT_Flow_Name = @AUTO  And PackageName= @PackageFT  And Process='FT' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 < @LCL)
										--หาค่าเดิม ก่อนการ Update ค่าใหม่
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										AVE='99.9',
										LastUpdateTime=@UpdateTime,
										LCL=@LCL ,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameR And FT_Flow_Name = @AUTO  And PackageName= @PackageFT  And Process='FT' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
				END	
							
			--5.ถ้าจำนวนLot ครบ 30 หรือ มากกว่า ให้คำนวณค่า LCL ใหม่ Process FT
			ELSE IF (@iCountFTRank >= 30)
				BEGIN
					---5.1คำนวณ 4sigma และ 2sigma จะได้ค่า Yield 
								SELECT @DeviceName2= Test2.DeviceName,@sigma_2 =(ROUND(AVG(AVG_YLD)-STDEV(AVG_YLD)*2,1)),@AVE = Cal_AVG
								FROM(
										Select Device,(ROUND(AVG(YLD)-STDEV(YLD)*4,1)) As  Sigma_4,ROUND(AVG(YLD),2) As  Cal_AVG
										From (select Device ,LotEndTime,
													  CASE WHEN TotalGoodBin1Qty = 0 THEN 0 ELSE CAST((CAST( TotalGoodBin1Qty AS decimal)/(CAST(TotalGoodBin1Qty AS decimal)+ CAST( TotalNGQty AS decimal)))*100 As decimal(10,2)) END AS YLD
											  from [DBx].[dbo].[View_Transac_FTData] 
											  where Device = @DeviceNameR and TestFlowName = @AUTO and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
									) As YLD1
								GROUP BY Device

								) AS Test1
								JOIN	
								(
									Select DeviceName,LotEndTime,AVG_YLD
									From (select  Device As DeviceName,LotEndTime,
												  CASE WHEN TotalGoodBin1Qty = 0 THEN 0 ELSE CAST((CAST( TotalGoodBin1Qty AS decimal)/(CAST(TotalGoodBin1Qty AS decimal)+ CAST( TotalNGQty AS decimal)))*100 As decimal(10,2))  END AS AVG_YLD
										  from [DBx].[dbo].[View_Transac_FTData] 
										  where  Device = @DeviceNameR and TestFlowName = @AUTO and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
									) As YLD2
								) AS Test2
								ON   Test1.Device = Test2.DeviceName
								WHERE Test2.AVG_YLD >= Test1.Sigma_4 
								GROUP BY Test2.DeviceName,Test1.Cal_AVG
				
								--6.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
								IF (@sigma_2 >= @LCL AND @sigma_2 < '99.8')
										----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastUCL=@OLDUCL,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUpdateTime=@UpdateTime,
										LCL=@sigma_2 ,
										AVE=@AVE,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameR And FT_Flow_Name = @AUTO And PackageName= @PackageFT   And Process='FT' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 >= @LCL AND @sigma_2 > '99.8')
										--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										LastUpdateTime=@UpdateTime,
										AVE='99.9',
										LCL='99.8' ,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameR And FT_Flow_Name = @AUTO And PackageName= @PackageFT  And Process='FT' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 < @LCL)
										--หาค่าเดิม ก่อนการ Update ค่าใหม่
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										AVE='99.9',
										LastUpdateTime=@UpdateTime,
										LCL=@LCL ,
										BoxFTB=@Box,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameR And FT_Flow_Name = @AUTO And PackageName= @PackageFT  And Process='FT' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
				END
			END	
		SET @iFT = @iFT + 1 --WHILE    
	END -- WHILE	
	END
	
	BEGIN
	--Process MAP
	DECLARE @iMAP INT
	SET @iMAP = 1 
	
	--1.หาจำนวน Device ที่มีการผลิต
	SELECT @iRowMAP = COUNT(*) FROM [DBx].[dbo].[View_DeviceMAP]

	--Loop Row FT
	WHILE (@iMAP <= @iRowMAP)
		BEGIN 
			--2.หา Device แรกจากจำนวนทั้งหมดวนลูป 
			SELECT @DeviceNameMAP = SUBSTRING(ETC1,1,case 
							when  CHARINDEX('-', ETC1,0) ='0' then LEN(ETC1) 
						else(CHARINDEX('-',ETC1,0)-1)end),@PackageMAP = Package, @DeviceMAPR=ETC1 FROM (SELECT ROW_NUMBER() OVER(ORDER BY ETC1) AS RowID,* FROM [DBx].[dbo].[View_DeviceMAP] WHERE ETC1 IS NOT NULL) AS c WHERE c.RowID = @iMAP
			
			
		   --3.หาค่า LCL ล่าสุด ของแต่ละDevice ในตารางView_UCL_LCL
		   SELECT  @statusRankMAP = StatusRank ,@DeviceMAP = Trim(DeviceName), @LCL = LCL, @UpdateTime=UpdateTime,  @statusLCLMAP=StatusLCL , @OLDAVE = AVE, @OLDLCL=LCL, @OLDUCL=UCL,@OLDUCL2=LastUCL,@OLDAVE2=LastAVE,@OLDLCL2=LastLCL,@OLDUpdateTime2=LastUpdateTime
		   FROM  [DBx].[dbo].[View_UCL_LCL] WHERE DeviceName like '%' + @DeviceNameMAP + '%' and PackageName= @PackageMAP  And Process='MAP'
			
			--หา Rank
		   SELECT @statusRankMAP = StatusRank,@DeviceMAP = Trim(DeviceName), @LCL = LCL, @UpdateTime=UpdateTime,  @statusLCLMAP=StatusLCL , @OLDAVE = AVE, @OLDLCL=LCL, @OLDUCL=UCL,@OLDUCL2=LastUCL,@OLDAVE2=LastAVE,@OLDLCL2=LastLCL,@OLDUpdateTime2=LastUpdateTime 
		   FROM  [DBx].[dbo].[View_UCL_LCL] WHERE DeviceName = @DeviceNameMAPR and PackageName= @PackageMAP  And Process='MAP'

		  

		   --4.หาจำนวน Lot ที่ Run 
		   --4.1 Select หาจำนวน Lot ที่ Run ว่าครบ 30 Lot แล้วหรือยัง Process FT
			SELECT TOP(1) @iCountMAP = COUNT(LotNo) ,@BoxMAP=BoxNo
			FROM [DBx].[dbo].[View_Transac_MAPData] WHERE Device like '%' + @DeviceNameMAP + '%'  and LotEndTime  Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
			GROUP BY BoxNo
			ORDER BY COUNT(LotNo) DESC	
			  
			SELECT TOP(1) @iCountMAPRank = COUNT(LotNo) ,@BoxMAP=BoxNo
			FROM [DBx].[dbo].[View_Transac_MAPData] WHERE Device = @DeviceNameR  and LotEndTime  Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
			GROUP BY BoxNo
			ORDER BY COUNT(LotNo) DESC
			
		   --4.2 Device นี้ครบ 3 เดือนแล้วหรือยัง Process FT
			SELECT  TOP(1) @iCountMonthMAP =  DATEDIFF(m, @UpdateTime, getdate() )
			FROM [DBx].[dbo].[View_Transac_MAPData] WHERE Device like '%' + @DeviceNameMAP + '%'  and LotEndTime  Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
					
			SELECT  TOP(1) @iCountMonthMAPRank =  DATEDIFF(m, @UpdateTime, getdate() )
			FROM [DBx].[dbo].[View_Transac_MAPData] WHERE Device = @DeviceNameMAPR  and LotEndTime  Between @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 

			--5.ถ้าจำนวนLot ไม่ครบ 30 แต่ครบ3เดือนแล้ว ให้คำนวณค่า LCL ใหม่	 (Process FL)
			IF @statusLCLMAP = 'AUTO UPDATE' and @statusRankMAP ='NOT FIX' and @statusRankMAP ='NOT FIX'
			BEGIN
			 IF (@iCountMonthMAP >= 3) 
				BEGIN
					---5.1คำนวณ 4sigma และ 2sigma จะได้ค่า Yield 
								SELECT @DeviceName2= Test2.DeviceName,@sigma_2 =(ROUND(AVG(AVG_YLD)-STDEV(AVG_YLD)*2,1)),@AVE = Cal_AVG
								FROM(
										Select Device,(ROUND(AVG(YLD)-STDEV(YLD)*4,1)) As  Sigma_4 ,ROUND(AVG(YLD),2) As  Cal_AVG
										From (select  Top(30) Device ,LotEndTime,
													  CASE WHEN TotalGood = 0 THEN 0 ELSE CAST((CAST( TotalGood AS decimal)/(CAST(TotalGood AS decimal)+ CAST( TotalNG AS decimal)))*100 As decimal(10,2)) END AS YLD
											  from [DBx].[dbo].[View_Transac_MAPData] 
											  where Device like '%' + @DeviceNameMAP + '%'  and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') and (BoxNo =@BoxMAP) Order by LotEndTime DESC
									) As YLD1
								GROUP BY Device

								) AS Test1
								JOIN	
								(
									Select DeviceName,LotEndTime,AVG_YLD
									From (select  Top(30) Device As DeviceName,LotEndTime,
												  CASE WHEN TotalGood = 0 THEN 0 ELSE CAST((CAST( TotalGood AS decimal)/(CAST(TotalGood AS decimal)+ CAST( TotalNG AS decimal)))*100 As decimal(10,2))  END AS AVG_YLD
										  from [DBx].[dbo].[View_Transac_MAPData] 
										  where  Device like '%' + @DeviceNameMAP + '%' and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') Order by LotEndTime DESC
									) As YLD2
								) AS Test2
								ON   Test1.Device = Test2.DeviceName   
								WHERE Test2.AVG_YLD >= Test1.Sigma_4 
								GROUP BY Test2.DeviceName,Test1.Cal_AVG
				
								--6.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
								IF (@sigma_2 >= @LCL AND @sigma_2 < '99.8')
										----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastUCL=@OLDUCL,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUpdateTime=@UpdateTime,
										LCL=@sigma_2 ,
										AVE=@AVE,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameMAP + '%' And PackageName= @PackageMAP And Process='MAP' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 >= @LCL AND @sigma_2 > '99.8')
										--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										LastUpdateTime=@UpdateTime,
										AVE='99.9',
										LCL='99.8' ,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameMAP + '%'  And PackageName= @PackageMAP And Process='MAP' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 < @LCL)
										--หาค่าเดิม ก่อนการ Update ค่าใหม่
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										AVE='99.9',
										LastUpdateTime=@UpdateTime,
										LCL=@LCL ,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameMAP + '%'    And PackageName= @PackageMAP  And Process='MAP' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
				END	
							
			--5.ถ้าจำนวนLot ครบ 30 หรือ มากกว่า ให้คำนวณค่า LCL ใหม่ Process FT
			ELSE IF (@iCountMAP>= 30)
				BEGIN
					---5.1คำนวณ 4sigma และ 2sigma จะได้ค่า Yield 
								SELECT @DeviceName2= Test2.DeviceName,@sigma_2 =(ROUND(AVG(AVG_YLD)-STDEV(AVG_YLD)*2,1)),@AVE = Cal_AVG
								FROM(
										Select Device,(ROUND(AVG(YLD)-STDEV(YLD)*4,1)) As  Sigma_4,ROUND(AVG(YLD),2) As  Cal_AVG
										From (select Device ,LotEndTime,
													  CASE WHEN TotalGood = 0 THEN 0 ELSE CAST((CAST( TotalGood AS decimal)/(CAST(TotalGood AS decimal)+ CAST( TotalNG AS decimal)))*100 As decimal(10,2)) END AS YLD
											  from [DBx].[dbo].[View_Transac_MAPData] 
											  where Device like '%' + @DeviceNameMAP + '%'  and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
									) As YLD1
								GROUP BY Device

								) AS Test1
								JOIN	
								(
									Select DeviceName,LotEndTime,AVG_YLD
									From (select  Device As DeviceName,LotEndTime,
												  CASE WHEN TotalGood = 0 THEN 0 ELSE CAST((CAST( TotalGood AS decimal)/(CAST(TotalGood AS decimal)+ CAST( TotalNG AS decimal)))*100 As decimal(10,2))  END AS AVG_YLD
										  from [DBx].[dbo].[View_Transac_MAPData] 
										  where  Device like '%' + @DeviceNameMAP + '%' and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
									) As YLD2
								) AS Test2
								ON   Test1.Device = Test2.DeviceName
								WHERE Test2.AVG_YLD >= Test1.Sigma_4 
								GROUP BY Test2.DeviceName,Test1.Cal_AVG
				
								--6.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
								IF (@sigma_2 >= @LCL AND @sigma_2 < '99.8')
										----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastUCL=@OLDUCL,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUpdateTime=@UpdateTime,
										LCL=@sigma_2 ,
										AVE=@AVE,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameMAP + '%'   And PackageName= @PackageMAP  And Process='MAP' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 >= @LCL AND @sigma_2 > '99.8')
										--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										LastUpdateTime=@UpdateTime,
										AVE='99.9',
										LCL='99.8' ,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameMAP + '%'   And PackageName= @PackageMAP  And Process='MAP' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 < @LCL)
										--หาค่าเดิม ก่อนการ Update ค่าใหม่
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										AVE='99.9',
										LastUpdateTime=@UpdateTime,
										LCL=@LCL ,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName like '%' + @DeviceNameMAP + '%'    And PackageName= @PackageMAP  And Process='MAP' And StatusRank='NOT FIX' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
				END
			END	

			IF @statusLCLMAP = 'AUTO UPDATE' and @statusRankMAP ='FIX' and @statusRankMAP ='FIX'
			BEGIN
			 IF (@iCountMonthMAPRank >= 3) 
				BEGIN
					---5.1คำนวณ 4sigma และ 2sigma จะได้ค่า Yield 
								SELECT @DeviceName2= Test2.DeviceName,@sigma_2 =(ROUND(AVG(AVG_YLD)-STDEV(AVG_YLD)*2,1)),@AVE = Cal_AVG
								FROM(
										Select Device,(ROUND(AVG(YLD)-STDEV(YLD)*4,1)) As  Sigma_4 ,ROUND(AVG(YLD),2) As  Cal_AVG
										From (select  Top(30) Device ,LotEndTime,
													  CASE WHEN TotalGood = 0 THEN 0 ELSE CAST((CAST( TotalGood AS decimal)/(CAST(TotalGood AS decimal)+ CAST( TotalNG AS decimal)))*100 As decimal(10,2)) END AS YLD
											  from [DBx].[dbo].[View_Transac_MAPData] 
											  where Device = @DeviceNameMAPR and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') and (BoxNo =@BoxMAP) Order by LotEndTime DESC
									) As YLD1
								GROUP BY Device

								) AS Test1
								JOIN	
								(
									Select DeviceName,LotEndTime,AVG_YLD
									From (select  Top(30) Device As DeviceName,LotEndTime,
												  CASE WHEN TotalGood = 0 THEN 0 ELSE CAST((CAST( TotalGood AS decimal)/(CAST(TotalGood AS decimal)+ CAST( TotalNG AS decimal)))*100 As decimal(10,2))  END AS AVG_YLD
										  from [DBx].[dbo].[View_Transac_MAPData] 
										  where  Device = @DeviceNameMAPR and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') Order by LotEndTime DESC
									) As YLD2
								) AS Test2
								ON   Test1.Device = Test2.DeviceName   
								WHERE Test2.AVG_YLD >= Test1.Sigma_4 
								GROUP BY Test2.DeviceName,Test1.Cal_AVG

								--6.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
								IF (@sigma_2 >= @LCL AND @sigma_2 < '99.8')
										----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastUCL=@OLDUCL,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUpdateTime=@UpdateTime,
										LCL=@sigma_2 ,
										AVE=@AVE,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameMAPR   And PackageName= @PackageMAP And Process='MAP' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 >= @LCL AND @sigma_2 > '99.8')
										--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										LastUpdateTime=@UpdateTime,
										AVE='99.9',
										LCL='99.8' ,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameMAPR   And PackageName= @PackageMAP  And Process='MAP' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 < @LCL)
										--หาค่าเดิม ก่อนการ Update ค่าใหม่
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										AVE='99.9',
										LastUpdateTime=@UpdateTime,
										LCL=@LCL ,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameMAPR And FT_Flow_Name = @AUTO  And PackageName= @PackageMAP  And Process='MAP' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
				END	
							
			--5.ถ้าจำนวนLot ครบ 30 หรือ มากกว่า ให้คำนวณค่า LCL ใหม่ Process FT
			ELSE IF (@iCountMAPRank >= 30)
				BEGIN
					---5.1คำนวณ 4sigma และ 2sigma จะได้ค่า Yield 
								SELECT @DeviceName2= Test2.DeviceName,@sigma_2 =(ROUND(AVG(AVG_YLD)-STDEV(AVG_YLD)*2,1)),@AVE = Cal_AVG
								FROM(
										Select Device,(ROUND(AVG(YLD)-STDEV(YLD)*4,1)) As  Sigma_4,ROUND(AVG(YLD),2) As  Cal_AVG
										From (select Device ,LotEndTime,
													  CASE WHEN TotalGood = 0 THEN 0 ELSE CAST((CAST( TotalGood AS decimal)/(CAST(TotalGood AS decimal)+ CAST( TotalNG AS decimal)))*100 As decimal(10,2)) END AS YLD
											  from [DBx].[dbo].[View_Transac_MAPData] 
											  where Device = @DeviceNameMAPR  and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
									) As YLD1
								GROUP BY Device

								) AS Test1
								JOIN	
								(
									Select DeviceName,LotEndTime,AVG_YLD
									From (select  Device As DeviceName,LotEndTime,
												  CASE WHEN TotalGood = 0 THEN 0 ELSE CAST((CAST( TotalGood AS decimal)/(CAST(TotalGood AS decimal)+ CAST( TotalNG AS decimal)))*100 As decimal(10,2))  END AS AVG_YLD
										  from [DBx].[dbo].[View_Transac_MAPData] 
										  where  Device = @DeviceNameMAPR and LotEndTime  Between  @UpdateTime and FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00') 
									) As YLD2
								) AS Test2
								ON   Test1.Device = Test2.DeviceName
								WHERE Test2.AVG_YLD >= Test1.Sigma_4 
								GROUP BY Test2.DeviceName,Test1.Cal_AVG
				
								--6.เทียบค่า LCL OLD กับ LCL NEW ของ Device นั้น ถ้าค่าLCL ใหม่มีค่ามากกว่า LCL เก่า ให้Update LCL ในDatabase
								IF (@sigma_2 >= @LCL AND @sigma_2 < '99.8')
										----ค่า LCL ใหม่ มากกว่าLCL เดิม แต่ LCLใหม่ น้อยกว่า LCL FIX ให้ใช้ค่าที่คำนวณได้
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastUCL=@OLDUCL,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUpdateTime=@UpdateTime,
										LCL=@sigma_2 ,
										AVE=@AVE,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameMAPR  And PackageName= @PackageMAP   And Process='MAP' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 >= @LCL AND @sigma_2 > '99.8')
										--ค่า LCL ใหม่ มากกว่าLCL เดิม และ LCLใหม่ มากกว่า LCL FIX ให้ใช้ค่า LCL FIX,AVE FIX แทน
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										LastUpdateTime=@UpdateTime,
										AVE='99.9',
										LCL='99.8' ,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameMAPR  And PackageName= @PackageMAP  And Process='MAP' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
								IF (@sigma_2 < @LCL)
										--หาค่าเดิม ก่อนการ Update ค่าใหม่
										UPDATE [DBx].[dbo].[Cal_LCL]
										SET LastUCL2=@OLDUCL2,
										LastAVE2= @OLDAVE2,
										LastLCL2=@OLDLCL2,
										LastUpdateTime2=@OLDUpdateTime2,
										LastAVE= @OLDAVE,
										LastLCL=@OLDLCL,
										LastUCL=@OLDUCL,
										AVE='99.9',
										LastUpdateTime=@UpdateTime,
										LCL=@LCL ,
										BoxFTB=@BoxMAP,
										StdevFT=@STDEV1,
										UpdateTime = FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
										WHERE DeviceName = @DeviceNameMAPR  And PackageName= @PackageMAP  And Process='MAP' And UpdateTime != FORMAT(getdate(), 'yyyy-MM-dd' +'  '+ '07:00:00')
				END
			END	
		SET @iMAP = @iMAP + 1 --WHILE    
	END -- WHILE	
	END
END

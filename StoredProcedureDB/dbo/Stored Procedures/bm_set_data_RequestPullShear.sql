-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[bm_set_data_RequestPullShear]
	-- Add the parameters for the stored procedure here
	@Lot_No varchar(20),
	@Machine_Name varchar(20),
	@Process varchar(5),
	@Line varchar(5),
	@Package varchar(20),
	@Device varchar(20),
	@OPNo int,
	@Periodic varchar(20),
	@Suddent varchar(20),
	@CapillaryBefore varchar(50),
	@CapillaryAfter varchar(50),
	@WireDie varchar(20)
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Check_Record int = 0;
	DECLARE @LENGTHMCGL1 int = 0;
	DECLARE @LENGTHMCGL2 int = 0;
	DECLARE @WireDieData varchar(20);
    DECLARE @ChkShearSpec varchar(10);
	DECLARE @ChkPullTest varchar(10);
	DECLARE @TypeName varchar(20);
	DECLARE @PackageName varchar(20);
	DECLARE @Shear  varchar(20);
	DECLARE @Pull varchar(20); 
	DECLARE @Bonding varchar(20);
	DECLARE @USB varchar(10);
	DECLARE @USBPAD varchar(10);
	DECLARE @COND varchar(10);
	DECLARE @COND2 varchar(10);
	DECLARE @str int =0;
	DECLARE @SMAT int = 0;
	DECLARE @chkUSABLE  varchar(10) = 'false';
	

	 -- Insert statements for procedure here
	BEGIN TRY
	BEGIN TRANSACTION

	  select @LENGTHMCGL1 = LEN(MANU_COND_GOLD_LINE) , @LENGTHMCGL2 = CHARINDEX( '/' , MANU_COND_GOLD_LINE) , @TypeName = TYPE , @PackageName = FORM_NAME_1 , @Shear = SUBSTRING(MANU_COND_GOLD_LINE, 1, 2) 
	  ,@Bonding = CASE 
					WHEN MANU_COND_1 = 'Reverse Bonding' THEN 1 
					WHEN MANU_COND_2 = 'Reverse Bonding' THEN 1 
					WHEN MANU_COND_3 = 'Reverse Bonding' THEN 1 
					WHEN MANU_COND_4 = 'Reverse Bonding' THEN 1 
					WHEN MANU_COND_5 = 'Reverse Bonding' THEN 1 
					WHEN MANU_COND_6 = 'Reverse Bonding' THEN 1 
					WHEN MANU_COND_7 = 'Reverse Bonding' THEN 1 
				 ELSE 0 END 
	  ,@USB = CHARINDEX('USABLE', MANU_COND_1 + MANU_COND_2 + MANU_COND_3 + MANU_COND_4 + MANU_COND_5 + MANU_COND_6 + MANU_COND_7)
	  ,@USBPAD = CHARINDEX('USABLE PAD', MANU_COND_1 + MANU_COND_2 + MANU_COND_3 + MANU_COND_4 + MANU_COND_5 + MANU_COND_6 + MANU_COND_7)
	  ,@COND = TRIM(SUBSTRING(MANU_COND_1 + MANU_COND_2 + MANU_COND_3 + MANU_COND_4 + MANU_COND_5 + MANU_COND_6 + MANU_COND_7,CHARINDEX('USABLE', MANU_COND_1 + MANU_COND_2 + MANU_COND_3 + MANU_COND_4 + MANU_COND_5 + MANU_COND_6 + MANU_COND_7)+ LEN('USABLE'), 3))
	  ,@COND2 = TRIM(SUBSTRING(MANU_COND_1 + MANU_COND_2 + MANU_COND_3 + MANU_COND_4 + MANU_COND_5 + MANU_COND_6 + MANU_COND_7,CHARINDEX('USABLE PAD', MANU_COND_1 + MANU_COND_2 + MANU_COND_3 + MANU_COND_4 + MANU_COND_5 + MANU_COND_6 + MANU_COND_7)+ LEN('USABLE PAD'), 3)) 
	  ,@SMAT = CHARINDEX('al-si-cu', MANU_COND_1 + MANU_COND_2 + MANU_COND_3 + MANU_COND_4 + MANU_COND_5 + MANU_COND_6 + MANU_COND_7)
	  from APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where LOT_NO_1 = @Lot_No


	  --Check Wire size And PullTest
	  IF (@WireDie = 'WB1' and @LENGTHMCGL1 = 16 and @LENGTHMCGL2 = 5)
		--Au28/PdCuAlloy30
		--@WireDie = 'WB1'  เอาค่าหน้า /
		  BEGIN
			SELECT @WireDieData = SUBSTRING(MANU_COND_GOLD_LINE, 1, 4)  
				  ,@ChkPullTest = CASE 
									WHEN SUBSTRING(MANU_COND_GOLD_LINE, 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(MANU_COND_GOLD_LINE, 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(MANU_COND_GOLD_LINE, 3, 2) between 32 and 38 THEN '0.08N' 
								  ELSE '' 
								  END 
				  ,@ChkShearSpec = CASE 
									WHEN SUBSTRING(MANU_COND_GOLD_LINE, 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(MANU_COND_GOLD_LINE, 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(MANU_COND_GOLD_LINE, 3, 2) between 32 and 38 THEN '0.08N' 
								  ELSE '' 
								  END 
				,@Pull = SUBSTRING(MANU_COND_GOLD_LINE, 3, 2)
			FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where LOT_NO_1 = @Lot_No
		  END 
	 ELSE IF (@WireDie = 'WB2' and @LENGTHMCGL1 = 16 and @LENGTHMCGL2 = 5)
		--Au28/PdCuAlloy30 => ความยาวข้อความ 16 => เครื่องหมาย / อยู่ตำแหน่งที่5 => Pd30
		--@WireDie = 'WB2'  เอาค่าหลัง /
		 BEGIN
			SELECT @WireDieData = REPLACE(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE)+1,12),'CuAlloy','') 
			,@ChkPullTest = CASE 
									WHEN SUBSTRING(REPLACE(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE)+1,12),'CuAlloy',''), 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(REPLACE(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE)+1,12),'CuAlloy','') , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(REPLACE(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE)+1,12),'CuAlloy','') , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@ChkShearSpec = CASE 
									WHEN SUBSTRING(REPLACE(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE)+1,12),'CuAlloy',''), 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(REPLACE(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE)+1,12),'CuAlloy','') , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(REPLACE(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE)+1,12),'CuAlloy','') , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@Pull = SUBSTRING(MANU_COND_GOLD_LINE, 8, 2)
			FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where LOT_NO_1 = @Lot_No
		  END 

	ELSE IF (@WireDie = 'WB1' and @LENGTHMCGL1 = 16 and @LENGTHMCGL2 = 12)
		--PdCuAlloy30/Au28 => ความยาวข้อความ 16 => เครื่องหมาย / อยู่ตำแหน่งที่ 12 => pd30
		--@WireDie = 'WB1'  เอาค่าหน้า/
		BEGIN
			SELECT @WireDieData = SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'CuAlloy',''), 1, 4)
			,@ChkPullTest = CASE 
									WHEN SUBSTRING(SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'CuAlloy',''), 1, 4), 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'CuAlloy',''), 1, 4), 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'CuAlloy',''), 1, 4), 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@ChkShearSpec = CASE 
									WHEN SUBSTRING(SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'CuAlloy',''), 1, 4), 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'CuAlloy',''), 1, 4), 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'CuAlloy',''), 1, 4), 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@Pull = SUBSTRING(MANU_COND_GOLD_LINE, 3, 2)
			FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where LOT_NO_1 = @Lot_No
		END 
	ELSE IF (@WireDie = 'WB2' and @LENGTHMCGL1 = 16 and @LENGTHMCGL2 = 12)
		--PdCuAlloy30/Au28 => ความยาวข้อความ 16 => เครื่องหมาย / อยู่ตำแหน่งที่ 12 => pd30
		--@WireDie = 'WB2'  เอาค่าหลัง /
		BEGIN
			SELECT @WireDieData = SUBSTRING(MANU_COND_GOLD_LINE, 13, 4) 
			,@ChkPullTest = CASE 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 13, 4) , 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 13, 4) , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 13, 4) , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@ChkShearSpec = CASE 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 13, 4) , 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 13, 4) , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 13, 4) , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@Pull = SUBSTRING(MANU_COND_GOLD_LINE, 8, 2)
			FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where LOT_NO_1 = @Lot_No
		END 
	ELSE IF (@WireDie = 'WB1' and @LENGTHMCGL1 != 16 and @LENGTHMCGL2 != 12)
		--Pd30/Au28
		--@WireDie = 'WB1'  เอาค่าหน้า /
		 BEGIN
			SELECT @WireDieData = SUBSTRING(MANU_COND_GOLD_LINE, 1, 4) 
			,@ChkPullTest = CASE 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4) , 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4) , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4) , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@ChkShearSpec = CASE 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4) , 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4) , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4) , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@Pull = SUBSTRING(MANU_COND_GOLD_LINE, 3, 2)
			FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where LOT_NO_1 = @Lot_No
		  END 
	ELSE IF (@WireDie = 'WB2' and @LENGTHMCGL1 != 16 and @LENGTHMCGL2 != 12)
		--Pd30/Au28
		--@WireDie = 'WB2'  เอาค่าหลัง /
		 BEGIN
			IF (@LENGTHMCGL1 = 10 and  @LENGTHMCGL2 =6)
				SELECT @WireDieData = SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE) + 1, 4) 
				,@ChkPullTest = CASE 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE) + 1, 4) , 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE) + 1, 4) , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE) + 1, 4) , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
				,@ChkShearSpec = CASE 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE) + 1, 4) , 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE) + 1, 4) , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, CHARINDEX( '/' , MANU_COND_GOLD_LINE) + 1, 4) , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
				,@Pull = SUBSTRING(MANU_COND_GOLD_LINE, 3, 2)
				FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where LOT_NO_1 = @Lot_No
			Else 
				SELECT @WireDieData = SUBSTRING(MANU_COND_GOLD_LINE, 6, 4) 
				,@ChkPullTest = CASE 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 6, 4),  3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 6, 4) , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 6, 4) , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
				,@ChkShearSpec = CASE 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 6, 4),  3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 6, 4) , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 6, 4) , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
				,@Pull = SUBSTRING(MANU_COND_GOLD_LINE, 3, 2)
				FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where LOT_NO_1 = @Lot_No
		  END 
	--@WireDie = 'WB'
	ELSE IF (@WireDie = 'WB' and (@LENGTHMCGL1 != 12 and @LENGTHMCGL2 != 10 ))
		 BEGIN
			SELECT @WireDieData = SUBSTRING(MANU_COND_GOLD_LINE, 1, 4) 
			,@ChkPullTest = CASE 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4), 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4), 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4), 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@ChkShearSpec = CASE 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4), 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4), 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(SUBSTRING(MANU_COND_GOLD_LINE, 1, 4), 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@Pull = SUBSTRING(MANU_COND_GOLD_LINE, 3, 2)
			FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where LOT_NO_1 = @Lot_No
		  END 
	ELSE IF (@WireDie = 'WB' and @LENGTHMCGL1 = 12)
		BEGIN
			SELECT @WireDieData = REPLACE(MANU_COND_GOLD_LINE,'Cu Alloy','') 
			,@ChkPullTest = CASE 
									WHEN SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'Cu Alloy','') , 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'Cu Alloy','') , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'Cu Alloy','') , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@ChkShearSpec = CASE 
									WHEN SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'Cu Alloy','') , 3, 2) between 20 and 25 THEN '0.04N' 
									WHEN SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'Cu Alloy','') , 3, 2) between 28 and 30 THEN '0.06N' 
									WHEN SUBSTRING(REPLACE(MANU_COND_GOLD_LINE,'Cu Alloy','') , 3, 2) between 32 and 38 THEN '0.08N' 
							ELSE '' 
							END 
			,@Pull = SUBSTRING(MANU_COND_GOLD_LINE, 3, 2)
			FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where LOT_NO_1 = @Lot_No
		END 




		--BEGIN Insert To Database
			select top(1) @Check_Record =  [ID]+1 from [DBx].[dbo].[BMMaintenance]  order by id desc

			INSERT INTO [DBx].[dbo].[BMMaintenance]
            (ID,MachineID,PMID,LotNo,Requestor,StatusID,TimeRequest,Package,Device,CategoryID,Line,ProcessID)
			VALUES
				   (@Check_Record,@Machine_Name,2,@Lot_No,@OPNo,7,GETDATE() ,@Package,@Device,16,@Line ,@Process)

			INSERT INTO [DBx].[dbo].[BMPM6Detail] 
	           --(BM_ID,ChkRequestType,PPChange1,PPChange2,WBConditionChange1,WBConditionChange2,MCTypePDChk,WireDie,WBData1,WhatRequest)
			   (BM_ID,ChkRequestType,PPChange1,PPChange2,WBConditionChange1,WBConditionChange2,MCTypePDChk,WireDie,WBData1,WhatRequest,WBData682)
			VALUES
			   --(@Check_Record,'PS',@Periodic,@Suddent,@CapillaryBefore,@CapillaryAfter,'K&S',@WireDieData,18,'RequestPSAuto')
			   (@Check_Record,'PS',@Periodic,@Suddent,@CapillaryBefore,@CapillaryAfter,'K&S',@WireDieData,18,'RequestPSAuto',@ChkPullTest)
		
		--END

		SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'Request OK' AS Error_Message_THA, N'บันทึกข้อมูลสำเร็จ' AS Handling,@Check_Record As BMID
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Request fail. !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA, N'กรุณาติดต่อ System' AS Handling
	END CATCH

END
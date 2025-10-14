

CREATE PROCEDURE [trans].[sp_rpt_ledger_carryover]
@YEAR_MONTH INTEGER,
@LOCATION_ID INT,
@USER_ID INT
AS
BEGIN
DECLARE @LAST_MONTH AS DATE
DECLARE @LAST_MONTH_INT AS INT

SET @LAST_MONTH  = (SELECT DATEADD(m, -1, CAST((SELECT CAST(@YEAR_MONTH AS VARCHAR(6)) + '01') AS date)))
SET @LAST_MONTH_INT = (SELECT CAST(
	CAST(DATEPART(yyyy, @LAST_MONTH) AS VARCHAR(4)) + 
	REPLACE(STR(DATEPART(MM, @LAST_MONTH), 2), SPACE(1), '0')
	AS INT))
PRINT @LAST_MONTH_INT

INSERT INTO [APCSProDB].[TRANS].[MATERIAL_LEDGER_HIST]
           (
           [LOCATION_ID]
           ,[WH_CODE]
           ,[CATEGORY_SHORT_NAME]
           ,[PRODUCT_NAME]
           ,[YEAR_MONTH]
           ,[MONTH_BEGIN_QTY]
           ,[MONTH_BEGIN_AMT]
		   ,[MONTH_BEGIN_AVG_UNIT_PRC]
           ,[REC1_QTY]
           ,[REC1_AMT]
		   ,[REC1_AVG_UNIT_PRC]
           ,[REC2_QTY]
           ,[REC2_AMT]
           ,[REC3_QTY]
           ,[REC3_AMT]
           ,[SERV1_QTY]
           ,[SERV1_AMT]
           ,[SERV2_QTY]
           ,[SERV2_AMT]
           ,[WH_INV_QTY]
		   ,[WH_INV_AMT]
           ,[MONTH_END_QTY]
		   ,[MONTH_END_AMT]
           ,[AVG_UNIT_PRC]
           ,[DIFF_QTY]
           ,[DEFECT_QTY]
           ,[SFILL]
           ,[CREATED_AT]
           ,[CREATED_BY]
           ,[UPDATED_AT]
           ,[UPDATED_BY]
		   ,[IN_PROCESS_QTY]) -- add by tun)
	SELECT 
           [LOCATION_ID]
           ,[WH_CODE]
           ,[CATEGORY_SHORT_NAME]
           ,[PRODUCT_NAME]
           ,[YEAR_MONTH]
           ,[MONTH_BEGIN_QTY]
           ,[MONTH_BEGIN_AMT]
		   ,[MONTH_BEGIN_AVG_UNIT_PRC]
           ,[REC1_QTY]
           ,[REC1_AMT]
		   ,[REC1_AVG_UNIT_PRC]
           ,[REC2_QTY]
           ,[REC2_AMT]
           ,[REC3_QTY]
           ,[REC3_AMT]
           ,[SERV1_QTY]
           ,[SERV1_AMT]
           ,[SERV2_QTY]
           ,[SERV2_AMT]
           ,[WH_INV_QTY]
		   ,[WH_INV_AMT]
           ,[MONTH_END_QTY]
		   ,[MONTH_END_AMT]
           ,[AVG_UNIT_PRC]
           ,[DIFF_QTY]
           ,[DEFECT_QTY]
           ,[SFILL]
           ,GETDATE()
           ,[CREATED_BY]
           ,[UPDATED_AT]
           ,[UPDATED_BY]
		   ,[IN_PROCESS_QTY] -- add by tun
		   FROM [APCSProDB].[TRANS].[MATERIAL_LEDGER_PROCESS]
		   WHERE [YEAR_MONTH] = @LAST_MONTH_INT;

		   DELETE FROM [APCSPRODB].[TRANS].[MATERIAL_LEDGER_PROCESS];

		   
			DECLARE @LASTEST_DATE AS DATETIME
			SET @LASTEST_DATE = (SELECT TOP 1 [CREATED_AT] FROM [APCSProDB].[TRANS].[MATERIAL_LEDGER_HIST] WHERE [YEAR_MONTH] = @LAST_MONTH_INT ORDER BY [CREATED_AT] DESC);
			PRINT @LASTEST_DATE
		   
		   INSERT [APCSPRODB].[TRANS].[MATERIAL_LEDGER_PROCESS] (
					LOCATION_ID,
					WH_CODE, 
					[CATEGORY_SHORT_NAME],
					[PRODUCT_NAME], 
					MONTH_BEGIN_QTY, 
					MONTH_BEGIN_AMT, 
					MONTH_BEGIN_AVG_UNIT_PRC, 
					[YEAR_MONTH],
					[REC1_QTY]
					,[REC1_AMT]
					,[REC1_AVG_UNIT_PRC]
					,[REC2_QTY]
					,[REC2_AMT]
					,[REC3_QTY]
					,[REC3_AMT]
					,[SERV1_QTY]
					,[SERV1_AMT]
					,[SERV2_QTY]
					,[SERV2_AMT]
					,[WH_INV_QTY]
				    ,[CREATED_AT]
				    ,[CREATED_BY]
				    ,[UPDATED_AT]
				    ,[UPDATED_BY]
					,[IN_PROCESS_QTY]
					,[WH_INV_AMT]
					)
				SELECT
				[HIST].LOCATION_ID, 
				[HIST].WH_CODE, 
				[CATEGORY_SHORT_NAME],
				[HIST].[PRODUCT_NAME], 
				ISNULL([HIST].[WH_INV_QTY], 0) + ISNULL([HIST].[IN_PROCESS_QTY], 0), ---ISNULL([HIST].[MONTH_END_QTY], 0), -- 2020/01/29
				ISNULL([HIST].[WH_INV_AMT], 0), --ISNULL([HIST].[MONTH_END_AMT], 0),-- 2020/01/29
				ROUND(ISNULL([HIST].AVG_UNIT_PRC, 0), 4),
				@YEAR_MONTH,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				,GETDATE(), NULL, NULL, NULL,0,0
					FROM [APCSPRODB].[TRANS].[MATERIAL_LEDGER_HIST] [HIST]
					WHERE [HIST].YEAR_MONTH = @LAST_MONTH_INT
						AND LOCATION_ID IN (SELECT ID FROM [APCSProDB].MATERIAL.LOCATIONS WHERE WH_CODE IN ('QI900', 'QI999'))
						AND [CREATED_AT] = @LASTEST_DATE;
END;

--EXEC [trans].[sp_rpt_ledger_carryover] '201911', 2, 1
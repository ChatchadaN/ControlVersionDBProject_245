-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_PD4_Progress_MachineSetup]
	-- Add the parameters for the stored procedure here
	@DateStart		DATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @CountDay		INTEGER
	DECLARE @DateTimeStart	DATETIME
	
	SET @DateTimeStart	= @DateStart
	SET @DateTimeStart	= DATEADD(HOUR,8,@DateTimeStart)

	CREATE TABLE #MACHINE_SETUP
	(
			[TestFlow]			VARCHAR(50)
			,[Job]				NVARCHAR(20)
			,[TestEquipment]	VARCHAR(50)
			,[PackageName]		VARCHAR(50)
			,[DeviceName]		VARCHAR(50)
			,[MCNo]				VARCHAR(50)
			,[Date]				DATE
	)

	SET @CountDay = 0
	
	WHILE (@CountDay < DAY(EOMONTH(@DateStart)))

	BEGIN

			INSERT INTO #MACHINE_SETUP

			SELECT DISTINCT
					REPLACE(REPLACE([TestFlow],'ASISAMPLE',' ASI (S)'),'AUTO','A') AS [TestFlow]
					,STUFF([TestFlow],5,1,'(' + SUBSTRING([TestFlow],5,1) + ')') AS [Job]
					,[TestEquipment]
					,[PackageName]
					,[DeviceName]
					,[MCNo]
					,DATEADD(DAY,@CountDay,@DateStart) AS [Date]

			FROM 

			(
					SELECT
							[DBx].[dbo].[FTSetupReportHistory].[TestFlow]
							,CASE 
								WHEN([TestBoxA] = '' AND [TestBoxB] <> '') THEN [TestBoxB]
								WHEN([TestBoxB] = '' AND [TestBoxA] <> '') THEN [TestBoxA]
								WHEN([TestBoxB] <> '' AND [TestBoxA] <> '') THEN [TestBoxA]
								ELSE NULL END
							AS [TestEquipment]
							,[DBx].[dbo].[FTSetupReportHistory].[PackageName]
							,[DBx].[dbo].[FTSetupReportHistory].[DeviceName]
							,[DBx].[dbo].[FTSetupReportHistory].[MCNo]

					FROM 
							[DBx].[dbo].[FTSetupReportHistory]

					RIGHT JOIN
							(
									SELECT		[MCNo],MAX([SetupConfirmDate]) AS [SetupConfirmDate]
									FROM		[DBx].[dbo].[FTSetupReportHistory]
									WHERE		[SetupConfirmDate] < DATEADD(DAY,@CountDay,@DateTimeStart) AND 
												([MCNo] LIKE 'FT-EP-%' OR [MCNo] LIKE 'FT-T-%' OR [MCNo] LIKE 'FT-IFZ-010') AND [MCNo] <> 'FT-EP-000'

									GROUP BY	[MCNo]
							) AS [SETUP_LAST]
					ON
							[SETUP_LAST].[MCNo] = [DBx].[dbo].[FTSetupReportHistory].[MCNo] AND
							[SETUP_LAST].[SetupConfirmDate] = [DBx].[dbo].[FTSetupReportHistory].[SetupConfirmDate]

			) AS [SETUP_DATA]

			SET @CountDay = @CountDay + 1
	END

	SELECT * FROM #MACHINE_SETUP

END

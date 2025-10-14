-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_PD4_Progress_RIST_INPUTDATA]
	-- Add the parameters for the stored procedure here
	@PackageName VARCHAR(50)
	,@DateStart DATE
	

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT 
				[DBx].[PCS].[RIST_INPUTDATA].[TYPE_NAME] AS [PackageName]
				,[DBx].[PCS].[RIST_INPUTDATA].[ROHM_NAME] AS [DeviceName]
				,[DBx].[PCS].[RIST_INPUTDATA].[INPUT_DAY] AS [InputDay]
				,[DBx].[PCS].[RIST_INPUTDATA].[LOTNO] AS [LotNo]
				,[DBx].[PCS].[RIST_INPUTDATA].[ALLOC_QTY] AS [QuantityPCS]
				,ISNULL([LeadTimeInput_Device].[LeadTime_Day],[LeadTimeInput_Package].[LeadTime_Day]) AS [LeadTime_Day]

		FROM 
				[DBx].[PCS].[RIST_INPUTDATA]

		LEFT JOIN
				OPENDATASOURCE('SQLNCLI', 'Data Source = 10.28.32.122;User ID=sa;Password=P@$$w0rd;').[DBx].[BOM_FL].[LeadTimeInput_Device] AS [LeadTimeInput_Device]
		ON
				[LeadTimeInput_Device].[Package_Name] = [DBx].[PCS].[RIST_INPUTDATA].[TYPE_NAME] 
				AND [LeadTimeInput_Device].[Device_Name] = [DBx].[PCS].[RIST_INPUTDATA].[ROHM_NAME] 

		LEFT JOIN
				OPENDATASOURCE('SQLNCLI', 'Data Source = 10.28.32.122;User ID=sa;Password=P@$$w0rd;').[DBx].[BOM_FL].[LeadTimeInput_Package] AS [LeadTimeInput_Package]
		ON
				[LeadTimeInput_Package].[Package_Name] = [DBx].[PCS].[RIST_INPUTDATA].[TYPE_NAME]

		WHERE 
				[DBx].[PCS].[RIST_INPUTDATA].[INPUT_DAY] BETWEEN DATEADD(DAY, -(15), DATEADD(MONTH, -1, @DateStart)) AND DATEADD(DAY, 15, DATEADD(MONTH, 1, @DateStart))
				--[DBx].[PCS].[RIST_INPUTDATA].[INPUT_DAY] BETWEEN DATEADD(DAY, -(15), DATEADD(MONTH, -1, @DateStart)) AND DATEADD(MONTH, 1, @DateStart)
				AND [DBx].[PCS].[RIST_INPUTDATA].[TYPE_NAME] LIKE '%' + @PackageName + '%'
				AND [DBx].[PCS].[RIST_INPUTDATA].[TIRANK] = [DBx].[PCS].[RIST_INPUTDATA].[RANK]
				AND SUBSTRING([DBx].[PCS].[RIST_INPUTDATA].[LOTNO],5,1) = 'A'
			
END

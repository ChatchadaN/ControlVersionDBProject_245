-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_rms_download] 
	-- Add the parameters for the stored procedure here
		@opNo varchar(10),
		@processName varchar(10),
		@machineType varchar(20),
		@recipeName varchar(20),
		@downloadType varchar(20),
		@approveStatus varchar(10)
AS
BEGIN
	DECLARE @tempApproveBy varchar(20) = null
	DECLARE @tempMCName varchar(20) = null
	DECLARE @tempTarget varchar(20) = null
	DECLARE @tempRecipeBody	varbinary(max)
	DECLARE @rowCount int

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		SET @rowCount = (SELECT COUNT (ID) FROM [RMS].[dbo].[Recipes]  
		WHERE [RMS].[dbo].[Recipes].[RecipeName] = @recipeName 
		AND [RMS].[dbo].[Recipes].[MCName] = @machineType 
		AND [RMS].[dbo].[Recipes].[Process] = @processName 
		AND [RMS].[dbo].[Recipes].[ApproveStatus] = @approveStatus
		AND [RMS].[dbo].[Recipes].[Target] = @downloadType)

		SELECT @tempApproveBy = [RMS].[dbo].[Recipes].[ApproveBy]
		,@tempMCName = [RMS].[dbo].[Recipes].[MCName]
		,@tempTarget = [RMS].[dbo].[Recipes].[Target]
		,@tempRecipeBody = [RMS].[dbo].[Recipes].[RecipeBody]
		FROM [RMS].[dbo].[Recipes]
		WHERE [RMS].[dbo].[Recipes].[RecipeName] = @recipename 
		AND [RMS].[dbo].[Recipes].[MCName] = @machineType 
		AND [RMS].[dbo].[Recipes].[Target] = @downloadType
		AND [RMS].[dbo].[Recipes].[Process] = @processName
		AND [RMS].[dbo].[Recipes].[ApproveStatus] = @approveStatus

		INSERT INTO [RMS].[dbo].[Transaction] 
		([RMS].[dbo].[Transaction].[Process]
		,[RMS].[dbo].[Transaction].[RecipeName]
		,[RMS].[dbo].[Transaction].[TransactionType]
		,[RMS].[dbo].[Transaction].[RequestBy]
		,[RMS].[dbo].[Transaction].[RequestDate]
		,[RMS].[dbo].[Transaction].[MCName]
		,[RMS].[dbo].[Transaction].[Target]
		,[RMS].[dbo].[Transaction].[Remark])
		VALUES (@processName,@recipeName,'Download',@opNo,(SELECT GETDATE()),@machineType,@downloadType,'')
		
		IF @rowCount = 0 
			BEGIN
				SELECT 'FALSE' AS Is_Pass,'Recipe := ' + @recipeName + ' not found' AS Error_Message_ENG
				,N'ไม่พบข้อมูล Recipe := ' + @recipeName AS Error_Message_THA, N'กรุณาติดต่อ PM' AS Handling
			END
		ELSE IF @rowCount > 1
			BEGIN
				SELECT 'FALSE' AS Is_Pass,'Recipe := ' + @recipeName + ' More than 1 ' AS Error_Message_ENG
				,'Recipe := ' + @recipeName + N' มากกว่า 1 ' AS Error_Message_THA, N'กรุณาติดต่อ system' AS Handling
			END
		ELSE IF @tempApproveBy = null
			BEGIN
				SELECT 'FALSE' AS Is_Pass,'Recipe := ' + @recipeName + ' not approve' AS Error_Message_ENG
				,N'Recipe := ' + @recipeName + N' ยังไม่ถูก Approve ' AS Error_Message_THA, N'กรุณาติดต่อ PM' AS Handling
			END
		ELSE
			BEGIN
				SELECT 'TRUE' AS Is_Pass,'' AS Error_Message_ENG,N'' AS Error_Message_THA, N'' AS Handling
				,@tempMCName AS MachineType ,@recipeName as RecipeName ,@tempRecipeBody as RecipeBody
			END
END
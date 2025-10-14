-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_rms_upload] 
	-- Add the parameters for the stored procedure here
		@opNo varchar(10),
		@mcNo varchar(20),
		@processName varchar(10),
		@machineType varchar(20),
		@recipeName varchar(20),
		@recipeBody varbinary(max),
		@uploadType varchar(20),
		@remark varchar(250)

AS
BEGIN
DECLARE @tempRecipeCount int
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	

	SET @tempRecipeCount = (SELECT COUNT (ID) FROM [RMS].[dbo].[Recipes]  
		WHERE [RMS].[dbo].[Recipes].[RecipeName] = @recipeName AND [RMS].[dbo].[Recipes].[MCName] = @machineType AND [RMS].[dbo].[Recipes].[Process] = @processName)

	IF (SELECT COUNT ([RMS].[dbo].[Target].Target) FROM [RMS].[dbo].[Target] WHERE [RMS].[dbo].[Target].[Target] = @uploadType) = 0
		BEGIN
			SELECT 'FALSE' AS Is_Pass,'UploadType := ' + @uploadType + ' not in setting' AS Error_Message_ENG
			,'UploadType := ' + @uploadType + N' ไม่สามารถใช้ได้' AS Error_Message_THA, N'กรุณาติดต่อ System' AS Handling
		END

	IF @tempRecipeCount > 0 
		BEGIN
			SELECT 'FALSE' AS Is_Pass,'This Recipe := ' + @recipeName + ' already in database' AS Error_Message_ENG
			,'Recipe := ' + @recipeName + N' มีอยู่ในฐานข้อมูลแล้ว' AS Error_Message_THA, N'กรุณาติดต่อหัวหน้างาน' AS Handling
		END
	ELSE
		BEGIN
			INSERT INTO [RMS].[dbo].[Recipes] 
			([RMS].[dbo].[Recipes].[Process]
			,[RMS].[dbo].[Recipes].[RecipeName]
			,[RMS].[dbo].[Recipes].[RecipeBody]
			,[RMS].[dbo].[Recipes].[ApproveStatus]
			,[RMS].[dbo].[Recipes].[UploadBy]
			,[RMS].[dbo].[Recipes].[UploadDate]
			,[RMS].[dbo].[Recipes].[ApproveBy]
			,[RMS].[dbo].[Recipes].[ApproveDate]
			,[RMS].[dbo].[Recipes].[MCName]
			,[RMS].[dbo].[Recipes].[Target]) 
			VALUES(@processName,@RecipeName,@RecipeBody,'Approve',@opNo,(SELECT GETDATE()),NULL,NULL,@machineType,@uploadType)

			INSERT INTO [RMS].[dbo].[Transaction] 
			([RMS].[dbo].[Transaction].[Process]
			,[RMS].[dbo].[Transaction].[RecipeName]
			,[RMS].[dbo].[Transaction].[TransactionType]
			,[RMS].[dbo].[Transaction].[RequestBy]
			,[RMS].[dbo].[Transaction].[RequestDate]
			,[RMS].[dbo].[Transaction].[MCName]
			,[RMS].[dbo].[Transaction].[Target]
			,[RMS].[dbo].[Transaction].[Remark])
			VALUES (@processName,@recipeName,'Upload',@opNo,(SELECT GETDATE()),@machineType,@uploadType,@remark)

			SELECT 'TRUE' AS Is_Pass,'' AS Error_Message_ENG,'' AS Error_Message_THA, '' AS Handling
		END

--SELECT @target as test

END

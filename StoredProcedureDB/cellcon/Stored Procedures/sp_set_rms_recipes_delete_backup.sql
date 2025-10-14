-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_rms_recipes_delete_backup]
	-- Add the parameters for the stored procedure here
		@process varchar(10),
		@recipe varchar(50),
		@opno varchar(10),
		@mcName varchar(50),
		@approveStatus nvarchar(50),
		@remark nvarchar(250)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @recipeBody varbinary(max)
	DECLARE @uploadBy varchar(50) = ''
	DECLARE @uploadDate datetime
	DECLARE @approveBy varchar(50)
	DECLARE @approveDate datetime = (SELECT GETDATE())
	DECLARE @target varchar(20)
	DECLARE @backupDate datetime = (SELECT GETDATE())

    -- Insert statements for procedure here
	SELECT @recipeBody = [RecipeBody]
      ,@uploadBy = [UploadBy]
      ,@uploadDate = [UploadDate]
      ,@approveBy = [ApproveBy]
      ,@approveDate = [ApproveDate]
      ,@target = [Target]
	FROM [RMS].[dbo].[Recipes] WHERE [Process] = @process AND [RecipeName] = @recipe AND [MCName] = @mcName AND [ApproveStatus] = @approveStatus

	IF (@uploadBy != '')
	BEGIN
		INSERT INTO [RMS].[dbo].[BackupInfo]
			   ([Process]
			   ,[RecipeName]
			   ,[RecipeBody]
			   ,[Target]
			   ,[BackupBy]
			   ,[BackupDate]
			   ,[UploadBy]
			   ,[UploadDate]
			   ,[ApproveBy]
			   ,[ApproveDate]
			   ,[MCName]
			   ,[Remark]
			   ,[ApproveStatus])
		 VALUES
			   (@process
			   ,@recipe
			   ,@recipeBody
			   ,@target
			   ,@opno
			   ,@backupDate
			   ,@uploadBy
			   ,@uploadDate
			   ,@approveBy
			   ,@approveDate
			   ,@mcName
			   ,@remark
			   ,@approveStatus)

		INSERT INTO [RMS].[dbo].[BackupDeleteHistory]
			([TimeStamp]
			,[Process]
			,[RecipeName]
			,[Target]
			,[OperateBy]
			,[UploadBy]
			,[UploadDate]
			,[ApproveBy]
			,[ApproveDate]
			,[MCName]
			,[Remark])
		VALUES
			(@backupDate
			,@process
			,@recipe
			,@target
			,@opno
			,@uploadBy
			,@uploadDate
			,@approveBy
			,@approveDate
			,@mcName
			,@remark)

		DELETE FROM [RMS].[dbo].[Recipes] WHERE [Process] = @process AND [RecipeName] = @recipe AND [MCName] = @mcName AND [ApproveDate] = @approveDate AND [ApproveBy] = @approveBy

		SELECT 'TRUE' AS Is_Pass,'' AS Error_Message_ENG
					,N'' AS Error_Message_THA
					,N'' AS Handling
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Is_Pass,'Recipe : ' + @recipe + ' not found' AS Error_Message_ENG
		,N'ไม่พบ Recipe : ' + @recipe AS Error_Message_THA
		,N'ทำการตรวจสอบใหม่อีกครั้ง' AS Handling
	END


END

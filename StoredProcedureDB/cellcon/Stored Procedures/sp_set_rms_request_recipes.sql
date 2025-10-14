-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_rms_request_recipes]
	-- Add the parameters for the stored procedure here
		@process varchar(10),
		@recipe varchar(50),
		@opno varchar(10),
		@mcName varchar(50),
		@remark nvarchar(100),
		@approveStatus nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @recipeBody varbinary(max)
	DECLARE @uploadBy varchar(50) = ''
	DECLARE @uploadDate datetime
	DECLARE @approveDate datetime = (SELECT GETDATE())

	IF (@approveStatus = 'Approve' or @approveStatus = 'Deny')
	BEGIN
	
		SELECT  @recipeBody = [RecipeBody]
			,@uploadDate = [UploadDate]
			,@uploadBy = [UploadBy]
		FROM [RMS].[dbo].[ApproveRequest]
		WHERE [RecipeName] = @recipe and [Process] = @process and [MCName] = @mcName;


	  IF (@uploadBy != '')
	  BEGIN
			IF (@approveStatus = 'Approve')
			BEGIN
			
				INSERT INTO [RMS].[dbo].[Recipes]
					   ([Process]
					   ,[RecipeName]
					   ,[RecipeBody]
					   ,[ApproveStatus]
					   ,[UploadBy]
					   ,[UploadDate]
					   ,[ApproveBy]
					   ,[ApproveDate]
					   ,[MCName]
					   ,[Target])
				 VALUES
					   (@process
					   ,@recipe
					   ,@recipeBody
					   ,@approveStatus
					   ,@uploadBy
					   ,@uploadDate
					   ,@opno
					   ,@approveDate
					   ,@mcName
					   ,'Central');


			END

			INSERT INTO [RMS].[dbo].[ApprovementHistory]
					([Process]
					,[RecipeName]
					,[ApproveStatus]
					,[ApproveBy]
					,[ApproveDate]
					,[UploadBy]
					,[UploadDate]
					,[Remark])
				VALUES
					(@process
					,@recipe
					,@approveStatus
					,@opno
					,@approveDate
					,@uploadBy
					,@uploadDate
					,@remark);		

			DELETE FROM [RMS].[dbo].[ApproveRequest] WHERE [RecipeName] = @recipe AND [UploadBy] = @uploadBy AND [Process] = @process AND [MCName] = @mcName AND [UploadDate] = @uploadDate;

			SELECT 'TRUE' AS Is_Pass,'' AS Error_Message_ENG
					,N'' AS Error_Message_THA
					,N'' AS Handling

		END ELSE
		BEGIN
					SELECT 'FALSE' AS Is_Pass,'Recipe : ' + @recipe + ' not found' AS Error_Message_ENG
					,N'ไม่พบ Recipe : ' + @recipe AS Error_Message_THA
					,N'ทำการตรวจสอบใหม่อีกครั้ง' AS Handling
		END		
	END	ELSE
	BEGIN
		SELECT 'FALSE' AS Is_Pass,'Approve status invalid' AS Error_Message_ENG
					,N'Approve status ไม่ถูกต้อง' AS Error_Message_THA
					,N'Approve status ได้เฉพาะ "Approve" หรือ "Deny"' AS Handling
	END
END

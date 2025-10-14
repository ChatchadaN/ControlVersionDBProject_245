-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_rms_request] 
	-- Add the parameters for the stored procedure here
	@mcName varchar(20) = '%',
	@opRequest varchar(10) = '%',
	@startDate datetime,
	@endDate datetime

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SELECT TOP (100)[Process]
      ,[RecipeName]
      ,[UploadDate]
      ,[UploadBy]
      ,[MCName]
      ,[Remark]
  FROM [RMS].[dbo].[ApproveRequest]
  WHERE [UploadDate] between @startDate and @endDate AND MCName LIKE @mcName AND UploadBy LIKE @opRequest
END

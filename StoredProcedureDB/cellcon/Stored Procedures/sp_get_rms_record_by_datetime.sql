-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_rms_record_by_datetime] 
	-- Add the parameters for the stored procedure here
	@startDate datetime,
	@endDate datetime,
	@recipe varchar(20),
	@mcname varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		SELECT [RMS].[dbo].[Recipes].[ID]
      ,[RMS].[dbo].[Recipes].[Process]
      ,[RMS].[dbo].[Recipes].[RecipeName]
      ,[RMS].[dbo].[Recipes].[ApproveStatus]
      ,[RMS].[dbo].[Recipes].[UploadBy]
      ,[RMS].[dbo].[Recipes].[UploadDate]
      ,[RMS].[dbo].[Recipes].[ApproveBy]
      ,[RMS].[dbo].[Recipes].[ApproveDate]
      ,[RMS].[dbo].[Recipes].[MCName]
      ,[RMS].[dbo].[Recipes].[Target]
  FROM [RMS].[dbo].[Recipes]
  WHERE [RMS].[dbo].[Recipes].[RecipeName] LIKE @recipe AND [RMS].[dbo].[Recipes].[MCName] LIKE @mcname AND [RMS].[dbo].[Recipes].[UploadDate] BETWEEN @startDate AND @endDate

END

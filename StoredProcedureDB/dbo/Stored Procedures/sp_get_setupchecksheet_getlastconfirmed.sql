-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_getlastconfirmed]
	-- Add the parameters for the stored procedure here
	@MCNo varchar(30), @lotNo varchar(10) = '%', @isShoko bit = 0, @isGoodng bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	If(@isShoko = 0 And @isGoodng = 0)
	BEGIN
		SELECT TOP(1) *
		FROM [DBx].[dbo].[FTSetupReportHistory]
		WHERE MCNo = @MCNo 
		 AND LotNo like @lotNo
		 AND (SetupStatus = 'CONFIRMED' OR SetupStatus = 'GOODNGTEST')
		ORDER BY id DESC
	END

	ELSE IF (@isShoko = 1 And @isGoodng = 0)
	BEGIN
		SELECT TOP(1) *
		FROM [DBx].[dbo].[FTSetupReportHistory]
		WHERE MCNo = @MCNo 
		 AND LotNo like @lotNo
		 AND (SetupStatus = 'CONFIRMED' OR SetupStatus = 'GOODNGTEST')
		 AND StatusShonoOP = @isShoko
		ORDER BY id DESC
	END

	ELSE IF (@isShoko = 0 And @isGoodng = 1)
	BEGIN
		SELECT TOP(1) *
		FROM [DBx].[dbo].[FTSetupReportHistory]
		WHERE MCNo = @MCNo 
		 AND LotNo like @lotNo
		 AND (SetupStatus = 'GOODNGTEST')
		ORDER BY id DESC
	END

	ELSE
	BEGIN
		SELECT TOP(1) *
		FROM [DBx].[dbo].[FTSetupReportHistory]
		WHERE MCNo = @MCNo 
		 AND LotNo like @lotNo
		 AND (SetupStatus = 'GOODNGTEST')
		 AND StatusShonoOP = @isShoko
		ORDER BY id DESC
	END
END

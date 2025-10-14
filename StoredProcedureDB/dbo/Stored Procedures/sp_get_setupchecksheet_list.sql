-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_list]
	-- Add the parameters for the stored procedure here
	@lotNo varchar(20) = '%', @isGoodNG bit = 0, @isCurrent bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @setupStatus varchar(20) = ''
	SET NOCOUNT ON;

	IF(@isGoodNG = 1)
	BEGIN
		SET @setupStatus = 'GOODNGTEST'
	END
	ELSE
		SET @setupStatus = 'CONFIRMED'
	END

    -- Insert statements for procedure here
	IF(@isCurrent = 1)
	BEGIN
		SELECT *
		FROM DBx.dbo.FTSetupReport
		WHERE LotNo = @lotNo AND SetupStatus = @setupStatus
	END
	ELSE
	BEGIN
		SELECT *
		FROM DBx.dbo.FTSetupReportHistory
		WHERE LotNo = @lotNo AND SetupStatus = @setupStatus
	END

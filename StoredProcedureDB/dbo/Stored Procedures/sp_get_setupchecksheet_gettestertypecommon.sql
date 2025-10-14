-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_gettestertypecommon]
	-- Add the parameters for the stored procedure here
	@testerType varchar(50),
	@testerType2 varchar(50) = '%',
	@testerType3 varchar(50) = '%',
	@testerType4 varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [BomTesterType]
	FROM [DBx].[BOM].[TesterTypeCommon]
	WHERE EqpTesterType like @testerType

	INTERSECT

	SELECT [BomTesterType]
	FROM [DBx].[BOM].[TesterTypeCommon]
	WHERE EqpTesterType like @testerType2

	INTERSECT

	SELECT [BomTesterType]
	FROM [DBx].[BOM].[TesterTypeCommon]
	WHERE EqpTesterType like @testerType3

	INTERSECT

	SELECT [BomTesterType]
	FROM [DBx].[BOM].[TesterTypeCommon]
	WHERE EqpTesterType like @testerType4
END

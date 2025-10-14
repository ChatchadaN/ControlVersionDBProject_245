-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [req].[sp_set_location_compared]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE FROM [APCSProDWR].[req].[location_compared];

	INSERT INTO [APCSProDWR].[req].[location_compared]
	SELECT [old].[id]
		, [new].[id]
		, [new].[key]
	FROM (
		SELECT [id]
			  , [name] + [address] AS [key]
		FROM [APCSProDB].[trans].[locations]
		WHERE [headquarter_id] = 1
	) AS [old]
	INNER JOIN (
		SELECT [id]
		  , [name] + [address] AS [key]
		FROM [10.29.1.230].[DWH].[trans].[locations]
	) AS [new] ON [old].[key] = [new].[key];
END
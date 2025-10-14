-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_mslevel_data]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here

	-------------------------------------------------------------------------------------------------------
	-- (1) delete table mslevel_data
	-------------------------------------------------------------------------------------------------------
	DELETE FROM [APCSProDB].[method].[mslevel_data];

	-------------------------------------------------------------------------------------------------------
	-- (2) insert from is.mslevel_data to pro.mslevel_data
	-------------------------------------------------------------------------------------------------------
	INSERT INTO [APCSProDB].[method].[mslevel_data]
	( 
		[Product_Name]
		, [Starting_Date]
		, [Spec]
		, [Floor_Life]
		, [PPBT]
		, [Date_Time]
	)
	SELECT [Product_Name]
		, [Starting_Date]
		, [Spec]
		, [Floor_Life]
		, [PPBT]
		, [Date_Time]
	FROM [ISDB].[DBLSISHT].[dbo].[MSLEVEL_DATA];
	---------------------------------------------------------------------------------------------
END

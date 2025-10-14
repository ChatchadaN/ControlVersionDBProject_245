
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_trans_lots_details_001]	-- Add the parameters for the stored procedure here	
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	SELECT [lots].[lot_no]
		, ISNULL([device_f].[R_Fukuoka_Model_Name], [device_names].[assy_name]) AS [device]
		, [packages].[short_name] AS [package]
		, IIF([lot_masks].[lot_no] IS NULL,0,1) AS [status_data]
		, [lot_masks].[mno] AS [mark_data]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
	LEFT JOIN (
		SELECT [ROHM_Model_Name], [ASSY_Model_Name], [R_Fukuoka_Model_Name] 
		FROM [APCSProDB].[method].[allocat_temp]
		GROUP BY [ROHM_Model_Name], [ASSY_Model_Name], [R_Fukuoka_Model_Name] 
	) AS [device_f] ON [device_names].[name] = [device_f].[ROHM_Model_Name] 
		AND [device_names].[assy_name] = [device_f].[ASSY_Model_Name]
	LEFT JOIN [APIStoredProDB].[dbo].[lot_masks] ON [lots].[lot_no] = [lot_masks].[lot_no]
	WHERE [lots].[lot_no] = @lot_no;
END

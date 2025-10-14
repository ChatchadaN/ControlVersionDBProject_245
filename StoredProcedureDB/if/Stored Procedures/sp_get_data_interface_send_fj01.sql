-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_send_fj01]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 'QI100' AS [pdcd]
		, ISNULL([cps_data_temp].[device_name], [dn].[name]) AS [device_name]
		, ISNULL([cps_data_temp].[rank], ISNULL([dn].[rank], '     ')) AS [rank]
		, ISNULL([cps_data_temp].[tp_rank], ISNULL([dn].[tp_rank], '   ')) AS [tp_rank]	
		, ISNULL([cps_data_temp].[package_name], [pk].[short_name]) AS [package_name]
		, [v_cps_stk_temp].[lot_no]
		, [v_cps_stk_temp].[qty] AS [qty]
		, FORMAT([v_cps_stk_temp].[updated_at], 'yyMMdd') AS [date]
	FROM [APCSProDWH].[if].[v_cps_stk_temp]
	LEFT JOIN [APCSProDWH].[if].[cps_data_temp] ON [v_cps_stk_temp].[lot_no] = [cps_data_temp].[lot_no]
	LEFT JOIN [APCSProDB].[trans].[lots] ON [v_cps_stk_temp].[lot_no] = [lots].[lot_no]
	LEFT JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id] 
	LEFT JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id] 
END
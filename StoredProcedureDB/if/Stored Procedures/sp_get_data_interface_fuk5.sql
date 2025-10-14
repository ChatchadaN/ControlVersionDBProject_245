-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_fuk5]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [ct].[short_name] AS [STOCKCLASS]
		, (CASE WHEN [lc].[wh_code] <> 'QI999' THEN 'QI900' ELSE 'QI999' END) AS [PDCD]
		, CAST(pr.[name] AS CHAR(20)) AS [PRODUCTION_NAME]
		, FORMAT([mt].[quantity], '000000000') AS [QUANTITY]
		, [pr].[supplier_cd] AS [SUPPLIER]
		, CAST(RIGHT([mt].[barcode], 12) AS CHAR(12)) AS [SEQ_NO]
		, FORMAT([ar].[recorded_at], 'yyyyMMdd') AS [IN_DATE]
	FROM [APCSProDB].[trans].[materials] AS [mt]
	INNER JOIN [APCSProDB].[material].[productions] AS [pr] ON [pr].[id] = [mt].[material_production_id]
	INNER JOIN [APCSProDB].[material].[categories] AS [ct] ON [ct].[id] = [pr].[category_id]
	INNER JOIN [APCSProDB].[material].[locations] AS [lc] ON [mt].[location_id] = [lc].[id]
	INNER JOIN [APCSProDB].[trans].[material_arrival_records] AS [ar] ON [ar].[material_id] = [mt].[id] 
		AND NOT EXISTS (
			SELECT [ar2].[material_id] 
			FROM [APCSProDB].[trans].[material_arrival_records] AS [ar2]
			WHERE [ar2].[material_id] = [ar].[material_id]
				AND [ar2].[recorded_at] > [ar].[recorded_at]
		)
	WHERE [ct].[short_name] = '03'  /*03:frame*/
		AND [lc].[wh_code] IN ('QI900', 'QI999')
		AND [mt].[quantity] <> 0
	ORDER BY [mt].[barcode];
END

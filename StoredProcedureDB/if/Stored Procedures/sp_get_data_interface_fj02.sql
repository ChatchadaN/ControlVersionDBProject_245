-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_fj02]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---- Version 3 2025/05/06 13:50
	SELECT [LOT_NO]
		, [ROHM_MODEL_NAME]
		, [RANK]
		, [TPRANK]	
		, [TYPE_NAME]
		, [STOCKCLASS]
		, [QTY]
		, [PDCD]
		, [CREATEDDATE]
	FROM (
		SELECT DISTINCT CAST([lots].[lot_no] AS VARCHAR(10)) AS [LOT_NO]
			, ISNULL([hasuu_data_temp].[device_name], [dn].[name]) AS [ROHM_MODEL_NAME]
			, ISNULL([hasuu_data_temp].[rank], ISNULL([dn].[rank], '     ')) AS [RANK]
			, ISNULL([hasuu_data_temp].[tp_rank], ISNULL([dn].[tp_rank], '   ')) AS [TPRANK]	
			, ISNULL([hasuu_data_temp].[package_name], [pk].[short_name]) AS [TYPE_NAME]
			, [sur].[stock_class] AS [STOCKCLASS]
			, ( CASE
				WHEN SUBSTRING([lots].[lot_no], 5, 1) = 'D'  THEN 
					( CASE
						WHEN [lots].[production_category] IN (20, 23, 70) 
							AND ([lots].[pc_instruction_code] IS NULL OR [lots].[pc_instruction_code] = 0)
						THEN 
							( CASE 
								WHEN [lots].[wip_state] IN (100, 70) THEN (0 + [sur].[pcs])
								ELSE [lots].[qty_out] + [sur].[pcs]
							END )
						ELSE (0 + [sur].[pcs])
					END )
				ELSE 
					( CASE 
						WHEN [lots].[wip_state] IN (100, 70) THEN (0 + [sur].[pcs])
						ELSE [lots].[qty_out] + [sur].[pcs]
					END )
			END ) AS [QTY]
			, 'QI000' AS [PDCD]
			, FORMAT([sur].[created_at], 'yyMMdd') AS [CREATEDDATE]
		FROM [APCSProDB].[trans].[surpluses] AS [sur]
		LEFT JOIN [APCSProDWH].[if].[hasuu_data_temp] ON [sur].[serial_no] = [hasuu_data_temp].[lot_no]
		LEFT JOIN [APCSProDB].[trans].[lots] ON [sur].[lot_id] = [lots].[id]
		LEFT JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id] 
		LEFT JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id]
		LEFT JOIN [APCSProDB].[method].[allocat_temp] AS [a_temp] ON [lots].[lot_no] = [a_temp].[LotNo]
		OUTER APPLY (
			SELECT [R_Fukuoka_Model_Name]
			FROM [APCSProDB].[method].[allocat_temp]
			WHERE ([ROHM_Model_Name] = [dn].[name])
				AND ([a_temp].[R_Fukuoka_Model_Name] IS NULL)
			GROUP BY [R_Fukuoka_Model_Name]
		) AS [a_temp_other]
		WHERE [sur].[in_stock] IN (2, 4)
			AND [sur].[pcs] >= 0
	) AS [table_fj02]
	ORDER BY [STOCKCLASS], [ROHM_MODEL_NAME], [LOT_NO];
	
	---- Version 2
	--SELECT *
	--FROM (
	--	SELECT DISTINCT CAST([lots].[lot_no] AS VARCHAR(10)) AS [LOT_NO]
	--		, ISNULL([hasuu_data_temp].[device_name], [dn].[name]) AS [ROHM_MODEL_NAME]
	--		, ISNULL([hasuu_data_temp].[rank], ISNULL([dn].[rank], '     ')) AS [RANK]
	--		, ISNULL([hasuu_data_temp].[tp_rank], ISNULL([dn].[tp_rank], '   ')) AS [TPRANK]	
	--		, ISNULL([hasuu_data_temp].[package_name], [pk].[short_name]) AS [TYPE_NAME]
	--		, [sur].[stock_class] AS [STOCKCLASS]
	--		, IIF(SUBSTRING([lots].[lot_no], 5, 1) = 'D' 
	--			, IIF([lots].[production_category] IN (20, 23, 70) 
	--				AND [lots].[pc_instruction_code] IS NULL
	--				, IIF([lots].[wip_state] IN (100, 70)
	--					, (0 + [sur].[pcs])
	--					, (ISNULL([dn].[pcs_per_pack], 0) * ([lots].[qty_in] / ISNULL([dn].[pcs_per_pack], 0))) + [sur].[pcs]
	--				)
	--				, (0 + [sur].[pcs])
	--			)
	--			, (0 + [sur].[pcs])
	--		) AS [QTY]
	--		, 'QI000' AS [PDCD]
	--		, FORMAT([sur].[created_at], 'yyMMdd') AS [CREATEDDATE]
	--	FROM [APCSProDB].[trans].[surpluses] AS [sur]
	--	LEFT JOIN [APCSProDWH].[if].[hasuu_data_temp] ON [sur].[serial_no] = [hasuu_data_temp].[lot_no]
	--	LEFT JOIN [APCSProDB].[trans].[lots] ON [sur].[lot_id] = [lots].[id]
	--	LEFT JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id] 
	--	LEFT JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id]
	--	WHERE ( [sur].[in_stock] = 2 )
	--		AND ( [sur].[pcs] >= 0 )
	--) AS [table_fj02]
	--ORDER BY [STOCKCLASS], [ROHM_MODEL_NAME], [LOT_NO];

	---- Version 1
	--SELECT CAST( [lot].[lot_no] AS VARCHAR(10) ) AS [LOT_NO] 
	--	, [dn].[name] AS [ROHM_MODEL_NAME] 
	--	, [dn].[rank] AS [RANK] 
	--	, [dn].[tp_rank] AS [TPRANK] 
	--	, [pk].[short_name] AS [TYPE_NAME] 
	--	, [sur].[stock_class] AS [STOCKCLASS] 
	--	, CASE  
	--		WHEN [lot].[wip_state] IN (70,100) THEN [sur].[pcs] 
	--		ELSE 
	--	   		CASE 
	--	   			WHEN SUBSTRING( [sur].[serial_no], 5, 1 ) = 'D' THEN [lot].[qty_out] + [sur].[pcs] 
	--	   			ELSE [sur].[pcs] 
	--	   		END 
	--	END AS [QTY] 
	--	, 'QI000' AS [PDCD] 
	--	, CAST( FORMAT( [sur].[created_at], 'yyMMdd' ) AS CHAR(6) ) AS [CREATEDDATE] 
	--FROM [APCSProDB].[trans].[surpluses] AS [sur] 
	--INNER JOIN [APCSProDB].[trans].[lots] AS [lot] ON [sur].[lot_id] = [lot].[id] 
	--INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [lot].[act_package_id] = [pk].[id] 
	--INNER JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lot].[act_device_name_id] = [dn].[id] 
	--WHERE ( [sur].[in_stock] = 2 ) 
	--	AND ( [sur].[pcs] >= 0 ) 
	--	AND ( SUBSTRING( [sur].[serial_no], 1, 3 ) <> 0 ) 
	--ORDER BY [sur].[stock_class], [dn].[name], [lot].[lot_no];
	---- Version 2
	--SELECT *
	--FROM ( 
	--	SELECT DISTINCT CAST( [lot].[lot_no] AS VARCHAR(10) ) AS [LOT_NO] 
	--		, [dn].[name] AS [ROHM_MODEL_NAME] 
	--		, [dn].[rank] AS [RANK] 
	--		, [dn].[tp_rank] AS [TPRANK] 
	--		, [pk].[short_name] AS [TYPE_NAME] 
	--		, [sur].[stock_class] AS [STOCKCLASS] 
 --   		, CASE  
 --   			WHEN [lot].[wip_state] IN (70,100) THEN [sur].[pcs] 
 --   			ELSE 
 --   				CASE 
 --   					WHEN SUBSTRING( [sur].[serial_no], 5, 1 ) = 'D' THEN [lot].[qty_out] + [sur].[pcs] 
 --   					ELSE [sur].[pcs] 
 --   				END 
 --   		END AS [QTY] 
 --   		, 'QI000' AS [PDCD] 
 --   		, CAST( FORMAT( [sur].[created_at], 'yyMMdd' ) AS CHAR(6) ) AS [CREATEDDATE] 
	--	FROM [APCSProDB].[trans].[surpluses] AS [sur] 
	--	INNER JOIN [APCSProDB].[trans].[lots] AS [lot] ON [sur].[lot_id] = [lot].[id] 
	--	INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [lot].[act_package_id] = [pk].[id] 
	--	INNER JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lot].[act_device_name_id] = [dn].[id] 
	--	WHERE ( [sur].[in_stock] = 2 ) 
 --   		AND ( [sur].[pcs] >= 0 ) 
 --   		AND ( SUBSTRING( [sur].[serial_no], 1, 3 ) <> 0 ) 		
	--) AS [table_fj02]
	--ORDER BY [STOCKCLASS], [ROHM_MODEL_NAME], [LOT_NO];
END
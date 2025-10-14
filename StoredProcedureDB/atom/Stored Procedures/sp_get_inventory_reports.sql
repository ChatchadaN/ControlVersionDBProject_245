-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_inventory_reports]
	@ClassNo NVARCHAR(100)  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @StockClass VARCHAR(2)

	SELECT @StockClass = [stock_class]
	FROM [APCSProDB].[inv].[Inventory_classfications]
	WHERE [class_no] = @ClassNo;
	
	SELECT 0 AS [MACHINE_NO]
		, [ITEM]
		, [LOTNO]
		, [QTY]
		, [FCOINO]
		, [SHEET_NO]
		, [RACK_NO]
		, [inputDate]
		, [Stock_Class]
		, [TYPE]
		, [RMODEL]
		, [AMODEL]
		, [TPRANK]
		, [TIRANK]
		, [LINE_NO]
		, [CLASSIFICATION_NO]
		, [PROCESS_NAME]
		, '' AS [FLOOR]
		, [Seq]
		, NULL AS [IP]
		, [Report_Type]
	FROM (
		SELECT [ITEM]
			, [LOTNO]
			, [QTY]
			, ISNULL([FCOINO], [Run]) AS [FCOINO]
			, [HEAD_INVEN] + FORMAT((DENSE_RANK() OVER (
					PARTITION BY [CLASSIFICATION_NO] 
					ORDER BY [CLASSIFICATION_NO] ASC
			  			, [CLASSIFICATION_ID] ASC
			  			, [RACK_NO] ASC
			  			, [SHEET_NO] ASC )
			  		),'000'
			) AS [SHEET_NO]
			, [RACK_NO]
			, [inputDate]
			, [Stock_Class]
			, [TYPE]
			, [RMODEL]
			, [AMODEL]
			, [TPRANK]
			, [TIRANK]
			, [LINE_NO]
			, [CLASSIFICATION_NO]
			, [PROCESS_NAME]
			, [Seq]
			, [Report_Type]
		FROM (
			SELECT [device_names].[assy_name] AS [ITEM]
				, [lot_inventory].[lot_no] AS [LOTNO]
				, CASE WHEN [Stock_Class] = '01' THEN 'WORK IN PROCESS'
					ELSE 'HASUU'
				END AS [Report_Type]
				, CASE WHEN [Stock_Class] = '01' THEN
					( CASE WHEN [lot_inventory].[job_id] = 317 THEN
							( CASE WHEN ([lot_inventory].[qty_out] IS NULL OR [lot_inventory].[qty_out] = 0) OR [lots].pc_instruction_code = 11 THEN [lot_inventory].[qty_pass]
								ELSE [lot_inventory].[qty_out]
							END )
						WHEN EXISTS (   
							SELECT TOP 1 [lots].[lot_no]
							FROM [APCSProDB].[trans].[lots]
							INNER JOIN [APCSProDB].[trans].[lot_process_records] ON [lots].[id] = [lot_process_records].[lot_id]
								AND [lot_process_records].[record_class] = 1 /*1 :LotStart*/
								AND [lot_process_records].[job_id] IN ( 93, 199, 209, 222, 236, 289, 293, 323, 332, 369, 401, 92, 143, 287 )
							WHERE [lots].[lot_no] = [APCSProDB].[trans].[lot_inventory].[lot_no]
						) THEN
						   IIF( ([lot_inventory].[qty_out] IS NULL OR [lot_inventory].[qty_out] = 0)
								, [lot_inventory].[qty_pass]
								, [lot_inventory].[qty_pass] )
						ELSE IIF( ( [lot_inventory].[qty_out] IS NULL OR [lot_inventory].[qty_out] = 0 )
							   , [lot_inventory].[qty_pass]
							   , [lot_inventory].[qty_pass] )
					END ) 
					ELSE [lot_inventory].[qty_hasuu]
				END AS [QTY]
				, [lot_inventory].[address] AS [FCOINO]
				, [lot_inventory].[location_id] AS [RACK_NO] 
				, ISNULL([lot_inventory].[created_at], GETDATE()) AS [inputDate]
				, [Stock_Class]
				, [packages].[short_name] AS [TYPE]
				, [device_names].[name] AS [RMODEL]
				, [device_names].[assy_name] AS [AMODEL]
				, '' AS [TPRANK]
				, '' AS [TIRANK]
				, (ROW_NUMBER() OVER (
						PARTITION BY [condition].[class_no]
							, [lot_inventory].[location_id]
						ORDER BY ( CASE WHEN [lot_inventory].[location_id] = 'ON MACHINE' THEN  CAST(1 AS BIT)
									ELSE CAST(0 AS BIT)
								END ) ASC
							, [lot_inventory].[location_id] ASC
							, [lot_inventory].[id] ASC )
				) AS [Run]
				, ( CASE WHEN (ROW_NUMBER() OVER (
						PARTITION BY [condition].[class_no]
							, [lot_inventory].[location_id]
						ORDER BY ( CASE WHEN [lot_inventory].[location_id] = 'ON MACHINE' THEN CAST(1 AS BIT)
									ELSE CAST(0 AS BIT)
								END ) ASC
							, [lot_inventory].[location_id] ASC
							, [lot_inventory].[id] ASC ) % 30
					) = 0 THEN 30	  
					ELSE (ROW_NUMBER() OVER (
						PARTITION BY [condition].[class_no]
							, [lot_inventory].[location_id]
						ORDER BY ( CASE WHEN [lot_inventory].[location_id] = 'ON MACHINE' THEN  CAST(1 AS BIT)
									ELSE CAST(0 AS BIT)
								END ) ASC
							, [lot_inventory].[location_id] ASC
							, [lot_inventory].[id] ASC ) % 30 )
				END ) AS [LINE_NO]
				, [condition].[class_no] AS [CLASSIFICATION_NO]
				, [condition].[sheet_no_start] + ((ROW_NUMBER() OVER (
						PARTITION BY [lot_inventory].[location_id] 
							, [condition].[class_no]
						ORDER BY [lot_inventory].[location_id] ASC 
							, [condition].[class_no] ASC ) - 1  ) / 30  
				) AS [SHEET_NO]
				, ( CASE WHEN [lot_inventory].[location_id] = 'ON MACHINE' THEN CAST(1 AS BIT)
					ELSE CAST(0 AS BIT)
				END ) AS [CLASSIFICATION_ID]
				, [name_of_process] AS [PROCESS_NAME]
				, ROW_NUMBER() OVER (
						ORDER BY [lot_inventory].[id] ASC
				) AS [Seq]
				, SUBSTRING([lot_inventory].[year_month], 3, 4) + [rack_no_inven] AS [HEAD_INVEN]
			FROM [APCSProDB].[trans].[lot_inventory]
			INNER JOIN [APCSProDB].[method].[packages] ON [lot_inventory].[package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[device_names] ON [lot_inventory].[device_id] = [device_names].[id]
			OUTER APPLY ( 
				SELECT TOP 1 [master].[class_no]
					, [master].[sheet_no_start]
					, FORMAT([master].[rack_no], '000') AS [rack_no_inven] 
					, [master].[name_of_process]
				FROM [APCSProDB].[inv].[class_locations] AS [match]
				INNER JOIN [APCSProDB].[inv].[Inventory_classfications] AS [master] ON [match].[class_id] = [master].[id]  
				WHERE [match].[location_name] = [lot_inventory].[location_id]
				UNION 
				SELECT TOP 1 [master].[class_no]
					, [master].[sheet_no_start]
					, FORMAT([master].[rack_no], '000') AS [rack_no_inven] 
					, [master].[name_of_process]
				FROM [APCSProDB].[inv].[class_locations] AS [match]
				INNER JOIN [APCSProDB].[inv].[Inventory_classfications] AS [master] ON [match].[class_id] = [master].[id]  
				WHERE [master].[class_no] = [lot_inventory].[classification_no]
			) AS [condition]
			LEFT JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_inventory].[lot_id]
			WHERE [lot_inventory].[stock_class] = @StockClass	
		) AS [T1]
	) AS [WIP_INVENTORY]
	WHERE [CLASSIFICATION_NO] IS NOT NULL
		AND [CLASSIFICATION_NO] = @ClassNo
	ORDER BY [SHEET_NO] ,[LINE_NO];
END

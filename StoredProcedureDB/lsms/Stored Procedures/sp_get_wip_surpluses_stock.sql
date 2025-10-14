
CREATE PROCEDURE [lsms].[sp_get_wip_surpluses_stock] 
	-- Add the parameters for the stored procedure here
	  @Start_date	DATE			= NULL
	, @End_date		DATE			= NULL
	, @Type			CHAR(20)		= ''  --package
	, @TRNo			CHAR(20)		= ''  --device
	, @Lot_type		VARCHAR(50)		= ''
	, @In_stock     VARCHAR(10)		= '2'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	DECLARE @datetime DATETIME
	DECLARE @year_now int = 0
	SET @datetime = GETDATE()

	SELECT @year_now = (FORMAT(@datetime,'yy'))
	SET @In_stock = IIF(@In_stock IS NULL OR @In_stock = '','2', @In_stock);

	SELECT [Detail].*,it.[color_code]
	FROM (
		SELECT [sur].[serial_no] AS [lot_no]
			, [lot].[type_name] 
			, [lot].[tr_no]
			, [lot].[hfe_rank]
			, [sur].[pcs] AS qty
			, [lot].[pack_unit_qty]
			, ISNULL([item_comment2].[label_eng], '') AS is_stock_value
			, [sur].[created_at]
			, ISNULL([item_comment].[label_eng], '') AS comment
			, [sur].[location_id]
			, [locations].[name] AS [Location]	
			, [rack_controls].[name] AS [RackName]
			, [rack_controls].[name] + '/' + [rack_addresses].[address] AS [RackAddress]
			, DATEDIFF(YEAR, [sur].[created_at], GETDATE()) AS year_diff
			, DATEDIFF(MONTH, [sur].[created_at], GETDATE()) % 12 AS month_diff
			--, CASE
			--	WHEN DATEDIFF(YEAR, [sur].[created_at], GETDATE()) >= 4 THEN '#FF0000'
			--	WHEN DATEDIFF(YEAR, [sur].[created_at], GETDATE()) = 3
			--		AND DATEDIFF(MONTH, [sur].[created_at], GETDATE()) % 12 = 11 THEN '#FEEE91'
			--	WHEN DATEDIFF(YEAR, [sur].[created_at], GETDATE()) <= 3 
			--		AND DATEDIFF(MONTH, [sur].[created_at], GETDATE()) % 12 < 11 THEN '2'
			--END AS [status]
			, ( CASE
				WHEN DATEDIFF(MONTH, [sur].[created_at], GETDATE()) >= 48 THEN '#FF0000' -- Surpluses Long (3)
				WHEN DATEDIFF(MONTH, [sur].[created_at], GETDATE()) = 47 THEN '#FEEE91' -- Warning Exprite date (1)
				ELSE '#FFFFFF' -- Normal (2)
			END ) AS [status]
		FROM [APCSProDB].[trans].[surpluses] AS [sur]
		INNER JOIN [APCSProDB].[trans].[lot_informations] AS [lot] ON [sur].[lot_id] = [lot].[id]
		LEFT JOIN [APCSProDB].[rcs].[rack_addresses] ON [lot].[lot_no] = [rack_addresses].[item]
			AND [sur].[location_id] = [rack_addresses].[id]
		LEFT JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
		LEFT JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_comment] ON [sur].[comment] = CAST([item_comment].[val] AS INT)
			AND [item_comment].[name] = 'surpluses.comment'
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_comment2] ON [sur].[in_stock] = CAST([item_comment2].[val] AS INT)
			AND [item_comment2].[name] = 'surpluse_records.in_stock'
		WHERE (@lot_type IS NULL OR @lot_type = '' OR SUBSTRING([sur].[serial_no], 5, 1) = @lot_type)
			AND (CONVERT(DATE, [sur].[created_at]) BETWEEN @Start_date AND @End_date)
			AND (@Type IS NULL OR @Type = '' OR [lot].[type_name] = @Type)
			AND (@TRNo IS NULL OR @TRNo = '' OR [lot].[tr_no] = @TRNo)
			AND (@In_stock IS NULL OR @In_stock = '' OR [sur].[in_stock] = @In_stock)
			--AND [locations].[address] = 'WideLine'
	) AS [Detail]
	LEFT JOIN APCSProDB.trans.item_labels AS it ON [Detail].[status] = [it].[val] 
		AND [it].[name] = 'surpluses.expiration'

END

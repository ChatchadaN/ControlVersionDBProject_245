-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_hasuu_stock_pro_bass_test] 
	-- Add the parameters for the stored procedure here
	@get_data varchar(10),
	@package varchar(20) = '',
	@device varchar(20) = '',
	@rank varchar(5) = '',
	@tomson3 char(4) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @HasuuStockMax char(10)
	DECLARE @HasuuTotal char(10)

	--Add Parameter 2022/05/25 Time : 11.05
	DECLARE @datetime DATETIME
	DECLARE @year_now int = 0
	SET @datetime = GETDATE()
	SELECT @year_now = (FORMAT(@datetime,'yy') - 3)

	DECLARE @table_config_mix TABLE (
		[parent_lot] VARCHAR(1),
		[hasuu_lot] VARCHAR(1),
		[package] CHAR(10),
		[device] CHAR(20),
		[is_enable] TINYINT,
		[created_at] DATETIME,
		[created_by] INT,
		[updated_at] DATETIME,
		[updated_by] INT
	)

	INSERT INTO @table_config_mix
	VALUES ('D', 'A', 'ALL', 'ALL', 1, GETDATE(), 1339, NULL, NULL)
		,('D', 'B', 'ALL', 'ALL', 1, GETDATE(), 1339, NULL, NULL)
		,('D', 'D', 'ALL', 'ALL', 1, GETDATE(), 1339, NULL, NULL)
		,('D', 'F', 'ALL', 'ALL', 1, GETDATE(), 1339, NULL, NULL)
		,('D', 'G', 'SSOP-C38W', 'SV010-HE2', 1, GETDATE(), 1339, NULL, NULL)         
		,('D', 'G', 'SSOP-C38W', 'SV013-HE2', 1, GETDATE(), 1339, NULL, NULL)          
		,('D', 'G', 'SSOP-C38W', 'SV014-HE2', 1, GETDATE(), 1339, NULL, NULL)           
		,('D', 'G', 'SSOP-C38W', 'SV131-HE2', 1, GETDATE(), 1339, NULL, NULL)          
		,('D', 'G', 'HSSOP-C16','BV2HC045EFU-CE2', 1, GETDATE(), 1339, NULL, NULL)      
		,('D', 'G', 'HSSOP-C16','BV2HD045EFU-CE2', 1, GETDATE(), 1339, NULL, NULL)      
		,('D', 'G', 'HSSOP-C16','BV2HD070EFU-CE2', 1, GETDATE(), 1339, NULL, NULL)      
		,('D', 'G', 'HSSOP-C16','BV2HC045EFU-C', 1, GETDATE(), 1339, NULL, NULL);

    -- Insert statements for procedure here
	--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--([record_at]
 --     , [record_class]
 --     , [login_name]
 --     , [hostname]
 --     , [appname]
 --     , [command_text])
	--SELECT GETDATE()
	--	,'4'
	--	,ORIGINAL_LOGIN()
	--	,HOST_NAME()
	--	,APP_NAME()
	--	,'EXEC [dbo].[tg_sp_get_hasuu_stock_pro_bass_test] @get_data = ''' + @get_data + ''',@package = ''' + @package + ''',@device = ''' + @device + ''',@rank = ''' + @rank + ''',@tomson3 = ''' + @tomson3 + ''''

	IF (@get_data ='stock')
	BEGIN
		SELECT [pk].[short_name] AS [Type_Name]
			, [dv].[name] AS [ASSY_Model_Name] 
			, [dv].[pcs_per_pack] AS [Packing_Standerd_QTY]
			, ISNULL([dv].[rank], '') AS [Rank]
			, SUM([sur].[pcs]) AS [HASU_Stock_QTY]
			, SUM(sur.pcs)/(dv.pcs_per_pack) AS [TotalRell]
			, COUNT([sur].[serial_no]) AS [QtyLot]
			, SUM([sur].[pcs])%([dv].[pcs_per_pack]) AS [Hasuu_Total]
			, [pk_g].[name] AS [package_group_name]
			, [sur].[qc_instruction] AS [Tomson3]
		FROM [APCSProDB].[trans].[surpluses] AS [sur]
		INNER JOIN [APCSProDB].[trans].[lots] AS [lot] ON [sur].[lot_id] = [lot].[id]
		INNER JOIN [APCSProDB].[method].[device_names] AS [dv] ON [lot].[act_device_name_id] = [dv].[id]
		INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [dv].[package_id] = [pk].[id]
		INNER JOIN [APCSProDB].[method].[package_groups] AS [pk_g] ON [pk].[package_group_id] = [pk_g].[id]
		LEFT JOIN [APCSProDB].[trans].[locations] AS [locat] ON [sur].[location_id] = [locat].[id]
		LEFT JOIN @table_config_mix AS [config_mix] ON [config_mix].[parent_lot] = 'D'
			AND [config_mix].[hasuu_lot] = SUBSTRING([sur].[serial_no], 5, 1)
			AND ([config_mix].[package] = 'ALL' OR [config_mix].[package] = [pk].[name])
			AND ([config_mix].[device] = 'ALL' OR [config_mix].[device] = [dv].[name])
			AND [config_mix].[is_enable] = 1
		WHERE ([sur].[location_id] IS NOT NULL AND [sur].[location_id] != 0)
			AND ([sur].[in_stock] = 2) 
			AND ([sur].[pcs] != 0)
			AND ([lot].[wip_state] IN (20,70,100))
			AND ([lot].[quality_state] = 0)
			AND (SUBSTRING([sur].[serial_no], 1, 2) >= (FORMAT(GETDATE(),'yy') - 3) OR [sur].[is_ability] = 1)
			AND [config_mix].[is_enable] IS NOT NULL
		GROUP BY [pk].[short_name]
			, [dv].[name]
			, ISNULL([dv].[rank], '')
			, [dv].[pcs_per_pack]
			, [pk_g].[name]
			, [sur].[qc_instruction]
		HAVING SUM([sur].[pcs]) >= [dv].[pcs_per_pack] 
			AND SUM([sur].[pcs])/(NULLIF([dv].[pcs_per_pack], 0)) >= 1
		ORDER BY [pk_g].[name] ASC;
	END
	ElSE IF (@get_data ='lot')
	BEGIN
		SELECT ROW_NUMBER() OVER(ORDER BY [sur].[pcs] ASC) AS [RowId] 
			, [pk_g].[name] AS [package_group_name]
			, TRIM([sur].[serial_no]) AS [LotNo]
			, TRIM([lot].[lot_no]) AS [tranlot_lotno]
			, sur.pcs AS HASU_Stock_QTY
			, ([sur].[pcs]/[dv].[pcs_per_pack]) AS [Rell]
			, [dv].[pcs_per_pack] AS [Packing_Standerd_QTY]
			, [lot].[location_id]
			, (CASE WHEN [locat].[name] IS NULL THEN 'NoLocalion' ELSE [locat].[name] END) AS [Rack_Location_name]
			, (CASE WHEN [locat].[address] IS NULL THEN 'NoLocalion' ELSE [locat].[address] END) AS [Rack_Location_address]
			, YEAR([sur].[updated_at]) AS [oldyear]
			, YEAR(GETDATE()) AS [Currentyear]
			, CAST(YEAR(GETDATE()) AS INT) - CAST(YEAR([sur].[updated_at]) AS INT) AS [Overdueyear]
			, [sur].[qc_instruction] AS [Tomson3]
		FROM [APCSProDB].[trans].[surpluses] AS [sur]
		INNER JOIN APCSProDB.trans.lots AS lot ON sur.lot_id = lot.id
		INNER JOIN [APCSProDB].[method].[device_names] AS [dv] ON [lot].[act_device_name_id] = [dv].[id]
		INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [dv].[package_id] = [pk].[id]
		INNER JOIN [APCSProDB].[method].[package_groups] AS [pk_g] ON [pk].[package_group_id] = [pk_g].[id]
		LEFT JOIN [APCSProDB].[trans].[locations] AS [locat] ON [sur].[location_id] = [locat].[id]
		LEFT JOIN @table_config_mix AS [config_mix] ON [config_mix].[parent_lot] = 'D'
			AND [config_mix].[hasuu_lot] = SUBSTRING([sur].[serial_no], 5, 1)
			AND ([config_mix].[package] = 'ALL' OR [config_mix].[package] = [pk].[name])
			AND ([config_mix].[device] = 'ALL' OR [config_mix].[device] = [dv].[name])
			AND [config_mix].[is_enable] = 1
		WHERE ([pk].[short_name] LIKE 'SSOP-B20W ')
			AND ([dv].[name] LIKE 'BM66002FV-CE2       ') 
			AND (ISNULL([dv].[rank], '') LIKE 'C') 
			AND ([sur].[qc_instruction] LIKE '                    ')
			AND ([sur].[location_id] IS NOT NULL AND [sur].[location_id] != 0)
			AND ([lot].[wip_state] IN (20,70,100))
			AND ([lot].[quality_state] = 0)
			AND ([sur].[in_stock] = 2) 
			AND ([sur].[pcs] != 0)
			AND (SUBSTRING([sur].[serial_no], 1, 2) >= (FORMAT(GETDATE(),'yy') - 3) OR [sur].[is_ability] = 1)
			AND [config_mix].[is_enable] IS NOT NULL
		ORDER BY [sur].[pcs] ASC;
	END

	IF @@ERROR <> 0
	GOTO ErrorHandler

	SET NOCOUNT OFF
	RETURN (0)
	ErrorHandler:
	RETURN (@@ERROR)
END

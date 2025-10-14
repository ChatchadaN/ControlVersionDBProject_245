-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_data_lot_outsource] 
	@is_function int =  1
	, @lot_no varchar(10) = ''
	, @date varchar(15) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if (@date = '')
	begin
		SET @date = (CONVERT(varchar(50), GETDATE() + 1,23))
	end
	
	if (@is_function = 1)
	begin
		-------------------------------------------
		--- 1 select half product
		-------------------------------------------
		---DECLARE PARAMETER
		DECLARE @Table_Half_Product table ( 
			[FormName] [varchar](15) NULL,
			[ThrowInDate] [datetime] NULL,
			[AsssyModelName] [varchar](20) NULL,
			[ORDER_MODEL_NAME] [varchar](20) NULL,
			[ThrowInRank] [varchar](3) NULL,
			[TP_Rank] [varchar](3) NULL,
			[OrderNo] [varchar](20) NULL,
			[LotNo] [varchar](10) NULL,
			[OutSourceLotNo] [varchar](13) NULL,
			[InvoiceNo] [varchar](10) NULL,
			[MNo] [varchar](10) NULL,
			[Qty] [int] NULL
		)
		---SQL SELECT IS
		DECLARE @sql NVARCHAR(MAX)
		SET @sql = 'SELECT [FormName]'+
					  ',[ThrowInDate]'+
					  ',[AsssyModelName]'+
					  ',[ORDER_MODEL_NAME]'+
					  ',[ThrowInRank]'+
					  ',[TP_Rank]'+
					  ',[OrderNo]'+
					  ',[LotNo]'+
					  ',[OutSourceLotNo]'+
					  ',[InvoiceNo]'+
					  ',[MNo]'+
					  ',[Qty] ' +
					'FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=Half_Product;Uid=ship;Pwd=ship'',' +
						'''SELECT [FormName]'+
							  ',[ThrowInDate]'+
							  ',[AsssyModelName]'+
							  ',[ORDER_MODEL_NAME]'+
							  ',[ThrowInRank]'+
							  ',[TP_Rank]'+
							  ',[OrderNo]'+
							  ',[LotNo]'+
							  ',[OutSourceLotNo]'+
							  ',[InvoiceNo]'+
							  ',[MNo]'+
							  ',[Qty] ' + 
						'FROM [Half_Product].[dbo].[Half_Product_Order_List] ' +
						'WHERE CONVERT(varchar(50), [ThrowInDate],23) = '''''+ @date  +''''' '')';

		INSERT INTO @Table_Half_Product EXEC sp_executesql @sql;
		---SELECT DATA
		SELECT [FormName]
			,[ThrowInDate]
			,[AsssyModelName]
			,[ORDER_MODEL_NAME]
			,[ThrowInRank]
			,[TP_Rank]
			,[OrderNo]
			,[LotNo]
			,[OutSourceLotNo]
			,[InvoiceNo]
			,[MNo]
			,[Qty] 
			,CASE WHEN [lots].[e_slip_id] IS NULL THEN 0 ELSE 1 END AS [EslipID]
		FROM @Table_Half_Product as [Half_Product_Order_List]
		LEFT JOIN [APCSProDB].[trans].[lots] ON [Half_Product_Order_List].[LotNo] = [lots].[lot_no]
		--UNION
		--SELECT 'TEST' AS [FormName]
		--	,'2022-06-30 00:00:00.000' AS [ThrowInDate]
		--	,'TEST' AS [AsssyModelName]
		--	,'TEST' AS [ORDER_MODEL_NAME]
		--	,'TEST' AS [ThrowInRank]
		--	,'TEST' AS [TP_Rank]
		--	,'TEST' AS [OrderNo]
		--	,'1234A1234V' AS [LotNo]
		--	,'2CH02030323 ' AS [OutSourceLotNo]
		--	,'TEST' AS [InvoiceNo]
		--	,'MX' AS [MNo]
		--	,100 AS [Qty] 
		--	,0 AS[EslipID]
		--UNION
		--SELECT 'TEST' AS [FormName]
		--	,'2022-07-01 00:00:00.000' AS [ThrowInDate]
		--	,'TEST' AS [AsssyModelName]
		--	,'TEST' AS [ORDER_MODEL_NAME]
		--	,'TEST' AS [ThrowInRank]
		--	,'TEST' AS [TP_Rank]
		--	,'TEST' AS [OrderNo]
		--	,'2140A6105V' AS [LotNo]
		--	,'2CH02030324 ' AS [OutSourceLotNo]
		--	,'TEST' AS [InvoiceNo]
		--	,'MX' AS [MNo]
		--	,100 AS [Qty] 
		--	,0 AS[EslipID]
	
		--UNION
		--SELECT 'TEST2' AS [FormName]
		--	,'2022-06-30 00:00:00.000' AS [ThrowInDate]
		--	,'TEST2' AS [AsssyModelName]
		--	,'TEST2' AS [ORDER_MODEL_NAME]
		--	,'TEST2' AS [ThrowInRank]
		--	,'TEST2' AS [TP_Rank]
		--	,'TEST2' AS [OrderNo]
		--	,'9999D9999V' AS [LotNo]
		--	,'2CH02030323 ' AS [OutSourceLotNo]
		--	,'TEST2' AS [InvoiceNo]
		--	,'MX' AS [MNo]
		--	,100 AS [Qty] 
		--	,1 AS[EslipID]
	end
	else if (@is_function = 2)
	begin
		-------------------------------------------
		--- 2 select data card
		-------------------------------------------
		select trim(isnull(lots.lot_no,'')) as lot_no
			, trim(isnull(packages.name,'')) as package
			, trim(isnull(device_names.name,'')) as device
			, trim(isnull(device_names.tp_rank,'')) as tp_rank
			, isnull(lots.carrier_no,'') as carrier
			, case when lots.is_special_flow = 1 then job_special.name else job_master.name end as job_name
		from APCSProDB.trans.lots
		left join APCSProDB.method.device_names on lots.act_device_name_id = device_names.id
		left join APCSProDB.method.packages on device_names.package_id = packages.id
		left join APCSProDB.method.jobs as job_master on lots.act_job_id = job_master.id
		left join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
			and lots.is_special_flow = 1
			and lots.special_flow_id = special_flows.id
		left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
			and special_flows.step_no = lot_special_flows.step_no
		left join APCSProDB.method.jobs as job_special on lot_special_flows.job_id = job_special.id
		where lots.lot_no = @lot_no
	end
END
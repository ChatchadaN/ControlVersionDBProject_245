-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_data_interface_demo_001] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--DECLARE @table_v_cps_stk table ( 
	--	[LOTN] [char](10) NOT NULL,
	--	[TKEM] [char](20) NOT NULL,
	--	[MZAS] int NULL,
	--	[NKJD] [char](8) NULL
	--)

	DECLARE @table_wh_ukeba table ( 
		[Record_Class] [char](2) NOT NULL,
		[ROHM_Model_Name] [char](20) NULL,
		[LotNo] [char](10) NULL,
		[RED_BLACK_Flag] [char](1) NULL,
		[QTY] [int] NULL,
		[Warehouse_Code] [char](5) NULL,
		[ORNo] [char](12) NULL
	)

	DECLARE @table_v_h_stock table ( 
		[stock_class] [char](2) NOT NULL,
		[name] [char](20) NULL,
		[rank] [char](5) NULL,
		[tp_rank] [char](3) NULL,
		[short_name] [char](10) NULL,
		[serial_no] [char](10) NULL,
		[pcs] [int] NULL,
		[pdcd] [char](5) NULL,
		[created_at] [datetime] NULL
	)

	DECLARE @sql NVARCHAR(MAX)
	--SET @sql = 'SELECT LOTN,TKEM,MZAS,NKJD FROM OPENROWSET(''SQLNCLI'', ''Server= 10.29.1.82;Database=IFDB;Uid=sa;Pwd=i$2007'',' + 
	--					'''SELECT LOTN,TKEM,MZAS,NKJD FROM [IFDB].[dbo].[V_CPS_STK] ' + 
	--					'WHERE SHGC = ''''10'''''')';

	--INSERT INTO @table_v_cps_stk EXEC sp_executesql @sql;

	SET @sql = '';
	SET @sql = 'SELECT Record_Class,ROHM_Model_Name,LotNo,RED_BLACK_Flag,QTY,Warehouse_Code,ORNo FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
						'''SELECT Record_Class,ROHM_Model_Name,LotNo,RED_BLACK_Flag,QTY,Warehouse_Code,ORNo FROM [DBLSISHT].[dbo].[WH_UKEBA] '+ 
						'WHERE [Delete_Flag] <> ''''1'''''')';

	INSERT INTO @table_wh_ukeba EXEC sp_executesql @sql;

	INSERT INTO @table_v_h_stock
	(
		[stock_class],
		[name],
		[rank],
		[tp_rank],
		[short_name],
		[serial_no],
		[pcs],
		[pdcd],
		[created_at]
	)
	SELECT ISNULL(stock_class,'')
		,dn.name
		,dn.rank
		,dn.tp_rank 
		,pk.short_name
		,serial_no
		,sur.pcs
		,pdcd
		,sur.created_at
	FROM APCSProDB.trans.surpluses AS sur
	inner join APCSProDB.trans.lots AS lot on sur.lot_id = lot.id
	inner join APCSProDB.method.packages AS pk on lot.act_package_id = pk.id
	inner join APCSProDB.method.device_names AS dn on lot.act_device_name_id = dn.id
	WHERE (sur.in_stock = 2) AND (sur.pcs >= 0)  AND (SUBSTRING(sur.serial_no, 1, 3) <> 0);

	print('1 success');

	SELECT WRITETIME
		, SEQNO6
		, SENDERID
		, ROVANSFILE
		, CASE
			WHEN [ROVANSFILE] = 'FSTK' AND [ROVANSDATA] = 'GEE' THEN CAST([ROVANSDATA] + RIGHT('000000'+ CONVERT(VARCHAR,row_no - 1),6) + 'FSTK' AS CHAR(80))
			WHEN [ROVANSFILE] = 'FJ01' AND [ROVANSDATA] = 'GEE' THEN CAST([ROVANSDATA] + RIGHT('000000'+ CONVERT(VARCHAR,count_row - 1),6) + 'FJ01' AS CHAR(80))
			WHEN [ROVANSFILE] = 'FJ02' AND [ROVANSDATA] = 'GEE' THEN CAST([ROVANSDATA] + RIGHT('000000'+ CONVERT(VARCHAR,row_no),6) + 'FJ02' AS CHAR(80))
			ELSE ROVANSDATA
		  END AS ROVANSDATA
		, SENDENDFL
		, MAKDT
		, MAKP
		, MAKC
		, DELC
		, DELP
		, DELDT
		, DELF
		, UPDC
		, UPDP
		, UPDDT
		--, CASE
		--	WHEN [ROVANSFILE] = 'FSTK' AND [ROVANSDATA] = 'GEE' THEN DATALENGTH(CAST([ROVANSDATA] + RIGHT('000000'+ CONVERT(VARCHAR,row_no),6) + 'FSTK' AS CHAR(80)))
		--	WHEN [ROVANSFILE] = 'FJ01' AND [ROVANSDATA] = 'GEE' THEN DATALENGTH(CAST([ROVANSDATA] + RIGHT('000000'+ CONVERT(VARCHAR,count_row),6) + 'FJ01' AS CHAR(80)))
		--	WHEN [ROVANSFILE] = 'FJ02' AND [ROVANSDATA] = 'GEE' THEN DATALENGTH(CAST([ROVANSDATA] + RIGHT('000000'+ CONVERT(VARCHAR,row_no),6) + 'FJ02' AS CHAR(80)))
		--	ELSE DATALENGTH(ROVANSDATA)
		--  END AS ROVANSDATA_LENGTH
	FROM (
		SELECT [t1].[order_by]
			, row_no
			, count_row
			, GETDATE() AS WRITETIME
			, ROW_NUMBER() OVER (
				ORDER BY [t1].[order_by],[t1].[row_no]
			) AS SEQNO6
			, N'ROHM0011' AS SENDERID
			, [t1].ROVANSFILE
			, ROVANSDATA
			, 0 AS SENDENDFL
			, GETDATE() AS MAKDT
			, '' AS MAKP
			, '' AS MAKC
			, '' AS DELC
			, '' AS DELP
			, '' AS DELDT
			, 0 AS DELF
			, '' AS UPDC
			, '' AS UPDP
			, '' AS UPDDT
		FROM 
		---------------------------------(DATA)---------------------------------
		(
			---------------------------------(FSTK)---------------------------------
			--SELECT 1 AS [order_by]
			--	, [ROVANSFILE]
			--	, [order_by_ro]
			--	, [ROVANSDATA]
			--	, RANK () OVER ( 
			--		PARTITION BY [ROVANSFILE]
			--		ORDER BY [order_by_ro],[row_no_1]
			--	) row_no 
			--FROM (
			--	---------------------------------(HEAD1)---------------------------------
			--	SELECT 'FSTK' AS [ROVANSFILE], 1 AS [order_by_ro], 1 AS [row_no_1], CAST('*CC,ZZROHM0011' AS  CHAR(80)) AS [ROVANSDATA]
			--	---------------------------------(HEAD1)---------------------------------
			--	UNION ALL
			--	---------------------------------(HEAD2)---------------------------------
			--	SELECT 'FSTK' AS [ROVANSFILE], 2 AS [order_by_ro], 1 AS [row_no_1], CAST('GESGEIS1.000ZZROHM0024       ZZROHM0010       ' + format(getdate(),'yyMMddHHmm') + 'FSTK' AS  CHAR(80)) AS [ROVANSDATA]
			--	---------------------------------(HEAD2)---------------------------------
			--	UNION ALL
			--	--SELECT 'FSTK' AS [ROVANSFILE], 3 AS [order_by_ro], '  211005QI000211005BH1730FVC-TR        00000000001QIW04399            2140A4485V' AS [ROVANSDATA]
			--	select 'FSTK' AS [ROVANSFILE]
			--		, 3 AS [order_by_ro]
			--		, 1 AS [row_no_1]
			--		, CAST(Record_Class AS CHAR(2))
			--			+ CAST(format(GETDATE(),'yyMMdd') AS CHAR(6))
			--			+ CAST(Warehouse_Code AS CHAR(5)) 
			--			+ CAST(format(GETDATE(),'yyMMdd') AS CHAR(6))
			--			+ CAST(ROHM_Model_Name AS CHAR(20)) 
			--			+ RIGHT('000000000'+ CONVERT(VARCHAR,QTY),9)
			--			+ CAST(IIF(RED_BLACK_Flag IS NULL,'',RED_BLACK_Flag) AS CHAR(1))
			--			+ CAST(ORNo AS CHAR(12))
			--			+ SPACE(9)
			--			+ CAST(LotNo AS CHAR(10)) as [ROVANSDATA]
			--	from @table_wh_ukeba
			--	UNION ALL
			--	--SELECT 'FSTK' AS [ROVANSFILE], 4 AS [order_by_ro], '92211005QI000210729BU97950AFUV-E2      0000000000                               ' AS [ROVANSDATA]
			--	SELECT 'FSTK' AS [ROVANSFILE] 
			--		, 4 AS [order_by_ro]
			--		, RANK () OVER ( 
			--			ORDER BY stock_class,name,serial_no
			--		) [row_no_1]
			--		, CAST('92' AS CHAR(2))
			--			+ CAST(format(GETDATE(),'yyMMdd') AS CHAR(6))
			--			+ CAST(IIF(pdcd is null,'',pdcd) AS CHAR(5)) 
			--			+ CAST(format(created_at,'yyMMdd') AS CHAR(6))
			--			+ CAST(name AS CHAR(20)) 
			--			+ RIGHT('000000000'+ CONVERT(VARCHAR,pcs),9)
			--			+ CAST('0' AS CHAR(1))
			--			+ SPACE(31) as [ROVANSDATA]
			--	FROM @table_v_h_stock
			--	UNION ALL
			--	---------------------------------(FOOTER)---------------------------------
			--	SELECT 'FSTK' AS [ROVANSFILE], 5 AS [order_by_ro], 1 AS [row_no_1], 'GEE' AS [ROVANSDATA]
			--	---------------------------------(FOOTER)---------------------------------
			--) AS [FSTK]
			-----------------------------------(FSTK)---------------------------------
			--UNION ALL
			-----------------------------------(FJ01)---------------------------------
			SELECT 2 AS [order_by]
				, [ROVANSFILE]
				, [order_by_ro]
				, [ROVANSDATA]
				, RANK () OVER ( 
					PARTITION BY [ROVANSFILE]
					ORDER BY [order_by_ro]
				) row_no 
			FROM (
				---------------------------------(HEAD)---------------------------------
				SELECT 'FJ01' AS [ROVANSFILE], 1 AS [order_by_ro], CAST('GESGEIS1.000ZZROHM0024       ZZROHM0011       ' + format(getdate(),'yyMMddHHmm') + 'FJ01' AS  CHAR(80)) AS [ROVANSDATA]
				---------------------------------(HEAD)---------------------------------
				UNION ALL
				--SELECT 'FJ01' AS [ROVANSFILE], 2 AS [order_by_ro], 'QI100BU97510CKV-ME2      M    E2 VQFP64    2138A1552V003000210922               ' AS [ROVANSDATA]
				--SELECT 'FJ01' AS [ROVANSFILE]
				--	, 2 AS [order_by_ro]
				--	, CAST('QI100' AS CHAR(5))
				--		+ CAST(dn.name AS CHAR(20)) 
				--		+ CAST(IIF(dn.rank is null,'',dn.rank) AS CHAR(5)) 
				--		+ CAST(IIF(dn.tp_rank is null,'',dn.tp_rank) AS CHAR(3))
				--		+ CAST(pk.short_name AS CHAR(10)) 
				--		+ CAST(lot.lot_no AS CHAR(10))
				--		+ RIGHT('000000'+ CONVERT(VARCHAR,v_cps_stk.MZAS),6)
				--		+ SUBSTRING(v_cps_stk.NKJD,3,8) 
				--		+ SPACE(15) as [ROVANSDATA]
				--from @table_v_cps_stk as v_cps_stk
				--left join APCSProDB.trans.lots as lot on v_cps_stk.LOTN = lot.lot_no
				--inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
				--inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
				SELECT 'FJ01' AS [ROVANSFILE]
					, 2 AS [order_by_ro]
					, CAST('QI100' AS CHAR(5))
						+ CAST(dn.name AS CHAR(20)) 
						+ CAST(IIF(dn.rank is null,'',dn.rank) AS CHAR(5)) 
						+ CAST(IIF(dn.tp_rank is null,'',dn.tp_rank) AS CHAR(3))
						+ CAST(pk.short_name AS CHAR(10)) 
						+ CAST(lot.lot_no AS CHAR(10))
						+ RIGHT('000000'+ CONVERT(VARCHAR,v_cps_stk.MZAS),6)
						+ SUBSTRING(v_cps_stk.NKJD,3,8) 
						+ SPACE(15) as [ROVANSDATA]
				from [CPSDB].[IFDB].[dbo].[V_CPS_STK] as v_cps_stk
				inner join APCSProDB.trans.lots as lot on v_cps_stk.LOTN = lot.lot_no
				inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
				inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
				UNION ALL
				---------------------------------(FOOTER)---------------------------------
				SELECT 'FJ01' AS [ROVANSFILE], 3 AS [order_by_ro], 'GEE' AS [ROVANSDATA]
				---------------------------------(FOOTER)---------------------------------
			) AS [FJ01]
			-----------------------------------(FJ01)---------------------------------
			UNION ALL
			---------------------------------(FJ02)---------------------------------
			SELECT 3 AS [order_by]
				, [ROVANSFILE]
				, [order_by_ro]
				, [ROVANSDATA]
				, RANK () OVER ( 
					PARTITION BY [ROVANSFILE]
					ORDER BY [order_by_ro],[row_no_1]
				) row_no 
			FROM (
				---------------------------------(HEAD)---------------------------------
				SELECT 'FJ02' AS [ROVANSFILE] , 1 AS [order_by_ro], 1 AS [row_no_1], CAST('GESGEIS1.000ZZROHM0024       ZZROHM0011       ' + format(getdate(),'yyMMddHHmm') + 'FJ02' AS  CHAR(80)) AS [ROVANSDATA]
				---------------------------------(HEAD)---------------------------------
				UNION ALL
				--SELECT 'FJ02' AS [ROVANSFILE] , 'QI00001A01651315-E2             E2 SOP20     1845A3115V001046200805             ' AS [ROVANSDATA], 2 AS [order_by_ro]
				SELECT 'FJ02' AS [ROVANSFILE] 
					, 2 AS [order_by_ro]
					, RANK () OVER ( 
						ORDER BY stock_class,name,serial_no
					) [row_no_1]
					, CAST('QI000' AS CHAR(5))
						--CAST(IIF(pdcd is null,'',pdcd) AS CHAR(5)) 
						+ CAST(stock_class AS CHAR(2)) 
						+ CAST(name AS CHAR(20)) 
						+ CAST(IIF(rank is null,'',rank) AS CHAR(5)) 
						+ CAST(IIF(tp_rank is null,'',tp_rank) AS CHAR(3)) 
						+ CAST(short_name AS CHAR(10)) 
						+ CAST(serial_no AS CHAR(10))
						+ RIGHT('000000'+ CONVERT(VARCHAR,pcs),6)
						+ CAST(format(created_at,'yyMMdd') AS CHAR(6))
						+ SPACE(13) as [ROVANSDATA]
				FROM @table_v_h_stock
				UNION ALL
				---------------------------------(FOOTER)---------------------------------
				SELECT 'FJ02' AS [ROVANSFILE] , 3 AS [order_by_ro], 1 AS [row_no_1], 'GEE' AS [ROVANSDATA]
				---------------------------------(FOOTER)---------------------------------
			) AS [FJ02]
			---------------------------------(FJ02)---------------------------------
		) AS [t1]
		---------------------------------(DATA)---------------------------------
		---------------------------------(COUNT ROW FSTK)---------------------------------
		LEFT JOIN (
			SELECT 'FJ01' AS [ROVANSFILE] 
				, 2 AS [order_by]
				, 3 AS [order_by_ro]
				, SUM([ROVANSDATA]) + 3 AS count_row
			FROM (
				select count(LotNo) as [ROVANSDATA]
				from @table_wh_ukeba
				UNION ALL
				SELECT count(serial_no) as [ROVANSDATA]
				FROM @table_v_h_stock
			) AS [tcount] 
			GROUP BY [ROVANSDATA]
		) AS [t2] on [t1].ROVANSFILE = [t2].ROVANSFILE
			AND [t1].order_by = [t2].order_by
			AND [t1].order_by_ro = [t2].order_by_ro
		---------------------------------(COUNT ROW FSTK)---------------------------------
	) AS [ADM00001]


END
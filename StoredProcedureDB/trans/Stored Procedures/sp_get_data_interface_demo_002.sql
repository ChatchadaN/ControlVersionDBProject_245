-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_data_interface_demo_002] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @table_adm00001 TABLE (
		[WRITETIME] [DATETIME] NOT NULL, 
		[SEQNO6] [DECIMAL](6, 0) NOT NULL, 
		[SENDERID] [CHAR](20) NOT NULL, 
		[ROVANSFILE] [CHAR](7) NOT NULL, 
		[ROVANSDATA] [CHAR](80) NOT NULL, 
		[SENDENDFL] [CHAR](1) NULL, 
		[MAKDT] [DATETIME] NOT NULL, 
		[MAKP] [CHAR](10) NOT NULL, 
		[MAKC] [CHAR](10) NOT NULL, 
		[UPDDT] [DATETIME] NOT NULL, 
		[UPDP] [CHAR](10) NOT NULL, 
		[UPDC] [CHAR](10) NOT NULL, 
		[DELF] [CHAR](1) NOT NULL, 
		[DELDT] [DATETIME] NOT NULL, 
		[DELP] [CHAR](10) NOT NULL, 
		[DELC] [CHAR](10) NOT NULL
	)
	
	DECLARE @table_wh_ukeba TABLE ( 
		[Record_Class] [CHAR](2) NOT NULL,
		[ROHM_Model_Name] [CHAR](20) NULL,
		[LotNo] [CHAR](10) NULL,
		[RED_BLACK_Flag] [CHAR](1) NULL,
		[QTY] [INT] NULL,
		[Warehouse_Code] [CHAR](5) NULL,
		[ORNo] [CHAR](12) NULL
	)
	
	DECLARE @table_v_h_stock TABLE ( 
		[stock_class] [CHAR](2) NOT NULL,
		[name] [CHAR](20) NULL,
		[rank] [CHAR](5) NULL,
		[tp_rank] [CHAR](3) NULL,
		[short_name] [CHAR](10) NULL,
		[serial_no] [CHAR](10) NULL,
		[pcs] [INT] NULL,
		[pdcd] [CHAR](5) NULL,
		[created_at] [DATETIME] NULL
	)
	
	--INSERT INTO @table_wh_ukeba 
	--SELECT [Record_Class]
	--	, [ROHM_Model_Name]
	--	, [LotNo]
	--	, [RED_BLACK_Flag]
	--	, [QTY]
	--	, [Warehouse_Code]
	--	, [ORNo]
	--FROM [ISDB].[DBLSISHT].[dbo].[WH_UKEBA]
	--WHERE [Delete_Flag] <> '1';

	INSERT INTO @table_wh_ukeba
	SELECT [record_class]
		, [rohm_model_name]
		, [lot_no]
		, [red_black_flag]
		, [qty]
		, [warehouse_code]
		, [or_no]
	FROM [APCSProDWH].[dbo].[wh_ukeba_table]
	WHERE [send_flag] = '';

	INSERT INTO @table_v_h_stock
	SELECT ISNULL( [stock_class], '' )
		, [dn].[name]
		, [dn].[rank]
		, [dn].[tp_rank] 
		, [pk].[short_name]
		, [serial_no]
		--, [sur].[pcs]
		, CASE 
			WHEN [lot].[wip_state] IN (70,100) THEN [sur].[pcs] 
			ELSE 
				CASE 
					WHEN SUBSTRING( [sur].[serial_no], 5, 1 ) = 'D' THEN [lot].[qty_out] + [sur].[pcs] 
					ELSE [sur].[pcs] 
				END
		END AS [pcs]
		, [pdcd]
		, [sur].[created_at]
	FROM [APCSProDB].[trans].[surpluses] AS [sur]
	INNER JOIN [APCSProDB].[trans].[lots] AS [lot] ON [sur].[lot_id] = [lot].[id]
	INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [lot].[act_package_id] = [pk].[id]
	INNER JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lot].[act_device_name_id] = [dn].[id]
	WHERE ( [sur].[in_stock] = 2 ) 
		AND ( [sur].[pcs] >= 0 )  
		AND ( SUBSTRING( [sur].[serial_no], 1, 3 ) <> 0 );

	---------------------------------(START INSERT @table_adm00001)---------------------------------
	---- # order_by 1: FSTK, 2: FJ01, 3: FJ02
	INSERT INTO @table_adm00001
	SELECT GETDATE() AS [WRITETIME]
		, ROW_NUMBER() OVER ( ORDER BY [order_by], [row_number] ) AS [SEQNO6]
		, N'ROHM0011' AS [SENDERID]
		, [ROVANSFILE]
		, [ROVANSDATA]
		, 0 AS [SENDENDFL]
		, GETDATE() AS [MAKDT]
		, '' AS [MAKP]
		, '' AS [MAKC] 
		, '' AS [UPDDT]
		--, CAST( 'SENDER' AS CHAR(10) ) AS [UPDP]
		--, CAST( 'QTRIST01' AS CHAR(10) ) AS [UPDC]
		, CAST( '' AS CHAR(10) ) AS [UPDP]
		, CAST( '' AS CHAR(10) ) AS [UPDC]
		, 0 AS [DELF]
		, '' AS [DELDT] 
		, '' AS [DELP]
		, '' AS [DELC]
	FROM (
		--**-------------------------------(## START FSTK)-------------------------------**--
		---- # type_data 1: head, 2: body, 3: footer
		SELECT 'FSTK' AS [ROVANSFILE]
			, 1 AS [order_by]
			, ROW_NUMBER() OVER ( ORDER BY [type_data], [row_number] ) AS [row_number] 
			, ( CASE
				WHEN [ROVANSDATA] = 'GEE' THEN CAST( [ROVANSDATA] + FORMAT( ROW_NUMBER() OVER ( ORDER BY [type_data], [row_number] ) - 1, '000000' ) + 'FSTK' AS CHAR(80) )
				ELSE [ROVANSDATA]
			END ) AS [ROVANSDATA]
		FROM (
			---------------------------------(START HEAD1 FSTK)---------------------------------
			SELECT 1 AS [type_data]
				, 1 AS [row_number]
				, CAST( '*CC,ZZROHM0011' AS CHAR(80) ) AS [ROVANSDATA]
			---------------------------------(END HEAD1 FSTK)---------------------------------
			UNION ALL
			---------------------------------(START HEAD2 FSTK)---------------------------------
			SELECT 2 AS [type_data]
				, 1 AS [row_number]
				, CAST( 'GESGEIS1.000ZZROHM0024' AS CHAR(22) )  
					+ SPACE(7) 
					+ CAST( 'ZZROHM0010' AS CHAR(10) )  
					+ SPACE(7) 
					+ CAST( FORMAT( GETDATE(), 'yyMMddHHmm' ) AS CHAR(10) ) 
					+ CAST( 'FSTK' AS CHAR(4) )
					+ SPACE(20) AS [ROVANSDATA]
			---------------------------------(END HEAD2 FSTK)---------------------------------
			UNION ALL
			---------------------------------(START BOBY FSTK)---------------------------------
			SELECT 3 AS [type_data]
				, ROW_NUMBER() OVER ( ORDER BY (SELECT 1) ) AS [row_number]
				, CAST( [Record_Class] AS CHAR(2) )
					+ CAST( FORMAT( GETDATE(), 'yyMMdd' ) AS CHAR(6) )
					+ CAST( [Warehouse_Code] AS CHAR(5) ) 
					+ CAST( FORMAT( GETDATE(), 'yyMMdd' ) AS CHAR(6) )
					+ CAST( [ROHM_Model_Name] AS CHAR(20) ) 
					+ FORMAT( [QTY], '000000000' )
					+ CAST( ISNULL([RED_BLACK_Flag], '' ) AS CHAR(1) )
					+ CAST( [ORNo] AS CHAR(12))
					+ SPACE(9)
					+ CAST( [LotNo] AS CHAR(10) ) AS [ROVANSDATA]
			FROM @table_wh_ukeba
			UNION ALL
			SELECT 4 AS [type_data]
				, ROW_NUMBER() OVER ( ORDER BY [stock_class], [name], [serial_no] ) AS [row_number]
				, CAST( '92' AS CHAR(2) )
					+ CAST( FORMAT( GETDATE(), 'yyMMdd' ) AS CHAR(6) )
					+ CAST( ISNULL( [pdcd], '' ) AS CHAR(5) ) 
					+ CAST( FORMAT( [created_at], 'yyMMdd' ) AS CHAR(6) )
					+ CAST( [name] AS CHAR(20) ) 
					+ FORMAT( [pcs], '000000000' )
					+ CAST( '0' AS CHAR(1) )
					+ SPACE(31) AS [ROVANSDATA]
			FROM @table_v_h_stock
			---------------------------------(END BOBY FSTK)---------------------------------
			UNION ALL
			---------------------------------(START FOOTER FSTK)---------------------------------
			SELECT 5 AS [type_data]
				, 1 AS [row_number]
				, 'GEE' AS [ROVANSDATA]
			---------------------------------(END FOOTER FSTK)---------------------------------
		) AS [FSTK]
		--**-------------------------------(## END FSTK)-------------------------------**--
		UNION ALL
		--**-------------------------------(## START FJ01)-------------------------------**--
		---- # type_data 1: head, 2: body, 3: footer
		SELECT 'FJ01' AS [ROVANSFILE]
			, 2 AS [order_by]
			, ROW_NUMBER() OVER ( ORDER BY [type_data], [row_number] ) AS [row_number] 
			, [ROVANSDATA]
				
		FROM (
			---------------------------------(START HEAD FJ01)---------------------------------
			SELECT 1 AS [type_data]
				, 1 AS [row_number]
				, CAST( 'GESGEIS1.000ZZROHM0024' AS CHAR(22) )  
					+ SPACE(7) 
					+ CAST( 'ZZROHM0011' AS CHAR(10) )  
					+ SPACE(7) 
					+ CAST( FORMAT( GETDATE(), 'yyMMddHHmm' ) AS CHAR(10) ) 
					+ CAST('FJ02' AS CHAR(4))
					+ SPACE(20) AS [ROVANSDATA]
			---------------------------------(END HEAD FJ01)---------------------------------
			UNION ALL
			---------------------------------(START BOBY FJ01)---------------------------------
			SELECT 	2 AS [type_data]
				, ROW_NUMBER() OVER ( ORDER BY (SELECT 1) ) AS [row_number]
				, CAST( 'QI100' AS CHAR(5) )
					+ CAST( [device_names].[name] AS CHAR(20) ) 
					+ CAST( ISNULL( [device_names].[rank], '' ) AS CHAR(5) ) 
					+ CAST( ISNULL( [device_names].[tp_rank], '' ) AS CHAR(3) )
					+ CAST( [packages].[short_name] AS CHAR(10) ) 
					+ CAST( [lots].[lot_no] AS CHAR(10) )
					+ FORMAT( [v_cps_stk].[MZAS], '000000' )
					+ SUBSTRING( [v_cps_stk].[NKJD], 3, 8 ) 
					+ SPACE(15) AS [ROVANSDATA]
			FROM [CPSDB].[IFDB].[dbo].[V_CPS_STK] AS [v_cps_stk]
			INNER JOIN [APCSProDB].[trans].[lots] ON [v_cps_stk].[LOTN] = [lots].[lot_no]
			INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
			---------------------------------(END BOBY FJ01)---------------------------------
			UNION ALL
			---------------------------------(START FOOTER FJ01)---------------------------------
			SELECT 3 AS [type_data]
				, 1 AS [row_number]
				, CAST( 'GEE' + FORMAT( (SUM( [ROVANSDATA] ) + 3) - 1, '000000' ) + 'FJ01' AS CHAR(80) ) AS [ROVANSDATA] 
			FROM (
				SELECT COUNT( [LotNo] ) AS [ROVANSDATA], 'FJ01' AS [ROVANSFILE] 
				from @table_wh_ukeba
				UNION ALL
				SELECT COUNT( [serial_no] ) AS [ROVANSDATA], 'FJ01' AS [ROVANSFILE] 
				FROM @table_v_h_stock
			) AS [tcount] 
			GROUP BY [ROVANSFILE]
			---------------------------------(END FOOTER FJ01)---------------------------------
		) AS [FJ01]
		--**-------------------------------(## END FJ01)-------------------------------**--
		UNION ALL
		--**-------------------------------(## START FJ02)-------------------------------**--
		---- # type_data 1: head, 2: body, 3: footer
		SELECT 'FJ02' AS [ROVANSFILE]
			, 3 AS [order_by]
			, ROW_NUMBER() OVER ( ORDER BY [type_data], [row_number] ) AS [row_number] 
			, ( CASE
				WHEN [ROVANSDATA] = 'GEE' THEN CAST( [ROVANSDATA] + FORMAT( ROW_NUMBER() OVER ( ORDER BY [type_data], [row_number] ), '000000' ) + 'FJ02' AS CHAR(80) )
				ELSE [ROVANSDATA]
			END ) AS [ROVANSDATA]
		FROM (
			---------------------------------(START HEAD FJ02)---------------------------------
			SELECT 1 AS [type_data]
				, 1 AS [row_number]
				, CAST( 'GESGEIS1.000ZZROHM0024' AS CHAR(22) )  
					+ SPACE(7) 
					+ CAST( 'ZZROHM0011' AS CHAR(10) )  
					+ SPACE(7) 
					+ CAST( FORMAT( GETDATE(), 'yyMMddHHmm' ) AS CHAR(10) ) 
					+ CAST( 'FJ02' AS CHAR(4) )
					+ SPACE(20) AS [ROVANSDATA]
			---------------------------------(END HEAD FJ02)---------------------------------
			UNION ALL
			---------------------------------(START BOBY FJ02)---------------------------------
			SELECT 2 AS [type_data]
				, ROW_NUMBER() OVER ( ORDER BY [stock_class], [name], [serial_no] ) [row_number]
				, CAST( 'QI000' AS CHAR(5) )
					+ CAST( [stock_class] AS CHAR(2) ) 
					+ CAST( [name] AS CHAR(20) ) 
					+ CAST( ISNULL( [rank], '' ) AS CHAR(5) ) 
					+ CAST( ISNULL( [tp_rank], '' ) AS CHAR(3) ) 
					+ CAST( [short_name] AS CHAR(10) ) 
					+ CAST( [serial_no] AS CHAR(10) )
					+ FORMAT( [pcs], '000000' )
					+ CAST( FORMAT( [created_at], 'yyMMdd' ) AS CHAR(6) )
					+ SPACE(13) AS [ROVANSDATA]
			FROM @table_v_h_stock
			---------------------------------(END BOBY FJ02)---------------------------------
			UNION ALL
			---------------------------------(START FOOTER FJ02)---------------------------------
			SELECT 3 AS [type_data]
				, 1 AS [row_number]
				, 'GEE' AS [ROVANSDATA]
			---------------------------------(END FOOTER FJ02)---------------------------------
		) AS [FJ02]
		--**-------------------------------(## END FJ02)-------------------------------**--
	) AS [ADM00001];
	---------------------------------(END INSERT @table_adm00001)---------------------------------	

	--SELECT wh_if.LotNo
	--	, [Delete_Flag]
	--	, 1 AS [New_Delete_Flag]
	--FROM @table_wh_ukeba AS wh
	--INNER JOIN [APCSProDWH].[dbo].[WH_UKEBA_IF] AS wh_if ON wh.LotNo = wh_if.LotNo

	INSERT INTO [APCSProDWH].[dbo].[adm00001_table]
		( [writetime]
        , [seqno6]
        , [rovansfile]
        , [rovansdata]
        , [sendendfl]
        , [makdt]
        , [makp]
        , [makc]
        , [upddt]
        , [updp]
        , [updc]
        , [delf]
        , [deldt]
        , [delp]
        , [delc] )
	SELECT [WRITETIME]
		, [SEQNO6]
		, [ROVANSFILE]
		, [ROVANSDATA]
		, [SENDENDFL]
		, [MAKDT]
		, [MAKP]
		, [MAKC]
		, [UPDDT]
		, [UPDP]
		, [UPDC]
		, [DELF]
		, [DELDT]
		, [DELP]
		, [DELC]
	FROM @table_adm00001
	ORDER BY SEQNO6 ASC;

	UPDATE [wh_ukeba_table]
	SET [wh_ukeba_table].[send_flag] = 1
	FROM [APCSProDWH].[dbo].[wh_ukeba_table]
	INNER JOIN @table_wh_ukeba AS [wh_ukeba] ON [wh_ukeba_table].[lot_no] = [wh_ukeba].[LotNo];
END
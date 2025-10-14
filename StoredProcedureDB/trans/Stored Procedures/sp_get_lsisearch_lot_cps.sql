-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [trans].[sp_get_lsisearch_lot_cps]
	-- Add the parameters for the stored procedure here
		  @LotNo      NVARCHAR(100)		= NULL
		--, @Device     INT				= NULL
		--, @Package    INT				= NULL
		, @Device     NVARCHAR(100)		= NULL
		, @Package    NVARCHAR(100)		= NULL
		, @Time1	  DATETIME
		, @Time2	  DATETIME
		, @Status     NVARCHAR(100)		= NULL

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

			--SELECT	  [SHIPDATE]
			--		, [TIME]
			--		, [LOTNO]
			--		, [MODEL]
			--		, [QTY]
			--		, [PACKAGE]
			--		, [TOMSON]
			--		, [PRODUCTCODE]
			--		, [CPSDATA]
			--		, [OPNo]​
			--FROM (SELECT CONVERT(varchar,dbdata.LotEndTime,103)		AS [SHIPDATE]​
			--		, CONVERT(varchar,dbdata.LotEndTime,108)		AS [TIME]​
			--		, dbdata.LotNo									AS [LOTNO]​
			--		, tdata.ETC2									AS [MODEL]​
			--		, dbdata.TotalGood								AS [QTY]​
			--		, tdata.Package									AS [PACKAGE]​
			--		, lot.act_package_id
			--		, lot.act_device_name_id
			--		, CASE WHEN (SELECT dn.is_incoming FROM APCSProDB.trans.lots AS lot​
			--						INNER JOIN APCSProDB.method.device_names as dn 
			--						ON lot.act_device_name_id = dn.id​
			--						WHERE lot_no = dbdata.LotNo) = 1​
			--				THEN (SELECT SUM(incoming_labels.total_of_box) 
			--						FROM APCSProDB.trans.incoming_label_details​
			--						INNER JOIN APCSProDB.trans.incoming_labels 
			--						ON incoming_label_details.incoming_id = incoming_labels.id​
			--						WHERE incoming_label_details.lot_no = dbdata.LotNo)​
			--				ELSE ISNULL(dbdata.ReelCount,0) 
			--				END AS [TOMSON]​
			--		, dbdata.ProductCode AS [PRODUCTCODE]​
			--		, CASE ​ WHEN dbdata.CPS_State = 3  THEN 'ERROR'​
			--				WHEN dbdata.CPS_State = 2  THEN 'HOLD'​
			--				WHEN dbdata.CPS_State = 1  THEN 'SHIP'​
			--		  ELSE ​ CASE  WHEN dbdata.MCNo = 'WEBTG' THEN 'HASUU' 
			--				ELSE dbdata.LotNo END​
			--		  END AS [CPSDATA]​
			--		, dbdata.OPNo AS [OPNo]​
			--		, LotEndTime​
			--	FROM	(	SELECT * 
			--				FROM dbx.dbo.OGIData 
			--				WHERE LotEndTime IS NOT NULL
			--			) AS dbdata​
			--	INNER JOIN dbx.dbo.TransactionData AS tdata 
			--	ON dbdata.LotNo = tdata.LotNo​
			--	LEFT JOIN APCSProDB.trans.lots AS lot​
			--	ON lot.lot_no =  dbdata.LotNo
			--	--WHERE (dbdata.LotNo				=  @LotNo	OR  @LotNo	IS NULL  )​
			--	--AND (lot.act_device_name_id		=  @Device  OR @Device	IS NULL )​
			--	--AND (lot.act_package_id			=  @Package OR @Package IS NULL )​
			--	--AND (dbdata.LotEndTime BETWEEN @Time1 AND @Time2)​
			--	--AND (dbdata.CPS_State != 1)) AS data​

			--	WHERE (dbdata.LotNo			LIKE '%' + @LotNo OR @LotNo	IS NULL)​
			--	AND (tdata.ETC2				LIKE '%' + @Device OR @Device IS NULL)​
			--	AND (tdata.Package			LIKE '%' + @Package OR @Package	IS NULL)​
			--	AND (dbdata.LotEndTime BETWEEN @Time1 AND @Time2)​
			--	AND (dbdata.CPS_State != 1)) AS data​

			--WHERE (data.CPSDATA LIKE @Status​ OR @Status IS NULL )
			--AND [CPSDATA] != 'HASUU'​
			--ORDER BY LotEndTime
			--, LotNo​
		SELECT  [SHIPDATE]
			, [TIME]
			, [LOTNO]
			, [MODEL]
			, [QTY]
			, [PACKAGE]
			, [TOMSON]
			, [PRODUCTCODE]
			, [CPSDATA]
			, [OPNo]
			--, [MNO]
			, [MCNO]
		FROM (SELECT CONVERT(varchar,dbdata.LotEndTime,103) AS [SHIPDATE]
		, CONVERT(varchar,dbdata.LotEndTime,108) AS [TIME]
		, dbdata.LotNo AS [LOTNO]
		, tdata.ETC2 AS [MODEL]
		, dbdata.TotalGood AS [QTY]
		, tdata.Package AS [PACKAGE]
		, CASE WHEN (select dn.is_incoming from APCSProDB.trans.lots as lot
				inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
				where lot_no = dbdata.LotNo) = 1
		THEN (select sum(incoming_labels.total_of_box) from APCSProDB.trans.incoming_label_details
			inner join APCSProDB.trans.incoming_labels on incoming_label_details.incoming_id = incoming_labels.id
			where incoming_label_details.lot_no = dbdata.LotNo)
		ELSE ISNULL(dbdata.ReelCount,0) END AS [TOMSON]
		, dbdata.ProductCode AS [PRODUCTCODE]
		, CASE 
		WHEN dbdata.CPS_State = 3  THEN 'ERROR'
		WHEN dbdata.CPS_State = 2  THEN 'HOLD'
		WHEN dbdata.CPS_State = 1  THEN 'SHIP'
		ELSE 
			CASE WHEN dbdata.MCNo = 'WEBTG' THEN 'HASUU' ELSE dbdata.LotNo END
		END AS [CPSDATA]
		, dbdata.OPNo AS [OPNo]
		, LotEndTime
		--, TRIM(labels.mno_std) + ' | ' +   TRIM(labels.mno_hasuu)  AS [MNO]
		,CASE
			WHEN TRIM(labels.mno_std) IS NOT NULL AND TRIM(labels.mno_hasuu) IS NOT NULL AND TRIM(labels.mno_hasuu) != '' THEN TRIM(labels.mno_std) + ' | ' + TRIM(labels.mno_hasuu)
			WHEN TRIM(labels.mno_std) IS NOT NULL THEN TRIM(labels.mno_std)
			WHEN TRIM(labels.mno_hasuu) IS NOT NULL AND TRIM(labels.mno_hasuu) != '' THEN TRIM(labels.mno_hasuu)
			ELSE '-'
		END AS [MCNO]
		FROM (SELECT * FROM dbx.dbo.OGIData WHERE LotEndTime is not null) AS dbdata
		INNER JOIN dbx.dbo.TransactionData AS tdata ON dbdata.LotNo = tdata.LotNo
		LEFT JOIN APCSProDB.trans.label_issue_records labels
		ON tdata.LotNo = labels.lot_no
		AND labels.type_of_label =  3 
		AND no_reel= 1
		WHERE
		(dbdata.LotNo LIKE '%' + @LotNo OR @LotNo	IS NULL )
		AND (tdata.ETC2 LIKE '%' + @Device OR @Device	IS NULL )
		AND (tdata.Package LIKE '%' + @Package OR @Package	IS NULL )
		AND (dbdata.LotEndTime BETWEEN @Time1 AND @Time2)
		AND (dbdata.CPS_State != 1)
		) as data
		WHERE data.CPSDATA LIKE @Status
			AND 
			[CPSDATA] != 'HASUU'
		ORDER BY LotEndTime, LotNo

END

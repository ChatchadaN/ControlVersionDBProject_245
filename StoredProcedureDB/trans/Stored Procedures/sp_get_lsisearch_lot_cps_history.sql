-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [trans].[sp_get_lsisearch_lot_cps_history]
	-- Add the parameters for the stored procedure here
		  @LotNo		NVARCHAR(100)		= NULL 
		--, @Device		INT					= NULL 
		--, @Package		INT				= NULL 
		, @Device		NVARCHAR(100)		= NULL 
		, @Package		NVARCHAR(100)		= NULL 
		, @Time1		DATETIME
		, @Time2		DATETIME

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	SELECT   CONVERT(varchar,dbdata.LotEndTime,103) AS [SHIPDATE]
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
                                        , dbdata.LotNo as [CPSDATA]
	                                    , CASE 
                                            WHEN dbdata.MCNo = 'WEBTG' THEN 'HASUU' 
                                            ELSE 'SHIP'
                                          END AS [STATUS]
										--, TRIM(labels.mno_std) + ' | ' +   TRIM(labels.mno_hasuu)  AS [MCNO]
										--,CASE 
										--	WHEN (TRIM(labels.mno_std) IS NOT NULL) AND (TRIM(labels.mno_hasuu) IS NOT NULL) THEN TRIM(labels.mno_std) + ' | ' + TRIM(labels.mno_hasuu)
										--	WHEN TRIM(labels.mno_std) IS NOT NULL THEN TRIM(labels.mno_hasuu)
										--	WHEN TRIM(labels.mno_hasuu) IS NOT NULL THEN TRIM(labels.mno_std)
										--	ELSE ''
										--END AS [MCNO]
										,CASE
											WHEN TRIM(labels.mno_std) IS NOT NULL AND TRIM(labels.mno_hasuu) IS NOT NULL AND TRIM(labels.mno_hasuu) != '' THEN TRIM(labels.mno_std) + ' | ' + TRIM(labels.mno_hasuu)
											WHEN TRIM(labels.mno_std) IS NOT NULL THEN TRIM(labels.mno_std)
											WHEN TRIM(labels.mno_hasuu) IS NOT NULL AND TRIM(labels.mno_hasuu) != '' THEN TRIM(labels.mno_hasuu)
											ELSE '-'
										END AS [MCNO]
                                FROM (SELECT * FROM dbx.dbo.OGIData WHERE LotEndTime is not null) AS dbdata
                                INNER JOIN dbx.dbo.TransactionData AS tdata 
								ON dbdata.LotNo = tdata.LotNo
								LEFT JOIN APCSProDB.trans.label_issue_records labels
								ON tdata.LotNo = labels.lot_no
								AND labels.type_of_label =  3 
								AND no_reel= 1
                                WHERE 
									--(dbdata.LotNo LIKE '%' + @LotNo OR @LotNo	IS NULL )
	        --                        AND (tdata.ETC2 LIKE '%' + @Device OR @Device	IS NULL )
	        --                        AND (tdata.Package LIKE '%' + @Package OR @Package	IS NULL )
									(dbdata.LotNo = @LotNo	OR @LotNo	IS NULL )
	                                AND (tdata.ETC2 = @Device	OR @Device	IS NULL)
	                                AND (tdata.Package = @Package	OR @Package IS NULL)
	                                AND (dbdata.LotEndTime BETWEEN @Time1 AND @Time2) AND
	                                  (dbdata.CPS_State = 1)
                                    AND dbdata.MCNo != 'WEBTG'
                                ORDER BY dbdata.LotEndTime,dbdata.LotNo

	 
			--SELECT		  CONVERT(varchar,lot_process_records.recorded_at,103)	AS [SHIPDATE]​
			--			, CONVERT(varchar,lot_process_records.recorded_at,108)	AS [TIME]​
			--			, lots.lot_no								AS [LOTNO]​
			--			, device_names.name								AS [MODEL]​
			--			, lot_process_records.qty_out						AS [QTY]​
			--			, packages.name								AS [PACKAGE]​ 
			--			, CASE WHEN	 device_names.is_incoming  	= 1​
			--				   THEN incoming.total_of_box
			--					ELSE   CASE WHEN [lots].[pc_instruction_code] = 11 THEN  (count_label_5.type_of_label + count_label_21.type_of_label )
			--							WHEN  [lots].[pc_instruction_code] = 13 THEN  1
			--							ELSE count_label_5.type_of_label  END 
			--					END AS [TOMSON]​
			--			, surpluses.pdcd AS [PRODUCTCODE]​
			--			, lots.lot_no as [CPSDATA]​
			--			,item_labels.label_eng AS  [STATUS]​
			--			,'' AS MCNo
			--	FROM  APCSProDB.trans.lots  
			--	INNER JOIN APCSProDB.trans.lot_process_records  
			--	ON  lots.id		= lot_process_records.lot_id​
			--	AND lot_process_records.record_class = 7 
			--	INNER JOIN APCSProDB.trans.surpluses
			--	ON lots.id  = surpluses.lot_id 
			--	INNER JOIN APCSProDB.trans.item_labels
			--	ON name =  'lots.wip_state'
			--	AND item_labels.val  =  lots.wip_state
			--	INNER JOIN APCSProDB.method.packages
			--	ON packages.id  = lots.act_package_id
			--	INNER JOIN APCSProDB.method.device_names 
			--	ON lots.act_device_name_id	= device_names.id​ 
			--	OUTER APPLY (SELECT SUM(incoming_labels.total_of_box)  AS total_of_box
			--							FROM APCSProDB.trans.incoming_label_details​
			--							INNER JOIN APCSProDB.trans.incoming_labels 
			--							ON incoming_label_details.incoming_id = incoming_labels.id​
			--							WHERE  incoming_label_details.lot_no = lots.lot_no
			--					) AS incoming
			--	OUTER APPLY (SELECT COUNT([no_reel]) AS type_of_label 
			--				FROM	[APCSProDB].[trans].[label_issue_records]
			--					WHERE type_of_label = 5 AND [label_issue_records].lot_no  = lots.lot_no
			--					) AS count_label_5
			--	OUTER APPLY (SELECT COUNT([no_reel]) AS type_of_label 
			--				FROM	[APCSProDB].[trans].[label_issue_records]
			--					WHERE type_of_label = 21 AND [label_issue_records].lot_no  = lots.lot_no
			--					) AS count_label_21
			--	--WHERE   (lots.lot_no				= @LotNo	OR @LotNo	IS NULL	)​
			--	--AND (lots.act_device_name_id		= @Device	OR @Device	IS NULL	)​
			--	--AND (lots.act_package_id			= @Package	OR @Package	IS NULL	)​
			--	--AND (lot_process_records.recorded_at BETWEEN @Time1 AND @Time2)​
			--	--AND lots.wip_state  =  100 
			--	--ORDER BY lot_process_records.recorded_at,lots.lot_no​

			--	WHERE (lots.lot_no		LIKE '%' + @LotNo OR @LotNo	IS NULL )​
			--	AND (device_names.name	LIKE '%' + @Device OR @Device IS NULL)​
			--	AND (packages.name		LIKE '%' + @Package OR @Package	IS NULL)​
			--	AND (lot_process_records.recorded_at BETWEEN @Time1 AND @Time2)​
			--	AND lots.wip_state  =  100 
			--	ORDER BY lot_process_records.recorded_at,lots.lot_no​

	 
	--SELECT  CONVERT(varchar,dbdata.LotEndTime,103)	AS [SHIPDATE]​
 --           , CONVERT(varchar,dbdata.LotEndTime,108)	AS [TIME]​
 --           , dbdata.LotNo								AS [LOTNO]​
 --           , tdata.ETC2								AS [MODEL]​
 --           , dbdata.TotalGood							AS [QTY]​
 --           , tdata.Package								AS [PACKAGE]​
 --           , CASE WHEN	(SELECT dn.is_incoming 
	--						FROM APCSProDB.trans.lots AS lot​
	--						INNER JOIN APCSProDB.method.device_names AS dn 
	--						ON lot.act_device_name_id		= dn.id​
	--						WHERE  lot_no = dbdata.LotNo)	= 1​
	--			   THEN (SELECT SUM(incoming_labels.total_of_box) 
	--						FROM APCSProDB.trans.incoming_label_details​
	--						INNER JOIN APCSProDB.trans.incoming_labels 
	--						ON incoming_label_details.incoming_id = incoming_labels.id​
	--						WHERE  incoming_label_details.lot_no = dbdata.LotNo)
	--				ELSE ISNULL(dbdata.ReelCount,0) END AS [TOMSON]​
	--		, surpluses.pdcd AS [PRODUCTCODE]​
	--		, dbdata.LotNo as [CPSDATA]​
	--		, lots.wip_state 
	--		, CASE WHEN dbdata.MCNo = 'WEBTG' THEN 'HASUU' ​  ELSE 'SHIP'​  END AS [STATUS]​
	--FROM  (SELECT * FROM dbx.dbo.OGIData WHERE LotEndTime IS NOT NULL) AS dbdata​
	--INNER JOIN dbx.dbo.TransactionData AS tdata 
	--ON dbdata.LotNo		= tdata.LotNo​
	--LEFT JOIN APCSProDB.trans.lots 
	--ON lots.lot_no		= tdata.LotNo
	--INNER JOIN APCSProDB.trans.surpluses
	--ON lots.id  = surpluses.lot_id 
	--WHERE (dbdata.LotNo					= @LotNo	OR @LotNo	IS NULL	)​
	--AND (lots.act_device_name_id		= @Device	OR @Device	IS NULL	)​
	--AND (lots.act_package_id			= @Package	OR @Package	IS NULL	)​
	--AND (dbdata.LotEndTime BETWEEN @Time1 AND @Time2)​
	--AND (dbdata.CPS_State = 1)​
	--AND lots.wip_state  =  100
	--ORDER BY dbdata.LotEndTime,dbdata.LotNo​
  
END

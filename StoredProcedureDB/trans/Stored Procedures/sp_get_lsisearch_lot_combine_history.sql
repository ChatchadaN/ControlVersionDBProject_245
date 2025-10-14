-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [trans].[sp_get_lsisearch_lot_combine_history]
	-- Add the parameters for the stored procedure here
		  @LotNo      NVARCHAR(100)		= NULL
		, @Device     INT				= NULL
		, @Package    INT				= NULL
		, @Time1	  DATETIME
		, @Time2	  DATETIME
		 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

		SELECT    Package  
				, Device  
				, Lot ​
				, HasuuLot 
				, qty_good 
				, hasuu_lot_before 
				, qty_combine 
				, qty_out
				, created_at
		FROM	(SELECT   pk.name						AS Package 
						, pk.id							AS Package_id
						, dn.name						AS Device 
						, dn.id							AS Device_id
						, l.lot_no						AS Lot ​
						, lm.lot_no						AS HasuuLot 
						, l.qty_pass					AS qty_good 
						, l.qty_combined				AS hasuu_lot_before 
						, l.qty_pass + l.qty_combined	AS qty_combine 
						, l.qty_out 
						, lc.created_at ​
				FROM [APCSProDB].[trans].[lot_combine] lc
				INNER JOIN [APCSProDB].trans.lots l 
				ON l.id = lc.lot_id 
				AND l.wip_state <> 200 
				AND l.wip_state <> 70
				INNER JOIN trans.lots lm 
				ON lm.id = lc.member_lot_id 
				AND l.wip_state <> 200 
				AND l.wip_state <> 70 ​
				INNER JOIN [APCSProDB].method.device_names dn 
				ON dn.id = l.act_device_name_id
				INNER JOIN [APCSProDB].method.packages pk 
				ON pk.id = dn.package_id
				WHERE (l.lot_no NOT LIKE '%D%' ) 
		UNION ​
				SELECT    pk.name				AS Package 
						, pk.id					AS Package_id
						, dn.name				AS Device 
						, dn.id					AS Device_id
						, l.lot_no				AS Lot 
						, lm.lot_no				AS HasuuLot 
						, lm.qty_hasuu			AS qty_good      
						, 0						AS hasuu_lot_before 
						, 0						AS qty_combine 
						, l.qty_out 
						, lc.created_at
				FROM [APCSProDB].[trans].[lot_combine] lc
				INNER JOIN [APCSProDB].trans.lots l 
				ON  l.id = lc.lot_id 
				AND l.wip_state <> 200 
				AND l.wip_state <> 70
				INNER JOIN [APCSProDB].trans.lots lm 
				ON lm.id = lc.member_lot_id 
				AND l.wip_state <> 200 
				AND l.wip_state <> 70
				INNER JOIN [APCSProDB].method.device_names dn 
				ON dn.id = l.act_device_name_id
				INNER JOIN [APCSProDB].method.packages pk 
				on pk.id = dn.package_id
				WHERE (l.lot_no LIKE '%D%' )
		UNION ​
				SELECT	  pk.name			AS Package 
						, pk.id				AS Package_id
						, dn.name			AS Device 
						, dn.id				AS Device_id
						, l.lot_no			AS Lot 
						, l.lot_no			AS HasuuLot 
						, SUM(lm.qty_hasuu) AS qty_good 
						, 0					AS hasuu_lot_before 
						, 0					AS qty_combine 
						, l.qty_out 
						, lc.created_at ​
				FROM [APCSProDB].[trans].[lot_combine] lc ​
				INNER JOIN [APCSProDB].trans.lots l 
				on l.id = lc.lot_id 
				AND l.wip_state <> 200 
				AND l.wip_state <> 70
				INNER JOIN [APCSProDB].trans.lots lm 
				ON lm.id = lc.member_lot_id 
				AND l.wip_state <> 200 
				AND l.wip_state <> 70 ​
				INNER JOIN [APCSProDB].method.device_names dn 
				ON dn.id = l.act_device_name_id 
				INNER JOIN [APCSProDB].method.packages pk 
				ON pk.id = dn.package_id ​
				WHERE (l.lot_no LIKE '%D%' )
				GROUP BY pk.name,dn.name,[lot_id],l.lot_no,l.qty_out,lc.created_at, pk.id, dn.id
				) AS data_combine 
        WHERE (data_combine.Lot			= @LotNo	OR @LotNo	IS NULL )
        AND (data_combine.Device_id		= @Device	OR @Device	IS NULL)  
		AND (data_combine.Package_id	= @Package	OR @Package IS NULL) 
		AND (data_combine.created_at BETWEEN @Time1 AND @Time2)
        ORDER BY data_combine.created_at DESC 


END
